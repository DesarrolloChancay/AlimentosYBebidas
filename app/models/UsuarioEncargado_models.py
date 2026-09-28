from datetime import datetime

from app.extensions import db
from app.utils.auth_utils import check_password, hash_password


class UsuarioEncargado(db.Model):
    """Tabla usuarios en la BD Postgres separada, para Encargado / Jefe de
    Establecimiento (roles sin código de colaborador en RRHH).

    Cada fila se refleja también en `usuarios` (MySQL, ver Usuario_models.py)
    vía `mysql_usuario_id`, para que encargados_establecimientos,
    jefes_establecimientos e inspecciones sigan funcionando sin cambios.
    """

    __bind_key__ = 'encargados'
    __tablename__ = 'usuarios'

    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    apellido = db.Column(db.String(100), nullable=False)
    contrasena = db.Column(db.String(255), nullable=False)
    correo = db.Column(db.String(150), nullable=True)
    dni = db.Column(db.String(20), nullable=False, unique=True)
    cod_usuario = db.Column(db.String(10), unique=True, nullable=True)
    telefono = db.Column(db.String(30), nullable=True)
    rol = db.Column(db.String(50), nullable=False)  # 'Encargado' | 'Jefe de Establecimiento'
    activo = db.Column(db.Boolean, default=True, nullable=False)
    mysql_usuario_id = db.Column(db.Integer, unique=True, nullable=True)
    created_at = db.Column(db.TIMESTAMP, default=datetime.utcnow)
    updated_at = db.Column(db.TIMESTAMP, default=datetime.utcnow, onupdate=datetime.utcnow)

    def set_password(self, password):
        self.contrasena = hash_password(password)

    def check_password(self, password):
        return check_password(password, self.contrasena)

    @staticmethod
    def generar_cod_usuario_unico():
        prefijo = 'CC'
        ultimo = (
            UsuarioEncargado.query
            .filter(UsuarioEncargado.cod_usuario.like(f'{prefijo}%'))
            .order_by(UsuarioEncargado.cod_usuario.desc())
            .first()
        )

        siguiente = 1
        if ultimo and ultimo.cod_usuario:
            try:
                siguiente = int(ultimo.cod_usuario[len(prefijo):]) + 1
            except ValueError:
                siguiente = 1

        for _ in range(1000):
            candidato = f'{prefijo}{siguiente:04d}'
            if not UsuarioEncargado.query.filter_by(cod_usuario=candidato).first():
                return candidato
            siguiente += 1

        raise ValueError('No se pudo generar un cod_usuario único')
