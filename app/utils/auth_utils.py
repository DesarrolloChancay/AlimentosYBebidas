import bcrypt
import secrets
import string

def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
    return hashed.decode('utf-8')

def check_password(password: str, hashed_password: str) -> bool:
    """Verify a password against a hash using bcrypt."""
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))

def generar_contrasena_temporal(longitud: int = 12) -> str:
    """
    Genera una contraseña temporal robusta y aleatoria.

    Args:
        longitud: Longitud de la contraseña (mínimo 8, máximo 20)

    Returns:
        str: Contraseña temporal generada
    """
    # Asegurar longitud razonable
    longitud = max(8, min(20, longitud))

    # Caracteres disponibles
    minusculas = string.ascii_lowercase
    mayusculas = string.ascii_uppercase
    digitos = string.digits
    simbolos = "!@#$%^&*"

    # Garantizar al menos un carácter de cada tipo
    contrasena = [
        secrets.choice(minusculas),
        secrets.choice(mayusculas),
        secrets.choice(digitos),
        secrets.choice(simbolos)
    ]

    # Completar con caracteres aleatorios
    todos_caracteres = minusculas + mayusculas + digitos + simbolos
    for _ in range(longitud - 4):
        contrasena.append(secrets.choice(todos_caracteres))

    # Mezclar aleatoriamente
    secrets.SystemRandom().shuffle(contrasena)

    return ''.join(contrasena)
