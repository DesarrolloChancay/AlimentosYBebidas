"""Utilidades para guardar firmas dibujadas en canvas."""

import os
from datetime import datetime

from flask import current_app

from app.utils.media import (
    private_signature_dir,
    signature_db_path,
    normalize_signature_reference,
)
from app.utils.security import save_validated_base64_image


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
    """Guarda una firma en formato data URL y devuelve su referencia privada."""
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

    safe_segments = [
        sanitize_signature_segment(segment)
        for segment in (directory_segments or [])
    ]
    upload_folder = private_signature_dir(*safe_segments)

    safe_prefix = sanitize_signature_segment(filename_prefix, "firma")
    safe_subject = sanitize_signature_segment(str(subject_id), "usuario")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    stored_image = save_validated_base64_image(
        signature_data,
        f"{safe_prefix}.{extension}",
        upload_folder,
        f"{safe_prefix}_{safe_subject}_{timestamp}",
        max_size=MAX_SIGNATURE_BYTES,
    )

    return signature_db_path(*safe_segments, stored_image.filename)


def delete_static_file(relative_path):
    """Elimina una firma privada o un archivo legado dentro de app/static."""
    if not relative_path:
        return

    normalized_path = normalize_signature_reference(relative_path)
    if not normalized_path or normalized_path.startswith("data:image/"):
        return

    if normalized_path.startswith("firmas/"):
        private_root = os.path.abspath(current_app.config["PRIVATE_UPLOAD_ROOT"])
        absolute_path = os.path.abspath(
            os.path.join(private_root, *normalized_path.split("/"))
        )
        allowed_root = private_root
    else:
        if normalized_path.startswith("static/firmas/"):
            normalized_path = normalized_path[len("static/"):]
        static_root = os.path.abspath(current_app.static_folder)
        absolute_path = os.path.abspath(
            os.path.join(static_root, *normalized_path.split("/"))
        )
        allowed_root = static_root

    if absolute_path != allowed_root and not absolute_path.startswith(allowed_root + os.sep):
        return

    if os.path.exists(absolute_path):
        os.remove(absolute_path)
