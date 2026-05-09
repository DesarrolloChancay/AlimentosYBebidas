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
    registrado_por = db.Column(db.Integer, db.ForeignKey("usuarios.id"))
    fecha_habilitacion = db.Column(db.TIMESTAMP)
    observaciones_jefe = db.Column(db.Text)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    # Relación usando string para evitar importaciones circulares
    usuario = db.relationship("Usuario", foreign_keys=[usuario_id], backref="encargos", lazy=True)
    registrador = db.relationship(
        "Usuario",
        foreign_keys=[registrado_por],
        lazy=True,
    )


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


class ItemReglamentoRestaurante(db.Model):
    """Descripción: Catálogo base de items del reglamento de restaurante.
    Lógica: Sirve como plantilla global, por establecimiento o ad hoc de reunión.
    Es independiente del checklist de inspecciones.
    """

    __tablename__ = "items_reglamento_restaurante"

    id = db.Column(db.Integer, primary_key=True)
    codigo = db.Column(db.String(10), nullable=False, unique=True)  # A-01, A-02, etc.
    descripcion = db.Column(db.Text, nullable=False)
    categoria = db.Column(db.String(100), nullable=False)  # Higiene, servicio, atención, etc.
    riesgo = db.Column(db.String(20), nullable=False)  # Mayor, Crítico, Menor
    puntaje = db.Column(db.Integer, nullable=False)  # 1, 3, 5
    tipo_validacion = db.Column(db.String(20), default='si_no')  # 'si_no', 'numerico', 'porcentaje'
    logica_inversa = db.Column(db.Boolean, default=False)  # True = SI es malo, NO es bueno
    valor_umbral = db.Column(db.Numeric(10, 2))  # Valor de referencia para validación numérica
    operador_comparacion = db.Column(db.String(10))  # '<', '>', '<=', '>=', '='
    establecimiento_id = db.Column(db.Integer)
    alcance = db.Column(db.String(20), nullable=False, default='global')
    tipo_vigencia = db.Column(db.String(20), nullable=False, default='permanente')
    fecha_fin_vigencia = db.Column(db.Date)
    reunion_origen_id = db.Column(db.Integer)
    created_by_user_id = db.Column(db.Integer)
    orden = db.Column(db.Integer, default=0)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )


class ReunionReglamento(db.Model):
    """Descripción: Reunión semanal para revisar infracciones.
    Lógica: Se crea cada lunes para revisar la semana anterior.
    """

    __tablename__ = "reuniones_reglamento"

    id = db.Column(db.Integer, primary_key=True)
    establecimiento_id = db.Column(db.Integer, db.ForeignKey("establecimientos.id"), nullable=False)
    semana = db.Column(db.Integer, nullable=False)  # Número de semana ISO
    ano = db.Column(db.Integer, nullable=False)
    fecha_reunion = db.Column(db.Date, nullable=False)  # Lunes de la semana
    fecha_inicio_semana = db.Column(db.Date, nullable=False)  # Lunes de semana evaluada
    fecha_fin_semana = db.Column(db.Date, nullable=False)  # Domingo de semana evaluada
    total_inspecciones = db.Column(db.Integer, default=0)
    total_infracciones = db.Column(db.Integer, default=0)
    total_puntos = db.Column(db.Integer, default=0)
    total_platos_sancion = db.Column(db.Integer, default=0)
    observaciones = db.Column(db.Text)
    estado = db.Column(db.String(20), default='pendiente')  # pendiente, completada
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint(
            "establecimiento_id",
            "semana",
            "ano",
            name="uq_reuniones_reglamento_establecimiento_semana",
        ),
    )

    # Relaciones
    establecimiento = db.relationship("Establecimiento", backref="reuniones_reglamento", lazy=True)
    items_configurados = db.relationship(
        "ReunionItemReglamento",
        backref="reunion",
        lazy=True,
        cascade="all, delete-orphan",
    )
    evaluaciones = db.relationship("EvaluacionReglamento", backref="reunion", lazy=True, cascade="all, delete-orphan")


class ReunionItemReglamento(db.Model):
    """Snapshot configurable de items del reglamento para una reunión específica.
    Se mantiene separado del checklist de inspecciones.
    """

    __tablename__ = "reunion_items_reglamento"

    id = db.Column(db.Integer, primary_key=True)
    reunion_id = db.Column(
        db.Integer, db.ForeignKey("reuniones_reglamento.id"), nullable=False
    )
    item_id = db.Column(
        db.Integer,
        db.ForeignKey("items_reglamento_restaurante.id"),
        nullable=False,
    )
    codigo = db.Column(db.String(10), nullable=False)
    descripcion = db.Column(db.Text, nullable=False)
    categoria = db.Column(db.String(100), nullable=False)
    riesgo = db.Column(db.String(20), nullable=False)
    puntaje = db.Column(db.Integer, nullable=False, default=0)
    tipo_validacion = db.Column(db.String(20), nullable=False, default='si_no')
    logica_inversa = db.Column(db.Boolean, default=False)
    valor_umbral = db.Column(db.Numeric(10, 2))
    operador_comparacion = db.Column(db.String(10))
    tipo_vigencia = db.Column(db.String(20), nullable=False, default='permanente')
    fecha_fin_vigencia = db.Column(db.Date)
    alcance = db.Column(db.String(20), nullable=False, default='global')
    orden = db.Column(db.Integer, default=0)
    activo = db.Column(db.Boolean, default=True)
    es_adicional = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(
        db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    __table_args__ = (
        db.UniqueConstraint(
            "reunion_id",
            "item_id",
            name="uq_reunion_items_reglamento_reunion_item",
        ),
    )

    item = db.relationship(
        "ItemReglamentoRestaurante", backref="instancias_reunion", lazy=True
    )


class EvaluacionReglamento(db.Model):
    """Descripción: Evaluación de cada item del reglamento en la reunión.
    Lógica: Registra si cumple o no cumple cada item del checklist.
    """

    __tablename__ = "evaluaciones_reglamento"

    id = db.Column(db.Integer, primary_key=True)
    reunion_id = db.Column(db.Integer, db.ForeignKey("reuniones_reglamento.id"), nullable=False)
    item_id = db.Column(db.Integer, db.ForeignKey("items_reglamento_restaurante.id"), nullable=False)
    reunion_item_id = db.Column(
        db.Integer,
        db.ForeignKey("reunion_items_reglamento.id"),
        unique=True,
    )
    cumple = db.Column(db.Boolean, nullable=False)  # True = Cumple, False = No Cumple
    numero_infracciones = db.Column(db.Integer, default=0)  # Cuántas veces se detectó en la semana
    puntaje_aplicado = db.Column(db.Integer, nullable=False, default=0)
    valor_medido = db.Column(db.Numeric(10, 2))  # Valor medido para validaciones numéricas
    observacion = db.Column(db.Text)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint(
            "reunion_id",
            "item_id",
            name="uq_evaluaciones_reglamento_reunion_item",
        ),
    )

    # Relaciones
    item = db.relationship("ItemReglamentoRestaurante", backref="evaluaciones", lazy=True)
    reunion_item = db.relationship(
        "ReunionItemReglamento",
        backref=db.backref("evaluacion", uselist=False),
        lazy=True,
    )


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


# Alias para compatibilidad con nuevos controladores
ItemReglamento = ItemReglamentoRestaurante
ReglamentoRestaurante = ReunionReglamento
