import base64
import binascii
import hmac
import io
import os
import re
import secrets
import uuid
from dataclasses import dataclass
from pathlib import Path

from flask import current_app, jsonify, request, session
from PIL import Image, ImageOps, UnidentifiedImageError


DEV_SECRET_KEY = "clave-desarrollo-temporal"
CSRF_HEADER_NAME = "X-CSRF-Token"
CSRF_SESSION_KEY = "_csrf_token"
UNSAFE_METHODS = {"POST", "PUT", "PATCH", "DELETE"}
CSRF_EXEMPT_PATHS = {
    "/api/auth/login",
    "/api/auth/login-forzado",
    "/healthz",
}
CSRF_EXEMPT_PREFIXES = (
    "/static/",
    "/socket.io/",
)

ALLOWED_IMAGE_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "avif"}
ALLOWED_PIL_FORMATS = {"JPEG", "PNG", "WEBP", "AVIF"}
MAX_IMAGE_UPLOAD_BYTES = 10 * 1024 * 1024
Image.MAX_IMAGE_PIXELS = 40_000_000


@dataclass(frozen=True)
class StoredImage:
    filename: str
    filepath: str
    size: int
    mime_type: str
    extension: str


def register_security(app):
    app.before_request(validate_csrf_request)
    app.context_processor(_security_context)
    app.after_request(set_security_headers)


def generate_csrf_token():
    token = session.get(CSRF_SESSION_KEY)
    if not token:
        token = secrets.token_urlsafe(32)
        session[CSRF_SESSION_KEY] = token
    return token


def validate_csrf_request():
    if request.method not in UNSAFE_METHODS:
        return None

    path = request.path or ""
    if path in CSRF_EXEMPT_PATHS or path.startswith(CSRF_EXEMPT_PREFIXES):
        return None

    # Public login routes stay open. Authenticated mutations must prove page origin.
    if not session.get("user_id"):
        return None

    expected = session.get(CSRF_SESSION_KEY)
    provided = (
        request.headers.get(CSRF_HEADER_NAME)
        or request.form.get("csrf_token")
        or request.headers.get("X-CSRFToken")
    )

    if not expected or not provided or not hmac.compare_digest(str(expected), str(provided)):
        return jsonify({"error": "Token CSRF invalido o ausente."}), 403

    return None


def _security_context():
    return {"csrf_token": generate_csrf_token()}


def set_security_headers(response):
    response.headers.setdefault("X-Content-Type-Options", "nosniff")
    response.headers.setdefault("X-Frame-Options", "DENY")
    response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
    response.headers.setdefault(
        "Permissions-Policy",
        "camera=(self), microphone=(), geolocation=()",
    )

    csp_report_only = current_app.config.get("CSP_REPORT_ONLY")
    if csp_report_only is None:
        csp_report_only = (
            "default-src 'self'; "
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' "
            "https://cdn.jsdelivr.net https://cdnjs.cloudflare.com https://unpkg.com "
            "https://cdn.tailwindcss.com; "
            "style-src 'self' 'unsafe-inline' https://cdnjs.cloudflare.com; "
            "img-src 'self' data: blob:; "
            "font-src 'self' data: https://cdnjs.cloudflare.com; "
            "connect-src 'self' ws: wss:; "
            "object-src 'none'; "
            "base-uri 'self'; "
            "frame-ancestors 'none'"
        )

    if csp_report_only:
        response.headers.setdefault("Content-Security-Policy-Report-Only", csp_report_only)

    if current_app.config.get("FLASK_ENV") == "production":
        response.headers.setdefault(
            "Strict-Transport-Security",
            "max-age=31536000; includeSubDomains",
        )

    for cookie_name in request.cookies:
        if cookie_name.startswith("inspeccion_form_data_"):
            response.delete_cookie(cookie_name, path="/")

    return response


def safe_text(value, max_length=None):
    if value is None:
        return ""

    text = str(value).replace("\x00", "").strip()
    text = re.sub(r"[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]", "", text)
    if max_length is not None:
        text = text[:max_length]
    return text


def is_allowed_image_filename(filename):
    if not filename or "." not in filename:
        return False
    extension = filename.rsplit(".", 1)[-1].lower()
    return extension in ALLOWED_IMAGE_EXTENSIONS


def decode_base64_image(data_url_or_base64):
    value = safe_text(data_url_or_base64)
    if not value:
        raise ValueError("Imagen vacia.")

    if value.startswith("data:"):
        match = re.match(r"^data:(image/[A-Za-z0-9.+-]+);base64,(.*)$", value, re.DOTALL)
        if not match:
            raise ValueError("Formato de imagen base64 invalido.")
        mime_type = match.group(1).lower()
        if mime_type in {"image/svg+xml", "text/html"}:
            raise ValueError("Tipo de imagen no permitido.")
        value = match.group(2)

    try:
        return base64.b64decode(value, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("Datos base64 invalidos.") from exc


def validate_and_reencode_image_bytes(data, original_filename=None, max_size=MAX_IMAGE_UPLOAD_BYTES):
    if not data:
        raise ValueError("Imagen vacia.")
    if len(data) > max_size:
        raise ValueError("Imagen demasiado grande.")
    if original_filename and not is_allowed_image_filename(original_filename):
        raise ValueError("Extension de imagen no permitida.")

    try:
        with Image.open(io.BytesIO(data)) as probe:
            image_format = probe.format
            if image_format not in ALLOWED_PIL_FORMATS:
                raise ValueError("Contenido de imagen no permitido.")
            probe.verify()

        with Image.open(io.BytesIO(data)) as image:
            image = ImageOps.exif_transpose(image)
            has_alpha = image.mode in {"RGBA", "LA"} or "transparency" in image.info

            output = io.BytesIO()
            if has_alpha:
                image = image.convert("RGBA")
                image.save(output, format="PNG", optimize=True)
                return output.getvalue(), "png", "image/png"

            image = image.convert("RGB")
            image.save(output, format="JPEG", quality=88, optimize=True)
            return output.getvalue(), "jpg", "image/jpeg"
    except (UnidentifiedImageError, OSError) as exc:
        raise ValueError("Archivo de imagen invalido.") from exc


def save_validated_upload_image(file_storage, target_dir, prefix, max_size=MAX_IMAGE_UPLOAD_BYTES):
    if not file_storage or not file_storage.filename:
        raise ValueError("No se envio ningun archivo.")

    data = file_storage.read()
    try:
        file_storage.stream.seek(0)
    except Exception:
        pass

    return save_validated_image_bytes(
        data=data,
        original_filename=file_storage.filename,
        target_dir=target_dir,
        prefix=prefix,
        max_size=max_size,
    )


def save_validated_base64_image(data_url_or_base64, original_filename, target_dir, prefix, max_size=MAX_IMAGE_UPLOAD_BYTES):
    data = decode_base64_image(data_url_or_base64)
    return save_validated_image_bytes(
        data=data,
        original_filename=original_filename,
        target_dir=target_dir,
        prefix=prefix,
        max_size=max_size,
    )


def save_validated_image_bytes(data, original_filename, target_dir, prefix, max_size=MAX_IMAGE_UPLOAD_BYTES):
    sanitized_data, extension, mime_type = validate_and_reencode_image_bytes(
        data,
        original_filename=original_filename,
        max_size=max_size,
    )

    target_path = Path(target_dir).resolve()
    target_path.mkdir(parents=True, exist_ok=True)

    safe_prefix_value = re.sub(r"[^A-Za-z0-9_-]+", "_", safe_text(prefix, 80)).strip("_")
    if not safe_prefix_value:
        safe_prefix_value = "imagen"

    filename = f"{safe_prefix_value}_{uuid.uuid4().hex}.{extension}"
    filepath = target_path / filename
    filepath.write_bytes(sanitized_data)

    return StoredImage(
        filename=filename,
        filepath=str(filepath),
        size=len(sanitized_data),
        mime_type=mime_type,
        extension=extension,
    )
