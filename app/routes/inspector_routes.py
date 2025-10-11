"""
Rutas para funcionalidades del Inspector
"""
from flask import Blueprint
from app.controllers.inspector_controller import InspectorController
from app.utils.auth_decorators import login_required, role_required

inspector_bp = Blueprint('inspector', __name__, url_prefix='/inspector')


# Vista de perfil del inspector para gestionar su firma
@inspector_bp.route('/perfil', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def perfil():
    """
    Mostrar página de perfil del inspector
    
    Permite al inspector ver y actualizar su firma digital
    """
    return InspectorController.ver_perfil()


# Guardar/actualizar firma del inspector
@inspector_bp.route('/guardar-firma', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def guardar_firma():
    """
    Guardar o actualizar la firma del inspector
    
    Request:
        - firma (file): Imagen de la firma
    
    Returns:
        JSON con resultado de la operación
    """
    return InspectorController.guardar_firma()


# Obtener firma actual del inspector
@inspector_bp.route('/obtener-firma', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def obtener_firma():
    """
    Obtener la firma actual del inspector
    
    Returns:
        JSON con los datos de la firma
    """
    return InspectorController.obtener_firma()


# =================== GESTIÓN DE JEFES DE ESTABLECIMIENTO ===================

@inspector_bp.route('/jefes-establecimiento')
@login_required
@role_required('Inspector', 'Administrador')
def gestionar_jefes_establecimiento():
    """
    Vista para gestionar jefes de establecimiento
    
    Returns:
        Template con lista de jefes
    """
    return InspectorController.gestionar_jefes_establecimiento()


@inspector_bp.route('/jefes-establecimiento/crear', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def crear_jefe_establecimiento():
    """
    Vista para crear un nuevo jefe de establecimiento
    
    Returns:
        Template con formulario de creación
    """
    return InspectorController.crear_jefe_establecimiento()


@inspector_bp.route('/api/jefes-establecimiento', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def api_crear_jefe_establecimiento():
    """
    API para crear un jefe de establecimiento
    
    Returns:
        JSON con resultado de la operación
    """
    return InspectorController.api_crear_jefe_establecimiento()


@inspector_bp.route('/api/establecimientos-disponibles', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def api_establecimientos_disponibles():
    """
    API para obtener establecimientos disponibles para asignar jefe
    
    Returns:
        JSON con lista de establecimientos sin jefe asignado
    """
    return InspectorController.obtener_establecimientos_disponibles()


@inspector_bp.route('/api/jefes-establecimiento/<int:jefe_id>/restablecer-contrasena', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def api_restablecer_contrasena_jefe(jefe_id):
    """
    API para restablecer la contraseña de un jefe de establecimiento
    
    Args:
        jefe_id: ID del jefe de establecimiento
    
    Returns:
        JSON con resultado de la operación
    """
    return InspectorController.restablecer_contrasena_jefe(jefe_id)
