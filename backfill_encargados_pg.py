#!/usr/bin/env python3
"""Backfill de la BD Postgres espejo (cod_usuario tipo CC0001) para
Encargado / Jefe de Establecimiento ya registrados antes de esta
funcionalidad.

Procesa TODAS las cuentas (activas e inactivas) para tener el historial
completo; las inactivas quedan con activo=False en Postgres y no pueden
iniciar sesión. Es seguro re-ejecutar: crear_usuario_encargado_pg es
idempotente (busca por DNI antes de crear).
"""

from dotenv import load_dotenv

from app import create_app
from app.extensions import db
from app.models.Usuario_models import Usuario, Rol
from app.utils.encargados_sync import crear_usuario_encargado_pg
from app.utils.roles import ROL_ENCARGADO, ROL_JEFE_ESTABLECIMIENTO

load_dotenv()

ROLES_CON_COD_USUARIO = (ROL_ENCARGADO, ROL_JEFE_ESTABLECIMIENTO)


def main():
    app = create_app()

    with app.app_context():
        usuarios = (
            Usuario.query
            .join(Rol)
            .filter(Rol.nombre.in_(ROLES_CON_COD_USUARIO))
            .all()
        )

        print(f'Usuarios a procesar: {len(usuarios)}')

        creados = 0
        ya_existian = 0
        errores = 0

        for usuario in usuarios:
            try:
                rol_nombre = usuario.rol.nombre
                usuario_pg = crear_usuario_encargado_pg(usuario, rol_nombre)
                es_nuevo = usuario_pg.id is None  # aún no flush/commit -> es una fila nueva

                db.session.commit()

                if es_nuevo:
                    creados += 1
                    print(f'✅ Usuario {usuario.id} ({usuario.dni}) → cod_usuario {usuario_pg.cod_usuario}')
                else:
                    ya_existian += 1
                    print(f'ℹ️  Usuario {usuario.id} ({usuario.dni}) ya tenía cod_usuario {usuario_pg.cod_usuario}')
            except Exception as exc:
                db.session.rollback()
                errores += 1
                print(f'⚠️  Error con usuario {usuario.id} ({usuario.dni}): {exc}')

        print(f'✅ Backfill completado. Creados: {creados}, ya existían: {ya_existian}, errores: {errores}')


if __name__ == '__main__':
    main()
