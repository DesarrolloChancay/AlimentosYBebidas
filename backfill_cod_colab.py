#!/usr/bin/env python3
"""Backfill de cod_colab (RRHH) para cuentas existentes de Administrador,
Inspector y Ayudante de Inspector que tienen DNI pero aún no tienen
cod_colab asignado.

Tolera fallos por fila (RRHH caído, DNI no encontrado, etc.) sin abortar
el resto del proceso.
"""

from dotenv import load_dotenv

from app import create_app
from app.extensions import db
from app.models.Usuario_models import Usuario, Rol
from app.services.rrhh_client import lookup_colaborador_por_dni, RRHHAPIError
from app.utils.employee_code import ROLES_CON_COD_COLAB, asignar_cod_colab

load_dotenv()


def main():
    app = create_app()

    with app.app_context():
        usuarios = (
            Usuario.query
            .join(Rol)
            .filter(
                Rol.nombre.in_(ROLES_CON_COD_COLAB),
                Usuario.dni.isnot(None),
                Usuario.dni != '',
                Usuario.cod_colab.is_(None),
            )
            .all()
        )

        print(f'Usuarios a procesar: {len(usuarios)}')

        actualizados = 0
        for usuario in usuarios:
            try:
                colaborador = lookup_colaborador_por_dni(usuario.dni)
            except RRHHAPIError as exc:
                print(f'⚠️  {usuario.id} ({usuario.dni}): {exc.message}')
                continue

            if asignar_cod_colab(usuario, colaborador.get('cod_colab')):
                db.session.commit()
                actualizados += 1
                print(f'✅ Usuario {usuario.id} → cod_colab {usuario.cod_colab}')
            else:
                db.session.rollback()
                print(f'ℹ️  Usuario {usuario.id}: RRHH no devolvió código válido')

        print(f'✅ Backfill completado. Usuarios actualizados: {actualizados}')


if __name__ == '__main__':
    main()
