from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from app.config import Config
from app.extensions import db, socketio
from app.routes.inspeccion_routes import inspeccion_bp
from app.controllers.auth_controller import AuthController

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Inicializar extensiones
    db.init_app(app)
    socketio.init_app(app, cors_allowed_origins="*")

    # Importar eventos de socket después de inicializar
    from app import socket_events

    # Registrar blueprints
    app.register_blueprint(inspeccion_bp)

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
        if session.get('user_role') != 'Admin':
            return jsonify({'error': 'Sin permisos'}), 403
        return AuthController.listar_sesiones_activas()

    @app.route('/api/auth/forzar-cierre/<int:user_id>', methods=['POST'])
    def forzar_cierre_sesion(user_id):
        # Solo admin puede forzar cierre de sesiones
        if session.get('user_role') != 'Admin':
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

    return app