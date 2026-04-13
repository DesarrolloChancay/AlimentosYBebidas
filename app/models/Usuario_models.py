from app.extensions import db
from datetime import datetime
from app.utils.auth_utils import hash_password, check_password, generar_base_nombre_usuario
import secrets

class Rol(db.Model):
    __tablename__ = 'roles'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50), nullable=False, unique=True)
    descripcion = db.Column(db.Text)
    permisos = db.Column(db.JSON)  # Campo JSON para permisos específicos del rol
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    usuarios = db.relationship('Usuario', backref='rol', lazy=True)

class Usuario(db.Model):
    __tablename__ = 'usuarios'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    apellido = db.Column(db.String(100))
    nombre_usuario = db.Column(db.String(160), nullable=False, unique=True, index=True)
    correo = db.Column(db.String(150), nullable=False)
    contrasena = db.Column(db.String(255), nullable=False)
    rol_id = db.Column(db.Integer, db.ForeignKey('roles.id'), nullable=False)
    activo = db.Column(db.Boolean, default=True, nullable=False)
    en_linea = db.Column(db.Boolean, default=False, nullable=False)  # Campo para sesión única
    ultimo_acceso = db.Column(db.TIMESTAMP, default=datetime.utcnow)  # Para timeout
    telefono = db.Column(db.String(30))
    dni = db.Column(db.String(20))
    ruta_firma = db.Column(db.String(500))
    cambiar_contrasena = db.Column(db.Boolean, default=False, nullable=False)  # Indica si debe cambiar contraseña
    fecha_creacion = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)

    def set_password(self, password):
        self.contrasena = hash_password(password)

    def check_password(self, password):
        return check_password(password, self.contrasena)

    @staticmethod
    def generar_nombre_usuario_unico(nombre, apellido):
        base = generar_base_nombre_usuario(nombre, apellido)

        for _ in range(200):
            candidato = f"{base}.{secrets.randbelow(1000):03d}"
            if not Usuario.query.filter_by(nombre_usuario=candidato).first():
                return candidato

        raise ValueError('No se pudo generar un nombre de usuario único')

class TipoEstablecimiento(db.Model):
    __tablename__ = 'tipos_establecimiento'
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False, unique=True)
    descripcion = db.Column(db.Text)
    activo = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
