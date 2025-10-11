from flask import Flask
from jinja2 import Undefined

# Crear filtro personalizado para manejar items de forma segura
def safe_items(obj):
    """Filtro seguro para obtener items de una categoría"""
    if obj is None:
        return []
    
    # Si es una lista, devolverla directamente
    if isinstance(obj, list):
        return obj
    
    # Si es callable (función/método), llamarla
    if callable(obj):
        try:
            result = obj()
            return result if isinstance(result, list) else []
        except Exception:
            return []
    
    # Si es iterable pero no lista, convertirla
    try:
        return list(obj)
    except Exception:
        return []

def sin_decimales(valor):
    """Filtro para mostrar números sin decimales según pedido.txt"""
    if valor is None:
        return 0
    
    try:
        # Convertir a float si es necesario
        numero = float(valor)
        # Redondear al entero más cercano
        return int(round(numero))
    except (ValueError, TypeError):
        return 0

def safe_length(obj):
    """Filtro seguro para obtener longitud"""
    try:
        if obj is None:
            return 0
        if hasattr(obj, '__len__'):
            return len(obj)
        if callable(obj):
            result = obj()
            return len(result) if hasattr(result, '__len__') else 0
        return 0
    except Exception:
        return 0

# Función para registrar los filtros
def register_filters(app):
    app.jinja_env.filters['safe_items'] = safe_items
    app.jinja_env.filters['safe_length'] = safe_length
    app.jinja_env.filters['sin_decimales'] = sin_decimales
