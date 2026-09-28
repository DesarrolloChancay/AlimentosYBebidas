"""Sincroniza usuarios Encargado / Jefe de Establecimiento hacia la BD
Postgres espejo (ver app/models/UsuarioEncargado_models.py).

Estos roles no están en RRHH, así que su identidad/autenticación vive en
Postgres con su propio cod_usuario (CC0001...), mientras la fila en
`usuarios` (MySQL) se conserva para que encargados_establecimientos,
jefes_establecimientos e inspecciones sigan funcionando sin cambios.
"""

from app.extensions import db
from app.models.UsuarioEncargado_models import UsuarioEncargado


def crear_usuario_encargado_pg(usuario_mysql, rol_nombre):
    """Crea (o vincula, si ya existía por DNI) la fila espejo en Postgres
    para `usuario_mysql` (Encargado o Jefe de Establecimiento).

    No hace commit; el llamador debe commitear junto con la fila de MySQL
    para mantener ambas bases consistentes.
    """
    usuario_pg = UsuarioEncargado.query.filter_by(dni=usuario_mysql.dni).first()

    if usuario_pg:
        usuario_pg.mysql_usuario_id = usuario_mysql.id
        usuario_pg.activo = usuario_mysql.activo
        return usuario_pg

    usuario_pg = UsuarioEncargado(
        nombre=usuario_mysql.nombre,
        apellido=usuario_mysql.apellido or '',
        contrasena=usuario_mysql.contrasena,
        correo=(usuario_mysql.correo or '').strip().lower() or None,
        dni=usuario_mysql.dni,
        telefono=usuario_mysql.telefono,
        rol=rol_nombre,
        activo=usuario_mysql.activo,
        mysql_usuario_id=usuario_mysql.id,
    )
    usuario_pg.cod_usuario = UsuarioEncargado.generar_cod_usuario_unico()

    db.session.add(usuario_pg)
    return usuario_pg
