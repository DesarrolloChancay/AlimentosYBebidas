"""Helpers para archivos privados servidos por rutas autenticadas."""

import os

from flask import current_app, url_for


SIGNATURE_ROUTE_PREFIX = "/media/firmas/"
SIGNATURE_DB_PREFIX = "firmas/"
LEGACY_STATIC_SIGNATURE_PREFIX = "img/firmas/"
LEGACY_STATIC_INSPECTION_PREFIX = "static/firmas/"
ALLOWED_SIGNATURE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


def private_upload_root():
    return os.path.abspath(current_app.config["PRIVATE_UPLOAD_ROOT"])


def private_signature_dir(*segments):
    safe_segments = [segment for segment in segments if segment]
    path = os.path.join(private_upload_root(), "firmas", *safe_segments)
    os.makedirs(path, exist_ok=True)
    return path


def signature_db_path(*segments):
    clean_segments = [
        str(segment).replace("\\", "/").strip("/")
        for segment in segments
        if segment
    ]
    return "/".join([SIGNATURE_DB_PREFIX.rstrip("/"), *clean_segments])


def _strip_query_and_fragment(value):
    return value.split("?", 1)[0].split("#", 1)[0]


def _reject_unsafe_reference(value):
    lowered = value.lower()
    if lowered.startswith(("http://", "https://", "blob:", "javascript:")):
        return True
    if "\x00" in value:
        return True
    return False


def normalize_signature_reference(value):
    """Normaliza rutas de firma nuevas y legadas al valor que se guarda en BD."""
    if not value or not isinstance(value, str):
        return None

    raw = _strip_query_and_fragment(value.strip().replace("\\", "/"))
    if raw.startswith("data:image/"):
        return raw
    if _reject_unsafe_reference(raw):
        return None

    cleaned = raw.lstrip("/")

    if cleaned.startswith("media/firmas/"):
        route_path = cleaned[len("media/firmas/"):]
        if route_path.startswith(LEGACY_STATIC_SIGNATURE_PREFIX):
            return route_path
        if route_path.startswith(LEGACY_STATIC_INSPECTION_PREFIX):
            return route_path
        if route_path.startswith(SIGNATURE_DB_PREFIX):
            return route_path
        return signature_db_path(route_path)

    if cleaned.startswith("static/img/firmas/"):
        return cleaned[len("static/"):]
    if cleaned.startswith("static/firmas/"):
        return cleaned
    if cleaned.startswith((SIGNATURE_DB_PREFIX, LEGACY_STATIC_SIGNATURE_PREFIX, LEGACY_STATIC_INSPECTION_PREFIX)):
        return cleaned

    if ".." in cleaned.split("/"):
        return None

    return cleaned


def signature_route_path(value):
    normalized = normalize_signature_reference(value)
    if not normalized or normalized.startswith("data:image/"):
        return None
    if normalized.startswith(SIGNATURE_DB_PREFIX):
        return normalized[len(SIGNATURE_DB_PREFIX):]
    return normalized


def signature_public_url(value):
    if not value:
        return None
    if isinstance(value, str) and value.startswith("data:image/"):
        return value

    route_path = signature_route_path(value)
    if not route_path:
        return None
    return url_for("media.servir_firma", filename=route_path)


def signature_reference_candidates(route_filename):
    route_path = _strip_query_and_fragment(
        (route_filename or "").replace("\\", "/").strip("/")
    )
    if not route_path or ".." in route_path.split("/"):
        return []

    candidates = {
        route_path,
        f"{SIGNATURE_ROUTE_PREFIX}{route_path}",
        f"media/firmas/{route_path}",
    }

    if route_path.startswith(LEGACY_STATIC_SIGNATURE_PREFIX):
        candidates.add(route_path)
        candidates.add(f"/static/{route_path}")
        candidates.add(f"static/{route_path}")
    elif route_path.startswith(LEGACY_STATIC_INSPECTION_PREFIX):
        candidates.add(route_path)
        candidates.add(f"/{route_path}")
        candidates.add(route_path[len("static/"):])
    elif route_path.startswith(SIGNATURE_DB_PREFIX):
        candidates.add(route_path)
        candidates.add(route_path[len(SIGNATURE_DB_PREFIX):])
    else:
        candidates.add(signature_db_path(route_path))

    return [candidate for candidate in candidates if candidate]


def resolve_signature_file_path(route_filename):
    route_path = _strip_query_and_fragment(
        (route_filename or "").replace("\\", "/").strip("/")
    )
    if not route_path or ".." in route_path.split("/"):
        return None

    extension = os.path.splitext(route_path)[1].lower()
    if extension not in ALLOWED_SIGNATURE_EXTENSIONS:
        return None

    static_root = os.path.abspath(current_app.static_folder)
    private_root = os.path.abspath(os.path.join(private_upload_root(), "firmas"))

    if route_path.startswith(LEGACY_STATIC_SIGNATURE_PREFIX):
        absolute_path = os.path.abspath(os.path.join(static_root, *route_path.split("/")))
        allowed_root = static_root
    elif route_path.startswith(LEGACY_STATIC_INSPECTION_PREFIX):
        legacy_path = route_path[len("static/"):]
        absolute_path = os.path.abspath(os.path.join(static_root, *legacy_path.split("/")))
        allowed_root = static_root
    elif route_path.startswith(SIGNATURE_DB_PREFIX):
        private_path = route_path[len(SIGNATURE_DB_PREFIX):]
        absolute_path = os.path.abspath(os.path.join(private_root, *private_path.split("/")))
        allowed_root = private_root
    else:
        absolute_path = os.path.abspath(os.path.join(private_root, *route_path.split("/")))
        allowed_root = private_root

    if absolute_path != allowed_root and not absolute_path.startswith(allowed_root + os.sep):
        return None

    if not os.path.isfile(absolute_path):
        return None
    return absolute_path
