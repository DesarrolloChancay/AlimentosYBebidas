"""
Rutas para funcionalidades de plantillas de checklists
"""
from flask import Blueprint
from app.controllers.plantillas_controller import PlantillasController
from app.utils.auth_decorators import login_required, role_required

plantillas_bp = Blueprint('plantillas', __name__, url_prefix='/plantillas')


# Listar plantillas disponibles
@plantillas_bp.route('/', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def listar_plantillas():
    """
    Mostrar lista de plantillas disponibles para inspectores

    Returns:
        Template con lista de plantillas
    """
    return PlantillasController.listar_plantillas()


# Ver detalles de una plantilla
@plantillas_bp.route('/<int:plantilla_id>', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def ver_plantilla(plantilla_id):
    """
    Ver detalles de una plantilla específica

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        Template con detalles de la plantilla
    """
    return PlantillasController.ver_plantilla(plantilla_id)


# Crear establecimiento desde plantilla
@plantillas_bp.route('/<int:plantilla_id>/crear-establecimiento', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def crear_establecimiento_desde_plantilla(plantilla_id):
    """
    Mostrar formulario para crear establecimiento desde plantilla

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        Template con formulario de creación
    """
    return PlantillasController.crear_establecimiento_desde_plantilla(plantilla_id)


# API para guardar establecimiento desde plantilla
@plantillas_bp.route('/guardar-establecimiento', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def guardar_establecimiento_desde_plantilla():
    """
    Crear establecimiento y checklist desde plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.guardar_establecimiento_desde_plantilla()


# Paso final de creación de establecimiento con items personalizados
@plantillas_bp.route('/<int:plantilla_id>/crear-establecimiento/finalizar', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def finalizar_creacion_establecimiento(plantilla_id):
    """
    Mostrar formulario final para crear establecimiento con items personalizados

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        Template con formulario final
    """
    return PlantillasController.finalizar_creacion_establecimiento(plantilla_id)


# API para guardar establecimiento con items personalizados
@plantillas_bp.route('/guardar-establecimiento-personalizado', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def guardar_establecimiento_con_items_personalizados():
    """
    Crear establecimiento con selección personalizada de items

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.guardar_establecimiento_con_items_personalizados()


# API para obtener plantillas en JSON
@plantillas_bp.route('/api/listar', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def obtener_plantillas_json():
    """
    Obtener plantillas en formato JSON

    Returns:
        JSON con lista de plantillas
    """
    return PlantillasController.obtener_plantillas_json()


# API para crear plantilla
@plantillas_bp.route('/api/crear', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def crear_plantilla():
    """
    Crear nueva plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.crear_plantilla()


# API para eliminar plantilla
@plantillas_bp.route('/api/<int:plantilla_id>', methods=['DELETE'])
@login_required
@role_required('Inspector', 'Administrador')
def eliminar_plantilla(plantilla_id):
    """
    Eliminar plantilla

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.eliminar_plantilla(plantilla_id)


# API para obtener plantilla específica
@plantillas_bp.route('/api/<int:plantilla_id>', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def obtener_plantilla(plantilla_id):
    """
    Obtener plantilla específica en formato JSON

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        JSON con datos de la plantilla
    """
    return PlantillasController.obtener_plantilla(plantilla_id)


# Editar plantilla
@plantillas_bp.route('/<int:plantilla_id>/editar', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def editar_plantilla(plantilla_id):
    """
    Mostrar formulario para editar plantilla

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        Template con formulario de edición
    """
    return PlantillasController.editar_plantilla(plantilla_id)


# Guardar edición de plantilla
@plantillas_bp.route('/guardar-edicion', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def guardar_edicion_plantilla():
    """
    Guardar cambios en plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.guardar_edicion_plantilla()


# API para gestionar items de plantilla
@plantillas_bp.route('/api/<int:plantilla_id>/items', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def obtener_items_plantilla(plantilla_id):
    """
    Obtener items de una plantilla específica

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        JSON con lista de items
    """
    return PlantillasController.obtener_items_plantilla(plantilla_id)


# API para buscar items base disponibles
@plantillas_bp.route('/api/items-base', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def buscar_items_base():
    """
    Buscar items base disponibles para agregar a plantillas

    Query Parameters:
        - query: Texto de búsqueda
        - exclude: Lista de IDs de items a excluir (separados por coma)

    Returns:
        JSON con lista de items base
    """
    return PlantillasController.buscar_items_base()


# API para obtener categorías
@plantillas_bp.route('/api/categorias', methods=['GET'])
@login_required
@role_required('Inspector', 'Administrador')
def obtener_categorias():
    """
    Obtener lista de categorías activas

    Returns:
        JSON con lista de categorías
    """
    return PlantillasController.obtener_categorias()


# API para agregar item a plantilla
@plantillas_bp.route('/api/<int:plantilla_id>/items', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def agregar_item_plantilla(plantilla_id):
    """
    Agregar nuevo item a plantilla

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.agregar_item_plantilla(plantilla_id)


# API para editar item de plantilla
@plantillas_bp.route('/api/items/<int:item_id>', methods=['PUT'])
@login_required
@role_required('Inspector', 'Administrador')
def editar_item_plantilla(item_id):
    """
    Editar item específico de plantilla

    Args:
        item_id: ID del item de plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.editar_item_plantilla(item_id)


# API para eliminar item de plantilla
@plantillas_bp.route('/api/items/<int:item_id>', methods=['DELETE'])
@login_required
@role_required('Inspector', 'Administrador')
def eliminar_item_plantilla(item_id):
    """
    Eliminar item de plantilla

    Args:
        item_id: ID del item de plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.eliminar_item_plantilla(item_id)


# API para reordenar items de plantilla
@plantillas_bp.route('/api/<int:plantilla_id>/items/reordenar', methods=['POST'])
@login_required
@role_required('Inspector', 'Administrador')
def reordenar_items_plantilla(plantilla_id):
    """
    Reordenar items de plantilla

    Args:
        plantilla_id: ID de la plantilla

    Returns:
        JSON con resultado de la operación
    """
    return PlantillasController.reordenar_items_plantilla(plantilla_id)