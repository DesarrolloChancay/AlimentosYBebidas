"""Cliente HTTP para la API de RRHH (consulta de colaborador por DNI).

Contrato: GET {RRHH_API_URL}/{dni} con header X-API-KEY.
Se usa solo al crear/refrescar cuentas de Administrador, Inspector y
Ayudante de Inspector (roles con código de colaborador en RRHH) — nunca
en el login, que se resuelve siempre contra la tabla local `usuarios`.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from typing import Any, Optional

from flask import current_app


class RRHHAPIError(Exception):
    """Error controlado al consumir la API de RRHH."""

    def __init__(self, message: str, status_code: Optional[int] = None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


def _config_auth() -> tuple[str, str, int]:
    base_url = (current_app.config.get("RRHH_API_URL") or "").rstrip("/")
    token = current_app.config.get("RRHH_API_TOKEN") or ""
    timeout = current_app.config.get("RRHH_API_TIMEOUT_SECONDS") or 8

    if not base_url:
        raise RRHHAPIError("RRHH_API_URL no está configurada.", status_code=503)
    if not token:
        raise RRHHAPIError("RRHH_API_TOKEN no está configurado.", status_code=503)
    return base_url, token, timeout


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
        400: "DNI inválido.",
        404: "Colaborador no encontrado en RRHH.",
    }.get(status_code, f"Error HTTP {status_code} al consultar RRHH.")

    if detalle:
        return f"{base} {detalle}"
    return base


def _http_get_json(url: str, token: str, timeout: int) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        headers={
            "X-API-KEY": token,
            "Accept": "application/json",
            "User-Agent": "AlimentosYBebidas/1.0",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw_body = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = ""
        try:
            body = exc.read().decode("utf-8", errors="replace")
        except Exception:
            pass
        raise RRHHAPIError(_mensaje_http_error(exc.code, body), status_code=exc.code) from exc
    except urllib.error.URLError as exc:
        raise RRHHAPIError(
            f"No se pudo conectar con RRHH: {exc.reason}", status_code=503
        ) from exc
    except TimeoutError as exc:
        raise RRHHAPIError("Timeout al consultar RRHH.", status_code=504) from exc

    try:
        payload = json.loads(raw_body) if raw_body else {}
    except json.JSONDecodeError as exc:
        raise RRHHAPIError("Respuesta inválida de RRHH (JSON).", status_code=502) from exc

    if isinstance(payload, dict) and isinstance(payload.get("data"), dict):
        payload = payload["data"]

    if not isinstance(payload, dict):
        raise RRHHAPIError("Respuesta inválida de RRHH.", status_code=502)

    return payload


def _normalizar_payload(payload: dict[str, Any]) -> dict[str, Any]:
    nombre = payload.get("nombres") or payload.get("nombre") or payload.get("first_name") or ""

    apellido = payload.get("apellidos") or payload.get("apellido") or payload.get("last_name")
    if not apellido:
        paterno = payload.get("apellido_paterno") or ""
        materno = payload.get("apellido_materno") or ""
        apellido = f"{paterno} {materno}".strip()

    cod_colab = (
        payload.get("codigo_empleado")
        or payload.get("employee_code")
        or payload.get("codigoEmpleado")
    )

    estado = str(payload.get("estado") or payload.get("estado_laboral") or "").strip().upper()
    if "activo" in payload:
        activo = bool(payload.get("activo"))
    elif estado:
        activo = estado not in {"INACTIVO", "INACTIVE"}
    else:
        activo = True

    return {
        "nombre": str(nombre).strip(),
        "apellido": str(apellido).strip(),
        "cod_colab": str(cod_colab).strip() if cod_colab else None,
        "activo": activo,
    }


def lookup_colaborador_por_dni(dni: str) -> dict[str, Any]:
    """Consulta RRHH por DNI y devuelve {nombre, apellido, cod_colab, activo}."""
    base_url, token, timeout = _config_auth()
    url = f"{base_url}/{dni}"

    payload = _http_get_json(url, token, timeout)
    colaborador = _normalizar_payload(payload)

    if not colaborador["activo"]:
        raise RRHHAPIError("Colaborador inactivo en RRHH.", status_code=403)

    return colaborador
