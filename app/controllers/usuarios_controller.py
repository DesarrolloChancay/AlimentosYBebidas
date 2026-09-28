from flask import Blueprint, request, jsonify, session, render_template
from app.models.Usuario_models import Usuario, Rol
from app.models.UsuarioEncargado_models import UsuarioEncargado
from app.controllers.auth_controller import AuthController
from app.utils.auth_utils import generar_contrasena_temporal, normalizar_correo_opcional
from app.utils.employee_code import asignar_cod_colab
from app.utils.encargados_sync import crear_usuario_encargado_pg
from app.utils.roles import ROL_ENCARGADO, ROL_JEFE_ESTABLECIMIENTO
from app.services.rrhh_client import lookup_colaborador_por_dni, RRHHAPIError
from app.extensions import db
from datetime import datetime
import re

usuarios_bp = Blueprint('usuarios', __name__, url_prefix='/usuarios')

# Middleware para verificar permisos
def verificar_permiso(roles_permitidos):
    """Decorador para verificar permisos de usuario"""
    def decorator(func):
        def verificar_permisos(*args, **kwargs):
            user_role = session.get('user_role')
            if not user_role or user_role not in roles_permitidos:
                return jsonify({'success': False, 'error': 'No autorizado'}), 403
            return func(*args, **kwargs)
        verificar_permisos.__name__ = func.__name__
        return verificar_permisos
    return decorator

@usuarios_bp.route('/admin/gestionar', methods=['GET'])
@verificar_permiso(['Administrador'])
def gestionar_usuarios_admin():
    """Página de gestión de usuarios para administrador"""
    return render_template('admin_gestionar_usuarios.html')

@usuarios_bp.route('/inspector/gestionar', methods=['GET'])
@verificar_permiso(['Inspector'])
def gestionar_usuarios_inspector():
    """Página de gestión de usuarios para inspector"""
    return render_template('inspector_gestionar_usuarios.html')

@usuarios_bp.route('/jefe/gestionar', methods=['GET'])
@verificar_permiso(['Jefe de Establecimiento'])
def gestionar_usuarios_jefe():
    """Página de gestión de usuarios para jefe de establecimiento"""
    return render_template('jefe_gestionar_usuarios.html')

@usuarios_bp.route('/api/listar', methods=['GET'])
@verificar_permiso(['Administrador', 'Inspector', 'Jefe de Establecimiento'])
def listar_usuarios():
    """API para listar usuarios según permisos"""
    try:
        user_role = session.get('user_role')
        user_id = session.get('user_id')

        # Base query
        query = Usuario.query.join(Rol)

        # Filtrar según rol del usuario actual
        if user_role == 'Administrador':
            # Administrador ve todos los usuarios
            pass
        elif user_role == 'Inspector':
            # Inspector ve: inspectores, jefes de establecimiento y encargados
            query = query.filter(Usuario.rol_id.in_([1, 2, 4]))  # Inspector, Encargado, Jefe
        elif user_role == 'Jefe de Establecimiento':
            # Jefe ve solo encargados de su establecimiento
            query = query.filter(Usuario.rol_id == 2)  # Solo Encargados

        usuarios = query.all()

        resultado = []
        for usuario in usuarios:
            # Obtener información adicional según el rol
            info_adicional = {}

            if usuario.rol_id == 2:  # Encargado
                # Obtener información del establecimiento del encargado
                from sqlalchemy import text
                encargado_info = db.session.execute(text("""
                    SELECT e.nombre as establecimiento_nombre,
                           ee.activo as encargado_activo,
                           ee.fecha_inicio
                    FROM encargados_establecimientos ee
                    JOIN establecimientos e ON ee.establecimiento_id = e.id
                    WHERE ee.usuario_id = :usuario_id
                    ORDER BY ee.fecha_inicio DESC
                    LIMIT 1
                """), {'usuario_id': usuario.id}).fetchone()

                if encargado_info:
                    info_adicional = {
                        'establecimiento': encargado_info[0],
                        'activo_en_establecimiento': encargado_info[1],
                        'fecha_asignacion': encargado_info[2].isoformat() if encargado_info[2] else None
                    }

            resultado.append({
                'id': usuario.id,
                'nombre': usuario.nombre,
                'apellido': usuario.apellido,
                'nombre_usuario': usuario.nombre_usuario,
                'correo': usuario.correo,
                'rol': usuario.rol.nombre,
                'rol_id': usuario.rol_id,
                'activo': usuario.activo,
                'telefono': usuario.telefono,
                'dni': usuario.dni,
                'cod_colab': usuario.cod_colab,
                'cambiar_contrasena': usuario.cambiar_contrasena,
                'fecha_creacion': usuario.fecha_creacion.isoformat() if usuario.fecha_creacion else None,
                'ultimo_acceso': usuario.ultimo_acceso.isoformat() if usuario.ultimo_acceso else None,
                'info_adicional': info_adicional
            })

        return jsonify({
            'success': True,
            'usuarios': resultado,
            'total': len(resultado)
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@usuarios_bp.route('/api/crear', methods=['POST'])
@verificar_permiso(['Administrador', 'Inspector', 'Jefe de Establecimiento'])
def crear_usuario():
    """API para crear un nuevo usuario"""
    try:
        data = request.get_json()
        user_role = session.get('user_role')

        # Validar permisos según jerarquía
        rol_solicitado = data.get('rol_id')

        if user_role == 'Administrador':
            # Administrador puede crear inspectores y jefes
            if rol_solicitado not in [1, 4]:  # Inspector, Jefe de Establecimiento
                return jsonify({'success': False, 'error': 'Rol no permitido para administrador'}), 403
        elif user_role == 'Inspector':
            # Inspector puede crear jefes de establecimiento
            if rol_solicitado != 4:  # Solo Jefe de Establecimiento
                return jsonify({'success': False, 'error': 'Rol no permitido para inspector'}), 403
        elif user_role == 'Jefe de Establecimiento':
            # Jefe puede crear encargados
            if rol_solicitado != 2:  # Solo Encargado
                return jsonify({'success': False, 'error': 'Rol no permitido para jefe de establecimiento'}), 403

        # Validar datos requeridos
        campos_requeridos = ['nombre', 'apellido', 'dni', 'rol_id']
        for campo in campos_requeridos:
            if not data.get(campo):
                return jsonify({'success': False, 'error': f'Campo {campo} es requerido'}), 400

        # Validar formato de DNI
        if not re.match(r'^\d{8}$', data['dni']):
            return jsonify({'success': False, 'error': 'DNI debe tener exactamente 8 dígitos'}), 400

        try:
            correo = normalizar_correo_opcional(data.get('correo'))
        except ValueError as exc:
            return jsonify({'success': False, 'error': str(exc)}), 400

        rol_id = int(data['rol_id'])

        # Inspector (rol_id 1): requiere código de colaborador RRHH.
        # El login de las cuentas nuevas se hace con ese código, ya no con nombre_usuario.
        rrhh_info = None
        if rol_id == 1:
            try:
                rrhh_info = lookup_colaborador_por_dni(data['dni'])
            except RRHHAPIError as exc:
                return jsonify({'success': False, 'error': exc.message}), exc.status_code or 502

            if not rrhh_info.get('cod_colab'):
                return jsonify({
                    'success': False,
                    'error': 'RRHH no devolvió un código de colaborador para este DNI. No se puede crear la cuenta.'
                }), 502

        nombre_usuario = Usuario.generar_nombre_usuario_unico(data['nombre'], data['apellido'])

        # Generar contraseña temporal robusta y única
        contrasena_temporal = generar_contrasena_temporal()

        # Crear usuario con contraseña por defecto
        nuevo_usuario = Usuario(
            nombre=data['nombre'],
            apellido=data['apellido'],
            nombre_usuario=nombre_usuario,
            dni=data['dni'],
            correo=correo,
            rol_id=rol_id,
            telefono=data.get('telefono'),
            activo=True,
            cambiar_contrasena=True  # Marcar que debe cambiar contraseña
        )

        # Contraseña por defecto
        nuevo_usuario.set_password(contrasena_temporal)

        db.session.add(nuevo_usuario)
        db.session.flush()  # Obtiene el id y resuelve la relación con Rol

        if rrhh_info:
            asignar_cod_colab(nuevo_usuario, rrhh_info.get('cod_colab'))
            if not nuevo_usuario.cod_colab:
                db.session.rollback()
                return jsonify({
                    'success': False,
                    'error': 'El código de colaborador ya está asignado a otro usuario en el sistema.'
                }), 409

        # Encargado (2) o Jefe de Establecimiento (4): se refleja en la BD Postgres
        cod_usuario = None
        if rol_id in (2, 4):
            rol_nombre = ROL_ENCARGADO if rol_id == 2 else ROL_JEFE_ESTABLECIMIENTO
            usuario_pg = crear_usuario_encargado_pg(nuevo_usuario, rol_nombre)
            if not usuario_pg.cod_usuario:
                db.session.rollback()
                return jsonify({'success': False, 'error': 'No se pudo generar el código de encargado (CC).'}), 500
            cod_usuario = usuario_pg.cod_usuario

        db.session.commit()

        return jsonify({
            'success': True,
            'mensaje': 'Usuario creado exitosamente',
            'usuario_id': nuevo_usuario.id,
            'nombre_usuario': nuevo_usuario.nombre_usuario,
            'cod_colab': nuevo_usuario.cod_colab,
            'cod_usuario': cod_usuario,
            'contrasena_temporal': contrasena_temporal,
            'correo': nuevo_usuario.correo
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@usuarios_bp.route('/api/resetear-contrasena/<int:usuario_id>', methods=['POST'])
@verificar_permiso(['Administrador', 'Inspector', 'Jefe de Establecimiento'])
def resetear_contrasena(usuario_id):
    """API para resetear contraseña de un usuario"""
    try:
        user_role = session.get('user_role')
        user_id = session.get('user_id')

        # Obtener el usuario a resetear
        usuario = Usuario.query.get(usuario_id)
        if not usuario:
            return jsonify({'success': False, 'error': 'Usuario no encontrado'}), 404

        # Validar permisos según jerarquía
        if user_role == 'Administrador':
            # Administrador puede resetear inspectores
            if usuario.rol_id != 1:  # Solo inspectores
                return jsonify({'success': False, 'error': 'No puede resetear contraseña de este usuario'}), 403
        elif user_role == 'Inspector':
            # Inspector puede resetear jefes de establecimiento
            if usuario.rol_id != 4:  # Solo jefes
                return jsonify({'success': False, 'error': 'No puede resetear contraseña de este usuario'}), 403
        elif user_role == 'Jefe de Establecimiento':
            # Jefe puede resetear encargados
            if usuario.rol_id != 2:  # Solo encargados
                return jsonify({'success': False, 'error': 'No puede resetear contraseña de este usuario'}), 403

        # Generar nueva contraseña temporal robusta
        nueva_contrasena_temporal = generar_contrasena_temporal()

        # Resetear contraseña
        usuario.set_password(nueva_contrasena_temporal)
        usuario.cambiar_contrasena = True  # Marcar que debe cambiar contraseña
        AuthController._sincronizar_password_pg(usuario)
        db.session.commit()

        usuario_pg = UsuarioEncargado.query.filter_by(mysql_usuario_id=usuario.id).first()

        return jsonify({
            'success': True,
            'mensaje': 'Contraseña reseteada exitosamente',
            'nombre_usuario': usuario.nombre_usuario,
            'cod_colab': usuario.cod_colab,
            'cod_usuario': usuario_pg.cod_usuario if usuario_pg else None,
            'contrasena_temporal': nueva_contrasena_temporal,
            'correo': usuario.correo
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

@usuarios_bp.route('/api/cambiar-contrasena', methods=['POST'])
def cambiar_contrasena():
    """API para que un usuario cambie su propia contraseña"""
    try:
        data = request.get_json()
        user_id = session.get('user_id')

        if not user_id:
            return jsonify({'success': False, 'error': 'Sesión no válida'}), 401

        usuario = Usuario.query.get(user_id)
        if not usuario:
            return jsonify({'success': False, 'error': 'Usuario no encontrado'}), 404

        contrasena_actual = data.get('contrasena_actual')
        contrasena_nueva = data.get('contrasena_nueva')

        if not contrasena_actual or not contrasena_nueva:
            return jsonify({'success': False, 'error': 'Contraseña actual y nueva son requeridas'}), 400

        # Validar contraseña actual
        if not usuario.check_password(contrasena_actual):
            return jsonify({'success': False, 'error': 'Contraseña actual incorrecta'}), 400

        # Validar formato de nueva contraseña
        if not validar_contrasena_fuerte(contrasena_nueva):
            return jsonify({
                'success': False,
                'error': 'La contraseña debe tener al menos 6 caracteres y contener solo letras y números'
            }), 400

        # Cambiar contraseña
        usuario.set_password(contrasena_nueva)
        usuario.cambiar_contrasena = False  # Marcar que ya cambió la contraseña
        AuthController._sincronizar_password_pg(usuario)
        db.session.commit()

        # Limpiar la marca de cambio obligatorio si existe
        if session.get('cambiar_contrasena_obligatorio'):
            session.pop('cambiar_contrasena_obligatorio', None)

        return jsonify({'success': True, 'mensaje': 'Contraseña cambiada exitosamente'})

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 500

def validar_contrasena_fuerte(contrasena):
    """Valida que la contraseña tenga solo letras y números y mínimo 6 caracteres"""
    if len(contrasena) < 6:
        return False
    # Solo letras y números
    return bool(re.match(r'^[a-zA-Z0-9]+$', contrasena))

@usuarios_bp.route('/api/verificar-cambio-contrasena', methods=['GET'])
def verificar_cambio_contrasena():
    """Verifica si el usuario necesita cambiar su contraseña"""
    try:
        user_id = session.get('user_id')
        if not user_id:
            return jsonify({'requiere_cambio': False}), 401

        usuario = Usuario.query.get(user_id)
        if not usuario:
            return jsonify({'requiere_cambio': False}), 404

        # Verificar si necesita cambiar contraseña (usar el campo cambiar_contrasena o la marca de sesión)
        requiere_cambio = usuario.cambiar_contrasena or session.get('cambiar_contrasena_obligatorio', False)

        return jsonify({
            'requiere_cambio': requiere_cambio,
            'usuario': {
                'id': usuario.id,
                'nombre': f"{usuario.nombre} {usuario.apellido or ''}",
                'nombre_usuario': usuario.nombre_usuario,
                'correo': usuario.correo
            }
        })

    except Exception as e:
        return jsonify({'requiere_cambio': False, 'error': str(e)}), 500