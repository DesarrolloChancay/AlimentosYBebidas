"""
✅ CONTROLADOR ADMINISTRADOR - Sistema de Control Total
Funcionalidades:
- Gestión completa de usuarios y roles
- Control de permisos por usuario/rol
- Dashboard administrativo con estadísticas
- Gestión de establecimientos y encargados
- Auditoría y logs del sistema
- Configuración global del sistema
"""

from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, flash, current_app
from flask_login import current_user
from datetime import datetime, date, timedelta
from functools import wraps
import json
from sqlalchemy import text, func, desc, or_, and_
from app.extensions import db
from app.models.Usuario_models import Usuario, Rol, TipoEstablecimiento
from app.models.Inspecciones_models import (
    Establecimiento, EncargadoEstablecimiento, Inspeccion, 
    InspeccionDetalle, CategoriaEvaluacion, ItemEvaluacionBase, ConfiguracionEvaluacion,
    JefeEstablecimiento
)
from app.models.ConfiguracionPermisos_models import (
    PermisoRol, PermisoUsuario, AuditoriaAcciones, 
    PermisosHelper, inicializar_configuraciones_basicas, inicializar_permisos_basicos
)
from app.utils.auth_utils import generar_contrasena_temporal

# Blueprint para rutas de administrador
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user_id') or session.get('user_role') != 'Administrador':
            # Detectar peticiones AJAX de múltiples formas
            is_ajax = (
                request.headers.get('X-Requested-With') == 'XMLHttpRequest' or
                request.headers.get('Content-Type') == 'application/json' or
                request.is_json or
                'application/json' in request.headers.get('Accept', '') or
                request.path.startswith('/admin/api/')  # Rutas API específicas
            )
            
            if is_ajax:
                return jsonify({'error': 'Acceso denegado. Se requieren permisos de administrador.'}), 403
            
            # Para requests normales, redirigir
            flash('Acceso denegado. Se requieren permisos de administrador.', 'error')
            return redirect(url_for('login_page'))
        return f(*args, **kwargs)
    return decorated_function

class AdminController:
    """Controlador principal para funciones administrativas"""
    
    @staticmethod
    @admin_bp.route('/dashboard')
    @admin_required
    def dashboard():
        """
        ✅ Dashboard principal del administrador
        Muestra estadísticas generales del sistema
        """
        try:
            # Estadísticas generales
            stats = AdminController.obtener_estadisticas_generales()
            
            # Actividad reciente
            actividad_reciente = AdminController.obtener_actividad_reciente()
            
            # Alertas del sistema
            alertas = AdminController.obtener_alertas_sistema()
            
            return render_template('admin/dashboard.html', 
                                 stats=stats,
                                 actividad_reciente=actividad_reciente,
                                 alertas=alertas)
                                 
        except Exception as e:
            flash('Error al cargar el dashboard administrativo', 'error')
            return redirect(url_for('inspeccion.index'))
    
    @staticmethod
    def obtener_estadisticas_generales():
        """Obtiene estadísticas generales del sistema"""
        try:
            # Contar usuarios por rol
            usuarios_stats = db.session.query(
                Rol.nombre,
                func.count(Usuario.id).label('cantidad')
            ).join(Usuario, Rol.id == Usuario.rol_id).filter(Usuario.activo == True).group_by(Rol.nombre).all()
            
            # Establecimientos y encargados
            total_establecimientos = Establecimiento.query.filter_by(activo=True).count()
            establecimientos_con_encargado = db.session.query(
                func.count(func.distinct(EncargadoEstablecimiento.establecimiento_id))
            ).filter(EncargadoEstablecimiento.activo == True).scalar()
            
            # Inspecciones del mes actual
            inicio_mes = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            inspecciones_mes = Inspeccion.query.filter(
                Inspeccion.fecha >= inicio_mes
            ).count()
            
            # Inspecciones pendientes
            inspecciones_pendientes = Inspeccion.query.filter_by(estado='pendiente').count()
            
            # Jefes de establecimiento activos
            total_jefes = JefeEstablecimiento.query.filter_by(activo=True).count()
            
            return {
                'usuarios_por_rol': dict(usuarios_stats),
                'total_usuarios': Usuario.query.filter_by(activo=True).count(),
                'total_establecimientos': total_establecimientos,
                'establecimientos_con_encargado': establecimientos_con_encargado,
                'inspecciones_mes': inspecciones_mes,
                'inspecciones_pendientes': inspecciones_pendientes,
                'usuarios_en_linea': Usuario.query.filter_by(en_linea=True).count(),
                'total_jefes': total_jefes
            }
            
        except Exception as e:
            return {}
    
    @staticmethod
    def obtener_actividad_reciente():
        """Obtiene actividad reciente del sistema"""
        try:
            # Últimas inspecciones con JOIN específico - corregido
            inspecciones_recientes = db.session.query(
                Inspeccion.id,
                Inspeccion.fecha,
                Inspeccion.estado,
                Establecimiento.nombre.label('establecimiento'),
                Usuario.nombre.label('inspector_nombre')
            ).join(
                Establecimiento, Inspeccion.establecimiento_id == Establecimiento.id
            ).join(
                Usuario, Inspeccion.inspector_id == Usuario.id
            ).order_by(desc(Inspeccion.fecha)).limit(10).all()
            
            # Últimos usuarios creados
            usuarios_recientes = Usuario.query.filter_by(activo=True).order_by(
                desc(Usuario.created_at)
            ).limit(5).all()
            
            return {
                'inspecciones': inspecciones_recientes,
                'usuarios': usuarios_recientes
            }
            
        except Exception as e:
            return {'inspecciones': [], 'usuarios': []}
    
    @staticmethod
    def obtener_alertas_sistema():
        """Obtiene alertas importantes del sistema"""
        try:
            alertas = []
            
            # Establecimientos sin encargado
            establecimientos_sin_encargado = db.session.query(
                Establecimiento.nombre
            ).outerjoin(EncargadoEstablecimiento, and_(
                EncargadoEstablecimiento.establecimiento_id == Establecimiento.id,
                EncargadoEstablecimiento.activo == True
            )).filter(
                Establecimiento.activo == True,
                EncargadoEstablecimiento.id.is_(None)
            ).all()
            
            if establecimientos_sin_encargado:
                alertas.append({
                    'tipo': 'warning',
                    'titulo': 'Establecimientos sin Encargado',
                    'mensaje': f'{len(establecimientos_sin_encargado)} establecimientos no tienen encargado asignado',
                    'detalles': [e.nombre for e in establecimientos_sin_encargado]
                })
            
            # Inspecciones pendientes por más de 7 días
            fecha_limite = datetime.now() - timedelta(days=7)
            inspecciones_atrasadas = Inspeccion.query.filter(
                Inspeccion.estado == 'pendiente',
                Inspeccion.fecha < fecha_limite
            ).count()
            
            if inspecciones_atrasadas > 0:
                alertas.append({
                    'tipo': 'danger',
                    'titulo': 'Inspecciones Atrasadas',
                    'mensaje': f'{inspecciones_atrasadas} inspecciones pendientes por más de 7 días'
                })
            
            return alertas
            
        except Exception as e:
            return []

# =================== GESTIÓN DE USUARIOS ===================

@admin_bp.route('/usuarios')
@admin_required
def gestionar_usuarios():
    """Vista para gestionar usuarios del sistema"""
    try:
        usuarios = db.session.query(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.telefono,
            Usuario.dni,
            Usuario.activo,
            Usuario.en_linea,
            Usuario.ultimo_acceso,
            Rol.nombre.label('rol_nombre')
        ).join(Rol, Usuario.rol_id == Rol.id).order_by(Usuario.nombre).all()
        
        roles = Rol.query.all()
        
        return render_template('admin/usuarios.html', 
                             usuarios=usuarios, 
                             roles=roles)
                             
    except Exception as e:
        flash('Error al cargar la gestión de usuarios', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/api/usuarios', methods=['GET'])
@admin_required
def api_obtener_usuarios():
    """API para obtener lista de usuarios con filtros"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        search = request.args.get('search', '')
        rol_filter = request.args.get('rol', '')
        activo_filter = request.args.get('activo', '')
        
        query = db.session.query(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.telefono,
            Usuario.dni,
            Usuario.activo,
            Usuario.en_linea,
            Usuario.ultimo_acceso,
            Usuario.created_at,
            Rol.nombre.label('rol_nombre'),
            Rol.id.label('rol_id')
        ).join(Rol, Usuario.rol_id == Rol.id)
        
        # Aplicar filtros
        if search:
            query = query.filter(or_(
                Usuario.nombre.contains(search),
                Usuario.apellido.contains(search),
                Usuario.correo.contains(search),
                Usuario.dni.contains(search)
            ))
        
        if rol_filter:
            query = query.filter(Rol.nombre == rol_filter)
        
        if activo_filter:
            query = query.filter(Usuario.activo == (activo_filter.lower() == 'true'))
        
        # Paginación
        usuarios_paginados = query.paginate(
            page=page, per_page=per_page, error_out=False
        )
        
        usuarios_data = []
        for usuario in usuarios_paginados.items:
            usuarios_data.append({
                'id': usuario.id,
                'nombre_completo': f"{usuario.nombre} {usuario.apellido or ''}".strip(),
                'correo': usuario.correo,
                'telefono': usuario.telefono,
                'dni': usuario.dni,
                'rol_nombre': usuario.rol_nombre,
                'rol_id': usuario.rol_id,
                'activo': usuario.activo,
                'en_linea': usuario.en_linea,
                'ultimo_acceso': usuario.ultimo_acceso.strftime('%Y-%m-%d %H:%M') if usuario.ultimo_acceso else None,
                'fecha_creacion': usuario.created_at.strftime('%Y-%m-%d') if usuario.created_at else None
            })
        
        return jsonify({
            'usuarios': usuarios_data,
            'total': usuarios_paginados.total,
            'pages': usuarios_paginados.pages,
            'current_page': page,
            'has_next': usuarios_paginados.has_next,
            'has_prev': usuarios_paginados.has_prev
        })
        
    except Exception as e:
        return jsonify({'error': 'Error obteniendo usuarios'}), 500

# =================== GESTIÓN DE CONFIGURACIONES ===================

@admin_bp.route('/configuraciones')
@admin_required
def configuraciones():
    """Gestión de configuraciones del sistema usando tabla existente"""
    try:
        # Obtener todas las configuraciones
        configuraciones = db.session.query(ConfiguracionEvaluacion).order_by(
            ConfiguracionEvaluacion.clave
        ).all()
        
        return render_template('admin/configuraciones.html', 
                             configuraciones=configuraciones)
    
    except Exception as e:
        flash('Error al cargar configuraciones', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/configuraciones/actualizar', methods=['POST'])
@admin_required
def actualizar_configuracion():
    """Actualizar una configuración específica usando tabla existente"""
    try:
        clave = request.form.get('clave')
        nuevo_valor = request.form.get('valor')
        
        config = ConfiguracionEvaluacion.query.filter_by(clave=clave).first()
        if not config:
            return jsonify({'success': False, 'message': 'Configuración no encontrada'})
        
        # Verificar permisos
        user_role = session.get('user_role', '')
        if user_role != 'Administrador' and not config.modificable_por_inspector:
            return jsonify({'success': False, 'message': 'Sin permisos para modificar esta configuración'})
        
        # Guardar valor anterior para auditoría
        valor_anterior = config.valor
        config.valor = nuevo_valor
        config.updated_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({'success': True, 'message': 'Configuración actualizada correctamente'})
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'})

# =================== AUDITORÍA ===================

@admin_bp.route('/auditoria')
@admin_required
def auditoria():
    """Visualización de auditoría del sistema"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = 50
        
        # Obtener registros de auditoría con JOIN explícito
        auditoria_paginada = db.session.query(AuditoriaAcciones).join(
            Usuario, AuditoriaAcciones.usuario_id == Usuario.id
        ).order_by(desc(AuditoriaAcciones.created_at)
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        # Obtener lista de usuarios para el filtro
        usuarios = db.session.query(Usuario).filter_by(activo=True).all()
        
        # Estadísticas del día de hoy
        hoy = datetime.now().date()
        inicio_hoy = datetime.combine(hoy, datetime.min.time())
        acciones_hoy = AuditoriaAcciones.query.filter(
            AuditoriaAcciones.created_at >= inicio_hoy
        ).count()
        
        # Filtros vacíos para la plantilla
        filtros = {
            'usuario_id': request.args.get('usuario_id'),
            'recurso': request.args.get('recurso'),
            'fecha_inicio': request.args.get('fecha_inicio'),
            'fecha_fin': request.args.get('fecha_fin')
        }
        
        return render_template('admin/auditoria.html',
                             auditoria=auditoria_paginada,
                             usuarios=usuarios,
                             filtros=filtros,
                             acciones_hoy=acciones_hoy)
    
    except Exception as e:
        flash('Error al cargar auditoría', 'error')
        return redirect(url_for('admin.dashboard'))

# =================== GESTIÓN DE ESTABLECIMIENTOS ===================

@admin_bp.route('/establecimientos')
@admin_required
def gestionar_establecimientos():
    """Vista para gestionar establecimientos"""
    try:
        # Subconsulta para contar encargados activos por establecimiento
        subquery_encargados = db.session.query(
            EncargadoEstablecimiento.establecimiento_id,
            func.count(EncargadoEstablecimiento.id).label('total_encargados')
        ).filter(EncargadoEstablecimiento.activo == True).group_by(EncargadoEstablecimiento.establecimiento_id).subquery()
        
        establecimientos = db.session.query(
            Establecimiento.id,
            Establecimiento.nombre,
            Establecimiento.direccion,
            Establecimiento.activo,
            Establecimiento.created_at,
            Usuario.nombre.label('jefe_nombre'),
            Usuario.apellido.label('jefe_apellido'),
            Usuario.correo.label('jefe_correo'),
            subquery_encargados.c.total_encargados
        ).outerjoin(JefeEstablecimiento, and_(
            JefeEstablecimiento.establecimiento_id == Establecimiento.id
        )).outerjoin(Usuario, Usuario.id == JefeEstablecimiento.usuario_id).outerjoin(
            subquery_encargados, Establecimiento.id == subquery_encargados.c.establecimiento_id
        ).all()

        establecimientos_data = []
        for est in establecimientos:
            # Contar inspecciones del establecimiento
            total_inspecciones = Inspeccion.query.filter_by(
                establecimiento_id=est.id
            ).count()
            
            establecimientos_data.append({
                'id': est.id,
                'nombre': est.nombre,
                'direccion': est.direccion,
                'activo': est.activo,
                'created_at': est.created_at.strftime('%Y-%m-%d') if est.created_at else None,
                'jefe': {
                    'nombre': f"{est.jefe_nombre or ''} {est.jefe_apellido or ''}".strip() or 'Sin asignar',
                    'correo': est.jefe_correo
                } if est.jefe_nombre else None,
                'total_inspecciones': total_inspecciones,
                'total_encargados': est.total_encargados or 0
            })

        return render_template('admin/establecimientos.html', establecimientos=establecimientos_data)

    except Exception as e:
        flash('Error al cargar la gestión de establecimientos', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/api/establecimientos', methods=['GET'])
@admin_required
def api_obtener_establecimientos():
    """API para obtener establecimientos con información completa"""
    try:
        establecimientos = db.session.query(
            Establecimiento.id,
            Establecimiento.nombre,
            Establecimiento.direccion,
            Establecimiento.tipo_establecimiento,
            Establecimiento.activo,
            Establecimiento.created_at,
            Usuario.nombre.label('encargado_nombre'),
            Usuario.apellido.label('encargado_apellido'),
            Usuario.correo.label('encargado_correo')
        ).outerjoin(EncargadoEstablecimiento, and_(
            EncargadoEstablecimiento.establecimiento_id == Establecimiento.id,
            EncargadoEstablecimiento.activo == True
        )).outerjoin(Usuario, Usuario.id == EncargadoEstablecimiento.usuario_id).all()
        
        establecimientos_data = []
        for est in establecimientos:
            # Contar inspecciones del establecimiento
            total_inspecciones = Inspeccion.query.filter_by(
                establecimiento_id=est.id
            ).count()
            
            establecimientos_data.append({
                'id': est.id,
                'nombre': est.nombre,
                'direccion': est.direccion,
                'tipo_establecimiento': est.tipo_establecimiento,
                'activo': est.activo,
                'created_at': est.created_at.strftime('%Y-%m-%d') if est.created_at else None,
                'encargado': {
                    'nombre': f"{est.encargado_nombre or ''} {est.encargado_apellido or ''}".strip() or 'Sin asignar',
                    'correo': est.encargado_correo
                } if est.encargado_nombre else None,
                'total_inspecciones': total_inspecciones
            })
        
        return jsonify({'establecimientos': establecimientos_data})
        
    except Exception as e:
        return jsonify({'error': 'Error obteniendo establecimientos'}), 500

@admin_bp.route('/api/health', methods=['GET'])
@admin_required
def api_health_check():
    """API para verificar el estado del servidor y la autenticación"""
    try:
        # Verificar conexión a base de datos
        db.session.execute(text('SELECT 1'))
        
        return jsonify({
            'status': 'ok',
            'timestamp': datetime.now().isoformat(),
            'user': {
                'authenticated': True,
                'username': current_user.username if current_user.is_authenticated else None
            },
            'database': 'connected'
        })
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

# =================== GESTIÓN DE ROLES ===================

@admin_bp.route('/roles')
@admin_required
def gestionar_roles():
    """Vista para gestionar roles y permisos"""
    try:
        roles = Rol.query.all()
        return render_template('admin/roles.html', roles=roles)
        
    except Exception as e:
        flash('Error al cargar la gestión de roles', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/api/roles', methods=['GET'])
@admin_required
def api_obtener_roles():
    """API para obtener roles con permisos"""
    try:
        roles = Rol.query.all()
        
        roles_data = []
        for rol in roles:
            usuarios_count = Usuario.query.filter_by(rol_id=rol.id, activo=True).count()
            
            roles_data.append({
                'id': rol.id,
                'nombre': rol.nombre,
                'descripcion': rol.descripcion,
                'permisos': rol.permisos,
                'usuarios_count': usuarios_count,
                'created_at': rol.created_at.strftime('%Y-%m-%d') if rol.created_at else None
            })
        
        return jsonify({'roles': roles_data})
        
    except Exception as e:
        return jsonify({'error': 'Error obteniendo roles'}), 500

# =================== CONFIGURACIÓN DEL SISTEMA ===================

@admin_bp.route('/configuracion')
@admin_required
def configuracion_sistema():
    """Vista para configuración general del sistema"""
    try:
        return render_template('admin/configuracion.html')
        
    except Exception as e:
        flash('Error al cargar la configuración del sistema', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/inicializar_sistema', methods=['POST'])
@admin_required
def inicializar_sistema():
    """Inicializar configuraciones y permisos básicos del sistema"""
    try:
        # Inicializar configuraciones básicas
        inicializar_configuraciones_basicas()

        # Inicializar permisos básicos
        inicializar_permisos_basicos()

        return jsonify({
            'success': True,
            'message': 'Sistema inicializado correctamente con configuraciones y permisos básicos'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'})

# =================== GESTIÓN DE JEFES DE ESTABLECIMIENTO ===================

@admin_bp.route('/jefes-establecimiento')
@admin_required
def gestionar_jefes_establecimiento():
    """Vista para gestionar jefes de establecimiento"""
    try:
        # Obtener jefes con información de establecimiento
        jefes = db.session.query(
            JefeEstablecimiento.id,
            JefeEstablecimiento.fecha_inicio,
            JefeEstablecimiento.fecha_fin,
            JefeEstablecimiento.activo,
            Usuario.id.label('usuario_id'),
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.telefono,
            Usuario.dni,
            Establecimiento.id.label('establecimiento_id'),
            Establecimiento.nombre.label('establecimiento_nombre'),
            Establecimiento.direccion.label('establecimiento_direccion')
        ).join(Usuario, JefeEstablecimiento.usuario_id == Usuario.id
        ).join(Establecimiento, JefeEstablecimiento.establecimiento_id == Establecimiento.id
        ).filter(JefeEstablecimiento.activo == True
        ).order_by(JefeEstablecimiento.fecha_inicio.desc()).all()

        return render_template('admin/jefes_establecimiento.html', jefes=jefes)

    except Exception as e:
        flash('Error al cargar la gestión de jefes de establecimiento', 'error')
        return redirect(url_for('admin.dashboard'))

@admin_bp.route('/jefes-establecimiento/crear', methods=['GET'])
@admin_required
def crear_jefe_establecimiento():
    """Vista para crear un nuevo jefe de establecimiento"""
    try:
        # Obtener establecimientos disponibles (sin jefe asignado)
        establecimientos_disponibles = db.session.query(
            Establecimiento.id,
            Establecimiento.nombre,
            Establecimiento.direccion
        ).outerjoin(JefeEstablecimiento, and_(
            JefeEstablecimiento.establecimiento_id == Establecimiento.id,
            JefeEstablecimiento.activo == True
        )).filter(
            Establecimiento.activo == True,
            JefeEstablecimiento.id.is_(None)
        ).order_by(Establecimiento.nombre).all()

        return render_template('admin/crear_jefe_establecimiento.html',
                             establecimientos=establecimientos_disponibles)

    except Exception as e:
        flash('Error al cargar el formulario de creación', 'error')
        return redirect(url_for('admin.gestionar_jefes_establecimiento'))

@admin_bp.route('/api/jefes-establecimiento', methods=['POST'])
@admin_required
def api_crear_jefe_establecimiento():
    """API para crear un nuevo jefe de establecimiento"""
    try:
        data = request.get_json()

        # Validar datos requeridos
        required_fields = ['nombre', 'apellido', 'correo', 'dni', 'establecimiento_id', 'fecha_inicio']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'success': False, 'message': f'El campo {field} es requerido'}), 400

        # Verificar que el correo no exista
        if Usuario.query.filter_by(correo=data['correo']).first():
            return jsonify({'success': False, 'message': 'Ya existe un usuario con este correo electrónico'}), 400

        # Verificar que el DNI no exista
        if Usuario.query.filter_by(dni=data['dni']).first():
            return jsonify({'success': False, 'message': 'Ya existe un usuario con este DNI'}), 400

        # Verificar que el establecimiento no tenga jefe asignado
        jefe_existente = JefeEstablecimiento.query.filter_by(
            establecimiento_id=data['establecimiento_id'],
            activo=True
        ).first()
        if jefe_existente:
            return jsonify({'success': False, 'message': 'Este establecimiento ya tiene un jefe asignado'}), 400

        # Obtener rol de Jefe de Establecimiento
        rol_jefe = Rol.query.filter_by(nombre='Jefe de Establecimiento').first()
        if not rol_jefe:
            return jsonify({'success': False, 'message': 'Rol de Jefe de Establecimiento no encontrado'}), 500

        # Generar contraseña temporal robusta
        contrasena_temporal = generar_contrasena_temporal()

        # Crear usuario
        nuevo_usuario = Usuario(
            nombre=data['nombre'],
            apellido=data['apellido'],
            correo=data['correo'],
            telefono=data.get('telefono'),
            dni=data['dni'],
            rol_id=rol_jefe.id,
            activo=True,
            cambiar_contrasena=True  # Marcar que debe cambiar contraseña
        )
        nuevo_usuario.set_password(contrasena_temporal)  # Contraseña temporal generada

        db.session.add(nuevo_usuario)
        db.session.flush()  # Para obtener el ID del usuario

        # Crear asignación de jefe
        nuevo_jefe = JefeEstablecimiento(
            usuario_id=nuevo_usuario.id,
            establecimiento_id=data['establecimiento_id'],
            fecha_inicio=datetime.strptime(data['fecha_inicio'], '%Y-%m-%d').date(),
            fecha_fin=datetime.strptime(data['fecha_fin'], '%Y-%m-%d').date() if data.get('fecha_fin') else None,
            comentario=data.get('comentario'),
            activo=True
        )

        db.session.add(nuevo_jefe)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'Jefe de establecimiento creado exitosamente. Usuario: {data["correo"]}, Contraseña temporal: {contrasena_temporal}',
            'usuario_id': nuevo_usuario.id,
            'jefe_id': nuevo_jefe.id,
            'correo': data['correo'],
            'contrasena_temporal': contrasena_temporal
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

@admin_bp.route('/api/establecimientos-disponibles', methods=['GET'])
@admin_required
def api_establecimientos_disponibles():
    """API para obtener establecimientos disponibles para asignar jefe"""
    try:
        # Establecimientos sin jefe asignado
        establecimientos = db.session.query(
            Establecimiento.id,
            Establecimiento.nombre,
            Establecimiento.direccion,
            Establecimiento.tipo_establecimiento
        ).outerjoin(JefeEstablecimiento, and_(
            JefeEstablecimiento.establecimiento_id == Establecimiento.id,
            JefeEstablecimiento.activo == True
        )).filter(
            Establecimiento.activo == True,
            JefeEstablecimiento.id.is_(None)
        ).order_by(Establecimiento.nombre).all()

        establecimientos_data = []
        for est in establecimientos:
            establecimientos_data.append({
                'id': est.id,
                'nombre': est.nombre,
                'direccion': est.direccion,
                'tipo_establecimiento': est.tipo_establecimiento
            })

        return jsonify({'establecimientos': establecimientos_data})

    except Exception as e:
        return jsonify({'error': 'Error obteniendo establecimientos disponibles'}), 500

# =================== GESTIÓN DE INSPECTORES ===================

@admin_bp.route('/inspectores')
@admin_required
def gestionar_inspectores():
    """Vista para gestionar inspectores"""
    try:
        # Obtener inspectores con estadísticas
        inspectores = db.session.query(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.telefono,
            Usuario.dni,
            Usuario.activo,
            Usuario.en_linea,
            Usuario.ultimo_acceso,
            Usuario.created_at
        ).join(Rol, Usuario.rol_id == Rol.id
        ).filter(Rol.nombre == 'Inspector'
        ).order_by(Usuario.nombre).all()

        inspectores_data = []
        for insp in inspectores:
            # Contar inspecciones realizadas por el inspector
            total_inspecciones = Inspeccion.query.filter_by(inspector_id=insp.id).count()
            
            # Contar inspecciones del mes actual
            inicio_mes = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            inspecciones_mes = Inspeccion.query.filter(
                Inspeccion.inspector_id == insp.id,
                Inspeccion.fecha >= inicio_mes
            ).count()

            inspectores_data.append({
                'id': insp.id,
                'nombre': insp.nombre,
                'apellido': insp.apellido,
                'correo': insp.correo,
                'telefono': insp.telefono,
                'dni': insp.dni,
                'activo': insp.activo,
                'en_linea': insp.en_linea,
                'ultimo_acceso': insp.ultimo_acceso.strftime('%Y-%m-%d %H:%M') if insp.ultimo_acceso else None,
                'created_at': insp.created_at.strftime('%Y-%m-%d') if insp.created_at else None,
                'total_inspecciones': total_inspecciones,
                'inspecciones_mes': inspecciones_mes
            })

        return render_template('admin/inspectores.html', inspectores=inspectores_data)

    except Exception as e:
        flash('Error al cargar la gestión de inspectores', 'error')
        return redirect(url_for('admin.dashboard'))


@admin_bp.route('/api/inspectores', methods=['POST'])
@admin_required
def api_crear_inspector():
    """API para crear un nuevo inspector"""
    try:
        data = request.get_json()

        # Validar datos requeridos
        required_fields = ['nombre', 'apellido', 'correo', 'dni']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'success': False, 'message': f'El campo {field} es requerido'}), 400

        # Verificar que el correo no exista
        if Usuario.query.filter_by(correo=data['correo']).first():
            return jsonify({'success': False, 'message': 'Ya existe un usuario con este correo electrónico'}), 400

        # Verificar que el DNI no exista
        if Usuario.query.filter_by(dni=data['dni']).first():
            return jsonify({'success': False, 'message': 'Ya existe un usuario con este DNI'}), 400

        # Obtener rol de Inspector
        rol_inspector = Rol.query.filter_by(nombre='Inspector').first()
        if not rol_inspector:
            return jsonify({'success': False, 'message': 'Rol de Inspector no encontrado'}), 500

        # Generar contraseña temporal robusta
        contrasena_temporal = generar_contrasena_temporal()

        # Crear usuario
        nuevo_usuario = Usuario(
            nombre=data['nombre'],
            apellido=data['apellido'],
            correo=data['correo'],
            telefono=data.get('telefono'),
            dni=data['dni'],
            rol_id=rol_inspector.id,
            activo=True,
            cambiar_contrasena=True  # Marcar que debe cambiar contraseña
        )
        nuevo_usuario.set_password(contrasena_temporal)  # Contraseña temporal generada

        db.session.add(nuevo_usuario)
        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'Inspector creado exitosamente. Usuario: {data["correo"]}, Contraseña temporal: {contrasena_temporal}',
            'usuario_id': nuevo_usuario.id,
            'correo': data['correo'],
            'contrasena_temporal': contrasena_temporal
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

@admin_bp.route('/api/inspectores/<int:inspector_id>', methods=['GET'])
@admin_required
def api_obtener_detalles_inspector(inspector_id):
    """
    API para obtener detalles completos de un inspector
    Maneja errores de forma robusta y proporciona logging detallado
    """
    try:
        # Verificar que el inspector_id sea válido
        if not inspector_id or inspector_id <= 0:
            return jsonify({'success': False, 'message': 'ID de inspector inválido'}), 400

        # Obtener inspector con información completa
        inspector = db.session.query(
            Usuario.id,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.telefono,
            Usuario.dni,
            Usuario.activo,
            Usuario.en_linea,
            Usuario.ultimo_acceso,
            Usuario.created_at,
            Usuario.updated_at,
            Rol.nombre.label('rol_nombre')
        ).join(Rol, Usuario.rol_id == Rol.id
        ).filter(Usuario.id == inspector_id, Rol.nombre == 'Inspector'
        ).first()

        if not inspector:
            return jsonify({'success': False, 'message': 'Inspector no encontrado o no tiene rol de Inspector'}), 404

        # Función auxiliar para formatear fechas de forma segura
        def formatear_fecha(fecha, formato='%Y-%m-%d %H:%M'):
            """Formatea una fecha de forma segura, manejando valores None"""
            if fecha is None:
                return None
            try:
                if hasattr(fecha, 'strftime'):
                    return fecha.strftime(formato)
                else:
                    # Si no es un objeto datetime, intentar convertir
                    from datetime import datetime
                    if isinstance(fecha, str):
                        # Si ya es string, devolver como está
                        return fecha
                    return str(fecha)
            except Exception as e:
                # En caso de error, devolver None
                return None

        # Contar inspecciones realizadas por el inspector
        total_inspecciones = Inspeccion.query.filter_by(inspector_id=inspector_id).count()

        # Contar inspecciones por estado
        inspecciones_pendientes = Inspeccion.query.filter_by(
            inspector_id=inspector_id, estado='pendiente'
        ).count()

        inspecciones_completadas = Inspeccion.query.filter_by(
            inspector_id=inspector_id, estado='completada'
        ).count()

        inspecciones_canceladas = Inspeccion.query.filter_by(
            inspector_id=inspector_id, estado='cancelada'
        ).count()

        # Obtener estadísticas del mes actual
        inicio_mes = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        inspecciones_mes = Inspeccion.query.filter(
            Inspeccion.inspector_id == inspector_id,
            Inspeccion.fecha >= inicio_mes
        ).count()

        # Obtener últimas 5 inspecciones con manejo de errores
        ultimas_inspecciones_data = []
        try:
            ultimas_inspecciones = db.session.query(
                Inspeccion.id,
                Inspeccion.fecha,
                Inspeccion.estado,
                Establecimiento.nombre.label('establecimiento_nombre')
            ).join(Establecimiento, Inspeccion.establecimiento_id == Establecimiento.id
            ).filter(Inspeccion.inspector_id == inspector_id
            ).order_by(Inspeccion.fecha.desc() if Inspeccion.fecha is not None else Inspeccion.id.desc()
            ).limit(5).all()

            for insp in ultimas_inspecciones:
                ultimas_inspecciones_data.append({
                    'id': insp.id,
                    'fecha': formatear_fecha(insp.fecha, '%Y-%m-%d %H:%M'),
                    'estado': insp.estado or 'desconocido',
                    'establecimiento': insp.establecimiento_nombre or 'Establecimiento desconocido'
                })
        except Exception as e:
            # Si hay error obteniendo inspecciones, continuar con lista vacía
            ultimas_inspecciones_data = []

        # Preparar datos del inspector con manejo seguro de fechas
        inspector_data = {
            'id': inspector.id,
            'nombre': inspector.nombre or '',
            'apellido': inspector.apellido or '',
            'nombre_completo': f"{inspector.nombre or ''} {inspector.apellido or ''}".strip(),
            'correo': inspector.correo or '',
            'telefono': inspector.telefono,
            'dni': inspector.dni or '',
            'rol': inspector.rol_nombre or 'Inspector',
            'activo': inspector.activo if inspector.activo is not None else True,
            'en_linea': inspector.en_linea if inspector.en_linea is not None else False,
            'ultimo_acceso': formatear_fecha(inspector.ultimo_acceso, '%Y-%m-%d %H:%M'),
            'created_at': formatear_fecha(inspector.created_at, '%Y-%m-%d %H:%M'),
            'fecha_actualizacion': formatear_fecha(inspector.updated_at, '%Y-%m-%d %H:%M'),
            'estadisticas': {
                'total_inspecciones': total_inspecciones,
                'inspecciones_mes': inspecciones_mes,
                'inspecciones_pendientes': inspecciones_pendientes,
                'inspecciones_completadas': inspecciones_completadas,
                'inspecciones_canceladas': inspecciones_canceladas
            },
            'ultimas_inspecciones': ultimas_inspecciones_data
        }

        return jsonify({
            'success': True,
            'inspector': inspector_data
        })

    except Exception as e:
        # Log detallado del error para debugging
        import traceback
        error_details = traceback.format_exc()

        # Devolver respuesta de error con más información en desarrollo
        return jsonify({
            'success': False,
            'message': 'Error obteniendo detalles del inspector',
            'error': str(e),
            'traceback': error_details if current_app.config.get('DEBUG', False) else None
        }), 500

@admin_bp.route('/api/inspectores/<int:inspector_id>/restablecer-contrasena', methods=['POST'])
@admin_required
def api_restablecer_contrasena_inspector(inspector_id):
    """API para restablecer la contraseña de un inspector"""
    try:
        # Verificar que el inspector existe y es un inspector
        inspector = db.session.query(Usuario).join(Rol).filter(
            Usuario.id == inspector_id,
            Rol.nombre == 'Inspector',
            Usuario.activo == True
        ).first()

        if not inspector:
            return jsonify({'success': False, 'message': 'Inspector no encontrado'}), 404

        # Generar nueva contraseña temporal
        nueva_contrasena = generar_contrasena_temporal()

        # Actualizar contraseña del usuario
        inspector.set_password(nueva_contrasena)
        inspector.cambiar_contrasena = True  # Forzar cambio de contraseña
        inspector.fecha_actualizacion = datetime.now()

        db.session.commit()

        return jsonify({
            'success': True,
            'message': 'Contraseña restablecida exitosamente',
            'correo': inspector.correo,
            'contrasena_temporal': nueva_contrasena
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500
