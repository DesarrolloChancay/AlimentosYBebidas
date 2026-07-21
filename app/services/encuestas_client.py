"""Cliente HTTP para la API de Encuestas (Laravel).

Resolución de survey_id: coincidencia por nombre normalizado
(establecimiento.nombre AyB ↔ surveys.title Encuestas, status=active).
"""

from __future__ import annotations

import json
import re
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Optional

from flask import current_app


class EncuestasAPIError(Exception):
    """Error controlado al consumir la API de Encuestas."""

    def __init__(self, message: str, status_code: Optional[int] = None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


# Código reglamento AyB → campo metrics de compliance-metrics
METRICAS_REGLAMENTO_ENCUESTAS = {
    "A-05": "satisfaction_pct",
    "A-06": "recommendation_pct",
    "A-07": "negative_comments_weekday",
    "A-08": "negative_comments_weekend",
}

# % que pueden venir null (sin datos esa semana)
METRICAS_OPCIONALES_NULL = {"satisfaction_pct", "recommendation_pct"}

# Prefijos/ruido frecuente en titles de Encuestas
_PREFIJOS_RUIDO = (
    "restaurante",
    "rest.",
    "rest",
    "local",
    "estab.",
    "establecimiento",
)


def normalizar_nombre_establecimiento(texto: Optional[str]) -> str:
    """Normaliza nombre/title para match: minúsculas, sin tildes, sin ruido."""
    if not texto:
        return ""

    valor = unicodedata.normalize("NFKD", str(texto))
    valor = "".join(ch for ch in valor if not unicodedata.combining(ch))
    valor = valor.lower().strip()
    valor = re.sub(r"[^\w\s]", " ", valor, flags=re.UNICODE)
    valor = re.sub(r"\s+", " ", valor).strip()

    for prefijo in _PREFIJOS_RUIDO:
        if valor.startswith(prefijo + " "):
            valor = valor[len(prefijo) + 1 :].strip()
            break

    return valor


def _config_auth() -> tuple[str, str, int]:
    base_url = (current_app.config.get("ENCUESTAS_API_URL") or "").rstrip("/")
    token = current_app.config.get("ENCUESTAS_API_TOKEN") or ""
    timeout = current_app.config.get("ENCUESTAS_TIMEOUT_SECONDS") or 15

    if not base_url:
        raise EncuestasAPIError(
            "ENCUESTAS_API_URL no está configurada.", status_code=500
        )
    if not token:
        raise EncuestasAPIError(
            "ENCUESTAS_API_TOKEN no está configurado.", status_code=500
        )
    return base_url, token, timeout


def _http_get_json(url: str, token: str, timeout: int) -> tuple[dict[str, Any], int]:
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw_body = response.read().decode("utf-8")
            status = getattr(response, "status", 200)
    except urllib.error.HTTPError as exc:
        body = ""
        try:
            body = exc.read().decode("utf-8", errors="replace")
        except Exception:
            pass
        raise EncuestasAPIError(
            _mensaje_http_error(exc.code, body), status_code=exc.code
        ) from exc
    except urllib.error.URLError as exc:
        raise EncuestasAPIError(
            f"No se pudo conectar con Encuestas: {exc.reason}",
            status_code=503,
        ) from exc
    except TimeoutError as exc:
        raise EncuestasAPIError(
            "Timeout al consultar Encuestas.", status_code=504
        ) from exc

    try:
        payload = json.loads(raw_body) if raw_body else {}
    except json.JSONDecodeError as exc:
        raise EncuestasAPIError(
            "Respuesta inválida de Encuestas (JSON).", status_code=502
        ) from exc

    if not isinstance(payload, dict):
        raise EncuestasAPIError(
            "Respuesta inválida de Encuestas.", status_code=502
        )

    if payload.get("success") is False:
        error_msg = payload.get("error") or "La API de Encuestas devolvió error."
        if isinstance(error_msg, dict):
            error_msg = error_msg.get("message") or str(error_msg)
        raise EncuestasAPIError(str(error_msg), status_code=status or 400)

    return payload, status


def list_active_surveys() -> list[dict[str, Any]]:
    """
    GET /surveys?status=active

    Espera data: [{ "id": 3, "title": "Restaurante Silvia", "status": "active" }, ...]
    """
    base_url, token, timeout = _config_auth()
    query = urllib.parse.urlencode({"status": "active"})
    url = f"{base_url}/surveys?{query}"

    payload, _status = _http_get_json(url, token, timeout)
    data = payload.get("data")

    # Soporta data: [...] o data: { "surveys": [...] }
    if isinstance(data, dict):
        data = data.get("surveys") or data.get("items") or []

    if not isinstance(data, list):
        raise EncuestasAPIError(
            "La respuesta de /surveys no incluye una lista en data.",
            status_code=502,
        )

    surveys = []
    for row in data:
        if not isinstance(row, dict):
            continue
        survey_id = row.get("id")
        title = row.get("title") or row.get("name") or ""
        try:
            survey_id = int(survey_id)
        except (TypeError, ValueError):
            continue
        surveys.append(
            {
                "id": survey_id,
                "title": str(title),
                "status": (row.get("status") or "").strip().lower(),
            }
        )
    return surveys


def match_survey_id_por_nombre(nombre_ayb: str, surveys: list[dict[str, Any]]) -> Optional[int]:
    """
    Empareja nombre AyB con title Encuestas (normalizado).

    Prioridad:
    1) igualdad exacta normalizada
    2) uno contiene al otro (silvia ⊂ restaurante silvia)
    Si hay varios candidatos en el mismo nivel → None (ambiguo).
    """
    clave = normalizar_nombre_establecimiento(nombre_ayb)
    if not clave:
        return None

    exactos = []
    contenidos = []

    for survey in surveys:
        titulo_norm = normalizar_nombre_establecimiento(survey.get("title"))
        if not titulo_norm:
            continue
        if titulo_norm == clave:
            exactos.append(survey["id"])
        elif clave in titulo_norm or titulo_norm in clave:
            contenidos.append(survey["id"])

    if len(exactos) == 1:
        return exactos[0]
    if len(exactos) > 1:
        current_app.logger.warning(
            "Match ambiguo (exacto) Encuestas para '%s': %s", nombre_ayb, exactos
        )
        return None

    unicos_contenido = list(dict.fromkeys(contenidos))
    if len(unicos_contenido) == 1:
        return unicos_contenido[0]
    if len(unicos_contenido) > 1:
        current_app.logger.warning(
            "Match ambiguo (contiene) Encuestas para '%s': %s",
            nombre_ayb,
            unicos_contenido,
        )
        return None

    return None


def resolve_survey_id(establecimiento) -> Optional[int]:
    """
    Resuelve survey_id Encuestas por nombre normalizado del establecimiento AyB.

    Override opcional: ENCUESTAS_SURVEY_MAP (id o nombre → survey_id).
    """
    mapping = current_app.config.get("ENCUESTAS_SURVEY_MAP") or {}

    est_id = str(getattr(establecimiento, "id", "") or "").strip()
    if est_id and est_id in mapping:
        return mapping[est_id]

    nombre = (getattr(establecimiento, "nombre", None) or "").strip()
    nombre_key = nombre.lower()
    if nombre_key and nombre_key in mapping:
        return mapping[nombre_key]

    if not nombre:
        return None

    surveys = list_active_surveys()
    return match_survey_id_por_nombre(nombre, surveys)


def get_compliance_metrics(survey_id: int, week_start: str, week_end: str) -> dict[str, Any]:
    """
    GET /restaurants/{survey_id}/compliance-metrics

    Returns:
        dict con las métricas (satisfaction_pct, recommendation_pct, ...).
    """
    base_url, token, timeout = _config_auth()

    query = urllib.parse.urlencode(
        {"week_start": week_start, "week_end": week_end}
    )
    url = f"{base_url}/restaurants/{int(survey_id)}/compliance-metrics?{query}"

    payload, _status = _http_get_json(url, token, timeout)
    data = payload.get("data") or {}
    metrics = data.get("metrics")
    if not isinstance(metrics, dict):
        raise EncuestasAPIError(
            "La respuesta de Encuestas no incluye metrics.", status_code=502
        )

    return metrics


def mapear_metricas_a_items(metrics: dict[str, Any]) -> dict[str, Any]:
    """
    Convierte metrics API → {codigo: {campo, valor, sin_datos}}.

    valor es int|None. sin_datos=True si % llegó null.
    """
    resultado = {}
    for codigo, campo in METRICAS_REGLAMENTO_ENCUESTAS.items():
        crudo = metrics.get(campo, None)
        sin_datos = campo in METRICAS_OPCIONALES_NULL and crudo is None
        valor = None if crudo is None else int(crudo)
        resultado[codigo] = {
            "campo": campo,
            "valor": valor,
            "sin_datos": sin_datos,
        }
    return resultado


def _mensaje_http_error(status_code: int, body: str) -> str:
    detalle = ""
    if body:
        try:
            parsed = json.loads(body)
            if isinstance(parsed, dict):
                err = parsed.get("error") or parsed.get("message")
                if isinstance(err, dict):
                    detalle = err.get("message") or str(err)
                elif err:
                    detalle = str(err)
        except Exception:
            detalle = body[:200]

    base = {
        401: "Token de Encuestas inválido o expirado (401).",
        403: "Sin permiso para consultar Encuestas (403).",
        404: "Recurso no encontrado en Encuestas (404).",
        422: "Parámetros inválidos para Encuestas (422).",
    }.get(status_code, f"Error HTTP {status_code} al consultar Encuestas.")

    if detalle:
        return f"{base} {detalle}"
    return base
