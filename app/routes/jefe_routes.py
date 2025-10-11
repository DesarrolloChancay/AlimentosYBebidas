from flask import Blueprint
from app.controllers.jefe_controller import jefe_bp

# Registrar el blueprint del jefe
jefe_routes = jefe_bp

# Las rutas están definidas en el controlador:
# /jefe/dashboard - Dashboard principal del jefe
# /jefe/gestionar-encargado - POST para habilitar/deshabilitar encargados
# /jefe/guardar-firma - POST para guardar firmas digitales
# /jefe/reporte-establecimiento - Generar reporte del establecimiento
