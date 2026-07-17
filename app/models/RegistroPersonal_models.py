from app.extensions import db
from datetime import datetime


class RegistroPersonalDiario(db.Model):
    """Registro real de personal presente un día en un establecimiento.
    Independiente del checklist de inspecciones (Janet lo llena los 7 días de la semana).
    """

    __tablename__ = "registro_personal_diario"

    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    fecha = db.Column(db.Date, nullable=False)
    registrado_por = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    __table_args__ = (
        db.UniqueConstraint(
            "establecimiento_id", "fecha", name="uq_registro_personal_establecimiento_fecha"
        ),
    )

    establecimiento = db.relationship("Establecimiento", backref="registros_personal", lazy=True)
    registrador = db.relationship("Usuario", foreign_keys=[registrado_por], lazy=True)
    detalles = db.relationship(
        "RegistroPersonalDetalle",
        backref="registro",
        lazy=True,
        cascade="all, delete-orphan",
    )


class RegistroPersonalDetalle(db.Model):
    """Un rol asignado dentro de un registro diario (cantidad + nombres libres)."""

    __tablename__ = "registro_personal_detalle"

    id = db.Column(db.Integer, primary_key=True)
    registro_id = db.Column(
        db.Integer, db.ForeignKey("registro_personal_diario.id"), nullable=False
    )
    rol_nombre = db.Column(db.String(100), nullable=False)
    cantidad = db.Column(db.Integer)
    nombres = db.Column(db.Text)
    es_rol_libre = db.Column(db.Boolean, default=False)
    orden = db.Column(db.Integer, default=0)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)


class RolPersonalMinimo(db.Model):
    """Mínimo requerido configurable de personal por rol y día de semana.
    establecimiento_id NULL = plantilla base (referencia global, ej. la hoja de Silvia).
    Liga con el ítem A-19 del Reglamento (no cumplir la programación semanal acordada).
    dia_semana: 0=Lunes .. 6=Domingo.
    """

    __tablename__ = "roles_personal_minimo"

    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(db.Integer, db.ForeignKey("establecimientos.id"))
    rol_nombre = db.Column(db.String(100), nullable=False)
    dia_semana = db.Column(db.SmallInteger, nullable=False)
    cantidad_minima = db.Column(db.Integer, nullable=False, default=0)
    opcional = db.Column(db.Boolean, default=False)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    __table_args__ = (
        db.UniqueConstraint(
            "establecimiento_id",
            "rol_nombre",
            "dia_semana",
            name="uq_roles_personal_minimo_establecimiento_rol_dia",
        ),
    )

    establecimiento = db.relationship("Establecimiento", backref="roles_personal_minimo", lazy=True)
