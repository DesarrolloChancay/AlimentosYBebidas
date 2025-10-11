from app.extensions import db
from datetime import datetime


class InspectorEstablecimiento(db.Model):
    __tablename__ = "inspector_establecimientos"
    id = db.Column(db.Integer, primary_key=True)
    inspector_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    fecha_asignacion = db.Column(db.Date, nullable=False)
    fecha_fin_asignacion = db.Column(db.Date)
    es_principal = db.Column(db.Boolean, default=False)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)


class Establecimiento(db.Model):
    __tablename__ = "establecimientos"
    id = db.Column(db.Integer, primary_key=True)
    tipo_establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("tipos_establecimiento.id")
    )
    nombre = db.Column(db.String(150), nullable=False)
    direccion = db.Column(db.String(255))
    telefono = db.Column(db.String(30))
    correo = db.Column(db.String(150))
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relaciones usando strings para evitar importaciones circulares
    tipo_establecimiento = db.relationship(
        "TipoEstablecimiento", backref="establecimientos", lazy=True
    )
    encargados = db.relationship(
        "EncargadoEstablecimiento", backref="establecimiento", lazy=True
    )
    items_evaluacion = db.relationship(
        "ItemEvaluacionEstablecimiento", backref="establecimiento", lazy=True
    )
    inspecciones = db.relationship("Inspeccion", backref="establecimiento", lazy=True)


class EncargadoEstablecimiento(db.Model):
    __tablename__ = "encargados_establecimientos"
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    fecha_inicio = db.Column(db.Date, nullable=False)
    fecha_fin = db.Column(db.Date)
    es_principal = db.Column(db.Boolean, default=False)
    comentario = db.Column(db.String(255))
    activo = db.Column(db.Boolean, default=True)
    habilitado_por = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    fecha_habilitacion = db.Column(db.TIMESTAMP)
    observaciones_jefe = db.Column(db.Text)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relación usando string para evitar importaciones circulares
    usuario = db.relationship("Usuario", foreign_keys=[usuario_id], backref="encargos", lazy=True)


class JefeEstablecimiento(db.Model):
    __tablename__ = "jefes_establecimientos"
    id = db.Column(db.Integer, primary_key=True)
    usuario_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    fecha_inicio = db.Column(db.Date, nullable=False)
    fecha_fin = db.Column(db.Date)
    es_principal = db.Column(db.Boolean, default=True)
    comentario = db.Column(db.String(255))
    activo = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relaciones
    usuario = db.relationship("Usuario", backref="jefes_asignados", lazy=True)
    establecimiento = db.relationship("Establecimiento", backref="jefes_asignados_establecimiento", lazy=True)


class FirmaEncargadoPorJefe(db.Model):
    __tablename__ = "firmas_encargados_por_jefe"
    id = db.Column(db.Integer, primary_key=True)
    jefe_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    encargado_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    path_firma = db.Column(db.String(250))
    fecha_firma = db.Column(db.TIMESTAMP, default=datetime.utcnow, nullable=False)
    activa = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relaciones - Evitando conflictos de nombres con backrefs únicos
    jefe = db.relationship("Usuario", foreign_keys=[jefe_id], backref="firmas_creadas", lazy=True)
    encargado = db.relationship("Usuario", foreign_keys=[encargado_id], backref="firmas_recibidas", lazy=True)
    establecimiento = db.relationship("Establecimiento", backref="firmas_encargados", lazy=True)


class PlanSemanal(db.Model):
    __tablename__ = "plan_semanal"
    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    semana = db.Column(db.Integer, nullable=False)
    ano = db.Column(db.Integer, nullable=False)
    evaluaciones_meta = db.Column(db.Integer, default=3)
    evaluaciones_realizadas = db.Column(db.Integer, default=0)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relaciones
    establecimiento = db.relationship("Establecimiento", backref="planes_semanales", lazy=True)

    # Índice único para evitar duplicados por establecimiento/semana/año
    __table_args__ = (
        db.UniqueConstraint('establecimiento_id', 'semana', 'ano', name='unique_plan_semanal'),
    )


class ConfiguracionEvaluacion(db.Model):
    __tablename__ = "configuracion_evaluaciones"
    id = db.Column(db.Integer, primary_key=True)
    clave = db.Column(db.String(100), nullable=False, unique=True)
    valor = db.Column(db.String(255), nullable=False)
    descripcion = db.Column(db.Text)
    modificable_por_inspector = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)


class CategoriaEvaluacion(db.Model):
    __tablename__ = "categorias_evaluacion"
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(150), nullable=False)
    descripcion = db.Column(db.Text)
    orden = db.Column(db.Integer, default=0)
    activo = db.Column(db.Boolean, default=True)
    items_base = db.relationship("ItemEvaluacionBase", backref="categoria", lazy=True)


class ItemEvaluacionBase(db.Model):
    __tablename__ = "items_evaluacion_base"
    id = db.Column(db.Integer, primary_key=True)
    categoria_id = db.Column(
        db.Integer, db.ForeignKey("categorias_evaluacion.id"), nullable=False
    )
    codigo = db.Column(db.String(20), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    riesgo = db.Column(
        db.Enum("Menor", "Mayor", "Crítico"), nullable=False, default="Menor"
    )
    puntaje_minimo = db.Column(db.Integer, nullable=False, default=0)
    puntaje_maximo = db.Column(db.Integer, nullable=False, default=4)
    orden = db.Column(db.Integer, default=0)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)


class ItemEvaluacionEstablecimiento(db.Model):
    __tablename__ = "items_evaluacion_establecimiento"
    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    item_base_id = db.Column(
        db.Integer, db.ForeignKey("items_evaluacion_base.id"), nullable=False
    )
    descripcion_personalizada = db.Column(db.Text)
    factor_ajuste = db.Column(
        db.Numeric(3, 2), default=1.00
    )  # Nuevo campo para ajuste de puntaje
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    item_base = db.relationship("ItemEvaluacionBase")


class Inspeccion(db.Model):
    __tablename__ = "inspecciones"
    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("establecimientos.id"), nullable=False
    )
    inspector_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"), nullable=False)
    encargado_id = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    fecha = db.Column(db.Date, nullable=False)
    hora_inicio = db.Column(db.Time)
    hora_fin = db.Column(db.Time)
    observaciones = db.Column(db.Text)
    puntaje_total = db.Column(db.DECIMAL(6, 2))
    puntaje_maximo_posible = db.Column(db.DECIMAL(6, 2))
    porcentaje_cumplimiento = db.Column(db.DECIMAL(5, 2))
    puntos_criticos_perdidos = db.Column(db.Integer)
    estado = db.Column(
        db.Enum("pendiente", "en_proceso", "completada"), default="pendiente"
    )
    firma_inspector = db.Column(db.String(500))
    firma_encargado = db.Column(db.String(500))
    fecha_firma_inspector = db.Column(db.TIMESTAMP)
    fecha_firma_encargado = db.Column(db.TIMESTAMP)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relaciones usando strings para evitar importaciones circulares
    inspector = db.relationship(
        "Usuario",
        foreign_keys=[inspector_id],
        backref="inspecciones_como_inspector",
        lazy=True,
    )
    encargado = db.relationship(
        "Usuario",
        foreign_keys=[encargado_id],
        backref="inspecciones_como_encargado",
        lazy=True,
    )
    detalles = db.relationship("InspeccionDetalle", backref="inspeccion", lazy=True)
    evidencias = db.relationship("EvidenciaInspeccion", backref="inspeccion", lazy=True)


class InspeccionDetalle(db.Model):
    __tablename__ = "inspeccion_detalles"
    id = db.Column(db.Integer, primary_key=True)
    inspeccion_id = db.Column(
        db.Integer, db.ForeignKey("inspecciones.id"), nullable=False
    )
    item_establecimiento_id = db.Column(
        db.Integer, db.ForeignKey("items_evaluacion_establecimiento.id"), nullable=False
    )
    rating = db.Column(db.Integer)
    score = db.Column(db.DECIMAL(5, 2))
    observacion_item = db.Column(db.Text)  # observación específica del item
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    item_establecimiento = db.relationship("ItemEvaluacionEstablecimiento")


class EvidenciaInspeccion(db.Model):
    __tablename__ = "evidencias_inspeccion"
    id = db.Column(db.Integer, primary_key=True)
    inspeccion_id = db.Column(
        db.Integer, db.ForeignKey("inspecciones.id"), nullable=False
    )
    item_detalle_id = db.Column(db.Integer, db.ForeignKey("inspeccion_detalles.id"))
    filename = db.Column(db.String(255), nullable=False)
    ruta_archivo = db.Column(db.String(500), nullable=False)
    descripcion = db.Column(db.String(500))
    mime_type = db.Column(db.String(100))
    tamano_bytes = db.Column(db.Integer)
    uploaded_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)