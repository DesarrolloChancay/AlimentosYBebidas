"""Rutas autenticadas para archivos privados."""

from flask import Blueprint, abort, send_file, session
from sqlalchemy import or_

from app.models.Inspecciones_models import FirmaEncargadoPorJefe, Inspeccion
from app.models.Usuario_models import Usuario
from app.utils.auth_decorators import login_required
from app.utils.media import resolve_signature_file_path, signature_reference_candidates
from app.utils.roles import (
    ROL_ADMINISTRADOR,
    ROL_AYUDANTE_INSPECTOR,
    ROL_INSPECTOR,
)


media_bp = Blueprint("media", __name__, url_prefix="/media")


def _es_rol_operativo():
    return session.get("user_role") in {
        ROL_ADMINISTRADOR,
        ROL_INSPECTOR,
        ROL_AYUDANTE_INSPECTOR,
    }


def _usuario_tiene_acceso_establecimiento(establecimiento_id):
    from app.controllers.inspecciones_controller import InspeccionesController

    return InspeccionesController._usuario_tiene_acceso_establecimiento(
        session.get("user_id"),
        session.get("user_role"),
        establecimiento_id,
    )


def _puede_servir_firma(candidates):
    user_id = session.get("user_id")
    if not user_id or not candidates:
        return False

    usuario_firma = Usuario.query.filter(Usuario.ruta_firma.in_(candidates)).first()
    if usuario_firma:
        if usuario_firma.id == user_id or _es_rol_operativo():
            return True

    inspeccion = Inspeccion.query.filter(
        or_(
            Inspeccion.firma_inspector.in_(candidates),
            Inspeccion.firma_encargado.in_(candidates),
        )
    ).first()
    if inspeccion:
        if _es_rol_operativo():
            return True
        return _usuario_tiene_acceso_establecimiento(inspeccion.establecimiento_id)

    firma_encargado = FirmaEncargadoPorJefe.query.filter(
        FirmaEncargadoPorJefe.path_firma.in_(candidates),
        FirmaEncargadoPorJefe.activa == True,
    ).first()
    if firma_encargado:
        if _es_rol_operativo():
            return True
        if user_id in {firma_encargado.jefe_id, firma_encargado.encargado_id}:
            return True
        return _usuario_tiene_acceso_establecimiento(firma_encargado.establecimiento_id)

    return False


@media_bp.route("/firmas/<path:filename>")
@login_required
def servir_firma(filename):
    candidates = signature_reference_candidates(filename)
    if not _puede_servir_firma(candidates):
        abort(403)

    absolute_path = resolve_signature_file_path(filename)
    if not absolute_path:
        abort(404)

    return send_file(absolute_path, conditional=True)
