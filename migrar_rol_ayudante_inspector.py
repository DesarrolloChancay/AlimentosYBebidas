#!/usr/bin/env python3
"""Crea el rol Ayudante de Inspector y sus permisos base."""

from dotenv import load_dotenv

from app import create_app
from app.extensions import db
from app.models.ConfiguracionPermisos_models import PermisoRol
from app.models.Usuario_models import Rol
from app.utils.roles import (
    ROL_AYUDANTE_INSPECTOR,
    ROL_INSPECTOR,
)

load_dotenv()


PERMISOS_AYUDANTE_INSPECTOR = [
    {"recurso": "inspecciones", "accion": "crear"},
    {"recurso": "inspecciones", "accion": "editar", "condicion": {"propias": True}},
    {"recurso": "inspecciones", "accion": "ver"},
    {"recurso": "firmas", "accion": "cargar"},
    {"recurso": "establecimientos", "accion": "ver"},
]


def obtener_permisos_referencia():
    rol_inspector = Rol.query.filter_by(nombre=ROL_INSPECTOR).first()
    if not rol_inspector:
        return {}

    permisos = {}
    for permiso in PermisoRol.query.filter_by(rol_id=rol_inspector.id, activo=True).all():
        permisos.setdefault(permiso.recurso, {})
        permisos[permiso.recurso][permiso.accion] = True
    return permisos


def main():
    app = create_app()

    with app.app_context():
        rol = Rol.query.filter_by(nombre=ROL_AYUDANTE_INSPECTOR).first()
        if not rol:
            rol = Rol(
                nombre=ROL_AYUDANTE_INSPECTOR,
                descripcion="Puede realizar inspecciones y gestionar su firma, sin acceso a dashboard ni configuraciones.",
                permisos=obtener_permisos_referencia(),
            )
            db.session.add(rol)
            db.session.flush()
            print("✅ Rol Ayudante de Inspector creado")
        else:
            print("ℹ️ El rol Ayudante de Inspector ya existe")

        for permiso_data in PERMISOS_AYUDANTE_INSPECTOR:
            existente = PermisoRol.query.filter_by(
                rol_id=rol.id,
                recurso=permiso_data["recurso"],
                accion=permiso_data["accion"],
            ).first()
            if existente:
                continue

            db.session.add(
                PermisoRol(
                    rol_id=rol.id,
                    recurso=permiso_data["recurso"],
                    accion=permiso_data["accion"],
                    condicion=permiso_data.get("condicion"),
                )
            )
            print(
                f"✅ Permiso agregado: {permiso_data['recurso']} / {permiso_data['accion']}"
            )

        db.session.commit()
        print("✅ Migración del rol Ayudante de Inspector completada")


if __name__ == "__main__":
    main()
