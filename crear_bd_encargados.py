#!/usr/bin/env python3
"""Crea la BD Postgres (ENCARGADOS_DB_NAME, ej. "ayb_encargados") si no
existe, y su esquema de tablas para los usuarios Encargado / Jefe de
Establecimiento.

Usa las variables ENCARGADOS_DB_USER/PASSWORD/HOST/PORT/NAME del .env.
El usuario de esas credenciales debe tener permiso para crear bases de
datos en el servidor Postgres (rol CREATEDB o superusuario).

Seguro de re-ejecutar: no recrea la base ni las tablas si ya existen.
"""

import os

import psycopg2
from psycopg2 import sql
from dotenv import load_dotenv

load_dotenv()


def crear_base_de_datos():
    """Crea la base de datos ENCARGADOS_DB_NAME si aún no existe.

    Se conecta a la BD de mantenimiento "postgres" del mismo servidor con
    autocommit (CREATE DATABASE no puede ejecutarse dentro de una
    transacción) para poder crear la base indicada.
    """
    db_name = os.getenv('ENCARGADOS_DB_NAME')
    db_user = os.getenv('ENCARGADOS_DB_USER')
    db_password = os.getenv('ENCARGADOS_DB_PASSWORD')
    db_host = os.getenv('ENCARGADOS_DB_HOST')
    db_port = os.getenv('ENCARGADOS_DB_PORT', '5432')

    if not all([db_name, db_user, db_password, db_host]):
        raise RuntimeError(
            'Faltan variables ENCARGADOS_DB_USER/ENCARGADOS_DB_PASSWORD/'
            'ENCARGADOS_DB_HOST/ENCARGADOS_DB_NAME en el .env'
        )

    conexion = psycopg2.connect(
        dbname='postgres',
        user=db_user,
        password=db_password,
        host=db_host,
        port=db_port,
    )
    conexion.autocommit = True

    try:
        with conexion.cursor() as cursor:
            cursor.execute('SELECT 1 FROM pg_database WHERE datname = %s', (db_name,))
            if cursor.fetchone():
                print(f'ℹ️  La base de datos "{db_name}" ya existe')
            else:
                cursor.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(db_name)))
                print(f'✅ Base de datos "{db_name}" creada')
    finally:
        conexion.close()


def crear_tablas():
    """Crea las tablas del bind 'encargados' (modelo UsuarioEncargado) dentro
    de la base de datos ya existente, usando la app Flask/SQLAlchemy."""
    from app import create_app
    from app.extensions import db
    from app.models.UsuarioEncargado_models import UsuarioEncargado  # noqa: F401

    app = create_app()
    with app.app_context():
        db.create_all(bind_key='encargados')
        print('✅ Esquema de la BD de Encargados/Jefes creado (o ya existente)')


def main():
    crear_base_de_datos()
    crear_tablas()


if __name__ == '__main__':
    main()
