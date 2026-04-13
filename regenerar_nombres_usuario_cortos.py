#!/usr/bin/env python3
"""Regenera los nombres de usuario existentes usando la regla corta actual."""

import secrets
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from app.config import Config
from app.utils.auth_utils import generar_base_nombre_usuario



def obtener_engine():
    url = make_url(Config.SQLALCHEMY_DATABASE_URI)
    if not url.drivername.startswith('mysql'):
        raise RuntimeError(
            f'Este script está preparado para MySQL. Base detectada: {url.drivername}'
        )
    return create_engine(url, future=True)



def generar_nombre_usuario(conn, usuario_id, nombre, apellido):
    base = generar_base_nombre_usuario(nombre, apellido)
    for _ in range(500):
        candidato = f"{base}.{secrets.randbelow(1000):03d}"
        existe = conn.execute(
            text(
                'SELECT 1 FROM usuarios WHERE nombre_usuario = :nombre_usuario AND id <> :usuario_id LIMIT 1'
            ),
            {'nombre_usuario': candidato, 'usuario_id': usuario_id},
        ).first()
        if not existe:
            return candidato
    raise RuntimeError(
        f'No se pudo generar un nombre de usuario único para el usuario {usuario_id}'
    )



def main():
    engine = obtener_engine()

    with engine.begin() as conn:
        usuarios = conn.execute(
            text('SELECT id, nombre, apellido, nombre_usuario FROM usuarios ORDER BY id')
        ).mappings().all()

        if not usuarios:
            print('ℹ️ No hay usuarios para procesar')
            return

        for usuario in usuarios:
            nuevo_nombre_usuario = generar_nombre_usuario(
                conn,
                usuario['id'],
                usuario['nombre'],
                usuario['apellido'],
            )

            conn.execute(
                text('UPDATE usuarios SET nombre_usuario = :nombre_usuario WHERE id = :id'),
                {'nombre_usuario': nuevo_nombre_usuario, 'id': usuario['id']},
            )

            print(
                f"✅ Usuario {usuario['id']}: {usuario['nombre_usuario']} -> {nuevo_nombre_usuario}"
            )

    print('✅ Regeneración completada correctamente')


if __name__ == '__main__':
    main()
