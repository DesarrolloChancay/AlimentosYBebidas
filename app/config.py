
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env (solo en desarrollo)
if os.getenv('FLASK_ENV') != 'production':
    load_dotenv()


def _get_bool_env(name, default=False):
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {'1', 'true', 'yes', 'on'}


def _get_int_env(name, default):
    value = os.getenv(name)
    if value is None or not value.strip():
        return default
    try:
        return int(value)
    except ValueError:
        return default


def _get_csv_env(name):
    value = os.getenv(name, '').strip()
    if not value:
        return None
    if value == '*':
        return '*'

    items = [item.strip() for item in value.split(',') if item.strip()]
    if not items:
        return None
    if len(items) == 1:
        return items[0]
    return items

class Config:
    # Entorno de ejecución
    FLASK_ENV = os.getenv('FLASK_ENV', 'development')
    DEBUG = FLASK_ENV == 'development'

    # Clave secreta
    SECRET_KEY = os.getenv('SECRET_KEY', 'clave-desarrollo-temporal')

    # Base de datos
    # En Render, las variables de entorno se pasan directamente
    DB_USER = os.getenv('DB_USER')
    DB_PASSWORD = os.getenv('DB_PASSWORD')
    DB_HOST = os.getenv('DB_HOST')
    DB_PORT = os.getenv('DB_PORT', '3306')
    DB_NAME = os.getenv('DB_NAME')

    # Construir URI de base de datos
    if all([DB_USER, DB_PASSWORD, DB_HOST, DB_NAME]):
        SQLALCHEMY_DATABASE_URI = (
            f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}"
            f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        )
    else:
        # Fallback para desarrollo local
        SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///dev.db')

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Proxy reverso / HTTPS
    TRUST_PROXY_COUNT = _get_int_env('TRUST_PROXY_COUNT', 1 if FLASK_ENV == 'production' else 0)
    PREFERRED_URL_SCHEME = os.getenv(
        'PREFERRED_URL_SCHEME',
        'https' if FLASK_ENV == 'production' else 'http'
    )

    # Cookies y sesión
    SESSION_COOKIE_SECURE = _get_bool_env(
        'SESSION_COOKIE_SECURE',
        FLASK_ENV == 'production'
    )
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = os.getenv('SESSION_COOKIE_SAMESITE', 'Lax')
    REMEMBER_COOKIE_SECURE = SESSION_COOKIE_SECURE
    REMEMBER_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_SAMESITE = SESSION_COOKIE_SAMESITE

    # Tamaño máximo de carga
    MAX_CONTENT_LENGTH = _get_int_env('MAX_CONTENT_LENGTH_MB', 25) * 1024 * 1024

    # Configuración de Socket.IO
    # En producción (Render) usar threading para evitar problemas de compatibilidad
    if FLASK_ENV == 'production':
        SOCKETIO_ASYNC_MODE = 'threading'  # Más compatible con Render
    else:
        SOCKETIO_ASYNC_MODE = 'threading'
    SOCKETIO_CORS_ALLOWED_ORIGINS = _get_csv_env('SOCKETIO_CORS_ALLOWED_ORIGINS')
    SOCKETIO_MESSAGE_QUEUE = os.getenv('SOCKETIO_MESSAGE_QUEUE')

    # Configuración específica para producción
    if FLASK_ENV == 'production':
        # Configuración para compatibilidad con threading
        SQLALCHEMY_ENGINE_OPTIONS = {
            'pool_pre_ping': True,
            'pool_recycle': 300,
            'pool_size': 5,
            'max_overflow': 10,
        }
    else:
        # Configuración estándar para desarrollo
        SQLALCHEMY_ENGINE_OPTIONS = {
            'pool_pre_ping': True,
            'pool_recycle': 300,
        }

    # Configuración adicional para producción
    if FLASK_ENV == 'production':
        # Deshabilitar reloader en producción
        USE_RELOADER = False
        # Configuración de logging
        LOG_LEVEL = 'INFO'
    else:
        USE_RELOADER = True
        LOG_LEVEL = 'DEBUG'
