from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from app.config import Config
from app.extensions import db, socketio
from app.routes.inspeccion_routes import inspeccion_bp
from app.routes.jefe_routes import jefe_routes
from app.routes.inspector_routes import inspector_bp
from app.routes.plantillas_routes import plantillas_bp
from app.controllers.usuarios_controller import usuarios_bp
from app.controllers.auth_controller import AuthController
from app.controllers.admin_controller import admin_bp

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Inicializar extensiones
    db.init_app(app)
    socketio.init_app(app,
                      cors_allowed_origins="*",
                      logger=app.config['FLASK_ENV'] == 'development',
                      engineio_logger=app.config['FLASK_ENV'] == 'development',
                      async_mode=app.config.get('SOCKETIO_ASYNC_MODE', 'threading'))

    # Importar eventos de socket después de inicializar
    try:
        from app import socket_events
        print("✅ Eventos de Socket.IO cargados correctamente")
    except Exception as e:
        print(f"❌ Error al cargar eventos de Socket.IO: {e}")

    # Registrar blueprints
    app.register_blueprint(inspeccion_bp)
    app.register_blueprint(jefe_routes)
    app.register_blueprint(inspector_bp)
    app.register_blueprint(plantillas_bp)
    app.register_blueprint(usuarios_bp)
    app.register_blueprint(admin_bp)
    
    # Registrar filtros personalizados
    from app.template_filters import register_filters
    register_filters(app)

    @app.route('/login', methods=['GET'])
    def login_page():
        return render_template('login.html')

    @app.route('/api/auth/login', methods=['POST'])
    def login():
        data = request.get_json()
        return AuthController.login(data.get('email'), data.get('password'))

    @app.route('/api/auth/login-forzado', methods=['POST'])
    def login_forzado():
        data = request.get_json()
        return AuthController.login_forzado(data.get('email'), data.get('password'))

    @app.route('/api/auth/logout', methods=['POST'])
    def logout():
        return AuthController.logout()

    @app.route('/api/auth/verificar-sesion-unica', methods=['POST'])
    def verificar_sesion_unica():
        return AuthController.verificar_sesion_unica()

    @app.route('/api/auth/verificar-timeout', methods=['POST'])
    def verificar_timeout():
        return AuthController.verificar_timeout_sesion()

    @app.route('/api/auth/sesiones-activas', methods=['GET'])
    def sesiones_activas():
        # Solo admin puede ver sesiones activas
        if session.get('user_role') != 'Administrador':
            return jsonify({'error': 'Sin permisos'}), 403
        return AuthController.listar_sesiones_activas()

    @app.route('/api/auth/forzar-cierre/<int:user_id>', methods=['POST'])
    def forzar_cierre_sesion(user_id):
        # Solo admin puede forzar cierre de sesiones
        if session.get('user_role') != 'Administrador':
            return jsonify({'error': 'Sin permisos'}), 403
        return AuthController.forzar_cierre_sesion(user_id)

    @app.route('/api/auth/check', methods=['GET'])
    def check_auth():
        if 'user_id' in session:
            return jsonify({
                'authenticated': True,
                'user': {
                    'id': session['user_id'],
                    'name': session.get('user_name'),
                    'role': session.get('user_role')
                }
            })
        return jsonify({'authenticated': False}), 401

    @app.before_request
    def verificar_cambio_contrasena_obligatorio():
        """Middleware que verifica si el usuario debe cambiar contraseña obligatoriamente"""
        from flask import session, request, redirect, url_for

        # Solo aplicar restricciones si hay una sesión activa
        if not session.get('user_id'):
            return  # No hay sesión, permitir la solicitud

        # Rutas permitidas durante cambio obligatorio
        rutas_permitidas = [
            '/cambiar-contrasena',  # Página de cambio
            '/usuarios/api/cambiar-contrasena',  # API de cambio
            '/api/auth/login',  # Login
            '/api/auth/login-forzado',  # Login forzado
            '/api/auth/logout',  # Logout
            '/api/auth/verificar-cambio-contrasena',  # Verificación
            '/static',  # Archivos estáticos
            '/login',  # Página de login
        ]

        # Verificar si la ruta actual está permitida
        ruta_actual = request.path
        ruta_permitida = any(ruta_actual.startswith(permitida) for permitida in rutas_permitidas)

        # Si la ruta no está permitida y el usuario tiene cambio obligatorio
        if not ruta_permitida and session.get('cambiar_contrasena_obligatorio'):
            # Redirigir a cambio de contraseña
            return redirect(url_for('cambiar_contrasena_page'))

    @app.route('/cambiar-contrasena', methods=['GET'])
    def cambiar_contrasena_page():
        return render_template('cambiar_contrasena.html')

    @app.route('/api/auth/verificar-cambio-contrasena', methods=['GET'])
    def verificar_cambio_contrasena():
        from app.controllers.usuarios_controller import verificar_cambio_contrasena
        return verificar_cambio_contrasena()

    @app.errorhandler(404)
    def page_not_found(e):
        """Manejador de error 404 - Página no encontrada"""
        return render_template('404.html'), 404

    @app.errorhandler(403)
    def forbidden(e):
        """Manejador de error 403 - Acceso denegado"""
        return render_template('403.html'), 403

    @app.errorhandler(500)
    def internal_server_error(e):
        """Manejador de error 500 - Error interno del servidor"""
        return render_template('500.html'), 500

    return app