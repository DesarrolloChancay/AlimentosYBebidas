
import os
from dotenv import load_dotenv

# Cargar variables de entorno desde .env (solo en desarrollo)
if os.getenv('FLASK_ENV') != 'production':
    load_dotenv()

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

    # Configuración de Socket.IO
    # En producción (Render) usar eventlet, en desarrollo usar threading
    if FLASK_ENV == 'production':
        SOCKETIO_ASYNC_MODE = 'eventlet'
    else:
        SOCKETIO_ASYNC_MODE = 'threading'

    # Configuración adicional para producción
    if FLASK_ENV == 'production':
        # Deshabilitar reloader en producción
        USE_RELOADER = False
        # Configuración de logging
        LOG_LEVEL = 'INFO'
    else:
        USE_RELOADER = True
        LOG_LEVEL = 'DEBUG'
