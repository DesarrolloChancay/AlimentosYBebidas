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

from flask import Blueprint, render_template, request, jsonify, session, redirect, url_for, flash
from datetime import datetime, date, timedelta
from functools import wraps
import json
from sqlalchemy import text, func, desc, or_, and_
from app.extensions import db
from app.models.Usuario_models import Usuario, Rol, TipoEstablecimiento
from app.models.Inspecciones_models import (
    Establecimiento, EncargadoEstablecimiento, Inspeccion, 
    InspeccionDetalle, CategoriaEvaluacion, ItemEvaluacionBase, ConfiguracionEvaluacion
)
from app.models.ConfiguracionPermisos_models import (
    PermisoRol, PermisoUsuario, AuditoriaAcciones, 
    PermisosHelper, inicializar_configuraciones_basicas, inicializar_permisos_basicos
)

# Blueprint para rutas de administrador
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('user_id') or session.get('user_role') != 'Administrador':
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
            ).join(Usuario).filter(Usuario.activo == True).group_by(Rol.nombre).all()
            
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
            
            return {
                'usuarios_por_rol': dict(usuarios_stats),
                'total_usuarios': Usuario.query.filter_by(activo=True).count(),
                'total_establecimientos': total_establecimientos,
                'establecimientos_con_encargado': establecimientos_con_encargado,
                'inspecciones_mes': inspecciones_mes,
                'inspecciones_pendientes': inspecciones_pendientes,
                'usuarios_en_linea': Usuario.query.filter_by(en_linea=True).count()
            }
            
        except Exception as e:
            return {}
    
    @staticmethod
    def obtener_actividad_reciente():
        """Obtiene actividad reciente del sistema"""
        try:
            # Últimas inspecciones
            inspecciones_recientes = db.session.query(
                Inspeccion.id,
                Inspeccion.fecha,
                Inspeccion.estado,
                Establecimiento.nombre.label('establecimiento'),
                Usuario.nombre.label('inspector_nombre')
            ).join(Establecimiento).join(Usuario).order_by(
                desc(Inspeccion.fecha)
            ).limit(10).all()
            
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
        ).join(Rol).order_by(Usuario.nombre).all()
        
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
        ).join(Rol)
        
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
        
        # Obtener registros de auditoría
        auditoria_paginada = db.session.query(AuditoriaAcciones).join(Usuario).order_by(
            desc(AuditoriaAcciones.created_at)
        ).paginate(page=page, per_page=per_page, error_out=False)
        
        # Obtener lista de usuarios para el filtro
        usuarios = db.session.query(Usuario).filter_by(activo=True).all()
        
        return render_template('admin/auditoria.html',
                             auditoria=auditoria_paginada,
                             usuarios=usuarios)
    
    except Exception as e:
        flash('Error al cargar auditoría', 'error')
        return redirect(url_for('admin.dashboard'))

# =================== GESTIÓN DE ESTABLECIMIENTOS ===================

@admin_bp.route('/establecimientos')
@admin_required
def gestionar_establecimientos():
    """Vista para gestionar establecimientos"""
    try:
        return render_template('admin/establecimientos.html')
        
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
