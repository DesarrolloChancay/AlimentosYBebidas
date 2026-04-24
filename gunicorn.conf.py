import os


bind = os.getenv("GUNICORN_BIND", "127.0.0.1:5060")
workers = int(os.getenv("GUNICORN_WORKERS", "1"))
threads = int(os.getenv("GUNICORN_THREADS", "100"))
worker_class = os.getenv("GUNICORN_WORKER_CLASS", "gthread")
timeout = int(os.getenv("GUNICORN_TIMEOUT", "120"))
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL_TIMEOUT", "30"))
keepalive = int(os.getenv("GUNICORN_KEEPALIVE", "5"))
accesslog = os.getenv("GUNICORN_ACCESSLOG", "-")
errorlog = os.getenv("GUNICORN_ERRORLOG", "-")
loglevel = os.getenv("GUNICORN_LOG_LEVEL", "info")
capture_output = True
limit_request_line = int(os.getenv("GUNICORN_LIMIT_REQUEST_LINE", "8190"))
limit_request_fields = int(os.getenv("GUNICORN_LIMIT_REQUEST_FIELDS", "100"))
limit_request_field_size = int(os.getenv("GUNICORN_LIMIT_REQUEST_FIELD_SIZE", "32768"))


if workers != 1 and not os.getenv("SOCKETIO_MESSAGE_QUEUE"):
    raise RuntimeError(
        "GUNICORN_WORKERS debe permanecer en 1 mientras Socket.IO use estado en memoria. "
        "Para múltiples workers necesitas sticky sessions y SOCKETIO_MESSAGE_QUEUE."
    )
