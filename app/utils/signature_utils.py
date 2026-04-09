"""Utilidades para guardar firmas dibujadas en canvas."""

import base64
import binascii
import os
import uuid
from datetime import datetime


MAX_SIGNATURE_BYTES = 2 * 1024 * 1024
SIGNATURE_MIME_EXTENSIONS = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
}


def _matches_signature_mime(mime_type, image_bytes):
    if mime_type == "image/png":
        return image_bytes.startswith(b"\x89PNG\r\n\x1a\n")
    if mime_type in ("image/jpeg", "image/jpg"):
        return image_bytes.startswith(b"\xff\xd8")
    return False


def sanitize_signature_segment(value, default="general"):
    """Devuelve un segmento seguro para rutas de firmas."""
    cleaned = "".join(
        char for char in (value or "") if char.isalnum() or char in (" ", "-", "_")
    ).strip()
    cleaned = cleaned.replace(" ", "_")
    return cleaned or default


def save_signature_data_url(
    signature_data,
    *,
    directory_segments=None,
    filename_prefix="firma",
    subject_id=None,
):
    """Guarda una firma en formato data URL y devuelve su ruta relativa a static."""
    if not signature_data or not isinstance(signature_data, str):
        raise ValueError("No se recibio la firma")

    if "," not in signature_data:
        raise ValueError("Formato de firma invalido")

    header, encoded_data = signature_data.split(",", 1)
    if not header.startswith("data:image/") or ";base64" not in header:
        raise ValueError("Formato de firma no permitido")

    mime_type = header[5:].split(";", 1)[0].lower()
    extension = SIGNATURE_MIME_EXTENSIONS.get(mime_type)
    if not extension:
        raise ValueError("Formato de firma no permitido")

    try:
        image_bytes = base64.b64decode(encoded_data, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("La firma no es una imagen valida") from exc

    if not image_bytes:
        raise ValueError("La firma esta vacia")

    if not _matches_signature_mime(mime_type, image_bytes):
        raise ValueError("La firma no coincide con el formato declarado")

    if len(image_bytes) > MAX_SIGNATURE_BYTES:
        raise ValueError("La firma supera el tamano maximo permitido")

    safe_segments = [
        sanitize_signature_segment(segment)
        for segment in (directory_segments or [])
    ]
    upload_folder = os.path.join("app", "static", "img", "firmas", *safe_segments)
    os.makedirs(upload_folder, exist_ok=True)

    safe_prefix = sanitize_signature_segment(filename_prefix, "firma")
    safe_subject = sanitize_signature_segment(str(subject_id), "usuario")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_suffix = uuid.uuid4().hex[:8]
    filename = f"{safe_prefix}_{safe_subject}_{timestamp}_{unique_suffix}.{extension}"

    filepath = os.path.join(upload_folder, filename)
    with open(filepath, "wb") as image_file:
        image_file.write(image_bytes)

    relative_parts = ["img", "firmas", *safe_segments, filename]
    return "/".join(relative_parts)


def delete_static_file(relative_path):
    """Elimina un archivo dentro de app/static si existe."""
    if not relative_path:
        return

    normalized_path = relative_path.replace("\\", "/").strip()
    if normalized_path.startswith("/static/"):
        normalized_path = normalized_path[len("/static/"):]
    normalized_path = normalized_path.lstrip("/")

    static_root = os.path.abspath(os.path.join("app", "static"))
    absolute_path = os.path.abspath(os.path.join(static_root, *normalized_path.split("/")))

    if not absolute_path.startswith(static_root + os.sep):
        return

    if os.path.exists(absolute_path):
        os.remove(absolute_path)
