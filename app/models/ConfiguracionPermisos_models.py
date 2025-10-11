"""
✅ MODELOS DE PERMISOS Y AUDITORÍA
Extensión de modelos para gestión de permisos granulares (sin duplicar configuraciones)
"""

from app.extensions import db
from datetime import datetime
import json

# Importar el modelo de configuración existente
from app.models.Inspecciones_models import ConfiguracionEvaluacion


class PermisoRol(db.Model):
    """Modelo para permisos granulares por rol"""
    __tablename__ = 'permisos_roles'
    
    id = db.Column(db.Integer, primary_key=True)
    rol_id = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=False)
    recurso = db.Column(db.String(100), nullable=False)  # usuarios, establecimientos, inspecciones, etc.
    accion = db.Column(db.String(50), nullable=False)    # crear, editar, eliminar, ver, etc.
    condicion = db.Column(db.JSON, nullable=True)        # Condiciones adicionales
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    
    # Índice único para evitar duplicados
    __table_args__ = (db.UniqueConstraint('rol_id', 'recurso', 'accion', name='uq_rol_recurso_accion'),)


class PermisoUsuario(db.Model):
    """Modelo para permisos específicos por usuario (sobrescribe permisos de rol)"""
    __tablename__ = 'permisos_usuarios'
    
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    recurso = db.Column(db.String(100), nullable=False)
    accion = db.Column(db.String(50), nullable=False)
    permitido = db.Column(db.Boolean, nullable=False)  # True permite, False deniega
    condicion = db.Column(db.JSON, nullable=True)
    razon = db.Column(db.String(255))  # Razón para el permiso/denegación específica
    otorgado_por = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=True)
    fecha_vencimiento = db.Column(db.TIMESTAMP, nullable=True)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    
    # Índice único para evitar duplicados
    __table_args__ = (db.UniqueConstraint('usuario_id', 'recurso', 'accion', name='uq_usuario_recurso_accion'),)


class AuditoriaAcciones(db.Model):
    """Modelo para auditoría de acciones administrativas"""
    __tablename__ = 'auditoria_acciones'
    
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    accion = db.Column(db.String(100), nullable=False)
    recurso = db.Column(db.String(100), nullable=False)
    recurso_id = db.Column(db.Integer, nullable=True)
    detalles = db.Column(db.JSON, nullable=True)
    ip_origen = db.Column(db.String(45))
    user_agent = db.Column(db.String(500))
    exitoso = db.Column(db.Boolean, default=True)
    mensaje_error = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)


class ConfiguracionSistema(db.Model):
    """Configuraciones generales del sistema"""
    __tablename__ = 'configuracion_sistema'
    
    id = db.Column(db.Integer, primary_key=True)
    modulo = db.Column(db.String(100), nullable=False)
    configuracion = db.Column(db.JSON, nullable=False)
    version = db.Column(db.String(20), default='1.0')
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=True)


def inicializar_configuraciones_basicas():
    """Función para inicializar configuraciones básicas del sistema usando tabla existente"""
    configuraciones_basicas = [
        {
            'clave': 'meta_semanal_default',
            'valor': '3',
            'descripcion': 'Meta de inspecciones por semana por defecto',
            'modificable_por_inspector': True
        },
        {
            'clave': 'dias_recordatorio',
            'valor': '1,3,5',
            'descripcion': 'Días de la semana para recordatorios (1=Lunes, 7=Domingo)',
            'modificable_por_inspector': False
        },
        {
            'clave': 'hora_recordatorio',
            'valor': '09:00',
            'descripcion': 'Hora para envío de recordatorios',
            'modificable_por_inspector': False
        },
        {
            'clave': 'zona_horaria',
            'valor': 'America/Lima',
            'descripcion': 'Zona horaria del sistema',
            'modificable_por_inspector': False
        },
        {
            'clave': 'notificaciones_email',
            'valor': 'true',
            'descripcion': 'Activar notificaciones por email',
            'modificable_por_inspector': False
        },
        {
            'clave': 'tiempo_sesion',
            'valor': '240',
            'descripcion': 'Tiempo de sesión en minutos',
            'modificable_por_inspector': False
        },
        {
            'clave': 'intentos_login',
            'valor': '5',
            'descripcion': 'Número máximo de intentos de login',
            'modificable_por_inspector': False
        }
    ]
    
    try:
        for config_data in configuraciones_basicas:
            # Solo crear si no existe
            existing = ConfiguracionEvaluacion.query.filter_by(clave=config_data['clave']).first()
            if not existing:
                config = ConfiguracionEvaluacion(**config_data)
                db.session.add(config)
        
        db.session.commit()
        
    except Exception as e:
        db.session.rollback()


def inicializar_permisos_basicos():
    """Función para inicializar permisos básicos por rol"""
    permisos_inspector = [
        # Inspecciones
        {'recurso': 'inspecciones', 'accion': 'crear'},
        {'recurso': 'inspecciones', 'accion': 'editar', 'condicion': {'propias': True}},
        {'recurso': 'inspecciones', 'accion': 'ver'},
        # Configuración limitada
        {'recurso': 'configuracion', 'accion': 'editar', 'condicion': {'solo_meta_semanal': True}},
        {'recurso': 'configuracion', 'accion': 'ver'},
        # Establecimientos
        {'recurso': 'establecimientos', 'accion': 'ver'},
    ]
    
    permisos_encargado = [
        # Inspecciones propias
        {'recurso': 'inspecciones', 'accion': 'ver', 'condicion': {'propias': True}},
        {'recurso': 'inspecciones', 'accion': 'firmar', 'condicion': {'propias': True}},
        # Establecimiento propio
        {'recurso': 'establecimientos', 'accion': 'ver', 'condicion': {'propios': True}},
    ]
    
    permisos_admin = [
        # Control total
        {'recurso': '*', 'accion': '*'},
    ]
    
    permisos_jefe = [
        # Gestión de establecimiento
        {'recurso': 'establecimientos', 'accion': 'ver', 'condicion': {'propios': True}},
        {'recurso': 'establecimientos', 'accion': 'editar', 'condicion': {'propios': True}},
        {'recurso': 'encargados', 'accion': 'gestionar', 'condicion': {'establecimiento_propio': True}},
        {'recurso': 'inspecciones', 'accion': 'ver', 'condicion': {'establecimiento_propio': True}},
        {'recurso': 'firmas', 'accion': 'cargar'},
    ]
    
    try:
        from app.models.Usuario_models import Rol
        
        # Mapear roles con sus permisos
        roles_permisos = {
            'Inspector': permisos_inspector,
            'Encargado': permisos_encargado,
            'Administrador': permisos_admin,
            'Jefe de Establecimiento': permisos_jefe
        }
        
        for nombre_rol, permisos in roles_permisos.items():
            rol = Rol.query.filter_by(nombre=nombre_rol).first()
            if rol:
                for permiso_data in permisos:
                    # Solo crear si no existe
                    existing = PermisoRol.query.filter_by(
                        rol_id=rol.id,
                        recurso=permiso_data['recurso'],
                        accion=permiso_data['accion']
                    ).first()
                    
                    if not existing:
                        permiso = PermisoRol(
                            rol_id=rol.id,
                            recurso=permiso_data['recurso'],
                            accion=permiso_data['accion'],
                            condicion=permiso_data.get('condicion')
                        )
                        db.session.add(permiso)
        
        db.session.commit()
        
    except Exception as e:
        db.session.rollback()


class PermisosHelper:
    """Helper class para verificación de permisos"""
    
    @staticmethod
    def usuario_puede(usuario_id, recurso, accion, contexto=None):
        """
        Verifica si un usuario puede realizar una acción sobre un recurso
        
        Args:
            usuario_id: ID del usuario
            recurso: Nombre del recurso (usuarios, inspecciones, etc.)
            accion: Acción a realizar (crear, editar, eliminar, ver)
            contexto: Contexto adicional para validaciones específicas
        
        Returns:
            bool: True si tiene permisos, False en caso contrario
        """
        try:
            from app.models.Usuario_models import Usuario
            
            usuario = Usuario.query.get(usuario_id)
            if not usuario or not usuario.activo:
                return False
            
            # Administrador tiene acceso total
            if usuario.rol.nombre == 'Administrador':
                return True
            
            # Verificar permisos específicos del usuario primero
            permiso_usuario = PermisoUsuario.query.filter_by(
                usuario_id=usuario_id,
                recurso=recurso,
                accion=accion,
                activo=True
            ).first()
            
            if permiso_usuario:
                # Verificar si no ha vencido
                if permiso_usuario.fecha_vencimiento and permiso_usuario.fecha_vencimiento < datetime.utcnow():
                    return False
                return permiso_usuario.permitido
            
            # Verificar permisos del rol
            permiso_rol = PermisoRol.query.filter_by(
                rol_id=usuario.rol_id,
                recurso=recurso,
                accion=accion,
                activo=True
            ).first()
            
            if permiso_rol:
                # Verificar condiciones específicas si existen
                if permiso_rol.condicion and contexto:
                    return PermisosHelper._verificar_condiciones(permiso_rol.condicion, contexto, usuario)
                return True
            
            # Verificar permisos comodín
            permiso_comodin = PermisoRol.query.filter_by(
                rol_id=usuario.rol_id,
                recurso='*',
                accion='*',
                activo=True
            ).first()
            
            return permiso_comodin is not None
            
        except Exception as e:
            return False
    
    @staticmethod
    def _verificar_condiciones(condicion, contexto, usuario):
        """Verifica condiciones específicas del permiso"""
        try:
            # Condición: solo propias (inspecciones, establecimientos, etc.)
            if condicion.get('propias') and contexto.get('objeto_usuario_id'):
                return contexto['objeto_usuario_id'] == usuario.id
            
            # Condición: solo establecimiento propio
            if condicion.get('establecimiento_propio') and contexto.get('establecimiento_id'):
                from app.models.Inspecciones_models import EncargadoEstablecimiento
                encargado = EncargadoEstablecimiento.query.filter_by(
                    usuario_id=usuario.id,
                    establecimiento_id=contexto['establecimiento_id'],
                    activo=True
                ).first()
                return encargado is not None
            
            # Condición: solo meta semanal para inspectores
            if condicion.get('solo_meta_semanal') and contexto.get('configuracion_clave'):
                return contexto['configuracion_clave'] == 'meta_semanal_default'
            
            return True
            
        except Exception as e:
            return False
    
    @staticmethod
    def registrar_accion(usuario_id, accion, recurso, recurso_id=None, detalles=None, 
                        exitoso=True, error=None, ip=None, user_agent=None):
        """Registra una acción en la auditoría"""
        try:
            auditoria = AuditoriaAcciones(
                usuario_id=usuario_id,
                accion=accion,
                recurso=recurso,
                recurso_id=recurso_id,
                detalles=detalles,
                ip_origen=ip,
                user_agent=user_agent,
                exitoso=exitoso,
                mensaje_error=error
            )
            db.session.add(auditoria)
            db.session.commit()
            
        except Exception as e:
            db.session.rollback()
