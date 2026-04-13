#!/usr/bin/env python3
"""Migra la tabla usuarios para usar nombre de usuario único y permitir correos repetidos."""

import re
import secrets
import unicodedata
from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL, make_url

from app.config import Config

load_dotenv()


def obtener_engine():
    uri = Config.SQLALCHEMY_DATABASE_URI
    url = make_url(uri)
    return create_engine(url, future=True)


def limpiar_fragmento(texto):
    texto = unicodedata.normalize('NFKD', (texto or '').strip().lower())
    texto = ''.join(char for char in texto if not unicodedata.combining(char))
    texto = re.sub(r'[^a-z0-9]+', '.', texto)
    texto = re.sub(r'\.+', '.', texto).strip('.')
    return texto


def obtener_fragmento_corto(texto, longitud=4):
    tokens = [
        limpiar_fragmento(token)
        for token in re.split(r'\s+', (texto or '').strip())
        if token.strip()
    ]
    tokens = [token for token in tokens if token]
    if not tokens:
        return ''

    for token in tokens:
        if len(token) > 2:
            return token[:longitud]

    return tokens[0][:longitud]



def generar_base(nombre, apellido):
    partes = [obtener_fragmento_corto(nombre), obtener_fragmento_corto(apellido)]
    base = '.'.join(parte for parte in partes if parte)
    return base or 'usuario'


def generar_nombre_usuario(conn, nombre, apellido):
    base = generar_base(nombre, apellido)
    for _ in range(500):
        candidato = f"{base}.{secrets.randbelow(1000):03d}"
        existe = conn.execute(
            text('SELECT 1 FROM usuarios WHERE nombre_usuario = :nombre_usuario LIMIT 1'),
            {'nombre_usuario': candidato},
        ).first()
        if not existe:
            return candidato
    raise RuntimeError(f'No se pudo generar un nombre de usuario único para {nombre} {apellido}')


def columna_existe(inspector, tabla, columna):
    return any(col['name'] == columna for col in inspector.get_columns(tabla))


def indices_unicos_correo(conn):
    filas = conn.execute(text("SHOW INDEX FROM usuarios WHERE Column_name = 'correo'"))
    indices = set()
    for fila in filas.mappings():
        if fila['Non_unique'] == 0 and fila['Key_name'] != 'PRIMARY':
            indices.add(fila['Key_name'])
    return sorted(indices)


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
        if not columna_existe(inspector, 'usuarios', 'nombre_usuario'):
            conn.execute(text('ALTER TABLE usuarios ADD COLUMN nombre_usuario VARCHAR(160) NULL AFTER apellido'))
            print('✅ Columna nombre_usuario agregada')
            inspector = inspect(engine)
        else:
            print('ℹ️ La columna nombre_usuario ya existe')

        for indice in indices_unicos_correo(conn):
            conn.execute(text(f'ALTER TABLE usuarios DROP INDEX `{indice}`'))
            print(f'✅ Índice único eliminado de correo: {indice}')

        usuarios = conn.execute(
            text("SELECT id, nombre, apellido FROM usuarios WHERE nombre_usuario IS NULL OR nombre_usuario = ''")
        ).mappings().all()

        for usuario in usuarios:
            nombre_usuario = generar_nombre_usuario(conn, usuario['nombre'], usuario['apellido'])
            conn.execute(
                text('UPDATE usuarios SET nombre_usuario = :nombre_usuario WHERE id = :id'),
                {'nombre_usuario': nombre_usuario, 'id': usuario['id']},
            )
            print(f"✅ Usuario {usuario['id']} migrado a {nombre_usuario}")

        conn.execute(text('ALTER TABLE usuarios MODIFY nombre_usuario VARCHAR(160) NOT NULL'))

        if not indice_existe(conn, 'uq_usuarios_nombre_usuario'):
            conn.execute(text('CREATE UNIQUE INDEX uq_usuarios_nombre_usuario ON usuarios (nombre_usuario)'))
            print('✅ Índice único creado para nombre_usuario')
        else:
            print('ℹ️ El índice uq_usuarios_nombre_usuario ya existe')

    print('✅ Migración completada correctamente')


if __name__ == '__main__':
    main()
