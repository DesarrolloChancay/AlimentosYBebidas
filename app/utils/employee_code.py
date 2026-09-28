"""Normalización y asignación del código de colaborador RRHH (cod_colab).

Solo Administrador, Inspector y Ayudante de Inspector llevan código de
colaborador en RRHH; los demás roles no deben recibir cod_colab.
"""

import re

from app.models.Usuario_models import Usuario
from app.utils.roles import (
    ROL_ADMINISTRADOR,
    ROL_AYUDANTE_INSPECTOR,
    ROL_INSPECTOR,
)

ROLES_CON_COD_COLAB = (ROL_ADMINISTRADOR, ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR)


def normalizar_cod_colab(raw):
    if not raw:
        return None
    valor = re.sub(r'\s+', '', str(raw)).strip().upper()
    return valor or None


def cod_colab_en_conflicto(cod_colab, excluir_usuario_id=None):
    query = Usuario.query.filter(Usuario.cod_colab == cod_colab)
    if excluir_usuario_id is not None:
        query = query.filter(Usuario.id != excluir_usuario_id)
    return query.first() is not None


def asignar_cod_colab(usuario, raw):
    """Asigna cod_colab a `usuario` si su rol lo permite y no hay conflicto.

    Devuelve True si se asignó/actualizó el valor, False en caso contrario.
    No hace commit; el llamador es responsable de persistir.
    """
    if not usuario.rol or usuario.rol.nombre not in ROLES_CON_COD_COLAB:
        return False

    codigo = normalizar_cod_colab(raw)
    if not codigo or codigo == usuario.cod_colab:
        return False

    if cod_colab_en_conflicto(codigo, excluir_usuario_id=usuario.id):
        return False

    usuario.cod_colab = codigo
    return True
