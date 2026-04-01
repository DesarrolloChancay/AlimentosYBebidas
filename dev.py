#!/usr/bin/env python3
"""
Script de desarrollo simplificado para ejecutar la aplicación localmente
"""
from app import create_app
from app.extensions import socketio
import os

if __name__ == "__main__":
    app = create_app()

    print("🚀 Iniciando servidor de desarrollo...")
    print("📱 Accede en: http://localhost:80")
    print("🛑 Presiona Ctrl+C para detener")

    socketio.run(app,
                 host='0.0.0.0',
                 port=5000,
                 debug=True,
                 use_reloader=True,
                 log_output=True)