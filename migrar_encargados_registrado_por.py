"""Agrega auditoría de registro para encargados por establecimiento."""

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

from app.config import Config

load_dotenv()


def obtener_engine():
    return create_engine(make_url(Config.SQLALCHEMY_DATABASE_URI), future=True)


def columna_existe(inspector, tabla, columna):
    return any(columna_info["name"] == columna for columna_info in inspector.get_columns(tabla))


def fk_existe(inspector, tabla, columna):
    return any(
        columna in (fk.get("constrained_columns") or [])
        for fk in inspector.get_foreign_keys(tabla)
    )


def indice_existe(conn, tabla, indice):
    fila = conn.execute(
        text(f"SHOW INDEX FROM {tabla} WHERE Key_name = :indice"),
        {"indice": indice},
    ).first()
    return fila is not None


def main():
    engine = obtener_engine()
    if not engine.url.drivername.startswith("mysql"):
        raise RuntimeError(
            f"Esta migración está preparada para MySQL. Base detectada: {engine.url.drivername}"
        )

    with engine.begin() as conn:
        inspector = inspect(conn)

        if not columna_existe(inspector, "encargados_establecimientos", "registrado_por"):
            conn.execute(
                text(
                    """
                    ALTER TABLE encargados_establecimientos
                    ADD COLUMN registrado_por INT NULL AFTER habilitado_por
                    """
                )
            )
            print("✅ Columna registrado_por agregada en encargados_establecimientos")
            inspector = inspect(conn)
        else:
            print("ℹ️ La columna registrado_por ya existe")

        if not indice_existe(
            conn,
            "encargados_establecimientos",
            "idx_encargados_establecimientos_registrado_por",
        ):
            conn.execute(
                text(
                    """
                    CREATE INDEX idx_encargados_establecimientos_registrado_por
                    ON encargados_establecimientos (registrado_por)
                    """
                )
            )
            print("✅ Índice creado para registrado_por")
        else:
            print("ℹ️ El índice de registrado_por ya existe")

        inspector = inspect(conn)
        if not fk_existe(inspector, "encargados_establecimientos", "registrado_por"):
            conn.execute(
                text(
                    """
                    ALTER TABLE encargados_establecimientos
                    ADD CONSTRAINT fk_encargados_establecimientos_registrado_por
                    FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
                    """
                )
            )
            print("✅ Llave foránea creada para registrado_por")
        else:
            print("ℹ️ La llave foránea de registrado_por ya existe")

    print("✅ Migración completada correctamente")


if __name__ == "__main__":
    main()
