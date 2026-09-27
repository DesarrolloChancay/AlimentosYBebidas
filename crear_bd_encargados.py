#!/usr/bin/env python3
"""Crea el esquema de la BD Postgres de usuarios Encargado / Jefe de Establecimiento.

Requiere que la base de datos indicada en ENCARGADOS_DB_* ya exista
(este script solo crea las tablas dentro de ella). Seguro de re-ejecutar.
"""

from dotenv import load_dotenv

from app import create_app
from app.extensions import db
from app.models.UsuarioEncargado_models import UsuarioEncargado  # noqa: F401

load_dotenv()


def main():
    app = create_app()
    with app.app_context():
        db.create_all(bind_key='encargados')
        print('✅ Esquema de la BD de Encargados/Jefes creado (o ya existente)')


if __name__ == '__main__':
    main()
