"""
Descripción: Crear tablas del reglamento usando SQLAlchemy directamente.
Lógica: Crea catálogo base, reuniones, snapshot por reunión y evaluaciones.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.extensions import db
from app.models.Inspecciones_models import (
    ItemReglamentoRestaurante,
    ReunionReglamento,
    ReunionItemReglamento,
    EvaluacionReglamento,
)

app = create_app()

with app.app_context():
    print("Creando tablas del reglamento...")

    ItemReglamentoRestaurante.__table__.create(db.engine, checkfirst=True)
    print("Tabla items_reglamento_restaurante creada")

    ReunionReglamento.__table__.create(db.engine, checkfirst=True)
    print("Tabla reuniones_reglamento creada")

    ReunionItemReglamento.__table__.create(db.engine, checkfirst=True)
    print("Tabla reunion_items_reglamento creada")

    EvaluacionReglamento.__table__.create(db.engine, checkfirst=True)
    print("Tabla evaluaciones_reglamento creada")

    print("\nTablas del reglamento verificadas correctamente.")
