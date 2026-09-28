#!/usr/bin/env python3
"""Deja el correo de usuarios como opcional (NULL permitido)."""

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

from app.config import Config

load_dotenv()


def obtener_engine():
    return create_engine(make_url(Config.SQLALCHEMY_DATABASE_URI), future=True)


def main():
    engine = obtener_engine()
    if not engine.url.drivername.startswith('mysql'):
        raise RuntimeError(
            f'Esta migración está preparada para MySQL. Base detectada: {engine.url.drivername}'
        )

    inspector = inspect(engine)
    columnas = {col['name']: col for col in inspector.get_columns('usuarios')}
    if 'correo' not in columnas:
        raise RuntimeError('La columna usuarios.correo no existe')

    with engine.begin() as conn:
        conn.execute(text("UPDATE usuarios SET correo = NULL WHERE correo = ''"))
        if columnas['correo']['nullable']:
            print('La columna correo ya admite NULL')
        else:
            conn.execute(text('ALTER TABLE usuarios MODIFY correo VARCHAR(150) NULL'))
            print('Columna correo ahora es opcional (NULL)')

        col = conn.execute(text(
            "SELECT IS_NULLABLE, COLUMN_TYPE FROM information_schema.COLUMNS "
            "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'usuarios' AND COLUMN_NAME = 'correo'"
        )).mappings().one()
        print(f"correo: type={col['COLUMN_TYPE']} nullable={col['IS_NULLABLE']}")

    print('Migracion completada correctamente')


if __name__ == '__main__':
    main()
