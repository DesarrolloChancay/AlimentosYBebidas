"""
Descripción: Controlador para gestionar el Reglamento de Restaurante
Lógica: Maneja reuniones semanales, catálogo configurable de items y cierre de evaluaciones
"""

from collections import defaultdict
from datetime import date, datetime, timedelta
import os
import re

from flask import Blueprint, abort, current_app, render_template, request, jsonify, send_from_directory, session, url_for
from sqlalchemy import and_, or_, text

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
from app.utils.security import safe_text, save_validated_upload_image

reglamento_bp = Blueprint("reglamento", __name__, url_prefix="/reglamento")
ROLES_GESTION_REGLAMENTO = {"Inspector", "Administrador"}
RIESGOS_REGLAMENTO = {"Menor", "Mayor", "Crítico"}
TIPOS_VALIDACION_REGLAMENTO = {"si_no", "numerico", "porcentaje", "automatico_semanal"}
TIPOS_VIGENCIA_REGLAMENTO = {"temporal", "permanente"}
ALCANCES_ITEM_REGLAMENTO = {"global", "establecimiento", "reunion"}
OPERADORES_VALIDOS = {"<", "<=", ">", ">=", "="}
CATEGORIAS_REGLAMENTO = [
    "Checklist (5 veces por semana)",
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


def _calcular_calificacion_semanal_establecimiento(establecimiento_id, fecha_inicio, fecha_fin):
    """Agrega todas las inspecciones completadas de un establecimiento en un rango de
    fechas (puntaje_total, items_calificados, críticos) y calcula UNA calificación
    cualitativa (EXCELENTE/MUY BIEN/REGULAR/MALO) para toda la semana, reutilizando la
    misma fórmula del Bloque C (una inspección crítica fallada suma +7 igual que en un
    solo checklist). Usado para automatizar A-01/A-02 del reglamento (Bloque F, 10/07)."""
    from app.models.Inspecciones_models import InspeccionDetalle
    from app.controllers.inspecciones_controller import InspeccionesController

    inspecciones = Inspeccion.query.filter(
        Inspeccion.establecimiento_id == establecimiento_id,
        Inspeccion.estado == "completada",
        Inspeccion.fecha >= fecha_inicio,
        Inspeccion.fecha <= fecha_fin,
    ).all()

    if not inspecciones:
        return None

    ids_inspecciones = [insp.id for insp in inspecciones]
    conteos = dict(
        db.session.query(
            InspeccionDetalle.inspeccion_id, db.func.count(InspeccionDetalle.id)
        )
        .filter(InspeccionDetalle.inspeccion_id.in_(ids_inspecciones))
        .group_by(InspeccionDetalle.inspeccion_id)
        .all()
    )

    puntaje_total_sum = sum(float(insp.puntaje_total or 0) for insp in inspecciones)
    items_calificados_sum = sum(conteos.get(insp.id, 0) for insp in inspecciones)
    criticos_sum = sum(int(insp.puntos_criticos_perdidos or 0) for insp in inspecciones)

    calificacion = InspeccionesController._calcular_calificacion_global(
        puntaje_total_sum, items_calificados_sum, criticos_sum
    )

    return {
        "calificacion": calificacion,
        "num_inspecciones": len(inspecciones),
        "puntaje_total_sum": puntaje_total_sum,
        "items_calificados_sum": items_calificados_sum,
        "criticos_sum": criticos_sum,
    }


def _evaluar_item_automatico_semanal(codigo, calificacion_semanal):
    """A-01 (Regular) y A-02 (Malo) son mutuamente excluyentes por construcción: una
    calificación semanal solo puede ser una de las 4 etiquetas a la vez."""
    codigo_norm = (codigo or "").strip().upper()
    if not calificacion_semanal:
        return True  # sin inspecciones completadas esa semana: no se sanciona sin datos
    if codigo_norm == "A-01":
        return calificacion_semanal != "REGULAR"
    if codigo_norm == "A-02":
        return calificacion_semanal != "MALO"
    return True


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


MESES_ES = [
    "Ene",
    "Feb",
    "Mar",
    "Abr",
    "May",
    "Jun",
    "Jul",
    "Ago",
    "Sep",
    "Oct",
    "Nov",
    "Dic",
]


def _promedio(valores):
    valores_validos = [valor for valor in valores if valor is not None]
    if not valores_validos:
        return 0
    return round(sum(valores_validos) / len(valores_validos), 2)


def _inicio_mes(fecha):
    return date(fecha.year, fecha.month, 1)


def _sumar_meses(fecha, meses):
    indice = fecha.year * 12 + (fecha.month - 1) + meses
    return date(indice // 12, (indice % 12) + 1, 1)


def _restar_un_anio(fecha):
    try:
        return fecha.replace(year=fecha.year - 1)
    except ValueError:
        return fecha.replace(year=fecha.year - 1, day=28)


def _meses_en_rango(fecha_inicio, fecha_fin):
    mes_actual = _inicio_mes(fecha_inicio)
    mes_fin = _inicio_mes(fecha_fin)
    meses = []
    while mes_actual <= mes_fin:
        meses.append(mes_actual)
        mes_actual = _sumar_meses(mes_actual, 1)
    return meses


def _fecha_referencia_reunion(reunion):
    if reunion.fecha_inicio_semana:
        return reunion.fecha_inicio_semana
    if reunion.fecha_reunion:
        return reunion.fecha_reunion
    if reunion.created_at:
        return reunion.created_at.date()
    return datetime.utcnow().date()


def _puntos_reunion(reunion):
    if reunion.total_puntos is not None:
        return int(reunion.total_puntos or 0)
    return _calcular_resumen_reunion_desde_evaluaciones(reunion.evaluaciones or [])[
        "total_puntos"
    ]


def _infracciones_reunion(reunion):
    if reunion.total_infracciones is not None:
        return int(reunion.total_infracciones or 0)
    return _calcular_resumen_reunion_desde_evaluaciones(reunion.evaluaciones or [])[
        "total_infracciones"
    ]


def _platos_reunion(reunion):
    if reunion.total_platos_sancion is not None:
        return int(reunion.total_platos_sancion or 0)
    return calcular_sancion_por_platos(_puntos_reunion(reunion)).get("platos", 0)


def _parsear_rango_analitica():
    hoy = datetime.utcnow().date()
    fecha_inicio = _parsear_fecha_iso(request.args.get("fecha_inicio")) or date(
        hoy.year, 1, 1
    )
    fecha_fin = _parsear_fecha_iso(request.args.get("fecha_fin")) or hoy

    if fecha_inicio > fecha_fin:
        fecha_inicio, fecha_fin = fecha_fin, fecha_inicio

    return fecha_inicio, fecha_fin


def _query_reuniones_analitica(establecimiento_ids, fecha_inicio, fecha_fin):
    if not establecimiento_ids:
        return []

    fecha_base = db.func.coalesce(
        ReglamentoRestaurante.fecha_inicio_semana,
        ReglamentoRestaurante.fecha_reunion,
    )

    return (
        ReglamentoRestaurante.query.filter(
            ReglamentoRestaurante.estado == "completada",
            ReglamentoRestaurante.establecimiento_id.in_(establecimiento_ids),
            fecha_base >= fecha_inicio,
            fecha_base <= fecha_fin,
        )
        .order_by(fecha_base.asc())
        .all()
    )


def _resolver_filtro_establecimientos_analitica():
    establecimientos = _obtener_establecimientos_gestionables()
    establecimiento_id = request.args.get("establecimiento_id", type=int)

    if establecimiento_id:
        establecimiento, error = _resolver_establecimiento_autorizado(
            establecimiento_id
        )
        if error:
            return establecimientos, [], error
        return establecimientos, [establecimiento.id], None

    return establecimientos, [establecimiento.id for establecimiento in establecimientos], None


def _promedio_por_semana(reuniones):
    semanas = defaultdict(list)
    for reunion in reuniones:
        fecha = _fecha_referencia_reunion(reunion)
        iso_year, iso_week, _ = fecha.isocalendar()
        semanas[(iso_year, iso_week)].append(_puntos_reunion(reunion))

    return _promedio([_promedio(puntos) for puntos in semanas.values()])


def _promedio_por_mes(reuniones):
    meses = defaultdict(list)
    for reunion in reuniones:
        fecha = _fecha_referencia_reunion(reunion)
        meses[(fecha.year, fecha.month)].append(_puntos_reunion(reunion))

    return _promedio([_promedio(puntos) for puntos in meses.values()])


def _serie_mensual(reuniones_actuales, reuniones_anio_anterior, fecha_inicio, fecha_fin):
    meses = _meses_en_rango(fecha_inicio, fecha_fin)
    actuales_por_mes = defaultdict(list)
    anteriores_por_mes_equivalente = defaultdict(list)

    for reunion in reuniones_actuales:
        fecha = _fecha_referencia_reunion(reunion)
        actuales_por_mes[(fecha.year, fecha.month)].append(_puntos_reunion(reunion))

    for reunion in reuniones_anio_anterior:
        fecha = _fecha_referencia_reunion(reunion)
        anteriores_por_mes_equivalente[(fecha.year + 1, fecha.month)].append(
            _puntos_reunion(reunion)
        )

    labels = [f"{MESES_ES[mes.month - 1]} {mes.year}" for mes in meses]
    actual = []
    anterior = []

    for mes in meses:
        puntos_actuales = actuales_por_mes.get((mes.year, mes.month), [])
        puntos_anteriores = anteriores_por_mes_equivalente.get((mes.year, mes.month), [])
        actual.append(_promedio(puntos_actuales) if puntos_actuales else None)
        anterior.append(_promedio(puntos_anteriores) if puntos_anteriores else None)

    return {"labels": labels, "actual": actual, "anterior": anterior}


def _barras_restaurantes(reuniones):
    datos = {}
    for reunion in reuniones:
        establecimiento = reunion.establecimiento
        if not establecimiento:
            continue
        item = datos.setdefault(
            establecimiento.id,
            {
                "establecimiento": establecimiento.nombre,
                "reuniones": 0,
                "total_puntos": 0,
                "total_infracciones": 0,
                "total_platos": 0,
            },
        )
        item["reuniones"] += 1
        item["total_puntos"] += _puntos_reunion(reunion)
        item["total_infracciones"] += _infracciones_reunion(reunion)
        item["total_platos"] += _platos_reunion(reunion)

    filas = []
    for item in datos.values():
        reuniones_count = item["reuniones"] or 1
        filas.append(
            {
                **item,
                "promedio_puntos": round(item["total_puntos"] / reuniones_count, 2),
            }
        )

    return sorted(filas, key=lambda item: item["promedio_puntos"], reverse=True)


def _datos_evaluacion_reglamento(evaluacion):
    item = evaluacion.reunion_item or evaluacion.item
    codigo = getattr(item, "codigo", "") or "S/C"
    descripcion = getattr(item, "descripcion", "") or "Sin descripcion"
    categoria = (
        _normalizar_categoria_reglamento(
            getattr(item, "categoria", None), permitir_desconocida=True
        )
        or "Sin categoria"
    )
    puntaje = evaluacion.puntaje_aplicado
    if puntaje is None:
        puntaje = getattr(item, "puntaje", 0) or 0

    numero_infracciones = evaluacion.numero_infracciones or 0
    if not evaluacion.cumple and numero_infracciones <= 0:
        numero_infracciones = 1

    puntos = 0 if evaluacion.cumple else int(puntaje or 0) * numero_infracciones
    return {
        "codigo": codigo,
        "descripcion": descripcion,
        "categoria": categoria,
        "cumple": bool(evaluacion.cumple),
        "numero_infracciones": numero_infracciones,
        "puntos": puntos,
    }


def _resumen_categorias_e_items(reunion_ids):
    if not reunion_ids:
        return {"categorias": [], "menos_cumplidos": [], "cumplidos": []}

    evaluaciones = EvaluacionReglamento.query.filter(
        EvaluacionReglamento.reunion_id.in_(reunion_ids)
    ).all()

    categorias = {}
    items = {}

    for evaluacion in evaluaciones:
        datos = _datos_evaluacion_reglamento(evaluacion)
        categoria = categorias.setdefault(
            datos["categoria"],
            {"categoria": datos["categoria"], "total": 0, "cumple": 0, "no_cumple": 0, "puntos": 0},
        )
        categoria["total"] += 1
        categoria["puntos"] += datos["puntos"]
        if datos["cumple"]:
            categoria["cumple"] += 1
        else:
            categoria["no_cumple"] += 1

        item_key = (datos["codigo"], datos["descripcion"])
        item = items.setdefault(
            item_key,
            {
                "codigo": datos["codigo"],
                "descripcion": datos["descripcion"],
                "categoria": datos["categoria"],
                "total": 0,
                "cumple": 0,
                "no_cumple": 0,
                "puntos": 0,
                "infracciones": 0,
            },
        )
        item["total"] += 1
        item["puntos"] += datos["puntos"]
        item["infracciones"] += datos["numero_infracciones"]
        if datos["cumple"]:
            item["cumple"] += 1
        else:
            item["no_cumple"] += 1

    categorias_data = []
    for categoria in categorias.values():
        total = categoria["total"] or 1
        categorias_data.append(
            {
                **categoria,
                "promedio_puntos": round(categoria["puntos"] / total, 2),
                "cumplimiento": round((categoria["cumple"] / total) * 100, 1),
            }
        )

    items_data = []
    for item in items.values():
        total = item["total"] or 1
        items_data.append(
            {
                **item,
                "cumplimiento": round((item["cumple"] / total) * 100, 1),
            }
        )

    menos_cumplidos = sorted(
        [item for item in items_data if item["no_cumple"] > 0],
        key=lambda item: (
            item["cumplimiento"],
            -item["no_cumple"],
            -item["puntos"],
            item["codigo"],
        ),
    )[:12]
    cumplidos = sorted(
        items_data,
        key=lambda item: (
            -item["cumplimiento"],
            -item["total"],
            item["no_cumple"],
            item["codigo"],
        ),
    )[:12]

    return {
        "categorias": sorted(categorias_data, key=lambda item: item["promedio_puntos"], reverse=True),
        "menos_cumplidos": menos_cumplidos,
        "cumplidos": cumplidos,
    }


def _construir_payload_analitica(establecimiento_ids, fecha_inicio, fecha_fin):
    reuniones_actuales = _query_reuniones_analitica(
        establecimiento_ids, fecha_inicio, fecha_fin
    )
    reuniones_anio_anterior = _query_reuniones_analitica(
        establecimiento_ids, _restar_un_anio(fecha_inicio), _restar_un_anio(fecha_fin)
    )

    puntos_actuales = [_puntos_reunion(reunion) for reunion in reuniones_actuales]
    puntos_anteriores = [_puntos_reunion(reunion) for reunion in reuniones_anio_anterior]
    promedio_actual = _promedio(puntos_actuales)
    promedio_anterior = _promedio(puntos_anteriores)

    if promedio_anterior > 0:
        variacion_anual = round(
            ((promedio_actual - promedio_anterior) / promedio_anterior) * 100, 1
        )
    else:
        variacion_anual = None

    resumen_items = _resumen_categorias_e_items(
        [reunion.id for reunion in reuniones_actuales]
    )

    return {
        "filtros": {
            "fecha_inicio": fecha_inicio.isoformat(),
            "fecha_fin": fecha_fin.isoformat(),
            "fecha_inicio_anio_anterior": _restar_un_anio(fecha_inicio).isoformat(),
            "fecha_fin_anio_anterior": _restar_un_anio(fecha_fin).isoformat(),
        },
        "kpis": {
            "promedio_semanal": _promedio_por_semana(reuniones_actuales),
            "promedio_mensual": _promedio_por_mes(reuniones_actuales),
            "promedio_actual": promedio_actual,
            "promedio_anio_anterior": promedio_anterior,
            "variacion_anual": variacion_anual,
            "reuniones": len(reuniones_actuales),
            "total_puntos": sum(puntos_actuales),
            "total_infracciones": sum(
                _infracciones_reunion(reunion) for reunion in reuniones_actuales
            ),
        },
        "series": {
            "movimiento_mensual": _serie_mensual(
                reuniones_actuales, reuniones_anio_anterior, fecha_inicio, fecha_fin
            ),
            "restaurantes": _barras_restaurantes(reuniones_actuales),
            "categorias": resumen_items["categorias"],
        },
        "reportes": {
            "menos_cumplidos": resumen_items["menos_cumplidos"],
            "cumplidos": resumen_items["cumplidos"],
        },
    }


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
                establecimientos=establecimientos,
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


@reglamento_bp.route("/analitica")
@login_required
def analitica():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return (
                "Acceso denegado. Solo inspectores y administradores pueden ver analítica del reglamento.",
                403,
            )

        establecimientos = _obtener_establecimientos_gestionables()
        hoy = datetime.utcnow().date()
        fecha_inicio_default = date(hoy.year, 1, 1)

        return render_template(
            "reglamento/analitica.html",
            establecimientos=establecimientos,
            fecha_inicio_default=fecha_inicio_default.isoformat(),
            fecha_fin_default=hoy.isoformat(),
        )

    except Exception:
        current_app.logger.exception("Error cargando analítica de reglamento")
        return "Error interno del módulo de reglamento.", 500


@reglamento_bp.route("/api/analitica")
@login_required
def api_analitica():
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para ver analítica."}), 403

        _, establecimiento_ids, error = _resolver_filtro_establecimientos_analitica()
        if error:
            return jsonify({"error": error[0]}), error[1]

        fecha_inicio, fecha_fin = _parsear_rango_analitica()
        payload = _construir_payload_analitica(
            establecimiento_ids, fecha_inicio, fecha_fin
        )
        return jsonify(payload)

    except Exception:
        current_app.logger.exception("Error generando analítica de reglamento")
        return jsonify({"error": "Error interno al generar analítica."}), 500


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

        resultado_calificacion_semanal = None
        if any(
            (item.tipo_validacion or "si_no").strip().lower() == "automatico_semanal"
            for item in items_reunion
        ):
            resultado_calificacion_semanal = _calcular_calificacion_semanal_establecimiento(
                reunion.establecimiento_id, reunion.fecha_inicio_semana, reunion.fecha_fin_semana
            )

        items_por_tipo = {}
        acuerdos_reunion = []
        for item in items_reunion:
            item.logica_inversa_efectiva = _item_logica_inversa(item)
            if (item.tipo_validacion or "si_no").strip().lower() == "automatico_semanal":
                item.resultado_automatico_semanal = resultado_calificacion_semanal
                item.cumple_automatico_semanal = _evaluar_item_automatico_semanal(
                    item.codigo,
                    resultado_calificacion_semanal["calificacion"] if resultado_calificacion_semanal else None,
                )
            item.categoria = _normalizar_categoria_reglamento(item.categoria, permitir_desconocida=True) or item.categoria
            if item.es_adicional:
                acuerdos_reunion.append(item)
                continue
            if item.categoria not in items_por_tipo:
                items_por_tipo[item.categoria] = []
            items_por_tipo[item.categoria].append(item)

        acuerdos_reunion.sort(
            key=lambda item: (
                (item.orden or 0),
                (item.codigo or ""),
                (item.descripcion or ""),
            )
        )

        items_reutilizables = [
            _serializar_item_catalogo(item)
            for item in _consulta_items_catalogo_reutilizables_reunion(reunion).all()
        ]
        items_reunion_editables = {
            item.id: _serializar_item_reunion(item)
            for item in acuerdos_reunion
        }
        resumen_actual = _calcular_resumen_reunion_desde_evaluaciones(
            reunion.evaluaciones
        )

        evidencias_reunion = db.session.execute(
            text("""
                SELECT id, filename, ruta_archivo, descripcion, uploaded_at
                FROM evidencias_reunion_reglamento
                WHERE reunion_id = :reunion_id
                ORDER BY uploaded_at DESC
            """),
            {"reunion_id": reunion.id},
        ).mappings().all()

        return render_template(
            "reglamento/reunion_detalle.html",
            evidencias_reunion=evidencias_reunion,
            reunion=reunion,
            items_por_tipo=items_por_tipo,
            acuerdos_reunion=acuerdos_reunion,
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

            activo_reunion = (
                _normalizar_booleano(eval_data.get("activo", True))
                if reunion_item.es_adicional
                else True
            )
            reunion_item.activo = activo_reunion

            puntaje_actual = int(reunion_item.puntaje or 0)
            if reunion_item.es_adicional:
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
            else:
                puntaje_enviado = eval_data.get("puntaje_reunion")
                if puntaje_enviado not in (None, ""):
                    try:
                        puntaje_enviado = int(puntaje_enviado)
                    except (TypeError, ValueError):
                        errores_validacion.append(
                            f"{reunion_item.codigo}: el puntaje del reglamento base no se puede modificar."
                        )
                        continue

                    if puntaje_enviado != puntaje_actual:
                        errores_validacion.append(
                            f"{reunion_item.codigo}: el puntaje del reglamento base no se puede modificar desde la reunión."
                        )
                        continue
                puntaje_reunion = puntaje_actual
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

            if tipo_validacion == "automatico_semanal":
                resultado_semanal = _calcular_calificacion_semanal_establecimiento(
                    reunion.establecimiento_id,
                    reunion.fecha_inicio_semana,
                    reunion.fecha_fin_semana,
                )
                calificacion_semanal = (
                    resultado_semanal["calificacion"] if resultado_semanal else None
                )
                cumple = _evaluar_item_automatico_semanal(
                    reunion_item.codigo, calificacion_semanal
                )
                incumplimiento = not cumple
                valor_medido_limpio = None
            elif tipo_validacion in ["numerico", "porcentaje"]:
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


@reglamento_bp.route("/evidencias/<int:evidencia_id>")
@login_required
def ver_evidencia_reunion(evidencia_id):
    evidencia = db.session.execute(
        text("""
            SELECT id, reunion_id, filename, ruta_archivo
            FROM evidencias_reunion_reglamento
            WHERE id = :evidencia_id
        """),
        {"evidencia_id": evidencia_id},
    ).mappings().first()

    if not evidencia:
        abort(404)

    _, error = _resolver_reunion_autorizada(evidencia["reunion_id"])
    if error:
        abort(error[1])

    ruta_relativa = (evidencia["ruta_archivo"] or "").replace("\\", "/").lstrip("/")
    if ".." in ruta_relativa or not ruta_relativa.startswith("evidencias_reglamento/"):
        abort(403)

    base_dir = os.path.abspath(
        os.path.join(current_app.root_path, "static", "evidencias_reglamento")
    )
    archivo_path = os.path.abspath(
        os.path.join(current_app.root_path, "static", ruta_relativa)
    )
    if not archivo_path.startswith(base_dir + os.sep) or not os.path.exists(archivo_path):
        abort(404)

    return send_from_directory(os.path.dirname(archivo_path), os.path.basename(archivo_path))


@reglamento_bp.route("/reunion/<int:reunion_id>/evidencia", methods=["POST"])
@login_required
def subir_evidencia_reunion(reunion_id):
    try:
        if not _usuario_puede_gestionar_reglamento():
            return jsonify({"error": "No autorizado para subir evidencias."}), 403

        reunion, error = _resolver_reunion_autorizada(reunion_id)

        if error:
            return jsonify({"error": error[0]}), error[1]

        if reunion.estado != "pendiente":
            return jsonify({"error": "No se puede subir evidencia a una reunión que ya está cerrada."}), 409

        if "evidencia" not in request.files:
            return jsonify({"error": "No se ha seleccionado ningún archivo para subir."}), 400

        archivo = request.files["evidencia"]
        if archivo.filename == "":
            return jsonify({"error": "No se ha seleccionado ningún archivo para subir."}), 400

        import os

        carpeta = os.path.join(
            current_app.root_path,
            "static",
            "evidencias_reglamento",
            str(reunion.establecimiento_id),
            str(reunion.id)
        )
        try:
            stored_image = save_validated_upload_image(
                archivo,
                carpeta,
                f"reunion_{reunion.id}",
            )
        except ValueError as exc:
            return jsonify({"error": str(exc)}), 400

        filename = stored_image.filename
        ruta_publica = f"evidencias_reglamento/{reunion.establecimiento_id}/{reunion.id}/{filename}"

        resultado_insert = db.session.execute(
            text("""
                INSERT INTO evidencias_reunion_reglamento
                    (reunion_id, filename, ruta_archivo, mime_type, tamano_bytes, descripcion, uploaded_by)
                VALUES
                    (:reunion_id, :filename, :ruta_archivo, :mime_type, :tamano_bytes, :descripcion, :uploaded_by)
            """),
            {
                "reunion_id": reunion.id,
                "filename": filename,
                "ruta_archivo": ruta_publica,
                "mime_type": stored_image.mime_type,
                "tamano_bytes": stored_image.size,
                "descripcion": safe_text(request.form.get("descripcion"), 500) or None,
                "uploaded_by": session.get("user_id"),
            },
        )

        evidencia_id = getattr(resultado_insert, "lastrowid", None)
        db.session.commit()
        foto_url = (
            url_for("reglamento.ver_evidencia_reunion", evidencia_id=evidencia_id)
            if evidencia_id
            else f"/static/{ruta_publica}"
        )

        return jsonify(
            {
                "success": True,
                "message": "Evidencia subida correctamente.",
                "foto": foto_url,
            }
        )

    except Exception:
        db.session.rollback()
        current_app.logger.exception("Error subiendo evidencia para reunión de reglamento")
        return jsonify({"error": "Error interno al subir la evidencia."}), 500
