from functools import wraps
from flask import session, jsonify
from app.models.Usuario_models import Usuario

def login_required(f):
    """Decorador que requiere que el usuario esté autenticado"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'No autorizado - Login requerido'}), 401
        return f(*args, **kwargs)
    return decorated_function

def role_required(*roles):
    """Decorador que requiere roles específicos"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                return jsonify({'error': 'No autorizado - Login requerido'}), 401
            
            user_role = session.get('user_role')
            if user_role not in roles:
                return jsonify({'error': f'Acceso denegado - Se requiere rol: {", ".join(roles)}'}), 403
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def permission_required(permission_path):
    """Decorador que verifica permisos específicos basados en el JSON de permisos del rol"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                return jsonify({'error': 'No autorizado - Login requerido'}), 401
            
            try:
                # Obtener usuario actual
                usuario = Usuario.query.get(session['user_id'])
                if not usuario or not usuario.activo:
                    return jsonify({'error': 'Usuario no válido'}), 401
                
                # Verificar permisos
                permisos = usuario.rol.permisos or {}
                
                # Navegar por el path de permisos (ej: "inspecciones.crear")
                current_level = permisos
                for key in permission_path.split('.'):
                    if not isinstance(current_level, dict) or key not in current_level:
                        return jsonify({'error': f'Permiso denegado: {permission_path}'}), 403
                    current_level = current_level[key]
                
                # El valor final debe ser True
                if current_level is not True:
                    return jsonify({'error': f'Permiso denegado: {permission_path}'}), 403
                
                return f(*args, **kwargs)
                
            except Exception as e:
                return jsonify({'error': f'Error verificando permisos: {str(e)}'}), 500
                
        return decorated_function
    return decorator

def establecimientos_asignados_only(f):
    """Decorador que permite solo acceder a establecimientos asignados (para inspectores)"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return jsonify({'error': 'No autorizado'}), 401
        
        user_role = session.get('user_role')
        
        # Admin puede ver todo
        if user_role == 'Administrador':
            return f(*args, **kwargs)
        
        # Inspector solo puede ver establecimientos asignados
        if user_role == 'Inspector':
            # El establecimiento_id puede venir de args, kwargs o request
            establecimiento_id = kwargs.get('establecimiento_id')
            if not establecimiento_id:
                return jsonify({'error': 'ID de establecimiento requerido'}), 400
            
            # Verificar si el inspector está asignado a este establecimiento
            from app.models.Inspecciones_models import InspectorEstablecimiento
            from datetime import date
            
            asignacion = InspectorEstablecimiento.query.filter_by(
                inspector_id=session['user_id'],
                establecimiento_id=establecimiento_id,
                activo=True
            ).filter(
                InspectorEstablecimiento.fecha_asignacion <= date.today()
            ).filter(
                (InspectorEstablecimiento.fecha_fin_asignacion.is_(None)) | 
                (InspectorEstablecimiento.fecha_fin_asignacion >= date.today())
            ).first()
            
            if not asignacion:
                return jsonify({'error': 'No tienes acceso a este establecimiento'}), 403
        
        # Encargado solo puede ver su establecimiento
        elif user_role == 'Encargado':
            establecimiento_id = kwargs.get('establecimiento_id')
            if not establecimiento_id:
                return jsonify({'error': 'ID de establecimiento requerido'}), 400
            
            # Verificar si es encargado de este establecimiento
            from app.models.Inspecciones_models import EncargadoEstablecimiento
            from datetime import date
            
            encargo = EncargadoEstablecimiento.query.filter_by(
                usuario_id=session['user_id'],
                establecimiento_id=establecimiento_id,
                activo=True
            ).filter(
                EncargadoEstablecimiento.fecha_inicio <= date.today()
            ).filter(
                (EncargadoEstablecimiento.fecha_fin.is_(None)) | 
                (EncargadoEstablecimiento.fecha_fin >= date.today())
            ).first()
            
            if not encargo:
                return jsonify({'error': 'No eres encargado de este establecimiento'}), 403
        
        return f(*args, **kwargs)
    return decorated_function
