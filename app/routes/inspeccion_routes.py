from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, flash
from app.controllers.inspecciones_controller import InspeccionesController
from datetime import datetime
from functools import wraps

inspeccion_bp = Blueprint('inspeccion', __name__)

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            if request.is_json:
                return jsonify({'error': 'Sesión requerida'}), 401
            return redirect(url_for('login_page'))
        return f(*args, **kwargs)
    return decorated_function

def role_required(allowed_roles):
    """Decorador para verificar roles específicos"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_role = session.get('user_role')
            if user_role not in allowed_roles:
                if request.is_json:
                    return jsonify({'error': 'Acceso denegado para su rol'}), 403
                return render_template('error.html', error='Acceso denegado'), 403
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@inspeccion_bp.route('/inspecciones')
@login_required
@role_required(['Inspector', 'Administrador'])
def historial_inspecciones():
    """Vista para buscar inspecciones guardadas"""
    user_role = session.get('user_role')
    return render_template('inspecciones.html', user_role=user_role)

@inspeccion_bp.route('/inspecciones/<int:inspeccion_id>/detalle')
@login_required
def detalle_inspeccion(inspeccion_id):
    """Vista detallada de una inspección específica"""
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    try:
        # Obtener la inspección
        from app.models.Inspecciones_models import Inspeccion
        inspeccion = Inspeccion.query.get_or_404(inspeccion_id)
        
        # Verificar permisos según el rol
        if user_role == 'Encargado':
            # Encargado solo puede ver inspecciones de sus establecimientos
            from app.models.Inspecciones_models import EncargadoEstablecimiento
            from datetime import date
            
            asignacion = EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.usuario_id == user_id,
                EncargadoEstablecimiento.establecimiento_id == inspeccion.establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= date.today()
            ).filter(
                (EncargadoEstablecimiento.fecha_fin.is_(None)) | 
                (EncargadoEstablecimiento.fecha_fin >= date.today())
            ).first()
            
            if not asignacion:
                return render_template('error.html', error='No tiene acceso a esta inspección'), 403
        
        # Obtener detalles completos de la inspección
        detalle_response = InspeccionesController.obtener_inspeccion_completa(inspeccion_id)
        if isinstance(detalle_response, tuple) and detalle_response[1] != 200:
            return render_template('error.html', error='Error al cargar inspección'), 500
            
        detalle = detalle_response[0].get_json() if hasattr(detalle_response[0], 'get_json') else detalle_response
        
        return render_template('detalle_inspeccion.html', 
                             inspeccion=detalle, 
                             user_role=user_role)
        
    except Exception as e:
        return render_template('error.html', error=f'Error al cargar inspección: {str(e)}'), 500

@inspeccion_bp.route('/')
@login_required
def index():
    """Ruta principal que valida sesión y carga la interfaz según rol"""
    from datetime import date
    
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    # Verificar que hay sesión válida (redundancia de seguridad)
    if not user_id or not user_role:
        session.clear()
        return redirect(url_for('login_page'))
    
    # Inicializar datos por defecto
    resumen = {
        'puntaje_total': 0,
        'puntaje_maximo': 0,
        'porcentaje_cumplimiento': 0,
        'puntos_criticos_perdidos': 0
    }
    
    plan_semanal = []
    establecimientos = []
    categorias = []
    
    try:
        # Obtener datos básicos para la interfaz según el rol
        if user_role in ['Administrador', 'Inspector']:
            # Admin e Inspector pueden ver plan semanal
            plan_response = InspeccionesController.obtener_plan_semanal()
            if isinstance(plan_response, tuple) and len(plan_response) == 2:
                if plan_response[1] == 200:
                    plan_semanal = plan_response[0].get_json()
            elif hasattr(plan_response, 'get_json'):
                plan_semanal = plan_response.get_json()
        
        # Todos los roles necesitan ver establecimientos (filtrados por rol)
        establecimientos_response = InspeccionesController.obtener_establecimientos()
        if isinstance(establecimientos_response, tuple) and len(establecimientos_response) == 2:
            if establecimientos_response[1] == 200:
                establecimientos = establecimientos_response[0].get_json()
        elif hasattr(establecimientos_response, 'get_json'):
            establecimientos = establecimientos_response.get_json()
            
        # Solo Inspector y Admin necesitan categorías completas
        if user_role in ['Administrador', 'Inspector']:
            categorias_response = InspeccionesController.obtener_categorias()
            if isinstance(categorias_response, tuple) and len(categorias_response) == 2:
                if categorias_response[1] == 200:
                    categorias = categorias_response[0].get_json()
            elif hasattr(categorias_response, 'get_json'):
                categorias = categorias_response.get_json()
                
    except Exception as e:
        print(f"Error inicializando datos: {str(e)}")
    
    # Obtener fecha actual
    fecha_actual = date.today().strftime('%Y-%m-%d')
    
    return render_template('index.html', 
                         resumen=resumen,
                         plan_semanal=plan_semanal,
                         establecimientos=establecimientos,
                         categorias=categorias,
                         fecha_actual=fecha_actual,
                         user_role=user_role)

@inspeccion_bp.route('/api/establecimientos')
@login_required
def get_establecimientos():
    return InspeccionesController.obtener_establecimientos()

@inspeccion_bp.route('/api/establecimientos/<int:establecimiento_id>/items')
@login_required
def get_items_establecimiento(establecimiento_id):
    """Solo cargar items cuando se selecciona un establecimiento"""
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    # Verificar que el usuario tiene acceso a este establecimiento
    if user_role == 'Encargado':
        # Verificar que el encargado está asignado a este establecimiento
        from app.models.Inspecciones_models import EncargadoEstablecimiento
        from datetime import date
        
        asignacion = EncargadoEstablecimiento.query.filter(
            EncargadoEstablecimiento.usuario_id == user_id,
            EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
            EncargadoEstablecimiento.activo == True,
            EncargadoEstablecimiento.fecha_inicio <= date.today()
        ).filter(
            (EncargadoEstablecimiento.fecha_fin.is_(None)) | 
            (EncargadoEstablecimiento.fecha_fin >= date.today())
        ).first()
        
        if not asignacion:
            return jsonify({'error': 'No tiene acceso a este establecimiento'}), 403
    
    return InspeccionesController.obtener_items_establecimiento(establecimiento_id)

@inspeccion_bp.route('/api/establecimientos/<int:establecimiento_id>/tiempo-real')
@login_required
def obtener_datos_tiempo_real(establecimiento_id):
    """Obtener datos en tiempo real de la inspección para el encargado"""
    return InspeccionesController.obtener_datos_tiempo_real_encargado(establecimiento_id)

@inspeccion_bp.route('/api/inspecciones/tiempo-real/establecimiento/<int:establecimiento_id>')
@login_required
def obtener_datos_tiempo_real_establecimiento(establecimiento_id):
    """Obtener datos actuales de tiempo real para un establecimiento específico"""
    return InspeccionesController.obtener_datos_tiempo_real_establecimiento(establecimiento_id)

@inspeccion_bp.route('/buscar')
@login_required
def buscar_inspecciones():
    """Vista para buscar inspecciones (para inspectores)"""
    user_role = session.get('user_role')
    if user_role not in ['Inspector', 'Admin']:
        flash('No tienes permisos para acceder a esta función.', 'error')
        return redirect(url_for('auth.index'))
    
    return render_template('buscar_inspecciones.html')

@inspeccion_bp.route('/api/inspecciones/buscar', methods=['GET'])
@login_required
def api_buscar_inspecciones():
    """API para buscar inspecciones con filtros"""
    return InspeccionesController.buscar_inspecciones()

@inspeccion_bp.route('/api/inspecciones/<int:inspeccion_id>/detalle')
@login_required 
def api_detalle_inspeccion(inspeccion_id):
    """API para obtener detalle de una inspección"""
    return InspeccionesController.obtener_detalle_inspeccion(inspeccion_id)

@inspeccion_bp.route('/api/inspecciones/temporal', methods=['POST'])
@login_required
def guardar_inspeccion_temporal():
    """Guardar cookie del formulario para que no se pierdan los datos"""
    return InspeccionesController.guardar_inspeccion_parcial()

@inspeccion_bp.route('/api/inspecciones/temporal', methods=['GET'])
@login_required
def obtener_inspeccion_temporal():
    """Recuperar cookie del formulario guardado"""
    return InspeccionesController.recuperar_inspeccion_temporal()

@inspeccion_bp.route('/api/inspecciones/temporal', methods=['DELETE'])
@login_required
def limpiar_inspeccion_temporal():
    """Borrar la cookie temporal al guardar la inspección"""
    return InspeccionesController.limpiar_inspeccion_temporal()

@inspeccion_bp.route('/api/inspecciones', methods=['POST'])
@login_required
def guardar_inspeccion():
    """Al guardar la inspección, se borrará la cookie temporal"""
    return InspeccionesController.guardar_inspeccion()

@inspeccion_bp.route('/api/inspecciones/<int:inspeccion_id>')
@login_required
def obtener_inspeccion(inspeccion_id):
    return InspeccionesController.obtener_inspeccion(inspeccion_id)

@inspeccion_bp.route('/api/informes')
@login_required
def obtener_informes():
    """El encargado podrá ver los informes solo de su establecimiento"""
    user_role = session.get('user_role')
    user_id = session.get('user_id')
    
    # Filtros desde query params
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    establecimiento_id = request.args.get('establecimiento_id', type=int)
    inspector_id = request.args.get('inspector_id', type=int)
    encargado_id = request.args.get('encargado_id', type=int)
    estado = request.args.get('estado')
    
    # Si es Encargado, solo puede ver informes de sus establecimientos
    if user_role == 'Encargado':
        encargado_id = user_id  # Forzar a ver solo sus informes
        
        # Si especifica un establecimiento, verificar que tiene acceso
        if establecimiento_id:
            from app.models.Inspecciones_models import EncargadoEstablecimiento
            from datetime import date
            
            asignacion = EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.usuario_id == user_id,
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= date.today()
            ).filter(
                (EncargadoEstablecimiento.fecha_fin.is_(None)) | 
                (EncargadoEstablecimiento.fecha_fin >= date.today())
            ).first()
            
            if not asignacion:
                return jsonify({'error': 'No tiene acceso a este establecimiento'}), 403
    
    return InspeccionesController.filtrar_inspecciones(
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        establecimiento_id=establecimiento_id,
        inspector_id=inspector_id,
        encargado_id=encargado_id,
        estado=estado
    )

@inspeccion_bp.route('/api/establecimientos/<int:establecimiento_id>/encargado')
@login_required
def obtener_encargado_actual(establecimiento_id):
    return InspeccionesController.obtener_encargado_actual(establecimiento_id)

@inspeccion_bp.route('/api/inspecciones')
@login_required
def filtrar_inspecciones():
    """Endpoint para filtrar inspecciones según criterios del pedido.txt"""
    fecha_inicio = request.args.get('fecha_inicio')
    fecha_fin = request.args.get('fecha_fin')
    establecimiento_id = request.args.get('establecimiento_id', type=int)
    inspector_id = request.args.get('inspector_id', type=int)
    encargado_id = request.args.get('encargado_id', type=int)
    estado = request.args.get('estado')
    
    return InspeccionesController.filtrar_inspecciones(
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        establecimiento_id=establecimiento_id,
        inspector_id=inspector_id,
        encargado_id=encargado_id,
        estado=estado
    )

@inspeccion_bp.route('/api/plan-semanal')
@login_required
def obtener_plan_semanal():
    return InspeccionesController.obtener_plan_semanal()

@inspeccion_bp.route('/api/categorias')
@login_required
def obtener_categorias():
    return InspeccionesController.obtener_categorias()

@inspeccion_bp.route('/api/inspecciones/actualizar-tiempo-real', methods=['POST'])
@login_required
def actualizar_item_tiempo_real():
    """Endpoint para actualizaciones en tiempo real"""
    return InspeccionesController.actualizar_item_tiempo_real()

# =========================
# RUTAS DE ADMINISTRADOR
# =========================

@inspeccion_bp.route('/api/admin/puntuaciones', methods=['PUT'])
@login_required
@role_required(['Administrador'])
def editar_puntuacion_admin():
    """Permite al admin editar puntuaciones"""
    return InspeccionesController.editar_puntuacion_inspeccion()

@inspeccion_bp.route('/api/admin/establecimientos', methods=['POST'])
@login_required
@role_required(['Administrador'])
def crear_establecimiento_admin():
    """Permite al admin crear establecimientos"""
    return InspeccionesController.crear_establecimiento()

@inspeccion_bp.route('/api/admin/establecimientos', methods=['DELETE'])
@login_required
@role_required(['Administrador'])
def eliminar_establecimiento_admin():
    """Permite al admin eliminar establecimientos"""
    return InspeccionesController.eliminar_establecimiento()

@inspeccion_bp.route('/api/admin/usuarios/rol', methods=['PUT'])
@login_required
@role_required(['Administrador'])
def actualizar_rol_usuario_admin():
    """Permite al admin cambiar roles de usuarios"""
    return InspeccionesController.actualizar_rol_usuario()

@inspeccion_bp.route('/api/admin/usuarios')
@login_required
@role_required(['Administrador'])
def obtener_usuarios_admin():
    """Obtener todos los usuarios para administración"""
    return InspeccionesController.obtener_todos_los_usuarios()

@inspeccion_bp.route('/api/tipos-establecimiento')
@login_required
def obtener_tipos_establecimiento():
    """Obtener tipos de establecimiento"""
    return InspeccionesController.obtener_tipos_establecimiento()

# =========================
# RUTAS ESPECÍFICAS PARA ENCARGADOS
# =========================

@inspeccion_bp.route('/api/encargado/firmar', methods=['POST'])
@login_required
@role_required(['Encargado'])
def firmar_inspeccion():
    """El encargado solo puede poner su firma para aceptar puntuaciones"""
    try:
        data = request.get_json()
        inspeccion_id = data.get('inspeccion_id')
        firma_data = data.get('firma_data')  # Base64 de la firma
        
        if not all([inspeccion_id, firma_data]):
            return jsonify({'error': 'Datos incompletos'}), 400
        
        # Verificar que el encargado tiene acceso a esta inspección
        from app.models.Inspecciones_models import Inspeccion
        inspeccion = Inspeccion.query.get(inspeccion_id)
        
        if not inspeccion:
            return jsonify({'error': 'Inspección no encontrada'}), 404
            
        if inspeccion.encargado_id != session.get('user_id'):
            return jsonify({'error': 'No tiene autorización para firmar esta inspección'}), 403
        
        # Guardar la firma
        inspeccion.firma_encargado = firma_data
        inspeccion.fecha_firma_encargado = datetime.now()
        
        from app.extensions import db
        db.session.commit()
        
        # Emitir evento de firma para notificar al inspector
        from app.extensions import socketio
        try:
            room = f"inspeccion_{inspeccion_id}"
            socketio.emit('firma_recibida', {
                'inspeccion_id': inspeccion_id,
                'tipo_firma': 'encargado',
                'firmado_por': session.get('user_name'),
                'timestamp': datetime.now().isoformat()
            }, to=room)
        except Exception as e:
            print(f"Error emitiendo firma Socket.IO: {str(e)}")
        
        return jsonify({'mensaje': 'Firma guardada exitosamente'})
        
    except Exception as e:
        from app.extensions import db
        db.session.rollback()
        return jsonify({'error': f'Error al guardar firma: {str(e)}'}), 500
