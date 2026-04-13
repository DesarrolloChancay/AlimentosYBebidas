import bcrypt
import re
import secrets
import string
import unicodedata


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed.decode('utf-8')



def check_password(password: str, hashed_password: str) -> bool:
    """Verify a password against a hash using bcrypt."""
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))



def limpiar_fragmento_nombre_usuario(texto: str) -> str:
    texto = unicodedata.normalize('NFKD', (texto or '').strip().lower())
    texto = ''.join(char for char in texto if not unicodedata.combining(char))
    texto = re.sub(r'[^a-z0-9]+', '.', texto)
    texto = re.sub(r'\.+', '.', texto).strip('.')
    return texto



def obtener_fragmento_corto(texto: str, longitud: int = 4) -> str:
    tokens = [
        limpiar_fragmento_nombre_usuario(token)
        for token in re.split(r'\s+', (texto or '').strip())
        if token.strip()
    ]
    tokens = [token for token in tokens if token]
    if not tokens:
        return ''

    for token in tokens:
        if len(token) > 2:
            return token[:longitud]

    return tokens[0][:longitud]



def generar_base_nombre_usuario(nombre: str, apellido: str) -> str:
    partes = [
        obtener_fragmento_corto(nombre),
        obtener_fragmento_corto(apellido),
    ]
    base = '.'.join(parte for parte in partes if parte)
    return base or 'usuario'



def generar_contrasena_temporal(longitud: int = 12) -> str:
    """
    Genera una contraseña temporal robusta y aleatoria.

    Args:
        longitud: Longitud de la contraseña (mínimo 8, máximo 20)

    Returns:
        str: Contraseña temporal generada
    """
    longitud = max(8, min(20, longitud))

    minusculas = string.ascii_lowercase
    mayusculas = string.ascii_uppercase
    digitos = string.digits
    simbolos = '!@#$%^&*'

    contrasena = [
        secrets.choice(minusculas),
        secrets.choice(mayusculas),
        secrets.choice(digitos),
        secrets.choice(simbolos),
    ]

    todos_caracteres = minusculas + mayusculas + digitos + simbolos
    for _ in range(longitud - 4):
        contrasena.append(secrets.choice(todos_caracteres))

    secrets.SystemRandom().shuffle(contrasena)
    return ''.join(contrasena)
