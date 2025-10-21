import os

# Aplicar monkey-patch de gevent ANTES de cualquier otra importación
if os.getenv('FLASK_ENV') == 'production':
    import gevent.monkey
    gevent.monkey.patch_all()

from app import create_app
from app.extensions import socketio

app = create_app()

# Variable de entorno para determinar el entorno
FLASK_ENV = os.getenv('FLASK_ENV', 'development')

if __name__ == "__main__":
    try:
        if FLASK_ENV == 'production':
            # En producción, usar gunicorn con gevent
            print("🚀 Iniciando servidor en modo producción...")
            # Esta parte será manejada por gunicorn + gevent en Render
            # Solo mantener compatibilidad con desarrollo local
            socketio.run(app,
                         host='0.0.0.0',
                         port=int(os.getenv('PORT', 80)),
                         debug=False,
                         use_reloader=False)
        else:
            # Modo desarrollo
            print("🚀 Iniciando servidor en modo desarrollo...")
            socketio.run(app,
                         host='0.0.0.0',
                         port=80,
                         debug=True,
                         use_reloader=True,
                         log_output=True)
    except Exception as e:
        print(f"❌ Error al iniciar el servidor: {e}")
        # Fallback a Flask normal si Socket.IO falla
        print("🔄 Intentando iniciar con Flask normal...")
        app.run(host='0.0.0.0',
                port=int(os.getenv('PORT', 80)),
                debug=FLASK_ENV != 'production',
                use_reloader=FLASK_ENV != 'production',
                threaded=True)