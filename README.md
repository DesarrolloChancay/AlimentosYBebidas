# AlimentosYBebidas

## Descripción

Sistema web para la gestión y evaluación sanitaria de establecimientos de alimentos y bebidas en el Castillo de Chancay. Permite a auditores registrar evaluaciones, visualizar puntajes, planificar metas semanales y gestionar usuarios y negocios.

## Estructura de Carpetas

```
AlimentosYBebidas/
│
├── README.md
├── requirements.txt
├── run.py
├── usuarios.txt
│
├── app/
│   ├── __init__.py
│   ├── config.py
│   ├── extensiones.py
│   ├── controllers/
│   │   └── inspecciones.py
│   ├── models/
│   │   └── (modelos de datos)
│   ├── routes/
│   │   └── inspeccion_routes.py
│   ├── static/
│   │   └── js/
│   │       └── app.js
│   └── templates/
│       ├── base.html
│       ├── index.html
│       └── login.html
│
├── data/
│   └── alimentosybebidas.sql
```

## Principales Archivos

- **run.py**: Archivo principal para ejecutar la aplicación Flask.
- **requirements.txt**: Dependencias del proyecto.
- **usuarios.txt**: Archivo de usuarios (puede usarse para pruebas o migraciones).
- **app/**: Carpeta principal de la aplicación Flask.
  - ****init**.py**: Inicializa la app, rutas principales y configuración.
  - **config.py**: Configuración de Flask y base de datos.
  - **extensiones.py**: Inicialización de extensiones (ej. SQLAlchemy).
  - **controllers/**: Lógica de negocio y acceso a datos.
    - **inspecciones.py**: Funciones para listar establecimientos y otras operaciones sanitarias.
  - **models/**: Modelos de datos (ORM SQLAlchemy).
  - **routes/**: Rutas y blueprints de la aplicación.
    - **inspeccion_routes.py**: Rutas relacionadas a inspecciones.
  - **static/**: Archivos estáticos (JS, CSS, imágenes).
    - **js/app.js**: Scripts de la aplicación.
  - **templates/**: Plantillas HTML (Jinja2).
    - **base.html**: Layout base.
    - **index.html**: Página principal de evaluación sanitaria.
    - **login.html**: Página de login.
- **data/alimentosybebidas.sql**: Script SQL con la estructura y datos de la base de datos.

## Estructura de Base de Datos (resumida)

- **roles**: Tipos de usuario (admin, auditor, etc.)
- **usuarios**: Usuarios del sistema
- **establecimientos**: Negocios a evaluar
- **categorias_evaluacion**: Categorías del checklist sanitario
- **items_evaluacion_base**: Ítems específicos de evaluación
- **evaluaciones**: Evaluaciones realizadas
- **evaluacion_detalles**: Detalle de cada ítem evaluado
- **plan_semanal**: Metas y seguimiento semanal

## Flujo principal

1. El auditor inicia sesión y accede a la página principal.
2. Selecciona el negocio y la fecha (por defecto, la actual en Lima, Perú).
3. Visualiza el resumen de puntaje y cumplimiento.
4. Realiza la evaluación sanitaria usando el checklist.
5. El sistema actualiza puntajes, metas semanales y permite consultar el historial.

## Tecnologías

- Python 3
- Flask
- Jinja2
- SQLAlchemy
- HTML, CSS, JS

## Características de Seguridad

### Flujo de Contraseña Temporal
- **Login con Temporal**: Usuario ingresa con "Temp123!" → Redirección automática a cambio de contraseña
- **Sesión Temporal**: Se crea sesión limitada solo para cambio de contraseña
- **Verificación Automática**: Sistema verifica continuamente si el usuario necesita cambiar contraseña
- **Cambio Exitoso**: Flag `cambiar_contrasena` se establece en False y sesión se normaliza
- **Prevención de Bypass**: Usuario no puede acceder al sistema sin cambiar contraseña

### Roles de Usuario y Jerarquía
1. **Administrador**: Control total del sistema, gestión de usuarios y configuraciones
2. **Jefe de Establecimiento**: Gestión de inspectores y supervisión de evaluaciones
3. **Inspector**: Realización de evaluaciones sanitarias
4. **Encargado**: Acceso limitado a funciones específicas

### Autenticación y Autorización
- Sesiones seguras con Flask-Session
- Control de acceso basado en roles
- Hashing de contraseñas con bcrypt
- Decoradores de autenticación personalizados

## Instalación y Configuración

1. Instalar dependencias:
```bash
pip install -r requirements.txt
```

2. Configurar la base de datos en `app/config.py`

3. Ejecutar la aplicación:
```bash
python run.py
```

## Pruebas del Sistema

### Verificación del Sistema de Contraseña Temporal
Para verificar que el sistema de contraseña temporal funciona correctamente:

```bash
python verificar_contrasena_temporal.py
```

Este script verifica:
- ✅ Creación de usuarios con `cambiar_contrasena=True`
- ✅ Asignación de contraseña temporal "Temp123!"
- ✅ Funcionamiento del método `verificar_cambio_contrasena`
- ✅ Actualización del flag después del cambio de contraseña

### Prueba del Flujo Completo
Para probar el flujo completo de login con cambio de contraseña:

```bash
python probar_flujo_completo.py
```

Este script simula:
- ✅ Creación de usuario con contraseña temporal
- ✅ Login que redirige a cambio de contraseña
- ✅ Sesión temporal creada correctamente
- ✅ Verificación de cambio funciona
- ✅ Cambio de contraseña actualiza flag y limpia sesión
- ✅ Usuario puede continuar normalmente

### Creación de Usuarios de Prueba
Para crear usuarios de prueba desde archivo:

```bash
python crear_usuarios.py
```

El archivo `usuarios.txt` contiene la lista de usuarios a crear.

## Autor

Desarrollo Castillo de Chancay
