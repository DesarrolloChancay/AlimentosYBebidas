"""
Modelos para el sistema de plantillas de checklists
"""
from app.extensions import db
from datetime import datetime


class PlantillaChecklist(db.Model):
    """
    Modelo para las plantillas de checklist de establecimientos
    """
    __tablename__ = "plantillas_checklist"

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(150), nullable=False)
    descripcion = db.Column(db.Text)
    tipo_establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("tipos_establecimiento.id")
    )
    tamano_local = db.Column(
        db.Enum("pequeno", "mediano", "grande"), default="mediano"
    )
    tipo_restaurante = db.Column(db.String(100))
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relaciones
    tipo_establecimiento = db.relationship(
        "TipoEstablecimiento", backref="plantillas_checklist", lazy=True
    )
    items_plantilla = db.relationship(
        "ItemPlantillaChecklist", backref="plantilla", lazy=True, cascade="all, delete-orphan"
    )

    # Índice único para evitar duplicados
    __table_args__ = (
        db.UniqueConstraint('nombre', 'tipo_establecimiento_id', 'tamano_local',
                          name='unique_plantilla'),
    )

    def __repr__(self):
        return f"<PlantillaChecklist {self.nombre}>"


class ItemPlantillaChecklist(db.Model):
    """
    Modelo para los items de una plantilla de checklist
    """
    __tablename__ = "items_plantilla_checklist"

    id = db.Column(db.Integer, primary_key=True)
    plantilla_id = db.Column(
        db.Integer, db.ForeignKey("plantillas_checklist.id"), nullable=False
    )
    item_base_id = db.Column(
        db.Integer, db.ForeignKey("items_evaluacion_base.id"), nullable=False
    )
    descripcion_personalizada = db.Column(db.Text)
    factor_ajuste = db.Column(db.Numeric(3, 2), default=1.00)
    riesgo_personalizado = db.Column(db.String(20))  # Permite override del riesgo base
    puntaje_minimo_personalizado = db.Column(db.Integer)  # Permite override del puntaje mínimo base
    puntaje_maximo_personalizado = db.Column(db.Integer)  # Permite override del puntaje máximo base
    obligatorio = db.Column(db.Boolean, default=True)
    orden = db.Column(db.Integer, default=0)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relaciones
    item_base = db.relationship("ItemEvaluacionBase", backref="items_plantilla", lazy=True)

    # Índice único para evitar duplicados
    __table_args__ = (
        db.UniqueConstraint('plantilla_id', 'item_base_id', name='unique_item_plantilla'),
    )

    @property
    def riesgo(self):
        """Retorna el riesgo personalizado si existe, sino el del item base"""
        return self.riesgo_personalizado if self.riesgo_personalizado else self.item_base.riesgo

    @property
    def puntaje_minimo(self):
        """Retorna el puntaje mínimo personalizado si existe, sino el del item base"""
        return self.puntaje_minimo_personalizado if self.puntaje_minimo_personalizado is not None else self.item_base.puntaje_minimo

    @property
    def puntaje_maximo(self):
        """Retorna el puntaje máximo personalizado si existe, sino el del item base"""
        return self.puntaje_maximo_personalizado if self.puntaje_maximo_personalizado is not None else self.item_base.puntaje_maximo

    def __repr__(self):
        return f"<ItemPlantillaChecklist plantilla={self.plantilla_id} item={self.item_base_id}>"