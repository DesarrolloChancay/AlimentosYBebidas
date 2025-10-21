from flask_socketio import SocketIO, emit, join_room, leave_room
from flask import session
from app.extensions import socketio
from app.controllers.inspecciones_controller import datos_tiempo_real

@socketio.on('connect')
def handle_connect():
    emit('connected', {'mensaje': 'Conectado exitosamente'})

@socketio.on('join_inspeccion')
def on_join_inspeccion(data):
    """Cliente se une a la sala de una inspección específica"""
    inspeccion_id = data.get('inspeccion_id')
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    if not inspeccion_id:
        emit('error', {'msg': 'ID de inspección requerido'})
        return
    
    room = f"inspeccion_{inspeccion_id}"
    join_room(room)
    
    # Notificar a todos en la sala
    emit('usuario_unido', {
        'usuario': session.get('user_name', 'Usuario'),
        'role': user_role,
        'inspeccion_id': inspeccion_id
    }, to=room)
    

@socketio.on('join_establecimiento')
def handle_join_establecimiento(data):
    """Unirse a una sala de establecimiento para tiempo real sin inspección activa"""
    establecimiento_id = data.get('establecimiento_id')
    usuario_id = data.get('usuario_id')
    role = data.get('role')
    
    if establecimiento_id:
        room = f"establecimiento_{establecimiento_id}"
        join_room(room)
        

@socketio.on('item_rating_tiempo_real')
def handle_item_rating_tiempo_real(data):
    """Manejar calificaciones en tiempo real para que el encargado las vea"""
    establecimiento_id = data.get('establecimiento_id')
    actualizado_por = data.get('actualizado_por')
    resumen = data.get('resumen', {})
    items = data.get('items', {})
    observaciones = data.get('observaciones', '')
    timestamp = data.get('timestamp')
    confirmada_por_encargado = data.get('confirmada_por_encargado')
    confirmador_nombre = data.get('confirmador_nombre')
    confirmador_rol = data.get('confirmador_rol')

    
    if establecimiento_id:
        room = f"establecimiento_{establecimiento_id}"
            
        clave_tiempo_real = f"establecimiento_{establecimiento_id}"
        estado_prev = datos_tiempo_real.get(clave_tiempo_real, {})

        if confirmada_por_encargado is None:
            confirmada_por_encargado = estado_prev.get('confirmada_por_encargado', False)
        if confirmada_por_encargado:
            if confirmador_nombre is None:
                confirmador_nombre = estado_prev.get('confirmador_nombre')
            if confirmador_rol is None:
                confirmador_rol = estado_prev.get('confirmador_rol')
        else:
            confirmador_nombre = None
            confirmador_rol = None

        datos_tiempo_real[clave_tiempo_real] = {
            'establecimiento_id': establecimiento_id,
            'actualizado_por': actualizado_por,
            'resumen': resumen,
            'timestamp': timestamp,
            'items': items,
            'observaciones': observaciones,
            'confirmada_por_encargado': bool(confirmada_por_encargado),
            'confirmador_nombre': confirmador_nombre,
            'confirmador_rol': confirmador_rol
        }
        
        # Emitir datos completos de tiempo real incluyendo resumen actualizado
        datos_emitir = {
            'establecimiento_id': establecimiento_id,
            'actualizado_por': actualizado_por,
            'resumen': resumen,
            'timestamp': timestamp,
            'items': items,
            'observaciones': observaciones,
            'confirmada_por_encargado': bool(confirmada_por_encargado),
            'confirmador_nombre': confirmador_nombre,
            'confirmador_rol': confirmador_rol
        }
        
        
        emit('inspeccion_tiempo_real', datos_emitir, to=room, include_self=False)
        

@socketio.on('leave_inspeccion')
def on_leave_inspeccion(data):
    """Cliente abandona la sala de inspección"""
    inspeccion_id = data.get('inspeccion_id')
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    room = f"inspeccion_{inspeccion_id}"
    leave_room(room)
    
    emit('usuario_salio', {
        'usuario': session.get('user_name', 'Usuario'),
        'inspeccion_id': inspeccion_id
    }, to=room)

@socketio.on('actualizar_item')
def handle_item_update(data):
    """Maneja la actualización en tiempo real de un item de inspección"""
    inspeccion_id = data.get('inspeccion_id')
    item_id = data.get('item_id')
    rating = data.get('rating')
    observacion = data.get('observacion', '')
    user_role = session.get('user_role')
    
    if not all([inspeccion_id, item_id, rating is not None]):
        emit('error', {'msg': 'Datos incompletos para actualizar item'})
        return
    
    room = f"inspeccion_{inspeccion_id}"
    
    # Enviar actualización a todos los clientes en la sala (excepto el que envía)
    emit('item_actualizado', {
        'inspeccion_id': inspeccion_id,
        'item_id': item_id,
        'rating': rating,
        'observacion': observacion,
        'actualizado_por': user_role,
        'usuario': session.get('user_name', 'Usuario')
    }, to=room, include_self=False)

@socketio.on('actualizar_observaciones')
def handle_observaciones_update(data):
    """Maneja la actualización de observaciones generales"""
    inspeccion_id = data.get('inspeccion_id')
    observaciones = data.get('observaciones', '')
    user_role = session.get('user_role')
    
    room = f"inspeccion_{inspeccion_id}"
    
    emit('observaciones_actualizadas', {
        'inspeccion_id': inspeccion_id,
        'observaciones': observaciones,
        'actualizado_por': user_role,
        'usuario': session.get('user_name', 'Usuario')
    }, to=room, include_self=False)

@socketio.on('cambiar_estado_inspeccion')
def handle_estado_change(data):
    """Maneja el cambio de estado de la inspección"""
    inspeccion_id = data.get('inspeccion_id')
    nuevo_estado = data.get('estado')
    user_role = session.get('user_role')
    
    room = f"inspeccion_{inspeccion_id}"
    
    emit('estado_inspeccion_cambiado', {
        'inspeccion_id': inspeccion_id,
        'estado': nuevo_estado,
        'cambiado_por': user_role,
        'completado_por': session.get('user_name', 'Usuario')
    }, to=room, include_self=False)

@socketio.on('solicitar_firma')
def handle_solicitud_firma(data):
    """Maneja solicitudes de firma del encargado"""
    inspeccion_id = data.get('inspeccion_id')
    tipo_firma = data.get('tipo')  # 'encargado' o 'inspector'
    user_role = session.get('user_role')
    
    room = f"inspeccion_{inspeccion_id}"
    
    emit('solicitud_firma', {
        'inspeccion_id': inspeccion_id,
        'tipo_firma': tipo_firma,
        'solicitado_por': user_role,
        'mensaje': 'Se solicita su firma para aprobar la inspección'
    }, to=room, include_self=False)

@socketio.on('encargado_aprobo')
def handle_encargado_aprobo(data):
    """Maneja cuando el encargado aprueba la inspección"""
    encargado_id = data.get('encargado_id')
    establecimiento_id = data.get('establecimiento_id')
    mensaje = data.get('mensaje', 'El encargado ha aprobado la inspección')
    firma_data = data.get('firma_data')
    
    # Emitir a todos los usuarios conectados (broadcast general)
    emit('encargado_aprobo', {
        'mensaje': mensaje,
        'encargado_id': encargado_id,
        'establecimiento_id': establecimiento_id,
        'firma_data': firma_data,
        'timestamp': data.get('timestamp')
    }, broadcast=True, include_self=False)

@socketio.on('notificacion_general')
def handle_notificacion_general(data):
    """Maneja notificaciones generales entre usuarios"""
    # Reenviar la notificación a todos los usuarios
    emit('notificacion_general', data, broadcast=True, include_self=False)

@socketio.on('disconnect')
def handle_disconnect():
    pass

@socketio.on('ping_keepalive')
def handle_ping_keepalive(data):
    """Responder a ping para mantener conexión activa en móviles"""
    emit('pong_keepalive', {'timestamp': data.get('timestamp'), 'server_time': __import__('time').time()})

@socketio.on('estado_completo_reconexion')
def handle_estado_completo_reconexion(data):
    """Manejar reenvío de estado completo tras reconexión"""
    inspeccion_id = data.get('inspeccion_id')
    establecimiento_id = data.get('establecimiento_id')

    if inspeccion_id:
        room = f"inspeccion_{inspeccion_id}"
        # Reenviar estado a todos en la sala para sincronizar
        emit('estado_sincronizado', {
            'inspeccion_id': inspeccion_id,
            'establecimiento_id': establecimiento_id,
            'items': data.get('items', {}),
            'observaciones': data.get('observaciones', ''),
            'resumen': data.get('resumen', {}),
            'evidencias_count': data.get('evidencias_count', 0),
            'reconectado': True
        }, to=room)


# Función auxiliar para emitir actualizaciones desde el controlador
def emitir_actualizacion_item(inspeccion_id, item_data):
    """Función para emitir actualizaciones desde otros módulos"""
    room = f"inspeccion_{inspeccion_id}"
    socketio.emit('item_actualizado', item_data, to=room)

def emitir_datos_tiempo_real_establecimiento(establecimiento_id, datos_completos):
    """Función para emitir datos completos de tiempo real al establecimiento"""
    room = f"establecimiento_{establecimiento_id}"
    socketio.emit('inspeccion_tiempo_real', datos_completos, to=room)
