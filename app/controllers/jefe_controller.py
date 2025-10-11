from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, send_file
from functools import wraps
from app.models.Usuario_models import Usuario, Rol
from app.models.Inspecciones_models import Establecimiento, JefeEstablecimiento, EncargadoEstablecimiento, Inspeccion, FirmaEncargadoPorJefe
from app.extensions import db
from app.utils.auth_decorators import login_required
from datetime import datetime, timedelta
import base64
import os
from io import BytesIO
import uuid
from sqlalchemy import text, func
from sqlalchemy.orm import joinedload

jefe_bp = Blueprint('jefe', __name__, url_prefix='/jefe')


def jefe_required(f):
    """Decorador para requerir rol de jefe de establecimiento"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('auth.login'))

        user = Usuario.query.get(session['user_id'])
        if not user or user.rol_id != 4:  # 4 = Jefe de Establecimiento
            return jsonify({'error': 'Acceso denegado. Requiere rol de Jefe de Establecimiento'}), 403

        return f(*args, **kwargs)
    return decorated_function


@jefe_bp.route('/dashboard')
@login_required
@jefe_required
def dashboard():
    """Dashboard principal del jefe de establecimiento"""
    try:
        user_id = session['user_id']

        # ✅ CONVERSIÓN A ORM: Obtener información del jefe y su establecimiento
        jefe_info = JefeEstablecimiento.query\
            .options(joinedload(JefeEstablecimiento.establecimiento))\
            .filter(
                JefeEstablecimiento.usuario_id == user_id,
                JefeEstablecimiento.activo == True
            ).first()

        if not jefe_info:
            return redirect(url_for('auth.login'))

        establecimiento_id = jefe_info.establecimiento.id

        # Obtener estadísticas
        stats = obtener_estadisticas_establecimiento(establecimiento_id)

        # Obtener encargados del establecimiento
        encargados = obtener_encargados_establecimiento(establecimiento_id)

        # Obtener inspecciones recientes
        inspecciones_recientes = obtener_inspecciones_recientes(
            establecimiento_id)

        # Obtener usuario actual
        current_user = Usuario.query.get(user_id)

        # Crear objeto establecimiento usando ORM
        establecimiento = {
            'id': jefe_info.establecimiento.id,
            'nombre': jefe_info.establecimiento.nombre,
            'direccion': jefe_info.establecimiento.direccion
        }

        return render_template('jefe_dashboard.html',
                                current_user=current_user,
                                establecimiento=establecimiento,
                                stats=stats,
                                encargados=encargados,
                                inspecciones_recientes=inspecciones_recientes)

    except Exception as e:
        return jsonify({'error': 'Error interno del servidor'}), 500


@jefe_bp.route('/gestionar-encargado', methods=['POST'])
@login_required
@jefe_required
def gestionar_encargado():
    """✅ CONVERTIDO A ORM: Habilitar o deshabilitar encargados"""
    try:
        data = request.get_json()
        encargado_id = data.get('encargado_id')
        accion = data.get('accion')  # 'habilitar' o 'deshabilitar'
        observaciones = data.get('observaciones', '')

        if not encargado_id or not accion:
            return jsonify({'success': False, 'message': 'Datos incompletos'}), 400

        # ✅ Verificar autoridad usando ORM con joins
        jefe_id = session['user_id']

        # Buscar el encargado y verificar autoridad en una sola consulta
        encargado = EncargadoEstablecimiento.query\
            .join(JefeEstablecimiento, EncargadoEstablecimiento.establecimiento_id == JefeEstablecimiento.establecimiento_id)\
            .filter(
                EncargadoEstablecimiento.id == encargado_id,
                JefeEstablecimiento.usuario_id == jefe_id,
                JefeEstablecimiento.activo == True
            ).first()

        if not encargado:
            return jsonify({'success': False, 'message': 'No tienes autoridad sobre este encargado'}), 403

        # ✅ Actualizar estado usando ORM
        if accion == 'habilitar':
            encargado.activo = True
            encargado.fecha_habilitacion = datetime.now()
        else:
            encargado.activo = False
            encargado.fecha_habilitacion = None

        encargado.observaciones_jefe = observaciones

        db.session.commit()

        accion_texto = 'habilitado' if accion == 'habilitar' else 'deshabilitado'
        return jsonify({'success': True, 'message': f'Encargado {accion_texto} exitosamente'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500


@jefe_bp.route('/agregar-encargado', methods=['POST'])
@login_required
@jefe_required
def agregar_encargado():
    """Agregar un nuevo encargado al establecimiento"""
    try:
        data = request.get_json()
        nombre = data.get('nombre', '').strip()
        apellido = data.get('apellido', '').strip()
        dni = data.get('dni', '').strip()
        telefono = data.get('telefono', '').strip()
        email = data.get('email', '').strip()

        # Validaciones básicas
        if not all([nombre, apellido, dni]):
            return jsonify({'success': False, 'message': 'Nombre, apellido y DNI son obligatorios'}), 400

        if len(dni) != 8 or not dni.isdigit():
            return jsonify({'success': False, 'message': 'El DNI debe tener 8 dígitos'}), 400

        # Obtener establecimiento del jefe usando ORM
        jefe_establecimiento = JefeEstablecimiento.query.filter_by(
            usuario_id=session['user_id'], 
            activo=True
        ).first()

        if not jefe_establecimiento:
            return jsonify({'success': False, 'message': 'No tienes establecimiento asignado'}), 403

        establecimiento_id = jefe_establecimiento.establecimiento_id

        # Verificar si ya existe un usuario con ese DNI
        usuario_existente = Usuario.query.filter_by(dni=dni).first()

        contrasena_temporal = None
        if usuario_existente:
            usuario_id = usuario_existente.id

            # Verificar que no esté ya asignado a este establecimiento
            encargado_existente = EncargadoEstablecimiento.query.filter_by(
                usuario_id=usuario_id, 
                establecimiento_id=establecimiento_id
            ).first()

            if encargado_existente:
                return jsonify({'success': False, 'message': 'Este usuario ya es encargado de este establecimiento'}), 400
        else:
            # Crear nuevo usuario con contraseña temporal robusta
            from app.utils.auth_utils import generar_contrasena_temporal
            
            contrasena_temporal = generar_contrasena_temporal()
            
            # Obtener rol de Encargado usando ORM
            rol_encargado = Rol.query.filter_by(nombre='Encargado').first()
            if not rol_encargado:
                return jsonify({'success': False, 'message': 'Rol de Encargado no encontrado'}), 500
            
            # Crear usuario usando el modelo
            nuevo_usuario = Usuario(
                nombre=nombre,
                apellido=apellido,
                dni=dni,
                telefono=telefono,
                correo=email,
                rol_id=rol_encargado.id,
                activo=True,
                cambiar_contrasena=True  # Marcar que debe cambiar contraseña
            )
            
            # Usar el método del modelo para hashear la contraseña
            nuevo_usuario.set_password(contrasena_temporal)
            
            db.session.add(nuevo_usuario)
            db.session.flush()  # Para obtener el ID del usuario
            
            usuario_id = nuevo_usuario.id

        # Crear relación encargado-establecimiento usando ORM
        nuevo_encargado = EncargadoEstablecimiento(
            usuario_id=usuario_id,
            establecimiento_id=establecimiento_id,
            fecha_inicio=datetime.now().date(),
            activo=True
        )
        
        db.session.add(nuevo_encargado)
        db.session.commit()

        return jsonify({
            'success': True, 
            'message': 'Encargado agregado exitosamente',
            'usuario_id': usuario_id,
            'correo': email,
            'contrasena_temporal': contrasena_temporal
        })

    except Exception as e:
        db.session.rollback()
        import traceback
        print(f"Error en agregar_encargado: {str(e)}")
        print(traceback.format_exc())
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500


@jefe_bp.route('/restablecer-contrasena-encargado', methods=['POST'])
@login_required
@jefe_required
def restablecer_contrasena_encargado():
    """
    Restablecer la contraseña de un encargado del establecimiento
    
    Args:
        encargado_id: ID del encargado
        
    Returns:
        JSON con resultado de la operación
    """
    try:
        data = request.get_json()
        print(f"Datos recibidos en restablecer_contrasena_encargado: {data}")
        
        encargado_id = data.get('encargado_id')
        print(f"encargado_id extraído: {encargado_id}")

        if not encargado_id:
            print("Error: ID de encargado requerido")
            return jsonify({'success': False, 'message': 'ID de encargado requerido'}), 400

        user_id = session['user_id']
        print(f"user_id de la sesión: {user_id}")

        # Verificar autoridad: el jefe debe tener autoridad sobre este encargado
        encargado = EncargadoEstablecimiento.query\
            .join(JefeEstablecimiento, EncargadoEstablecimiento.establecimiento_id == JefeEstablecimiento.establecimiento_id)\
            .options(joinedload(EncargadoEstablecimiento.usuario))\
            .filter(
                EncargadoEstablecimiento.id == encargado_id,
                JefeEstablecimiento.usuario_id == user_id,
                JefeEstablecimiento.activo == True,
                EncargadoEstablecimiento.activo == True
            ).first()

        print(f"Encargado encontrado: {encargado}")
        if encargado:
            print(f"Usuario del encargado: {encargado.usuario.nombre} {encargado.usuario.apellido}")

        if not encargado:
            print("Error: No tienes autoridad sobre este encargado o no está activo")
            return jsonify({'success': False, 'message': 'No tienes autoridad sobre este encargado o no está activo'}), 403

        # Generar nueva contraseña temporal
        from app.utils.auth_utils import generar_contrasena_temporal
        nueva_contrasena = generar_contrasena_temporal()
        print(f"Nueva contraseña generada: {nueva_contrasena}")
        
        # Actualizar contraseña del usuario
        encargado.usuario.set_password(nueva_contrasena)
        encargado.usuario.cambiar_contrasena = True  # Forzar cambio de contraseña
        encargado.usuario.fecha_actualizacion = datetime.now()
        
        db.session.commit()
        print("Contraseña actualizada exitosamente")

        return jsonify({
            'success': True,
            'message': 'Contraseña restablecida exitosamente',
            'correo': encargado.usuario.correo,
            'contrasena_temporal': nueva_contrasena
        })

    except Exception as e:
        db.session.rollback()
        import traceback
        print(f"Error en restablecer_contrasena_encargado: {str(e)}")
        print(traceback.format_exc())
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500


@jefe_bp.route('/eliminar-encargado', methods=['POST'])
@login_required
@jefe_required
def eliminar_encargado():
    """Eliminar encargado del establecimiento"""
    try:
        data = request.get_json()
        encargado_id = data.get('encargado_id')

        if not encargado_id:
            return jsonify({'success': False, 'message': 'ID de encargado requerido'}), 400

        # Verificar que el jefe tenga autoridad sobre este encargado
        jefe_id = session['user_id']
        verificacion = db.session.execute(text("""
            SELECT e.establecimiento_id 
            FROM encargados_establecimientos e
            JOIN jefes_establecimientos j ON e.establecimiento_id = j.establecimiento_id
            WHERE e.id = :encargado_id AND j.usuario_id = :jefe_id AND j.activo = 1
        """), {'encargado_id': encargado_id, 'jefe_id': jefe_id}).fetchone()

        if not verificacion:
            return jsonify({'success': False, 'message': 'No tienes autoridad sobre este encargado'}), 403

        # Verificar si el encargado tiene inspecciones asociadas
        inspecciones_count = db.session.execute(text("""
            SELECT COUNT(*) FROM inspecciones i
            JOIN encargados_establecimientos e ON i.establecimiento_id = e.establecimiento_id
            WHERE e.id = :encargado_id
        """), {'encargado_id': encargado_id}).scalar()

        if inspecciones_count > 0:
            # Si tiene inspecciones, solo desactivar
            db.session.execute(text("""
                UPDATE encargados_establecimientos 
                SET activo = 0, fecha_baja = :fecha_baja,
                    observaciones_jefe = 'Eliminado por jefe de establecimiento'
                WHERE id = :encargado_id
            """), {
                'fecha_baja': datetime.now(),
                'encargado_id': encargado_id
            })
            mensaje = 'Encargado desactivado exitosamente (mantiene historial de inspecciones)'
        else:
            # Si no tiene inspecciones, eliminar completamente
            db.session.execute(text("""
                DELETE FROM encargados_establecimientos WHERE id = :encargado_id
            """), {'encargado_id': encargado_id})
            mensaje = 'Encargado eliminado exitosamente'

        db.session.commit()

        return jsonify({'success': True, 'message': mensaje})

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500


@jefe_bp.route('/guardar-firma', methods=['POST'])
@login_required
@jefe_required
def guardar_firma():
    """Guardar firma digital del jefe como archivo de imagen"""
    try:
        # Verificar que se envió un archivo
        if 'archivo' not in request.files:
            return jsonify({'success': False, 'message': 'No se encontró archivo de firma'}), 400

        archivo = request.files['archivo']
        if archivo.filename == '':
            return jsonify({'success': False, 'message': 'No se seleccionó archivo'}), 400

        # Obtener datos adicionales del formulario
        tipo_firma = request.form.get('tipo', 'jefe')
        motivo = request.form.get('motivo', '')
        establecimiento_nombre = request.form.get('establecimiento_nombre', '')

        # Validar tipo de archivo
        extensiones_permitidas = {'png', 'jpg', 'jpeg', 'gif'}
        extension = archivo.filename.rsplit(
            '.', 1)[1].lower() if '.' in archivo.filename else ''

        if extension not in extensiones_permitidas:
            return jsonify({'success': False, 'message': 'Formato de archivo no permitido. Use PNG, JPG o JPEG'}), 400

        # Crear directorio basado en el nombre del establecimiento
        nombre_limpio = "".join(
            c for c in establecimiento_nombre if c.isalnum() or c in (' ', '-', '_')).rstrip()
        nombre_limpio = nombre_limpio.replace(' ', '_')

        directorio_firmas = os.path.join(
            'app', 'static', 'img', 'firmas', nombre_limpio)
        os.makedirs(directorio_firmas, exist_ok=True)

        # Generar nombre único para la firma
        user_id = session['user_id']
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        nombre_archivo = f"firma_{tipo_firma}_{user_id}_{timestamp}.{extension}"
        ruta_archivo = os.path.join(directorio_firmas, nombre_archivo)

        # Guardar archivo
        archivo.save(ruta_archivo)

        # Ruta relativa para guardar en base de datos
        ruta_relativa = f"img/firmas/{nombre_limpio}/{nombre_archivo}"

        # Actualizar base de datos con la ruta de la firma
        db.session.execute(text("""
            UPDATE jefes_establecimientos 
            SET firma_digital = :ruta_firma, fecha_firma = :fecha_firma,
                observaciones_firma = :motivo
            WHERE usuario_id = :user_id
        """), {
            'ruta_firma': ruta_relativa,
            'fecha_firma': datetime.now(),
            'motivo': motivo,
            'user_id': user_id
        })

        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Firma guardada exitosamente',
            'ruta_archivo': ruta_relativa
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error al guardar la firma'}), 500


@jefe_bp.route('/reporte')
@jefe_bp.route('/reporte-establecimiento')
@login_required
@jefe_required
def reporte_establecimiento():
    """Mostrar reporte detallado del establecimiento"""
    try:
        user_id = session['user_id']

        # Obtener información del establecimiento
        jefe_query = db.session.execute(text("""
            SELECT j.*, e.nombre as establecimiento_nombre, e.direccion as establecimiento_direccion, e.id as establecimiento_id
            FROM jefes_establecimientos j
            JOIN establecimientos e ON j.establecimiento_id = e.id
            WHERE j.usuario_id = :user_id AND j.activo = 1
        """), {'user_id': user_id})

        jefe_info = jefe_query.fetchone()

        if not jefe_info:
            return redirect(url_for('auth.login'))

        establecimiento_id = jefe_info[5]

        # Obtener datos para el reporte
        datos_reporte = generar_datos_reporte(establecimiento_id)
        estadisticas_adicionales = obtener_estadisticas_reporte(
            establecimiento_id)
        inspecciones_recientes = obtener_inspecciones_recientes(
            establecimiento_id, 10)

        # Crear objeto establecimiento
        establecimiento = {
            'id': establecimiento_id,
            'nombre': jefe_info[3],
            'direccion': jefe_info[4]
        }

        # Fecha actual formateada
        fecha_actual = datetime.now().strftime('%d/%m/%Y a las %H:%M')

        return render_template('jefe_reporte.html',
                               establecimiento=establecimiento,
                               reporte=datos_reporte,
                               estadisticas=estadisticas_adicionales,
                               inspecciones_recientes=inspecciones_recientes,
                               fecha_actual=fecha_actual)

    except Exception as e:
        return jsonify({'error': 'Error interno del servidor'}), 500


@jefe_bp.route('/historial')
@login_required
@jefe_required
def historial():
    """Mostrar historial de inspecciones del establecimiento"""
    try:
        user_id = session['user_id']

        # Obtener información del establecimiento
        jefe_query = db.session.execute(text("""
            SELECT j.*, e.nombre as establecimiento_nombre, e.direccion as establecimiento_direccion, e.id as establecimiento_id
            FROM jefes_establecimientos j
            JOIN establecimientos e ON j.establecimiento_id = e.id
            WHERE j.usuario_id = :user_id AND j.activo = 1
        """), {'user_id': user_id})

        jefe_info = jefe_query.fetchone()

        if not jefe_info:
            return redirect(url_for('auth.login'))

        establecimiento_id = jefe_info[5]

        # Obtener historial de inspecciones
        inspecciones = db.session.execute(text("""
            SELECT i.id, i.fecha, i.estado, i.porcentaje_cumplimiento, i.observaciones,
                   u.nombre as inspector_nombre, u.apellido as inspector_apellido,
                   e_enc.nombre as encargado_nombre, e_enc.apellido as encargado_apellido
            FROM inspecciones i
            LEFT JOIN usuarios u ON i.inspector_id = u.id
            LEFT JOIN encargados_establecimientos ee ON i.establecimiento_id = ee.establecimiento_id
            LEFT JOIN usuarios e_enc ON ee.usuario_id = e_enc.id
            WHERE i.establecimiento_id = :establecimiento_id
            ORDER BY i.fecha DESC
        """), {'establecimiento_id': establecimiento_id}).fetchall()

        historial_inspecciones = [
            {
                'id': insp[0],
                'fecha': insp[1].strftime('%d/%m/%Y %H:%M') if insp[1] else '',
                'estado': insp[2],
                'porcentaje_cumplimiento': insp[3] or 0,
                'observaciones': insp[4] or '',
                'inspector_nombre': f"{insp[5]} {insp[6]}" if insp[5] else 'N/A',
                'encargado_nombre': f"{insp[7]} {insp[8]}" if insp[7] else 'N/A'
            }
            for insp in inspecciones
        ]

        # Crear objeto establecimiento
        establecimiento = {
            'id': establecimiento_id,
            'nombre': jefe_info[3],
            'direccion': jefe_info[4]
        }

        return render_template('buscar_inspecciones.html',
                               establecimiento=establecimiento,
                               inspecciones=historial_inspecciones)

    except Exception as e:
        return jsonify({'error': 'Error interno del servidor'}), 500

# Funciones auxiliares


def obtener_estadisticas_establecimiento(establecimiento_id):
    """✅ CONVERTIDO A ORM: Obtener estadísticas del establecimiento"""
    try:
        # ✅ Encargados activos usando ORM
        encargados_activos = EncargadoEstablecimiento.query.filter(
            EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
            EncargadoEstablecimiento.activo == True
        ).count()

        # ✅ Inspecciones este mes usando ORM
        fecha_inicio_mes = datetime.now().replace(day=1)
        inspecciones_mes = Inspeccion.query.filter(
            Inspeccion.establecimiento_id == establecimiento_id,
            Inspeccion.fecha >= fecha_inicio_mes
        ).count()

        # ✅ Firmas pendientes usando ORM
        firmas_pendientes = EncargadoEstablecimiento.query.filter(
            EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
            EncargadoEstablecimiento.activo == True,
            EncargadoEstablecimiento.fecha_habilitacion.is_(None)
        ).count()

        # ✅ Promedio de cumplimiento usando ORM
        promedio_cumplimiento = db.session.query(
            func.coalesce(func.avg(Inspeccion.porcentaje_cumplimiento), 0)
        ).filter(
            Inspeccion.establecimiento_id == establecimiento_id,
            Inspeccion.estado == 'completada',
            Inspeccion.fecha >= fecha_inicio_mes
        ).scalar()

        return {
            'encargados_activos': encargados_activos,
            'inspecciones_mes': inspecciones_mes,
            'firmas_pendientes': firmas_pendientes,
            'promedio_cumplimiento': round(float(promedio_cumplimiento or 0), 1)
        }

    except Exception as e:
        return {
            'encargados_activos': 0,
            'inspecciones_mes': 0,
            'firmas_pendientes': 0,
            'promedio_cumplimiento': 0
        }


def obtener_encargados_establecimiento(establecimiento_id):
    """✅ CONVERTIDO A ORM: Obtener lista de encargados del establecimiento"""
    try:
        # ✅ Usando ORM con join y order_by
        encargados = EncargadoEstablecimiento.query\
            .options(joinedload(EncargadoEstablecimiento.usuario))\
            .filter(EncargadoEstablecimiento.establecimiento_id == establecimiento_id)\
            .order_by(
                EncargadoEstablecimiento.activo.desc(),
                EncargadoEstablecimiento.usuario.has(Usuario.nombre)
            ).all()

        return [
            {
                'id': enc.id,
                'nombre': enc.usuario.nombre,
                'apellido': enc.usuario.apellido,
                'correo': enc.usuario.correo,
                'activo': enc.activo,
                'observaciones_jefe': enc.observaciones_jefe,
                'fecha_habilitacion': enc.fecha_habilitacion
            }
            for enc in encargados
        ]

    except Exception as e:
        return []


def obtener_inspecciones_recientes(establecimiento_id, limit=10):
    """✅ CONVERTIDO A ORM: Obtener inspecciones recientes del establecimiento"""
    try:
        # ✅ Usando ORM con relaciones
        inspecciones = Inspeccion.query\
            .options(joinedload(Inspeccion.inspector))\
            .filter(Inspeccion.establecimiento_id == establecimiento_id)\
            .order_by(Inspeccion.fecha.desc())\
            .limit(limit)\
            .all()

        return [
            {
                'id': insp.id,
                'fecha': insp.fecha.strftime('%d/%m/%Y') if insp.fecha else '',
                'estado': insp.estado,
                'porcentaje_cumplimiento': insp.porcentaje_cumplimiento,
                'inspector_nombre': f"{insp.inspector.nombre} {insp.inspector.apellido}" if insp.inspector else 'N/A'
            }
            for insp in inspecciones
        ]

    except Exception as e:
        return []


def generar_datos_reporte(establecimiento_id):
    """Generar datos completos para el reporte"""
    try:
        # Datos del último mes, trimestre y año
        ahora = datetime.now()
        hace_mes = ahora - timedelta(days=30)
        hace_trimestre = ahora - timedelta(days=90)
        hace_año = ahora - timedelta(days=365)

        reporte = {}

        # Inspecciones por período
        for periodo, fecha_inicio in [('mes', hace_mes), ('trimestre', hace_trimestre), ('año', hace_año)]:
            datos = db.session.execute(text("""
                SELECT COUNT(*) as total,
                       COUNT(CASE WHEN estado = 'completada' THEN 1 END) as completadas,
                       AVG(CASE WHEN estado = 'completada' THEN porcentaje_cumplimiento END) as promedio
                FROM inspecciones 
                WHERE establecimiento_id = :establecimiento_id AND fecha >= :fecha_inicio
            """), {'establecimiento_id': establecimiento_id, 'fecha_inicio': fecha_inicio}).fetchone()

            reporte[periodo] = {
                'total_inspecciones': datos[0] or 0,
                'completadas': datos[1] or 0,
                'promedio_cumplimiento': round(float(datos[2] or 0), 1)
            }

        return reporte

    except Exception as e:
        return {}


def obtener_estadisticas_reporte(establecimiento_id):
    """Obtener estadísticas adicionales para el reporte"""
    try:
        # Encargados activos e inactivos
        encargados_stats = db.session.execute(text("""
            SELECT 
                COUNT(CASE WHEN activo = 1 THEN 1 END) as activos,
                COUNT(CASE WHEN activo = 0 THEN 1 END) as inactivos
            FROM encargados_establecimientos 
            WHERE establecimiento_id = :establecimiento_id
        """), {'establecimiento_id': establecimiento_id}).fetchone()

        # Firmas registradas y pendientes (simplificado)
        firmas_stats = db.session.execute(text("""
            SELECT 
                COUNT(CASE WHEN fecha_habilitacion IS NOT NULL THEN 1 END) as registradas,
                COUNT(CASE WHEN fecha_habilitacion IS NULL THEN 1 END) as pendientes
            FROM encargados_establecimientos
            WHERE establecimiento_id = :establecimiento_id AND activo = 1
        """), {'establecimiento_id': establecimiento_id}).fetchone()

        return {
            'encargados_activos': encargados_stats[0] or 0,
            'encargados_inactivos': encargados_stats[1] or 0,
            'firmas_registradas': firmas_stats[0] or 0,
            'firmas_pendientes': firmas_stats[1] or 0
        }

    except Exception as e:
        return {
            'encargados_activos': 0,
            'encargados_inactivos': 0,
            'firmas_registradas': 0,
            'firmas_pendientes': 0
        }

# ===== NUEVAS RUTAS PARA GESTIÓN DE FIRMAS =====


@jefe_bp.route('/firmas/subir', methods=['POST'])
@login_required
@jefe_required
def subir_firma():
    """✅ CONVERTIDO A ORM: Subir firma de encargado - actualiza o crea nueva"""
    try:
        user_id = session['user_id']

        # Obtener datos del formulario
        encargado_id = request.form.get('encargado_id')

        if not encargado_id:
            return jsonify({'success': False, 'message': 'ID de encargado requerido'}), 400

        # Verificar que hay archivo
        if 'firma' not in request.files:
            return jsonify({'success': False, 'message': 'No se encontró archivo de firma'}), 400

        archivo = request.files['firma']
        if archivo.filename == '':
            return jsonify({'success': False, 'message': 'No se seleccionó archivo'}), 400

        # Verificar extensión de archivo
        extensiones_permitidas = {'png', 'jpg', 'jpeg', 'gif'}
        if not ('.' in archivo.filename and archivo.filename.rsplit('.', 1)[1].lower() in extensiones_permitidas):
            return jsonify({'success': False, 'message': 'Tipo de archivo no permitido. Use PNG, JPG, JPEG o GIF'}), 400

        # ✅ ORM: Obtener información del jefe y establecimiento
        jefe_info = JefeEstablecimiento.query\
            .options(joinedload(JefeEstablecimiento.establecimiento))\
            .filter(
                JefeEstablecimiento.usuario_id == user_id,
                JefeEstablecimiento.activo == True
            ).first()

        if not jefe_info:
            return jsonify({'success': False, 'message': 'Jefe no encontrado'}), 404

        establecimiento_id = jefe_info.establecimiento.id
        establecimiento_nombre = jefe_info.establecimiento.nombre

        # ✅ ORM: Verificar que el encargado pertenece al establecimiento
        encargado_verificacion = EncargadoEstablecimiento.query\
            .options(joinedload(EncargadoEstablecimiento.usuario))\
            .filter(
                EncargadoEstablecimiento.id == encargado_id,
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True
            ).first()

        if not encargado_verificacion:
            return jsonify({'success': False, 'message': f'Encargado no pertenece a este establecimiento: {encargado_id}'}), 403


        # ✅ VERIFICAR SI YA EXISTE UNA FIRMA ACTIVA
        firma_existente = FirmaEncargadoPorJefe.query.filter(
            FirmaEncargadoPorJefe.jefe_id == user_id,
            FirmaEncargadoPorJefe.encargado_id == encargado_verificacion.usuario_id,
            FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
            FirmaEncargadoPorJefe.activa == True
        ).first()

        # ✅ ELIMINAR ARCHIVO FÍSICO ANTERIOR SI EXISTE
        if firma_existente and firma_existente.path_firma:
            ruta_archivo_anterior = os.path.join('app', 'static', firma_existente.path_firma)
            try:
                if os.path.exists(ruta_archivo_anterior):
                    os.remove(ruta_archivo_anterior)
            except Exception as e:
                pass

        # Crear directorio para las firmas
        nombre_seguro = establecimiento_nombre.replace(' ', '_').replace('/', '_')
        directorio_firma = os.path.join('app', 'static', 'img', 'firmas', f"{nombre_seguro}")

        # Crear directorio si no existe
        os.makedirs(directorio_firma, exist_ok=True)

        # Generar nombre único para el archivo
        extension = archivo.filename.rsplit('.', 1)[1].lower()
        nombre_archivo = f"firma_{encargado_verificacion.usuario_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{extension}"
        ruta_archivo = os.path.join(directorio_firma, nombre_archivo)

        # Guardar archivo
        archivo.save(ruta_archivo)

        # Ruta relativa para guardar en BD
        ruta_relativa = f"img/firmas/{nombre_seguro}/{nombre_archivo}"

        # ✅ ORM: ACTUALIZAR O CREAR FIRMA
        if firma_existente:
            # Actualizar firma existente
            firma_existente.path_firma = ruta_relativa
            firma_existente.fecha_firma = datetime.now()
        else:
            # Crear nueva firma
            nueva_firma = FirmaEncargadoPorJefe(
                jefe_id=user_id,
                encargado_id=encargado_verificacion.usuario_id,
                establecimiento_id=establecimiento_id,
                path_firma=ruta_relativa,
                activa=True
            )
            db.session.add(nueva_firma)

        db.session.commit()


        return jsonify({
            'success': True,
            'message': f'Firma guardada exitosamente para {encargado_verificacion.usuario.nombre} {encargado_verificacion.usuario.apellido}',
            'ruta_firma': ruta_relativa,
            'encargado_usuario_id': encargado_verificacion.usuario_id,
            'accion': 'actualizada' if firma_existente else 'creada'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error al subir firma: {str(e)}'}), 500


@jefe_bp.route('/firmas/eliminar', methods=['POST'])
@login_required
@jefe_required
def eliminar_firma():
    """Eliminar firma de encargado"""
    try:
        user_id = session['user_id']
        data = request.get_json()

        encargado_id = data.get('encargado_id')

        if not encargado_id:
            return jsonify({'success': False, 'message': 'ID de encargado requerido'}), 400

        # Obtener información del establecimiento del jefe
        jefe_query = db.session.execute(text("""
            SELECT j.*, e.id as establecimiento_id
            FROM jefes_establecimientos j
            JOIN establecimientos e ON j.establecimiento_id = e.id
            WHERE j.usuario_id = :user_id AND j.activo = 1
        """), {'user_id': user_id})

        jefe_info = jefe_query.fetchone()

        if not jefe_info:
            return jsonify({'success': False, 'message': 'Jefe no encontrado'}), 404

        establecimiento_id = jefe_info[5]

        # Obtener firma activa
        firma_query = db.session.execute(text("""
            SELECT f.id, f.path_firma, u.nombre, u.apellido
            FROM firmas_encargados_por_jefe f
            JOIN usuarios u ON f.encargado_id = u.id
            WHERE f.jefe_id = :jefe_id AND f.encargado_id = :encargado_id 
            AND f.establecimiento_id = :establecimiento_id AND f.activa = 1
        """), {
            'jefe_id': user_id,
            'encargado_id': encargado_id,
            'establecimiento_id': establecimiento_id
        })

        firma_info = firma_query.fetchone()

        if not firma_info:
            return jsonify({'success': False, 'message': 'Firma no encontrada'}), 404

        # Eliminar archivo físico
        try:
            ruta_completa = os.path.join('app', 'static', firma_info[1])
            if os.path.exists(ruta_completa):
                os.remove(ruta_completa)
        except Exception as e:
            import logging
            logging.warning(f"No se pudo eliminar archivo de firma: {str(e)}")

        # Marcar como inactiva en BD
        db.session.execute(text("""
            UPDATE firmas_encargados_por_jefe 
            SET activa = 0 
            WHERE id = :firma_id
        """), {'firma_id': firma_info[0]})

        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'Firma eliminada exitosamente para {firma_info[2]} {firma_info[3]}'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': f'Error al eliminar firma: {str(e)}'}), 500


@jefe_bp.route('/firmas/listar', methods=['GET'])
@login_required
@jefe_required
def listar_firmas():
    """
    Obtener lista de firmas activas de encargados para el establecimiento del jefe
    """
    try:
        user_id = session['user_id']

        # Obtener establecimiento del jefe
        jefe_info = JefeEstablecimiento.query\
            .options(joinedload(JefeEstablecimiento.establecimiento))\
            .filter(
                JefeEstablecimiento.usuario_id == user_id,
                JefeEstablecimiento.activo == True
            ).first()

        if not jefe_info:
            return jsonify({'success': False, 'message': 'Jefe no encontrado'}), 404

        establecimiento_id = jefe_info.establecimiento.id

        # Obtener firmas activas con información del encargado
        firmas = FirmaEncargadoPorJefe.query\
            .join(Usuario, FirmaEncargadoPorJefe.encargado_id == Usuario.id)\
            .filter(
                FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
                FirmaEncargadoPorJefe.activa == True
            )\
            .all()

        firmas_list = [
            {
                'id': firma.id,
                'encargado_id': firma.encargado_id,
                'encargado_nombre': firma.encargado.nombre if firma.encargado else 'Sin nombre',
                'encargado_apellido': firma.encargado.apellido if firma.encargado else 'Sin apellido',
                'path_firma': firma.path_firma,
                'fecha_firma': firma.fecha_firma.strftime('%d/%m/%Y %H:%M') if firma.fecha_firma else ''
            }
            for firma in firmas
        ]

        return jsonify({
            'success': True,
            'firmas': firmas_list
        })

    except Exception as e:
        return jsonify({'success': False, 'message': f'Error al listar firmas: {str(e)}'}), 500


@jefe_bp.route('/firmas/obtener/<int:establecimiento_id>', methods=['GET'])
@login_required
def obtener_firmas_establecimiento(establecimiento_id):
    """
    Endpoint para obtener la firma del usuario actual según su rol:
    - Inspector/Admin: Su propia firma desde Usuario.ruta_firma
    - Jefe: Su propia firma desde Usuario.ruta_firma
    - Encargado: Su firma desde FirmaEncargadoPorJefe (subida por el jefe)
    """
    try:
        user_id = session.get('user_id')
        user = Usuario.query.get(user_id)
        
        if not user:
            return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404


        # Obtener el nombre del rol para más claridad
        rol_nombre = user.rol.nombre if user.rol else 'Sin rol'

        # Inspector, Admin o Jefe: Cargar su propia firma desde Usuario.ruta_firma
        # Y también verificar si hay firma del encargado para este establecimiento
        if rol_nombre in ['Inspector', 'Administrador', 'Jefe de Establecimiento']:
            
            response_data = {'success': True}
            
            # Firma del inspector/admin/jefe
            if user.ruta_firma:
                response_data['firma_inspector'] = {
                    'id': user.id,
                    'ruta': user.ruta_firma,
                    'usuario_nombre': f"{user.nombre} {user.apellido}"
                }
            else:
                response_data['firma_inspector'] = None
            
            # Verificar si hay firma del encargado para este establecimiento
            firma_encargado = FirmaEncargadoPorJefe.query\
                .join(Usuario, FirmaEncargadoPorJefe.encargado_id == Usuario.id)\
                .filter(
                    FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
                    FirmaEncargadoPorJefe.activa == True
                )\
                .first()
            
            if firma_encargado:
                response_data['firma_encargado'] = {
                    'id': firma_encargado.id,
                    'encargado_id': firma_encargado.encargado_id,
                    'encargado_nombre': firma_encargado.encargado.nombre,
                    'encargado_apellido': firma_encargado.encargado.apellido,
                    'ruta': firma_encargado.path_firma,
                    'fecha_firma': firma_encargado.fecha_firma.strftime('%d/%m/%Y %H:%M') if firma_encargado.fecha_firma else ''
                }
            else:
                response_data['firma_encargado'] = None
            
            return jsonify(response_data)

        # Encargado: Cargar firma desde FirmaEncargadoPorJefe
        elif rol_nombre == 'Encargado':
            
            firma = FirmaEncargadoPorJefe.query\
                .filter(
                    FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
                    FirmaEncargadoPorJefe.encargado_id == user_id,
                    FirmaEncargadoPorJefe.activa == True
                )\
                .first()

            if firma:
                return jsonify({
                    'success': True,
                    'firma_encargado': {
                        'id': firma.id,
                        'encargado_id': firma.encargado_id,
                        'encargado_nombre': user.nombre,
                        'encargado_apellido': user.apellido,
                        'ruta': firma.path_firma,
                        'fecha_firma': firma.fecha_firma.strftime('%d/%m/%Y %H:%M') if firma.fecha_firma else ''
                    }
                })
            else:
                
                # Verificar si existe alguna firma para este encargado en cualquier establecimiento
                firma_cualquier = FirmaEncargadoPorJefe.query\
                    .filter(
                        FirmaEncargadoPorJefe.encargado_id == user_id,
                        FirmaEncargadoPorJefe.activa == True
                    )\
                    .first()
                
                return jsonify({
                    'success': False,
                    'message': 'No tiene firma registrada para este establecimiento. Contacte al jefe del establecimiento.'
                })
        
        # Si es inspector o admin, devolver todas las firmas del establecimiento
        else:
            
            firmas = FirmaEncargadoPorJefe.query\
                .join(Usuario, FirmaEncargadoPorJefe.encargado_id == Usuario.id)\
                .filter(
                    FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
                    FirmaEncargadoPorJefe.activa == True
                )\
                .all()


            firmas_list = [
                {
                    'id': firma.id,
                    'encargado_id': firma.encargado_id,
                    'encargado_nombre': firma.encargado.nombre if firma.encargado else 'Sin nombre',
                    'encargado_apellido': firma.encargado.apellido if firma.encargado else 'Sin apellido',
                    'path_firma': firma.path_firma,
                    'fecha_firma': firma.fecha_firma.strftime('%d/%m/%Y %H:%M') if firma.fecha_firma else ''
                }
                for firma in firmas
            ]

            return jsonify({
                'success': True,
                'firma_propia': False,
                'firmas': firmas_list
            })

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'message': f'Error al obtener firmas: {str(e)}'}), 500


@jefe_bp.route('/firmas/obtener-propia', methods=['GET'])
@login_required
def obtener_firma_propia():
    """
    Endpoint simplificado para obtener SOLO la firma del usuario actual
    sin necesidad de especificar establecimiento.
    Usado para cargar la firma del inspector al inicio de la página.
    """
    try:
        user_id = session.get('user_id')
        user = Usuario.query.get(user_id)
        
        if not user:
            return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

        rol_nombre = user.rol.nombre if user.rol else 'Sin rol'

        # Solo Inspector, Admin o Jefe tienen firma propia en Usuario.ruta_firma
        if rol_nombre in ['Inspector', 'Administrador', 'Jefe de Establecimiento']:
            if user.ruta_firma:
                return jsonify({
                    'success': True,
                    'firma': {
                        'id': user.id,
                        'ruta': user.ruta_firma,
                        'usuario_nombre': f"{user.nombre} {user.apellido}"
                    }
                })
            else:
                return jsonify({
                    'success': False,
                    'message': 'No tiene firma registrada. Por favor, suba su firma desde su perfil.'
                }), 404
        else:
            # Encargados no tienen firma propia (depende del establecimiento)
            return jsonify({
                'success': False,
                'message': 'Este rol no tiene firma propia'
            }), 400

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'message': f'Error al obtener firma: {str(e)}'}), 500


@jefe_bp.route('/gestionar-encargados')
@login_required
@jefe_required
def gestionar_encargados():
    """Página para gestionar encargados del establecimiento"""
    try:
        user_id = session['user_id']

        # Obtener información del jefe y su establecimiento
        jefe_info = JefeEstablecimiento.query\
            .options(joinedload(JefeEstablecimiento.establecimiento))\
            .filter(
                JefeEstablecimiento.usuario_id == user_id,
                JefeEstablecimiento.activo == True
            ).first()

        if not jefe_info:
            return redirect(url_for('auth.login'))

        establecimiento_id = jefe_info.establecimiento.id

        # Obtener encargados del establecimiento
        encargados = obtener_encargados_establecimiento(establecimiento_id)

        # Calcular estadísticas
        encargados_activos = sum(1 for e in encargados if e['activo'])
        encargados_inactivos = len(encargados) - encargados_activos

        # Obtener información de firmas
        encargados_con_firma = 0
        for encargado in encargados:
            firma = FirmaEncargadoPorJefe.query.filter(
                FirmaEncargadoPorJefe.encargado_id == encargado['id'],
                FirmaEncargadoPorJefe.establecimiento_id == establecimiento_id,
                FirmaEncargadoPorJefe.activa == True
            ).first()
            encargado['tiene_firma'] = firma is not None
            if firma:
                encargados_con_firma += 1

        # Crear objeto establecimiento
        establecimiento = {
            'id': jefe_info.establecimiento.id,
            'nombre': jefe_info.establecimiento.nombre,
            'direccion': jefe_info.establecimiento.direccion
        }

        return render_template('jefe_gestionar_encargados.html',
                               establecimiento=establecimiento,
                               encargados=encargados,
                               encargados_activos=encargados_activos,
                               encargados_inactivos=encargados_inactivos,
                               encargados_con_firma=encargados_con_firma)

    except Exception as e:
        return jsonify({'error': 'Error interno del servidor'}), 500
