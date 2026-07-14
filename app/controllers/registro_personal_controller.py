from datetime import date, datetime

from flask import Blueprint, jsonify, render_template, request, session

from app.extensions import db
from app.models.Inspecciones_models import Establecimiento
from app.models.RegistroPersonal_models import (
    RegistroPersonalDetalle,
    RegistroPersonalDiario,
    RolPersonalMinimo,
)
from app.utils.auth_decorators import login_required, role_required

registro_personal_bp = Blueprint(
    "registro_personal", __name__, url_prefix="/registro-personal"
)

ROLES_PERSONAL = [
    "Encargado", "Caja", "Jalador", "Mozos", "Cocina",
    "Cantante", "Barra", "Lavaplatos", "Dueño", "Preventa",
]
DIAS_SEMANA = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]


@registro_personal_bp.route("/nuevo")
@login_required
def nuevo():
    """Pantalla única de registro/consulta diario de personal."""
    establecimientos = Establecimiento.query.filter_by(activo=True).order_by(Establecimiento.nombre).all()
    establecimiento_id = request.args.get("establecimiento_id", "")
    fecha = request.args.get("fecha", "")

    datos_guardados = {}
    roles_libres = []
    minimos_dia = {}
    es_fecha_pasada = False
    if establecimiento_id and fecha:
        registro = RegistroPersonalDiario.query.filter_by(
            establecimiento_id=establecimiento_id, fecha=fecha
        ).first()
        if registro:
            for detalle in registro.detalles:
                if detalle.es_rol_libre:
                    roles_libres.append({"rol_nombre": detalle.rol_nombre, "nombres": detalle.nombres or ""})
                else:
                    datos_guardados[detalle.rol_nombre] = detalle.nombres or ""

        try:
            fecha_parseada = datetime.strptime(fecha, "%Y-%m-%d").date()
            es_fecha_pasada = fecha_parseada < date.today()
            dia_semana = fecha_parseada.weekday()
            filas_minimo = RolPersonalMinimo.query.filter_by(
                establecimiento_id=establecimiento_id, dia_semana=dia_semana
            ).all()
            if not filas_minimo:
                filas_minimo = RolPersonalMinimo.query.filter_by(
                    establecimiento_id=None, dia_semana=dia_semana
                ).all()
            for fila in filas_minimo:
                minimos_dia[fila.rol_nombre] = {
                    "cantidad_minima": fila.cantidad_minima,
                    "opcional": fila.opcional,
                }
        except ValueError:
            pass

    return render_template(
        "registro_personal/nuevo.html",
        establecimientos=establecimientos,
        establecimiento_id_preseleccionado=establecimiento_id,
        fecha_preseleccionada=fecha,
        datos_guardados=datos_guardados,
        roles_libres=roles_libres,
        minimos_dia=minimos_dia,
        es_fecha_pasada=es_fecha_pasada,
    )


@registro_personal_bp.route("/guardar", methods=["POST"])
@login_required
def guardar():
    """Guarda (o actualiza) el registro de personal de un establecimiento/fecha."""
    data = request.get_json(silent=True) or {}
    establecimiento_id = data.get("establecimiento_id")
    fecha = data.get("fecha")
    roles = data.get("roles", [])

    if not establecimiento_id or not fecha:
        return jsonify({"success": False, "error": "Falta establecimiento o fecha"}), 400

    try:
        fecha_parseada = datetime.strptime(fecha, "%Y-%m-%d").date()
    except ValueError:
        return jsonify({"success": False, "error": "Fecha inválida"}), 400

    if fecha_parseada < date.today():
        return jsonify({"success": False, "error": "No se pueden editar registros de fechas anteriores"}), 403

    registro = RegistroPersonalDiario.query.filter_by(
        establecimiento_id=establecimiento_id, fecha=fecha_parseada
    ).first()
    if not registro:
        registro = RegistroPersonalDiario(
            establecimiento_id=establecimiento_id, fecha=fecha_parseada
        )
        db.session.add(registro)
        db.session.flush()

    registro.registrado_por = session.get("user_id")

    RegistroPersonalDetalle.query.filter_by(registro_id=registro.id).delete()

    for orden, rol in enumerate(roles):
        rol_nombre = (rol.get("rol_nombre") or "").strip()
        nombres = (rol.get("nombres") or "").strip()
        if not rol_nombre or not nombres:
            continue
        db.session.add(
            RegistroPersonalDetalle(
                registro_id=registro.id,
                rol_nombre=rol_nombre,
                nombres=nombres,
                es_rol_libre=bool(rol.get("es_rol_libre")),
                orden=orden,
            )
        )

    db.session.commit()
    return jsonify({"success": True, "registro_id": registro.id})


@registro_personal_bp.route("/historial")
@login_required
def historial():
    """Lista de solo lectura de los registros de personal guardados."""
    establecimientos = Establecimiento.query.filter_by(activo=True).order_by(Establecimiento.nombre).all()

    establecimiento_id = request.args.get("establecimiento_id", "")
    desde = request.args.get("desde", "")
    hasta = request.args.get("hasta", "")

    query = RegistroPersonalDiario.query
    if establecimiento_id:
        query = query.filter_by(establecimiento_id=establecimiento_id)
    if desde:
        query = query.filter(RegistroPersonalDiario.fecha >= desde)
    if hasta:
        query = query.filter(RegistroPersonalDiario.fecha <= hasta)

    registros = query.order_by(RegistroPersonalDiario.fecha.desc()).limit(100).all()

    return render_template(
        "registro_personal/historial.html",
        establecimientos=establecimientos,
        registros=registros,
        filtro_establecimiento_id=establecimiento_id,
        filtro_desde=desde,
        filtro_hasta=hasta,
    )


@registro_personal_bp.route("/configuracion")
@role_required("Administrador")
def configuracion():
    """Configuración del mínimo requerido de personal por rol y día de semana, por establecimiento."""
    establecimientos = Establecimiento.query.filter_by(activo=True).order_by(Establecimiento.nombre).all()
    establecimiento_id = request.args.get("establecimiento_id", "")

    minimos = {}
    if establecimiento_id:
        filas = RolPersonalMinimo.query.filter_by(establecimiento_id=establecimiento_id).all()
        if not filas:
            filas = RolPersonalMinimo.query.filter_by(establecimiento_id=None).all()
        for fila in filas:
            minimos[(fila.rol_nombre, fila.dia_semana)] = {
                "cantidad_minima": fila.cantidad_minima,
                "opcional": fila.opcional,
            }

    return render_template(
        "registro_personal/configuracion.html",
        establecimientos=establecimientos,
        establecimiento_id_preseleccionado=establecimiento_id,
        roles=ROLES_PERSONAL,
        dias=DIAS_SEMANA,
        minimos=minimos,
    )


@registro_personal_bp.route("/configuracion/guardar", methods=["POST"])
@role_required("Administrador")
def guardar_configuracion():
    """Guarda (upsert completo) el mínimo requerido de personal de un establecimiento."""
    data = request.get_json(silent=True) or {}
    establecimiento_id = data.get("establecimiento_id")
    filas = data.get("filas", [])

    if not establecimiento_id:
        return jsonify({"success": False, "error": "Falta establecimiento"}), 400

    RolPersonalMinimo.query.filter_by(establecimiento_id=establecimiento_id).delete()

    for fila in filas:
        rol_nombre = (fila.get("rol_nombre") or "").strip()
        dia_semana = fila.get("dia_semana")
        if not rol_nombre or dia_semana is None:
            continue
        db.session.add(
            RolPersonalMinimo(
                establecimiento_id=establecimiento_id,
                rol_nombre=rol_nombre,
                dia_semana=dia_semana,
                cantidad_minima=fila.get("cantidad_minima") or 0,
                opcional=bool(fila.get("opcional")),
            )
        )

    db.session.commit()
    return jsonify({"success": True})
