#!/usr/bin/env python3
"""
Script de verificación de configuración
Ejecutar antes del despliegue para asegurar que todo esté configurado correctamente
"""
import os
import sys
from dotenv import load_dotenv

def check_env_vars():
    """Verificar variables de entorno requeridas"""
    print("🔍 Verificando variables de entorno...")

    required_vars = ['SECRET_KEY', 'DB_USER', 'DB_PASSWORD', 'DB_HOST', 'DB_NAME']
    missing_vars = []

    for var in required_vars:
        if not os.getenv(var):
            missing_vars.append(var)

    if missing_vars:
        print(f"❌ Variables de entorno faltantes: {', '.join(missing_vars)}")
        return False

    print("✅ Variables de entorno configuradas")
    return True

def check_database_connection():
    """Verificar conexión a base de datos"""
    print("🔍 Verificando conexión a base de datos...")

    try:
        import pymysql
        from pymysql import Error

        connection = pymysql.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME'),
            port=int(os.getenv('DB_PORT', 3306))
        )

        if connection.open:
            connection.close()
            print("✅ Conexión a base de datos exitosa")
            return True

    except ImportError:
        print("❌ pymysql no instalado")
        return False
    except Error as e:
        print(f"❌ Error de conexión a base de datos: {e}")
        return False

def check_dependencies():
    """Verificar dependencias instaladas"""
    print("🔍 Verificando dependencias...")

    required_packages = [
        'flask', 'flask_sqlalchemy', 'flask_socketio',
        'pymysql', 'bcrypt', 'python_dotenv'
    ]

    missing_packages = []

    for package in required_packages:
        try:
            __import__(package.replace('_', '-'))
        except ImportError:
            missing_packages.append(package)

    if missing_packages:
        print(f"❌ Paquetes faltantes: {', '.join(missing_packages)}")
        print("   Ejecutar: pip install -r requirements.txt")
        return False

    print("✅ Dependencias instaladas")
    return True

def check_app_initialization():
    """Verificar que la aplicación se puede inicializar"""
    print("🔍 Verificando inicialización de aplicación...")

    try:
        from app import create_app
        app = create_app()
        print("✅ Aplicación inicializada correctamente")
        return True
    except Exception as e:
        print(f"❌ Error al inicializar aplicación: {e}")
        return False

def main():
    """Función principal"""
    print("🚀 Verificación de configuración del Sistema de Alimentos y Bebidas")
    print("=" * 60)

    # Cargar variables de entorno
    if os.path.exists('.env'):
        load_dotenv()
        print("📄 Archivo .env cargado")
    else:
        print("⚠️  Archivo .env no encontrado")

    # Verificaciones
    checks = [
        check_env_vars,
        check_dependencies,
        check_app_initialization,
        check_database_connection
    ]

    results = []
    for check in checks:
        results.append(check())
        print()

    # Resultado final
    print("=" * 60)
    if all(results):
        print("🎉 ¡Todas las verificaciones pasaron exitosamente!")
        print("✅ El proyecto está listo para ejecutarse")
        return 0
    else:
        print("❌ Algunas verificaciones fallaron")
        print("🔧 Revisa los errores arriba y corrige antes de continuar")
        return 1

if __name__ == "__main__":
    sys.exit(main())