"""
Descripción: Controlador para gestionar el Reglamento de Restaurante
Lógica: Maneja reuniones semanales, catálogo configurable de items y cierre de evaluaciones
"""

from datetime import datetime, timedelta
import re

from flask import Blueprint, current_app, render_template, request, jsonify, session
from sqlalchemy import and_, or_

from app.extensions import db
from app.models.Inspecciones_models import (
    ItemReglamento,
    ReglamentoRestaurante,
    EvaluacionReglamento,
    Establecimiento,
    Inspeccion,
    ReunionItemReglamento,
)
from app.utils.auth_decorators import login_required

reglamento_bp = Blueprint("reglamento", __name__, url_prefix="/reglamento")
ROLES_GESTION_REGLAMENTO = {"Inspector", "Administrador"}
RIESGOS_REGLAMENTO = {"Menor", "Mayor", "Crítico"}
TIPOS_VALIDACION_REGLAMENTO = {"si_no", "numerico", "porcentaje"}
TIPOS_VIGENCIA_REGLAMENTO = {"temporal", "permanente"}
ALCANCES_ITEM_REGLAMENTO = {"global", "establecimiento", "reunion"}
OPERADORES_VALIDOS = {"<", "<=", ">", ">=", "="}
CATEGORIAS_REGLAMENTO = [
    "Checklist (3 veces por semana)",
    "Satisfacción al cliente - Encuestas",
    "Incumplimientos Laborales",
    "Otros incumplimientos",
    "Incumplimiento en pagos",
]
CATEGORIAS_REGLAMENTO_MAP = {
    categoria.lower(): categoria for categoria in CATEGORIAS_REGLAMENTO
}
CATEGORIAS_REGLAMENTO_MAP.update({
    "checklist": CATEGORIAS_REGLAMENTO[0],
    "satisfacción": CATEGORIAS_REGLAMENTO[1],
    "satisfaccion": CATEGORIAS_REGLAMENTO[1],
    "satisfacción al cliente": CATEGORIAS_REGLAMENTO[1],
    "satisfaccion al cliente": CATEGORIAS_REGLAMENTO[1],
    "incumplimientos laborales": CATEGORIAS_REGLAMENTO[2],
    "otros incumplimientos": CATEGORIAS_REGLAMENTO[3],
    "incumplimiento en pagos": CATEGORIAS_REGLAMENTO[4],
    "incumplimientos en pagos": CATEGORIAS_REGLAMENTO[4],
})


def _obtener_contexto_usuario():
    return session.get("user_id"), session.get("user_role")


def _usuario_puede_gestionar_reglamento():
    _, user_role = _obtener_contexto_usuario()
    return user_role in ROLES_GESTION_REGLAMENTO


def _normalizar_booleano(valor):
    if isinstance(valor, bool):
        return valor
    if valor is None:
        return False
    return str(valor).strip().lower() in {"1", "true", "si", "sí", "yes", "on"}


def _normalizar_riesgo(valor):
    mapa = {
        "menor": "Menor",
        "mayor": "Mayor",
        "critico": "Crítico",
        "crítico": "Crítico",
    }
    return mapa.get((valor or "").strip().lower())


def _parsear_fecha_iso(valor):
    if valor in (None, ""):
        return None
    if isinstance(valor, datetime):
        return valor.date()
    if hasattr(valor, "year") and hasattr(valor, "month") and hasattr(valor, "day"):
        return valor
    try:
        return datetime.strptime(str(valor).strip(), "%Y-%m-%d").date()
    except (TypeError, ValueError):
        return None


def _formatear_fecha(valor):
    fecha = _parsear_fecha_iso(valor)
    return fecha.strftime("%d/%m/%Y") if fecha else None


def _normalizar_categoria_reglamento(valor, permitir_desconocida=False):
    categoria = " ".join((valor or "").strip().split())
    if not categoria:
        return None
    normalizada = CATEGORIAS_REGLAMENTO_MAP.get(categoria.lower())
    if normalizada:
        return normalizada
    return categoria if permitir_desconocida else None


def _obtener_establecimientos_gestionables():
    user_id, user_role = _obtener_contexto_usuario()

    if not _usuario_puede_gestionar_reglamento():
        return []

    from app.controllers.inspecciones_controller import InspeccionesController

    establecimiento_ids = InspeccionesController._obtener_establecimientos_autorizados(
        user_id, user_role
    )
    if not establecimiento_ids:
        return []

    return (
        Establecimiento.query.filter(
            Establecimiento.id.in_(establecimiento_ids),
            Establecimiento.activo == True,
        )
        .order_by(Establecimiento.nombre.asc())
        .all()
    )


def _resolver_establecimiento_autorizado(establecimiento_id):
    user_id, user_role = _obtener_contexto_usuario()

    if not _usuario_puede_gestionar_reglamento():
        return None, ("Acceso denegado al módulo de reglamento.", 403)

    from app.controllers.inspecciones_controller import InspeccionesController

    if not InspeccionesController._usuario_tiene_acceso_establecimiento(
        user_id, user_role, establecimiento_id
    ):
        return None, ("Sin acceso a este establecimiento.", 403)

    establecimiento = Establecimiento.query.filter_by(
        id=establecimiento_id, activo=True
    ).first()
    if not establecimiento:
        return None, ("Establecimiento no encontrado o inactivo.", 404)

    return establecimiento, None


def _resolver_reunion_autorizada(reunion_id):
    reunion = ReglamentoRestaurante.query.get(reunion_id)
    if not reunion:
        return None, ("Reunión no encontrada.", 404)

    _, error = _resolver_establecimiento_autorizado(reunion.establecimiento_id)
    if error:
        return None, error

    return reunion, None


def _evaluar_condicion(valor, operador, umbral):
    if operador == "<":
        return valor < umbral
    if operador == "<=":
        return valor <= umbral
    if operador == ">":
        return valor > umbral
    if operador == ">=":
        return valor >= umbral
    if operador == "=":
        return valor == umbral
    return False


def _item_logica_inversa(item):
    codigo = (getattr(item, "codigo", "") or "").strip().upper()
    if codigo == "A-19":
        return True
    return bool(getattr(item, "logica_inversa", False))


def _calcular_resumen_reunion_desde_evaluaciones(evaluaciones):
    total_infracciones = 0
    total_puntos = 0

    for evaluacion in evaluaciones:
        if evaluacion.cumple:
            continue

        numero_infracciones = evaluacion.numero_infracciones or 0
        if numero_infracciones <= 0:
            numero_infracciones = 1

        puntaje = evaluacion.puntaje_aplicado
        if puntaje is None and evaluacion.reunion_item:
            puntaje = evaluacion.reunion_item.puntaje or 0
        if puntaje is None:
            puntaje = (evaluacion.item.puntaje or 0) if evaluacion.item else 0

        total_infracciones += numero_infracciones
        total_puntos += puntaje * numero_infracciones

    sancion = calcular_sancion_por_platos(total_puntos)
    return {
        "total_infracciones": total_infracciones,
        "total_puntos": total_puntos,
        "sancion": sancion,
    }


def _construir_resumen_reunion(reunion):
    if reunion.estado == "completada" and reunion.total_puntos is not None:
        sancion = calcular_sancion_por_platos(reunion.total_puntos or 0)
        return {
            "reunion": reunion,
            "total_infracciones": reunion.total_infracciones or 0,
            "total_puntos": reunion.total_puntos or 0,
            "total_platos_sancion": reunion.total_platos_sancion or 0,
            "sancion_descripcion": sancion.get("descripcion", "Sin sanción"),
        }

    resumen = _calcular_resumen_reunion_desde_evaluaciones(reunion.evaluaciones or [])
    return {
        "reunion": reunion,
        "total_infracciones": resumen["total_infracciones"],
        "total_puntos": resumen["total_puntos"],
        "total_platos_sancion": resumen["sancion"].get("platos", 0),
        "sancion_descripcion": resumen["sancion"].get("descripcion", "Sin sanción"),
    }


def _obtener_siguiente_orden_item():
    return (db.session.query(db.func.max(ItemReglamento.orden)).scalar() or 0) + 1


def _obtener_siguiente_codigo_item():
    maximo = 0
    patron = re.compile(r"^A-(\d+)$", re.IGNORECASE)
    for (codigo,) in db.session.query(ItemReglamento.codigo).all():
        match = patron.match((codigo or "").strip())
        if match:
            maximo = max(maximo, int(match.group(1)))
    return f"A-{maximo + 1:02d}"


def _consulta_items_catalogo_aplicables(
    establecimiento_id,
    fecha_referencia=None,
    incluir_inactivos=False,
):
    if fecha_referencia is None:
        fecha_referencia = datetime.utcnow().date()

    query = ItemReglamento.query.filter(
        or_(
            ItemReglamento.alcance.is_(None),
            ItemReglamento.alcance == "global",
            and_(
                ItemReglamento.alcance == "establecimiento",
                ItemReglamento.establecimiento_id == establecimiento_id,
            ),
        )
    )

    if not incluir_inactivos:
        query = query.filter(ItemReglamento.activo == True)

    query = query.filter(
        or_(
            ItemReglamento.tipo_vigencia.is_(None),
            ItemReglamento.tipo_vigencia != "temporal",
            and_(
                ItemReglamento.tipo_vigencia == "temporal",
                ItemReglamento.fecha_fin_vigencia.isnot(None),
                ItemReglamento.fecha_fin_vigencia >= fecha_referencia,
            ),
        )
    )

    return query.order_by(
        ItemReglamento.categoria.asc(),
        ItemReglamento.orden.asc(),
        ItemReglamento.codigo.asc(),
    )

def _consulta_items_catalogo_gestionables(establecimiento_id):
    return (
        ItemReglamento.query.filter(
            or_(ItemReglamento.alcance.is_(None), ItemReglamento.alcance != "reunion"),
            or_(
                ItemReglamento.alcance.is_(None),
                ItemReglamento.alcance == "global",
                and_(
                    ItemReglamento.alcance == "establecimiento",
                    ItemReglamento.establecimiento_id == establecimiento_id,
                ),
            ),
        )
        .order_by(
            ItemReglamento.categoria.asc(),
            ItemReglamento.orden.asc(),
            ItemReglamento.codigo.asc(),
        )
    )


def _consulta_items_catalogo_reutilizables_reunion(reunion):
    item_ids_actuales = {
        item.item_id
        for item in reunion.items_configurados or []
        if getattr(item, "item_id", None) is not None
    }

    query = _consulta_items_catalogo_gestionables(reunion.establecimiento_id).filter(
        ItemReglamento.activo == True
    )

    if item_ids_actuales:
        query = query.filter(~ItemReglamento.id.in_(item_ids_actuales))

    return query


def _serializar_item_catalogo(item):
    alcance = (item.alcance or "global").strip().lower()
    if alcance not in ALCANCES_ITEM_REGLAMENTO:
        alcance = "establecimiento" if item.establecimiento_id else "global"

    tipo_vigencia = (item.tipo_vigencia or "permanente").strip().lower()
    if tipo_vigencia not in TIPOS_VIGENCIA_REGLAMENTO:
        tipo_vigencia = "permanente"

    fecha_fin_vigencia = _parsear_fecha_iso(getattr(item, "fecha_fin_vigencia", None))
    categoria = _normalizar_categoria_reglamento(item.categoria, permitir_desconocida=True) or item.categoria

    alcance_label = {
        "global": "Plantilla global",
        "establecimiento": "Solo establecimiento",
        "reunion": "Solo reunión",
    }.get(alcance, "Plantilla global")

    return {
        "id": item.id,
        "codigo": item.codigo,
        "descripcion": item.descripcion,
        "categoria": categoria,
        "riesgo": item.riesgo,
        "puntaje": item.puntaje,
        "tipo_validacion": (item.tipo_validacion or "si_no").strip().lower(),
        "logica_inversa": _item_logica_inversa(item),
        "valor_umbral": float(item.valor_umbral) if item.valor_umbral is not None else None,
        "operador_comparacion": item.operador_comparacion,
        "alcance": alcance,
        "alcance_label": alcance_label,
        "tipo_vigencia": tipo_vigencia,
        "fecha_fin_vigencia": fecha_fin_vigencia.isoformat() if fecha_fin_vigencia else None,
        "fecha_fin_vigencia_label": _formatear_fecha(fecha_fin_vigencia),
        "activo": bool(item.activo),
        "orden": item.orden or 0,
        "establecimiento_id": item.establecimiento_id,
        "reunion_origen_id": item.reunion_origen_id,
    }

def _serializar_item_reunion(item):
    fecha_fin_vigencia = _parsear_fecha_iso(getattr(item, "fecha_fin_vigencia", None))
    categoria = _normalizar_categoria_reglamento(item.categoria, permitir_desconocida=True) or item.categoria
    alcance = (item.alcance or "global").strip().lower()
    alcance_label = {
        "global": "Plantilla global",
        "establecimiento": "Solo establecimiento",
        "reunion": "Solo esta reunión",
    }.get(alcance, "Plantilla global")
    return {
        "id": item.id,
        "item_id": item.item_id,
        "codigo": item.codigo,
        "descripcion": item.descripcion,
        "categoria": categoria,
        "riesgo": item.riesgo,
        "puntaje": item.puntaje,
        "tipo_validacion": item.tipo_validacion,
        "logica_inversa": bool(item.logica_inversa),
        "valor_umbral": float(item.valor_umbral) if item.valor_umbral is not None else None,
        "operador_comparacion": item.operador_comparacion,
        "activo": bool(item.activo),
        "alcance": alcance,
        "alcance_label": alcance_label,
        "tipo_vigencia": item.tipo_vigencia,
        "fecha_fin_vigencia": fecha_fin_vigencia.isoformat() if fecha_fin_vigencia else None,
        "fecha_fin_vigencia_label": _formatear_fecha(fecha_fin_vigencia),
        "es_adicional": bool(item.es_adicional),
    }

def _crear_snapshot_item_reunion(
    reunion,
    item_base,
    es_adicional=False,
    activo=True,
    puntaje=None,
):
    snapshot = ReunionItemReglamento(
        reunion_id=reunion.id,
        item_id=item_base.id,
        codigo=item_base.codigo,
        descripcion=item_base.descripcion,
        categoria=_normalizar_categoria_reglamento(item_base.categoria, permitir_desconocida=True) or item_base.categoria,
        riesgo=item_base.riesgo,
        puntaje=(item_base.puntaje or 0) if puntaje is None else puntaje,
        tipo_validacion=(item_base.tipo_validacion or "si_no").strip().lower(),
        logica_inversa=_item_logica_inversa(item_base),
        valor_umbral=item_base.valor_umbral,
        operador_comparacion=item_base.operador_comparacion,
        tipo_vigencia=(item_base.tipo_vigencia or "permanente").strip().lower(),
        fecha_fin_vigencia=item_base.fecha_fin_vigencia,
        alcance=(item_base.alcance or ("establecimiento" if item_base.establecimiento_id else "global")).strip().lower(),
        orden=item_base.orden or 0,
        activo=activo,
        es_adicional=es_adicional,
    )
    db.session.add(snapshot)
    return snapshot

def _obtener_items_reunion_ordenados(reunion):
    return (
        ReunionItemReglamento.query.filter_by(reunion_id=reunion.id)
        .order_by(
            ReunionItemReglamento.categoria.asc(),
            ReunionItemReglamento.orden.asc(),
            ReunionItemReglamento.codigo.asc(),
        )
        .all()
    )


def _inicializar_items_reunion(reunion):
    for item in _consulta_items_catalogo_aplicables(
        reunion.establecimiento_id,
        fecha_referencia=reunion.fecha_reunion,
    ).all():
        _crear_snapshot_item_reunion(reunion, item)


def _asegurar_items_reunion(reunion):
    items_reunion = _obtener_items_reunion_ordenados(reunion)
    if items_reunion:
        return items_reunion

    cambios = False
    creados_por_item = {}

    for evaluacion in reunion.evaluaciones or []:
        item_base = evaluacion.item
        if not item_base or item_base.id in creados_por_item:
            continue

        snapshot = _crear_snapshot_item_reunion(
            reunion,
            item_base,
            es_adicional=(item_base.alcance == "reunion"),
            activo=True,
            puntaje=(
                evaluacion.puntaje_aplicado
                if evaluacion.puntaje_aplicado is not None
                else (item_base.puntaje or 0)
            ),
        )
        db.session.flush()
        evaluacion.reunion_item_id = snapshot.id
        creados_por_item[item_base.id] = snapshot
        cambios = True

    if reunion.estado == "pendiente" or not reunion.evaluaciones:
        for item in _consulta_items_catalogo_aplicables(
            reunion.establecimiento_id,
            fecha_referencia=reunion.fecha_reunion,
        ).all():
            if item.id in creados_por_item:
                continue
            _crear_snapshot_item_reunion(reunion, item)
            cambios = True

    if cambios:
        db.session.commit()

    return _obtener_items_reunion_ordenados(reunion)


def _parsear_payload_item_base(
    data,
    establecimiento_id,
    item_existente=None,
    permitir_reunion=False,
    fecha_referencia=None,
):
    if item_existente is None:
        codigo = _obtener_siguiente_codigo_item()
    else:
        codigo = (item_existente.codigo or "").strip().upper()
        if not codigo:
            codigo = _obtener_siguiente_codigo_item()

    descripcion = (data.get("descripcion") or "").strip()
    if not descripcion:
        return None, ("La descripción del item es obligatoria.", 400)

    categoria = _normalizar_categoria_reglamento(
        data.get("categoria") or (item_existente.categoria if item_existente else None)
    )
    if not categoria:
        return None, ("Debe seleccionar una categoría válida.", 400)

    riesgo = _normalizar_riesgo(data.get("riesgo"))
    if riesgo not in RIESGOS_REGLAMENTO:
        return None, ("Debe seleccionar un riesgo válido.", 400)

    try:
        puntaje = int(data.get("puntaje"))
    except (TypeError, ValueError):
        return None, ("El puntaje debe ser un número entero.", 400)

    if puntaje < 0:
        return None, ("El puntaje no puede ser negativo.", 400)

    alcance = (
        data.get("alcance")
        or (item_existente.alcance if item_existente else "global")
        or "global"
    )
    alcance = alcance.strip().lower()
    if alcance not in ALCANCES_ITEM_REGLAMENTO:
        return None, ("Debe seleccionar un alcance válido.", 400)
    if alcance == "reunion" and not permitir_reunion:
        return None, ("Este formulario no permite items solo de reunión.", 400)

    tipo_vigencia = (
        data.get("tipo_vigencia")
        or (item_existente.tipo_vigencia if item_existente else "permanente")
        or "permanente"
    )
    tipo_vigencia = tipo_vigencia.strip().lower()
    if tipo_vigencia not in TIPOS_VIGENCIA_REGLAMENTO:
        return None, ("Debe seleccionar una vigencia válida.", 400)

    raw_fecha_fin_vigencia = data.get("fecha_fin_vigencia")
    if raw_fecha_fin_vigencia in (None, ""):
        fecha_fin_vigencia = (
            _parsear_fecha_iso(item_existente.fecha_fin_vigencia)
            if item_existente is not None and tipo_vigencia == "temporal"
            else None
        )
    else:
        fecha_fin_vigencia = _parsear_fecha_iso(raw_fecha_fin_vigencia)
        if fecha_fin_vigencia is None:
            return None, ("La fecha fin de vigencia no es válida.", 400)

    referencia = _parsear_fecha_iso(fecha_referencia)
    if tipo_vigencia == "temporal":
        if fecha_fin_vigencia is None:
            return None, ("Debe indicar hasta qué fecha estará vigente el item temporal.", 400)
        if referencia and fecha_fin_vigencia < referencia:
            return None, (
                f"La vigencia temporal no puede terminar antes del {_formatear_fecha(referencia)}.",
                400,
            )
    else:
        fecha_fin_vigencia = None

    tipo_validacion = (
        data.get("tipo_validacion")
        or (item_existente.tipo_validacion if item_existente else "si_no")
        or "si_no"
    )
    tipo_validacion = tipo_validacion.strip().lower()
    if tipo_validacion not in TIPOS_VALIDACION_REGLAMENTO:
        return None, ("Debe seleccionar un tipo de validación válido.", 400)

    logica_inversa = _normalizar_booleano(data.get("logica_inversa"))

    valor_umbral = None
    operador_comparacion = None
    if tipo_validacion in {"numerico", "porcentaje"}:
        operador_comparacion = (data.get("operador_comparacion") or "").strip()
        if operador_comparacion not in OPERADORES_VALIDOS:
            return None, ("Debe seleccionar un operador de comparación válido.", 400)

        try:
            valor_umbral = float(data.get("valor_umbral"))
        except (TypeError, ValueError):
            return None, ("Debe ingresar un umbral numérico válido.", 400)

    raw_activo = data.get("activo")
    if raw_activo is None:
        activo = item_existente.activo if item_existente is not None else True
    else:
        activo = _normalizar_booleano(raw_activo)

    raw_orden = data.get("orden")
    if raw_orden in (None, ""):
        orden = (
            item_existente.orden
            if item_existente is not None and item_existente.orden is not None
            else _obtener_siguiente_orden_item()
        )
    else:
        try:
            orden = int(raw_orden)
        except (TypeError, ValueError):
            return None, ("El orden debe ser un número entero.", 400)
        if orden < 0:
            return None, ("El orden no puede ser negativo.", 400)

    conflicto = ItemReglamento.query.filter(ItemReglamento.codigo == codigo)
    if item_existente is not None:
        conflicto = conflicto.filter(ItemReglamento.id != item_existente.id)
    if conflicto.first():
        return None, ("No se pudo generar un código único para el item. Intenta nuevamente.", 409)

    establecimiento_item_id = (
        establecimiento_id if alcance in {"establecimiento", "reunion"} else None
    )

    return {
        "codigo": codigo,
        "descripcion": descripcion,
        "categoria": categoria,
        "riesgo": riesgo,
        "puntaje": puntaje,
        "tipo_validacion": tipo_validacion,
        "logica_inversa": logica_inversa,
        "valor_umbral": valor_umbral,
        "operador_comparacion": operador_comparacion,
        "alcance": alcance,
        "tipo_vigencia": tipo_vigencia,
        "fecha_fin_vigencia": fecha_fin_vigencia,
        "activo": activo,
        "orden": orden,
        "establecimiento_id": establecimiento_item_id,
    }, None

def _aplicar_payload_item(item, payload):
    item.codigo = payload["codigo"]
    item.descripcion = payload["descripcion"]
    item.categoria = payload["categoria"]
    item.riesgo = payload["riesgo"]
    item.puntaje = payload["puntaje"]
    item.tipo_validacion = payload["tipo_validacion"]
    item.logica_inversa = payload["logica_inversa"]
    item.valor_umbral = payload["valor_umbral"]
    item.operador_comparacion = payload["operador_comparacion"]
    item.alcance = payload["alcance"]
    item.tipo_vigencia = payload["tipo_vigencia"]
    item.fecha_fin_vigencia = payload["fecha_fin_vigencia"]
    item.activo = payload["activo"]
    item.orden = payload["orden"]
    item.establecimiento_id = payload["establecimiento_id"]

def calcular_sancion_por_platos(total_puntos):
    if total_puntos <= 2:
        return {"platos": 0, "descripcion": "Llamado de atencion"}
    if 3 <= total_puntos <= 4:
        return {"platos": 5, "descripcion": "5 platos"}
    if 5 <= total_puntos <= 6:
        return {"platos": 10, "descripcion": "10 platos"}
    if 7 <= total_puntos <= 8:
        return {"platos": 15, "descripcion": "15 platos"}
    if 9 <= total_puntos <= 10:
        return {"platos": 20, "descripcion": "20 platos"}
    return {"platos": 25, "descripcion": "25 platos"}


@reglamento_bp.route("/dashboard")
@login_required
def dashboard():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return (
                "Acceso denegado. Solo inspectores y administradores pueden gestionar el reglamento.",
                403,
            )

        establecimientos = _obtener_establecimientos_gestionables()
        establecimiento_id = request.args.get("establecimiento_id", type=int)

        if establecimiento_id:
            establecimiento, error = _resolver_establecimiento_autorizado(
                establecimiento_id
            )
            if error:
                return error[0], error[1]

            reuniones_totales_modelo = (
                ReglamentoRestaurante.query.filter_by(
                    establecimiento_id=establecimiento_id
                )
                .order_by(ReglamentoRestaurante.fecha_reunion.desc())
                .all()
            )

            reuniones_modelo = (
                ReglamentoRestaurante.query.filter_by(
                    establecimiento_id=establecimiento_id
                )
                .order_by(ReglamentoRestaurante.fecha_reunion.desc())
                .limit(10)
                .all()
            )
            reuniones = [
                _construir_resumen_reunion(reunion) for reunion in reuniones_modelo
            ]
            reuniones_totales = [
                _construir_resumen_reunion(reunion)
                for reunion in reuniones_totales_modelo
            ]
            pendientes_count = sum(
                1
                for reunion_data in reuniones_totales
                if reunion_data["reunion"].estado == "pendiente"
            )
            ultima_sancion = (
                reuniones_totales[0]["sancion_descripcion"]
                if reuniones_totales
                else "Sin reuniones"
            )
            items_activos_count = _consulta_items_catalogo_aplicables(
                establecimiento_id
            ).count()

            return render_template(
                "reglamento/dashboard.html",
                establecimiento=establecimiento,
                reuniones=reuniones,
                total_reuniones=len(reuniones_totales),
                pendientes_count=pendientes_count,
                ultima_sancion=ultima_sancion,
                items_activos_count=items_activos_count,
            )

        return render_template(
            "reglamento/seleccionar_establecimiento.html",
            establecimientos=establecimientos,
        )

    except Exception:
        current_app.logger.exception("Error cargando dashboard de reglamento")
        return "Error interno del módulo de reglamento.", 500

@reglamento_bp.route("/crear-reunion", methods=["POST"])
@login_required
def crear_reunion():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para crear reuniones."}), 403

        data = request.get_json(silent=True) or {}
        establecimiento_id = data.get("establecimiento_id")

        if not establecimiento_id:
            return jsonify({"error": "Establecimiento requerido"}), 400

        _, error = _resolver_establecimiento_autorizado(establecimiento_id)
        if error:
            return jsonify({"error": error[0]}), error[1]

        hoy = datetime.now().date()
        dias_hasta_lunes_actual = hoy.weekday()
        lunes_actual = hoy - timedelta(days=dias_hasta_lunes_actual)
        lunes_semana_anterior = lunes_actual - timedelta(days=7)
        domingo_semana_anterior = lunes_semana_anterior + timedelta(days=6)
        semana = lunes_semana_anterior.isocalendar()[1]
        ano = lunes_semana_anterior.year

        reunion_existente = ReglamentoRestaurante.query.filter_by(
            establecimiento_id=establecimiento_id, semana=semana, ano=ano
        ).first()
        if reunion_existente:
            return (
                jsonify(
                    {
                        "error": "Ya existe una reunión para esta semana",
                        "reunion_id": reunion_existente.id,
                    }
                ),
                409,
            )

        inspecciones = Inspeccion.query.filter(
            Inspeccion.establecimiento_id == establecimiento_id,
            Inspeccion.fecha >= lunes_semana_anterior,
            Inspeccion.fecha <= domingo_semana_anterior,
            Inspeccion.estado == "completada",
        ).count()

        nueva_reunion = ReglamentoRestaurante(
            establecimiento_id=establecimiento_id,
            semana=semana,
            ano=ano,
            fecha_reunion=hoy,
            fecha_inicio_semana=lunes_semana_anterior,
            fecha_fin_semana=domingo_semana_anterior,
            total_inspecciones=inspecciones,
            estado="pendiente",
        )

        db.session.add(nueva_reunion)
        db.session.flush()
        _inicializar_items_reunion(nueva_reunion)
        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Reunión creada exitosamente",
                "reunion_id": nueva_reunion.id,
                "semana_evaluada": f"Semana {semana} ({lunes_semana_anterior.strftime('%d/%m')} - {domingo_semana_anterior.strftime('%d/%m/%Y')})",
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error creando reunión de reglamento")
        return jsonify({"error": "Error interno al crear la reunión."}), 500


@reglamento_bp.route("/reunion/<int:reunion_id>")
@login_required
def ver_reunion(reunion_id):
    try:
        reunion, error = _resolver_reunion_autorizada(reunion_id)
        if error:
            return error[0], error[1]

        items_reunion = _asegurar_items_reunion(reunion)
        items_reunion_por_base = {item.item_id: item for item in items_reunion}

        evaluaciones = {}
        for evaluacion in reunion.evaluaciones:
            item_reunion = evaluacion.reunion_item or items_reunion_por_base.get(
                evaluacion.item_id
            )
            if not item_reunion:
                continue

            tipo_validacion = (item_reunion.tipo_validacion or "si_no").strip().lower()
            if tipo_validacion in ["numerico", "porcentaje"]:
                estado_guardado = None
            elif _item_logica_inversa(item_reunion):
                estado_guardado = "no_cumple" if evaluacion.cumple else "cumple"
            else:
                estado_guardado = "cumple" if evaluacion.cumple else "no_cumple"

            evaluaciones[item_reunion.id] = {
                "cumple": evaluacion.cumple,
                "estado": estado_guardado,
                "numero_infracciones": evaluacion.numero_infracciones,
                "valor_medido": (
                    float(evaluacion.valor_medido)
                    if evaluacion.valor_medido is not None
                    else None
                ),
                "observacion": evaluacion.observacion or "",
            }

        items_por_tipo = {}
        for item in items_reunion:
            item.logica_inversa_efectiva = _item_logica_inversa(item)
            item.categoria = _normalizar_categoria_reglamento(item.categoria, permitir_desconocida=True) or item.categoria
            if item.categoria not in items_por_tipo:
                items_por_tipo[item.categoria] = []
            items_por_tipo[item.categoria].append(item)

        items_reutilizables = [
            _serializar_item_catalogo(item)
            for item in _consulta_items_catalogo_reutilizables_reunion(reunion).all()
        ]
        items_reunion_editables = {
            item.id: _serializar_item_reunion(item)
            for categoria_items in items_por_tipo.values()
            for item in categoria_items
            if item.es_adicional
        }
        resumen_actual = _calcular_resumen_reunion_desde_evaluaciones(
            reunion.evaluaciones
        )

        return render_template(
            "reglamento/reunion_detalle.html",
            reunion=reunion,
            items_por_tipo=items_por_tipo,
            evaluaciones=evaluaciones,
            resumen_actual=resumen_actual,
            observaciones_reunion=reunion.observaciones or "",
            solo_lectura=reunion.estado != "pendiente",
            riesgos_disponibles=["Menor", "Mayor", "Crítico"],
            categorias_disponibles=CATEGORIAS_REGLAMENTO,
            items_reutilizables=items_reutilizables,
            items_reunion_editables=items_reunion_editables,
            alcances_creables=[
                ("establecimiento", "Plantilla para este establecimiento"),
                ("global", "Plantilla global"),
                ("reunion", "Solo esta reunión"),
            ],
            vigencias_disponibles=[("permanente", "Permanente"), ("temporal", "Temporal")],
        )

    except Exception:
        current_app.logger.exception("Error cargando detalle de reunión de reglamento")
        return "Error interno del módulo de reglamento.", 500

@reglamento_bp.route("/guardar-evaluacion", methods=["POST"])
@login_required
def guardar_evaluacion():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para guardar evaluaciones."}), 403

        data = request.get_json(silent=True) or {}
        reunion_id = data.get("reunion_id")
        evaluaciones_data = data.get("evaluaciones", [])
        observaciones_reunion = (data.get("observaciones_reunion") or "").strip()

        if not reunion_id:
            return jsonify({"error": "Reunión requerida."}), 400

        reunion, error = _resolver_reunion_autorizada(reunion_id)
        if error:
            return jsonify({"error": error[0]}), error[1]

        if reunion.estado != "pendiente":
            return (
                jsonify(
                    {
                        "error": "La reunión ya está cerrada y no puede modificarse."
                    }
                ),
                409,
            )

        if not isinstance(evaluaciones_data, list) or not evaluaciones_data:
            return jsonify({"error": "Debe enviar la configuración de la reunión."}), 400

        if len(observaciones_reunion) > 5000:
            return (
                jsonify(
                    {
                        "error": "Las observaciones generales no pueden superar los 5000 caracteres."
                    }
                ),
                400,
            )

        items_reunion = {
            item.id: item for item in _asegurar_items_reunion(reunion)
        }
        if not items_reunion:
            return jsonify({"error": "No hay items configurados para esta reunión."}), 400

        evaluaciones_limpias = []
        errores_validacion = []

        for eval_data in evaluaciones_data:
            reunion_item_id = eval_data.get("reunion_item_id")
            if reunion_item_id in (None, ""):
                continue

            try:
                reunion_item_id = int(reunion_item_id)
            except (TypeError, ValueError):
                errores_validacion.append("Se recibió un item inválido en la reunión.")
                continue

            reunion_item = items_reunion.get(reunion_item_id)
            if not reunion_item:
                continue

            activo_reunion = _normalizar_booleano(eval_data.get("activo", True))
            reunion_item.activo = activo_reunion

            try:
                puntaje_reunion = int(eval_data.get("puntaje_reunion"))
            except (TypeError, ValueError):
                errores_validacion.append(
                    f"{reunion_item.codigo}: el puntaje de la reunión debe ser un entero."
                )
                continue

            if puntaje_reunion < 0:
                errores_validacion.append(
                    f"{reunion_item.codigo}: el puntaje no puede ser negativo."
                )
                continue

            reunion_item.puntaje = puntaje_reunion
            observacion = (eval_data.get("observacion") or "").strip()

            if not activo_reunion:
                continue

            valor_medido = eval_data.get("valor_medido")
            tipo_validacion = (reunion_item.tipo_validacion or "si_no").strip().lower()
            logica_inversa = _item_logica_inversa(reunion_item)

            try:
                numero_infracciones = int(eval_data.get("numero_infracciones") or 0)
            except (TypeError, ValueError):
                errores_validacion.append(
                    f"{reunion_item.codigo}: número de infracciones inválido."
                )
                continue

            if numero_infracciones < 0:
                errores_validacion.append(
                    f"{reunion_item.codigo}: el número de infracciones no puede ser negativo."
                )
                continue

            if tipo_validacion in ["numerico", "porcentaje"]:
                if valor_medido in (None, ""):
                    errores_validacion.append(
                        f"{reunion_item.codigo}: debe ingresar un valor medido."
                    )
                    continue

                try:
                    valor_float = float(valor_medido)
                except (TypeError, ValueError):
                    errores_validacion.append(
                        f"{reunion_item.codigo}: el valor medido no es válido."
                    )
                    continue

                if reunion_item.valor_umbral is None or not reunion_item.operador_comparacion:
                    errores_validacion.append(
                        f"{reunion_item.codigo}: el item no tiene configuración de umbral válida."
                    )
                    continue

                condicion = _evaluar_condicion(
                    valor_float,
                    reunion_item.operador_comparacion,
                    float(reunion_item.valor_umbral),
                )
                incumplimiento = not condicion if logica_inversa else condicion
                cumple = not incumplimiento
                valor_medido_limpio = valor_float
            else:
                estado = (eval_data.get("estado") or "").strip().lower()
                if estado not in {"cumple", "no_cumple"}:
                    errores_validacion.append(
                        f"{reunion_item.codigo}: debe seleccionar SI o NO."
                    )
                    continue

                seleccion_si = estado == "cumple"
                cumple = (not logica_inversa and seleccion_si) or (
                    logica_inversa and not seleccion_si
                )
                incumplimiento = not cumple
                valor_medido_limpio = None

            if incumplimiento and numero_infracciones <= 0:
                numero_infracciones = 1
            elif not incumplimiento:
                numero_infracciones = 0

            evaluacion = EvaluacionReglamento(
                reunion_id=reunion.id,
                item_id=reunion_item.item_id,
                reunion_item_id=reunion_item.id,
                cumple=cumple,
                numero_infracciones=numero_infracciones,
                puntaje_aplicado=reunion_item.puntaje or 0,
                valor_medido=valor_medido_limpio,
                observacion=observacion,
            )
            evaluacion.item = reunion_item.item
            evaluacion.reunion_item = reunion_item
            evaluaciones_limpias.append(evaluacion)

        faltantes = [
            item.codigo
            for item in items_reunion.values()
            if item.activo
            and item.id not in {evaluacion.reunion_item_id for evaluacion in evaluaciones_limpias}
        ]

        if faltantes:
            errores_validacion.append(
                "Faltan respuestas obligatorias: " + ", ".join(faltantes[:8])
            )

        if errores_validacion:
            return jsonify({"error": errores_validacion[0]}), 400

        EvaluacionReglamento.query.filter_by(reunion_id=reunion.id).delete()
        for evaluacion in evaluaciones_limpias:
            db.session.add(evaluacion)

        resumen = _calcular_resumen_reunion_desde_evaluaciones(evaluaciones_limpias)
        sancion = resumen["sancion"]

        reunion.estado = "completada"
        reunion.total_infracciones = resumen["total_infracciones"]
        reunion.total_puntos = resumen["total_puntos"]
        reunion.total_platos_sancion = sancion.get("platos", 0)
        reunion.observaciones = observaciones_reunion or None

        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Evaluación guardada exitosamente",
                "total_infracciones": resumen["total_infracciones"],
                "total_puntos": resumen["total_puntos"],
                "sancion": sancion,
                "observaciones_reunion": reunion.observaciones or "",
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error guardando evaluación de reglamento")
        return jsonify({"error": "Error interno al guardar la evaluación."}), 500

@reglamento_bp.route("/items/<int:establecimiento_id>/gestion")
@login_required
def gestionar_items(establecimiento_id):
    try:
        establecimiento, error = _resolver_establecimiento_autorizado(
            establecimiento_id
        )
        if error:
            return error[0], error[1]

        items = [
            _serializar_item_catalogo(item)
            for item in _consulta_items_catalogo_gestionables(establecimiento_id).all()
        ]

        return render_template(
            "reglamento/gestion_items.html",
            establecimiento=establecimiento,
            items=items,
            riesgos_disponibles=["Menor", "Mayor", "Crítico"],
            categorias_disponibles=CATEGORIAS_REGLAMENTO,
            tipos_validacion=[("si_no", "SI / NO"), ("numerico", "Numérico"), ("porcentaje", "Porcentaje")],
            vigencias_disponibles=[("permanente", "Permanente"), ("temporal", "Temporal")],
            alcances_disponibles=[("establecimiento", "Solo este establecimiento"), ("global", "Plantilla global")],
        )

    except Exception:
        current_app.logger.exception("Error cargando gestión de items de reglamento")
        return "Error interno del módulo de reglamento.", 500


@reglamento_bp.route("/items/guardar", methods=["POST"])
@login_required
def guardar_item_catalogo():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para gestionar items."}), 403

        data = request.get_json(silent=True) or {}
        item_id = data.get("item_id")
        establecimiento_id = data.get("establecimiento_id")

        item_existente = None
        if item_id not in (None, ""):
            try:
                item_id = int(item_id)
            except (TypeError, ValueError):
                return jsonify({"error": "Item inválido."}), 400

            item_existente = ItemReglamento.query.get(item_id)
            if not item_existente:
                return jsonify({"error": "Item no encontrado."}), 404
            if (item_existente.alcance or "").strip().lower() == "reunion":
                return jsonify({"error": "Los items solo de reunión se editan desde la reunión."}), 400
            if item_existente.establecimiento_id:
                _, error = _resolver_establecimiento_autorizado(
                    item_existente.establecimiento_id
                )
                if error:
                    return jsonify({"error": error[0]}), error[1]

        if establecimiento_id not in (None, ""):
            try:
                establecimiento_id = int(establecimiento_id)
            except (TypeError, ValueError):
                return jsonify({"error": "Establecimiento inválido."}), 400
            _, error = _resolver_establecimiento_autorizado(establecimiento_id)
            if error:
                return jsonify({"error": error[0]}), error[1]
        elif item_existente and item_existente.establecimiento_id:
            establecimiento_id = item_existente.establecimiento_id

        payload, error = _parsear_payload_item_base(
            data,
            establecimiento_id,
            item_existente=item_existente,
            permitir_reunion=False,
        )
        if error:
            return jsonify({"error": error[0]}), error[1]

        if item_existente is None:
            item_existente = ItemReglamento(
                created_by_user_id=session.get("user_id"),
            )
            db.session.add(item_existente)

        _aplicar_payload_item(item_existente, payload)
        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Item guardado correctamente.",
                "item": _serializar_item_catalogo(item_existente),
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error guardando item del catálogo de reglamento")
        return jsonify({"error": "Error interno al guardar el item."}), 500


@reglamento_bp.route("/reunion/<int:reunion_id>/items", methods=["POST"])
@login_required
def agregar_item_reunion(reunion_id):
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para agregar items."}), 403

        reunion, error = _resolver_reunion_autorizada(reunion_id)
        if error:
            return jsonify({"error": error[0]}), error[1]

        if reunion.estado != "pendiente":
            return jsonify({"error": "La reunión ya está cerrada."}), 409

        data = request.get_json(silent=True) or {}
        modo = (data.get("modo") or "nuevo").strip().lower()
        if modo not in {"nuevo", "existente"}:
            return jsonify({"error": "Modo de registro no válido."}), 400

        if modo == "existente":
            item_catalogo_id = data.get("item_catalogo_id")
            try:
                item_catalogo_id = int(item_catalogo_id)
            except (TypeError, ValueError):
                return jsonify({"error": "Debe seleccionar una plantilla existente válida."}), 400

            item = (
                _consulta_items_catalogo_gestionables(reunion.establecimiento_id)
                .filter(
                    ItemReglamento.id == item_catalogo_id,
                    ItemReglamento.activo == True,
                )
                .first()
            )
            if not item:
                return jsonify({"error": "La plantilla seleccionada no está disponible para este establecimiento."}), 404

            snapshot_existente = ReunionItemReglamento.query.filter_by(
                reunion_id=reunion.id,
                item_id=item.id,
            ).first()
            if snapshot_existente:
                return jsonify({"error": "La plantilla seleccionada ya forma parte de esta reunión."}), 409

            fecha_vigencia_original = _parsear_fecha_iso(item.fecha_fin_vigencia)
            raw_fecha_fin_vigencia = data.get("fecha_fin_vigencia")
            if raw_fecha_fin_vigencia in (None, ""):
                fecha_fin_vigencia = fecha_vigencia_original
            else:
                fecha_fin_vigencia = _parsear_fecha_iso(raw_fecha_fin_vigencia)
                if fecha_fin_vigencia is None:
                    return jsonify({"error": "La fecha de vigencia indicada no es válida."}), 400

            if fecha_fin_vigencia and fecha_fin_vigencia < reunion.fecha_reunion:
                return jsonify({
                    "error": f"La vigencia no puede terminar antes del {_formatear_fecha(reunion.fecha_reunion)}."
                }), 400

            tipo_vigencia_snapshot = (item.tipo_vigencia or "permanente").strip().lower()
            if fecha_fin_vigencia:
                tipo_vigencia_snapshot = "temporal"
            else:
                tipo_vigencia_snapshot = "permanente"

            if tipo_vigencia_snapshot == "temporal" and fecha_fin_vigencia is None:
                return jsonify({
                    "error": "La plantilla temporal seleccionada requiere una fecha de vigencia."
                }), 400

            snapshot = _crear_snapshot_item_reunion(
                reunion,
                item,
                es_adicional=True,
                activo=True,
                puntaje=item.puntaje,
            )
            snapshot.tipo_vigencia = tipo_vigencia_snapshot
            snapshot.fecha_fin_vigencia = fecha_fin_vigencia
        else:
            payload, error = _parsear_payload_item_base(
                data,
                reunion.establecimiento_id,
                item_existente=None,
                permitir_reunion=True,
                fecha_referencia=reunion.fecha_reunion,
            )
            if error:
                return jsonify({"error": error[0]}), error[1]

            item = ItemReglamento(
                created_by_user_id=session.get("user_id"),
                reunion_origen_id=reunion.id,
            )
            _aplicar_payload_item(item, payload)
            if payload["alcance"] == "reunion":
                item.activo = False
            db.session.add(item)
            db.session.flush()

            snapshot = _crear_snapshot_item_reunion(
                reunion,
                item,
                es_adicional=True,
                activo=True,
                puntaje=item.puntaje,
            )

        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Item agregado a la reunión correctamente.",
                "item": _serializar_item_reunion(snapshot),
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error agregando item a reunión de reglamento")
        return jsonify({"error": "Error interno al agregar el item."}), 500


@reglamento_bp.route("/reunion/<int:reunion_id>/items/<int:reunion_item_id>/editar", methods=["POST"])
@login_required
def editar_item_reunion(reunion_id, reunion_item_id):
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para editar items."}), 403

        reunion, error = _resolver_reunion_autorizada(reunion_id)
        if error:
            return jsonify({"error": error[0]}), error[1]

        if reunion.estado != "pendiente":
            return jsonify({"error": "La reunión ya está cerrada."}), 409

        reunion_item = ReunionItemReglamento.query.filter_by(
            id=reunion_item_id,
            reunion_id=reunion.id,
        ).first()
        if not reunion_item:
            return jsonify({"error": "Item de reunión no encontrado."}), 404

        if not reunion_item.es_adicional:
            return (
                jsonify(
                    {
                        "error": "Solo se pueden editar desde aquí los items agregados en la reunión."
                    }
                ),
                409,
            )

        data = request.get_json(silent=True) or {}

        descripcion = (data.get("descripcion") or "").strip()
        if not descripcion:
            return jsonify({"error": "La descripción del item es obligatoria."}), 400

        riesgo = _normalizar_riesgo(data.get("riesgo") or reunion_item.riesgo)
        if riesgo not in RIESGOS_REGLAMENTO:
            return jsonify({"error": "Debe seleccionar un riesgo válido."}), 400

        try:
            puntaje = int(data.get("puntaje"))
        except (TypeError, ValueError):
            return jsonify({"error": "El puntaje debe ser un número entero."}), 400
        if puntaje < 0:
            return jsonify({"error": "El puntaje no puede ser negativo."}), 400

        alcance = (data.get("alcance") or reunion_item.alcance or "reunion").strip().lower()
        if alcance not in ALCANCES_ITEM_REGLAMENTO:
            return jsonify({"error": "Debe seleccionar un alcance válido."}), 400

        tipo_vigencia = (
            data.get("tipo_vigencia") or reunion_item.tipo_vigencia or "permanente"
        ).strip().lower()
        if tipo_vigencia not in TIPOS_VIGENCIA_REGLAMENTO:
            return jsonify({"error": "Debe seleccionar una vigencia válida."}), 400

        raw_fecha_fin_vigencia = data.get("fecha_fin_vigencia")
        if raw_fecha_fin_vigencia in (None, ""):
            fecha_fin_vigencia = None
        else:
            fecha_fin_vigencia = _parsear_fecha_iso(raw_fecha_fin_vigencia)
            if fecha_fin_vigencia is None:
                return jsonify({"error": "La fecha de vigencia indicada no es válida."}), 400

        if tipo_vigencia == "temporal":
            if fecha_fin_vigencia is None:
                return (
                    jsonify(
                        {
                            "error": "Debe indicar hasta qué fecha estará vigente el item temporal."
                        }
                    ),
                    400,
                )
            if fecha_fin_vigencia < reunion.fecha_reunion:
                return (
                    jsonify(
                        {
                            "error": f"La vigencia temporal no puede terminar antes del {_formatear_fecha(reunion.fecha_reunion)}."
                        }
                    ),
                    400,
                )
        else:
            fecha_fin_vigencia = None

        reunion_item.descripcion = descripcion
        reunion_item.riesgo = riesgo
        reunion_item.puntaje = puntaje
        reunion_item.alcance = alcance
        reunion_item.tipo_vigencia = tipo_vigencia
        reunion_item.fecha_fin_vigencia = fecha_fin_vigencia

        item_catalogo = reunion_item.item
        sincroniza_catalogo = bool(
            item_catalogo and item_catalogo.reunion_origen_id == reunion.id
        )
        if sincroniza_catalogo:
            item_catalogo.descripcion = descripcion
            item_catalogo.riesgo = riesgo
            item_catalogo.puntaje = puntaje
            item_catalogo.alcance = alcance
            item_catalogo.tipo_vigencia = tipo_vigencia
            item_catalogo.fecha_fin_vigencia = fecha_fin_vigencia
            item_catalogo.establecimiento_id = (
                reunion.establecimiento_id
                if alcance in {"establecimiento", "reunion"}
                else None
            )
            item_catalogo.activo = alcance != "reunion"

        db.session.commit()

        if sincroniza_catalogo and alcance != "reunion":
            mensaje = (
                "Item actualizado para esta reunión y para su plantilla reutilizable."
            )
        elif sincroniza_catalogo:
            mensaje = "Item actualizado solo para esta reunión."
        else:
            mensaje = "Item actualizado correctamente para esta reunión."

        return jsonify(
            {
                "success": True,
                "message": mensaje,
                "sincroniza_catalogo": sincroniza_catalogo and alcance != "reunion",
                "item": _serializar_item_reunion(reunion_item),
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error editando item agregado en reunión de reglamento")
        return jsonify({"error": "Error interno al editar el item."}), 500


@reglamento_bp.route("/items")
@login_required
def listar_items():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para ver items."}), 403

        establecimiento_id = request.args.get("establecimiento_id", type=int)
        if establecimiento_id:
            _, error = _resolver_establecimiento_autorizado(establecimiento_id)
            if error:
                return jsonify({"error": error[0]}), error[1]
            items = _consulta_items_catalogo_gestionables(establecimiento_id).all()
        else:
            items = (
                ItemReglamento.query.filter(
                    or_(ItemReglamento.alcance.is_(None), ItemReglamento.alcance != "reunion")
                )
                .order_by(
                    ItemReglamento.categoria.asc(),
                    ItemReglamento.orden.asc(),
                    ItemReglamento.codigo.asc(),
                )
                .all()
            )

        return jsonify([_serializar_item_catalogo(item) for item in items])

    except Exception:
        current_app.logger.exception("Error listando items de reglamento")
        return jsonify({"error": "Error interno al listar items."}), 500


@reglamento_bp.route("/historial/<int:establecimiento_id>")
@login_required
def historial_reuniones(establecimiento_id):
    try:
        establecimiento, error = _resolver_establecimiento_autorizado(
            establecimiento_id
        )
        if error:
            return error[0], error[1]

        reuniones_modelo = (
            ReglamentoRestaurante.query.filter_by(establecimiento_id=establecimiento_id)
            .order_by(ReglamentoRestaurante.fecha_reunion.desc())
            .all()
        )
        reuniones_data = [
            _construir_resumen_reunion(reunion) for reunion in reuniones_modelo
        ]

        return render_template(
            "reglamento/historial.html",
            establecimiento=establecimiento,
            reuniones=reuniones_data,
        )

    except Exception:
        current_app.logger.exception("Error cargando historial de reglamento")
        return "Error interno del módulo de reglamento.", 500
