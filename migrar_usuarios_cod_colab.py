#!/usr/bin/env python3
"""Agrega la columna cod_colab (código de colaborador RRHH) a usuarios."""

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

from app.config import Config

load_dotenv()


def obtener_engine():
    return create_engine(make_url(Config.SQLALCHEMY_DATABASE_URI), future=True)


def columna_existe(inspector, tabla, columna):
    return any(col['name'] == columna for col in inspector.get_columns(tabla))


def indice_existe(conn, indice):
    fila = conn.execute(
        text('SHOW INDEX FROM usuarios WHERE Key_name = :indice'),
        {'indice': indice},
    ).first()
    return fila is not None


def main():
    engine = obtener_engine()
    url = engine.url

    if not url.drivername.startswith('mysql'):
        raise RuntimeError(
            f'Esta migración está preparada para MySQL. Base detectada: {url.drivername}'
        )

    inspector = inspect(engine)

    with engine.begin() as conn:
        if not columna_existe(inspector, 'usuarios', 'cod_colab'):
            conn.execute(text('ALTER TABLE usuarios ADD COLUMN cod_colab VARCHAR(20) NULL AFTER dni'))
            print('✅ Columna cod_colab agregada')
            inspector = inspect(engine)
        else:
            print('ℹ️ La columna cod_colab ya existe')

        if not indice_existe(conn, 'uq_usuarios_cod_colab'):
            conn.execute(text('CREATE UNIQUE INDEX uq_usuarios_cod_colab ON usuarios (cod_colab)'))
            print('✅ Índice único creado para cod_colab')
        else:
            print('ℹ️ El índice uq_usuarios_cod_colab ya existe')

    print('✅ Migración completada correctamente')


if __name__ == '__main__':
    main()
