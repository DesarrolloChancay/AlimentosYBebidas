"""Migra el esquema del reglamento para soportar items configurables y snapshot por reunión."""

from sqlalchemy import inspect, text

from app import create_app
from app.extensions import db
from app.models.Inspecciones_models import ReunionItemReglamento

COLUMNAS_ITEMS = {
    "establecimiento_id": "INTEGER",
    "alcance": "VARCHAR(20)",
    "tipo_vigencia": "VARCHAR(20)",
    "fecha_fin_vigencia": "DATE",
    "reunion_origen_id": "INTEGER",
    "created_by_user_id": "INTEGER",
    "updated_at": "TIMESTAMP",
}

COLUMNAS_REUNION_ITEMS = {
    "fecha_fin_vigencia": "DATE",
}

COLUMNAS_EVALUACIONES = {
    "reunion_item_id": "INTEGER",
}


def agregar_columna_si_falta(tabla, columna, ddl_tipo):
    inspector = inspect(db.engine)
    existentes = {col["name"] for col in inspector.get_columns(tabla)}
    if columna in existentes:
        print(f"- {tabla}.{columna}: ya existe")
        return

    sql = text(f"ALTER TABLE {tabla} ADD COLUMN {columna} {ddl_tipo}")
    db.session.execute(sql)
    db.session.commit()
    print(f"- {tabla}.{columna}: creada")


app = create_app()

with app.app_context():
    print("Migrando reglamento configurable...")

    for columna, ddl_tipo in COLUMNAS_ITEMS.items():
        agregar_columna_si_falta("items_reglamento_restaurante", columna, ddl_tipo)

    for columna, ddl_tipo in COLUMNAS_EVALUACIONES.items():
        agregar_columna_si_falta("evaluaciones_reglamento", columna, ddl_tipo)

    ReunionItemReglamento.__table__.create(db.engine, checkfirst=True)
    for columna, ddl_tipo in COLUMNAS_REUNION_ITEMS.items():
        agregar_columna_si_falta("reunion_items_reglamento", columna, ddl_tipo)
    print("- reunion_items_reglamento: verificada")

    db.session.execute(
        text(
            "UPDATE items_reglamento_restaurante SET alcance = 'global' WHERE alcance IS NULL OR TRIM(alcance) = ''"
        )
    )
    db.session.execute(
        text(
            "UPDATE items_reglamento_restaurante SET tipo_vigencia = 'permanente' WHERE tipo_vigencia IS NULL OR TRIM(tipo_vigencia) = ''"
        )
    )
    db.session.execute(
        text(
            "UPDATE items_reglamento_restaurante SET alcance = LOWER(TRIM(alcance)) WHERE alcance IS NOT NULL AND TRIM(alcance) <> ''"
        )
    )
    db.session.execute(
        text(
            "UPDATE items_reglamento_restaurante SET tipo_vigencia = LOWER(TRIM(tipo_vigencia)) WHERE tipo_vigencia IS NOT NULL AND TRIM(tipo_vigencia) <> ''"
        )
    )

    sincronizados = 0
    for snapshot in ReunionItemReglamento.query.filter(
        ReunionItemReglamento.fecha_fin_vigencia.is_(None),
        ReunionItemReglamento.tipo_vigencia == 'temporal',
    ).all():
        if snapshot.item and snapshot.item.fecha_fin_vigencia:
            snapshot.fecha_fin_vigencia = snapshot.item.fecha_fin_vigencia
            sincronizados += 1

    db.session.commit()
    print(f"- reunion_items_reglamento.fecha_fin_vigencia: sincronizados {sincronizados} registros")

    print("Migración finalizada.")
