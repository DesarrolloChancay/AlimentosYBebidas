from flask import (
    Blueprint,
    render_template,
    request,
    jsonify,
    session,
    redirect,
    url_for,
    flash,
    send_from_directory,
    abort,
)
from app.controllers.inspecciones_controller import InspeccionesController
from app.extensions import db
from app.models.Inspecciones_models import ItemEvaluacionBase
from datetime import datetime
from functools import wraps
import os

inspeccion_bp = Blueprint("inspeccion", __name__)


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if "user_id" not in session:
            if request.is_json:
                return jsonify({"error": "Sesión requerida"}), 401
            return redirect(url_for("login_page"))
        return f(*args, **kwargs)

    return decorated_function


def role_required(allowed_roles):
    """Decorador para verificar roles específicos"""

    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            user_role = session.get("user_role")
            if user_role not in allowed_roles:
                if request.is_json:
                    return jsonify({"error": "Acceso denegado para su rol"}), 403
                flash("Acceso denegado para su rol", "error")
                return redirect(url_for("inspeccion.buscar_inspecciones"))
            return f(*args, **kwargs)

        return decorated_function

    return decorator


@inspeccion_bp.route("/inspecciones")
@login_required
@role_required(["Inspector", "Administrador"])
def historial_inspecciones():
    """Vista para buscar inspecciones guardadas"""
    user_role = session.get("user_role")
    return render_template("inspecciones.html", user_role=user_role)


@inspeccion_bp.route("/inspecciones/<int:inspeccion_id>/detalle")
@login_required
def detalle_inspeccion(inspeccion_id):
    """Vista detallada de una inspección específica"""
    user_role = session.get("user_role")
    user_id = session.get("user_id")

    try:
        # Obtener la inspección
        from app.models.Inspecciones_models import Inspeccion

        inspeccion = Inspeccion.query.get_or_404(inspeccion_id)

        # Verificar permisos según el rol
        if user_role == "Encargado":
            # Encargado solo puede ver inspecciones de sus establecimientos
            from app.models.Inspecciones_models import EncargadoEstablecimiento
            from datetime import date

            asignacion = (
                EncargadoEstablecimiento.query.filter(
                    EncargadoEstablecimiento.usuario_id == user_id,
                    EncargadoEstablecimiento.establecimiento_id
                    == inspeccion.establecimiento_id,
                    EncargadoEstablecimiento.activo == True,
                    EncargadoEstablecimiento.fecha_inicio <= date.today(),
                )
                .filter(
                    (EncargadoEstablecimiento.fecha_fin.is_(None))
                    | (EncargadoEstablecimiento.fecha_fin >= date.today())
                )
                .first()
            )

            if not asignacion:
                flash("No tiene acceso a esta inspección", "error")
                return redirect(url_for("inspeccion.buscar_inspecciones"))

        # Obtener detalles completos de la inspección
        detalle, error = InspeccionesController.obtener_inspeccion_completa(
            inspeccion_id, return_json=False
        )
        
        if error or not detalle:
            flash(error or "Error al cargar la inspección", "error")
            return redirect(url_for("inspeccion.buscar_inspecciones"))

        return render_template(
            "detalle_inspeccion.html", inspeccion=detalle, user_role=user_role
        )

    except Exception as e:
        flash(f"Error al cargar inspección: {str(e)}", "error")
        return redirect(url_for("inspeccion.buscar_inspecciones"))


@inspeccion_bp.route("/")
@login_required
def index():
    """Ruta principal que valida sesión y carga la interfaz según rol"""
    from datetime import date

    user_role = session.get("user_role")
    user_id = session.get("user_id")

    # Verificar que hay sesión válida (redundancia de seguridad)
    if not user_id or not user_role:
        session.clear()
        return redirect(url_for("login_page"))

    # Inicializar datos por defecto
    resumen = {
        "puntaje_total": 0,
        "puntaje_maximo": 0,
        "porcentaje_cumplimiento": 0,
        "puntos_criticos_perdidos": 0,
    }

    plan_semanal = []
    establecimientos = []
    categorias = []

    try:
        # Obtener datos básicos para la interfaz según el rol
        if user_role in ["Administrador", "Inspector"]:
            # Admin e Inspector pueden ver plan semanal
            plan_response = InspeccionesController.obtener_plan_semanal()
            if isinstance(plan_response, tuple) and len(plan_response) == 2:
                if plan_response[1] == 200:
                    plan_semanal = plan_response[0].get_json()
            elif hasattr(plan_response, "get_json"):
                plan_semanal = plan_response.get_json()

        # Todos los roles necesitan ver establecimientos (filtrados por rol)
        establecimientos_response = InspeccionesController.obtener_establecimientos()
        if (
            isinstance(establecimientos_response, tuple)
            and len(establecimientos_response) == 2
        ):
            if establecimientos_response[1] == 200:
                establecimientos = establecimientos_response[0].get_json()
        elif hasattr(establecimientos_response, "get_json"):
            establecimientos = establecimientos_response.get_json()

        # Solo Inspector y Admin necesitan categorías completas
        if user_role in ["Administrador", "Inspector"]:
            categorias_response = InspeccionesController.obtener_categorias()
            if isinstance(categorias_response, tuple) and len(categorias_response) == 2:
                if categorias_response[1] == 200:
                    categorias = categorias_response[0].get_json()
            elif hasattr(categorias_response, "get_json"):
                categorias = categorias_response.get_json()

    except Exception as e:
        pass  # Error silenciado en producción

    # Obtener fecha actual
    fecha_actual = date.today().strftime("%Y-%m-%d")

    return render_template(
        "index.html",
        resumen=resumen,
        plan_semanal=plan_semanal,
        establecimientos=establecimientos,
        categorias=categorias,
        fecha_actual=fecha_actual,
        user_role=user_role,
    )


@inspeccion_bp.route("/api/establecimientos")
@login_required
def get_establecimientos():
    return InspeccionesController.obtener_establecimientos()


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/items")
@login_required
def get_items_establecimiento(establecimiento_id):
    """Obtener items detallados del establecimiento"""
    user_role = session.get("user_role")
    user_id = session.get("user_id")

    # Verificar que el usuario tiene acceso a este establecimiento
    if user_role == "Encargado":
        # Verificar que el encargado está asignado a este establecimiento
        from app.models.Inspecciones_models import EncargadoEstablecimiento
        from datetime import date

        asignacion = (
            EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.usuario_id == user_id,
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= date.today(),
            )
            .filter(
                (EncargadoEstablecimiento.fecha_fin.is_(None))
                | (EncargadoEstablecimiento.fecha_fin >= date.today())
            )
            .first()
        )

        if not asignacion:
            return jsonify({"error": "No tiene acceso a este establecimiento"}), 403

    try:
        categorias = InspeccionesController.obtener_items_establecimiento_detallado(establecimiento_id)
        return jsonify({"success": True, "categorias": categorias})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/tiempo-real")
@login_required
def obtener_datos_tiempo_real(establecimiento_id):
    """Obtener datos en tiempo real de la inspección para el encargado"""
    return InspeccionesController.obtener_datos_tiempo_real_encargado(
        establecimiento_id
    )


@inspeccion_bp.route(
    "/api/inspecciones/tiempo-real/establecimiento/<int:establecimiento_id>"
)
@login_required
def obtener_datos_tiempo_real_establecimiento(establecimiento_id):
    """Obtener datos actuales de tiempo real para un establecimiento específico"""
    return InspeccionesController.obtener_datos_tiempo_real_establecimiento(
        establecimiento_id
    )


@inspeccion_bp.route("/buscar")
@login_required
def buscar_inspecciones():
    """Vista para buscar inspecciones (para inspectores)"""
    user_role = session.get("user_role")
    if user_role not in ["Inspector", "Encargado", "Administrador", "Jefe de Establecimiento"]:
        flash("No tienes permisos para acceder a esta función.", "error")
        return redirect(url_for("inspeccion.index"))

    return render_template("buscar_inspecciones.html")


@inspeccion_bp.route("/api/inspecciones/buscar", methods=["GET"])
@login_required
def api_buscar_inspecciones():
    """API para buscar inspecciones con filtros"""
    return InspeccionesController.buscar_inspecciones()


@inspeccion_bp.route("/api/inspecciones/<int:inspeccion_id>/detalle")
@login_required
def api_detalle_inspeccion(inspeccion_id):
    """API para obtener detalle de una inspección"""
    return InspeccionesController.obtener_detalle_inspeccion(inspeccion_id)


@inspeccion_bp.route("/api/inspecciones/temporal", methods=["POST"])
@login_required
def guardar_inspeccion_temporal():
    """Guardar cookie del formulario para que no se pierdan los datos"""
    return InspeccionesController.guardar_inspeccion_parcial()


@inspeccion_bp.route("/api/inspecciones/temporal", methods=["GET"])
@login_required
def obtener_inspeccion_temporal():
    """Recuperar cookie del formulario guardado"""
    return InspeccionesController.recuperar_inspeccion_temporal()


@inspeccion_bp.route("/api/inspecciones/temporal", methods=["DELETE"])
@login_required
def limpiar_inspeccion_temporal():
    """Borrar la cookie temporal al guardar la inspección"""
    return InspeccionesController.limpiar_inspeccion_temporal()


@inspeccion_bp.route("/api/inspecciones/sincronizado/establecimiento/<int:establecimiento_id>", methods=["GET"])
@login_required
def obtener_estado_sincronizado_establecimiento(establecimiento_id):
    """Obtener el estado sincronizado del establecimiento para Inspector y Encargado"""
    return InspeccionesController.obtener_estado_sincronizado_establecimiento(establecimiento_id)


@inspeccion_bp.route("/api/inspecciones/confirmar", methods=["POST"])
@login_required
def confirmar_inspeccion_encargado():
    """Confirmar inspección por parte de un encargado o jefe (solo el primero puede hacerlo)"""
    return InspeccionesController.confirmar_inspeccion_encargado()


@inspeccion_bp.route("/api/inspecciones", methods=["POST"])
@login_required
def guardar_inspeccion():
    """Al guardar la inspección, se borrará la cookie temporal"""
    return InspeccionesController.guardar_inspeccion()


@inspeccion_bp.route("/api/inspecciones/evidencias", methods=["POST"])
@login_required
@role_required(["Inspector", "Administrador"])
def subir_evidencias():
    """Subir evidencias fotográficas para una inspección"""
    return InspeccionesController.subir_evidencias()

@inspeccion_bp.route("/evidencias/<path:filename>")
@login_required  
def servir_evidencia(filename):
    """Servir archivos de evidencias de forma segura"""
    try:
        # Construir ruta base de evidencias
        evidencias_dir = os.path.join(os.getcwd(), 'app', 'static', 'evidencias')
        
        # Verificar que el archivo existe
        archivo_path = os.path.join(evidencias_dir, filename)
        if not os.path.exists(archivo_path):
            abort(404)
            
        # Verificar que el archivo está dentro del directorio permitido (seguridad)
        archivo_path = os.path.abspath(archivo_path)
        evidencias_dir = os.path.abspath(evidencias_dir)
        
        if not archivo_path.startswith(evidencias_dir):
            abort(403)
            
        # Servir el archivo
        directory = os.path.dirname(archivo_path)
        filename = os.path.basename(archivo_path)
        
        return send_from_directory(directory, filename)
        
    except Exception as e:
        abort(404)


@inspeccion_bp.route("/api/usuarios/encargados")
@login_required
def obtener_encargados():
    """Obtener lista de encargados para filtros"""
    return InspeccionesController.obtener_lista_encargados()

@inspeccion_bp.route("/api/inspecciones/<int:inspeccion_id>")
@login_required
def obtener_inspeccion(inspeccion_id):
    return InspeccionesController.obtener_inspeccion(inspeccion_id)


@inspeccion_bp.route("/api/informes")
@login_required
def obtener_informes():
    """El encargado podrá ver los informes solo de su establecimiento"""
    user_role = session.get("user_role")
    user_id = session.get("user_id")

    # Filtros desde query params
    fecha_inicio = request.args.get("fecha_inicio")
    fecha_fin = request.args.get("fecha_fin")
    establecimiento_id = request.args.get("establecimiento_id", type=int)
    inspector_id = request.args.get("inspector_id", type=int)
    encargado_id = request.args.get("encargado_id", type=int)
    estado = request.args.get("estado")

    # Si es Encargado, solo puede ver informes de sus establecimientos
    if user_role == "Encargado":
        encargado_id = user_id  # Forzar a ver solo sus informes

        # Si especifica un establecimiento, verificar que tiene acceso
        if establecimiento_id:
            from app.models.Inspecciones_models import EncargadoEstablecimiento
            from datetime import date

            asignacion = (
                EncargadoEstablecimiento.query.filter(
                    EncargadoEstablecimiento.usuario_id == user_id,
                    EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                    EncargadoEstablecimiento.activo == True,
                    EncargadoEstablecimiento.fecha_inicio <= date.today(),
                )
                .filter(
                    (EncargadoEstablecimiento.fecha_fin.is_(None))
                    | (EncargadoEstablecimiento.fecha_fin >= date.today())
                )
                .first()
            )

            if not asignacion:
                return jsonify({"error": "No tiene acceso a este establecimiento"}), 403

    return InspeccionesController.filtrar_inspecciones(
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        establecimiento_id=establecimiento_id,
        inspector_id=inspector_id,
        encargado_id=encargado_id,
        estado=estado,
    )


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/encargado")
@login_required
def obtener_encargado_actual(establecimiento_id):
    return InspeccionesController.obtener_encargado_actual(establecimiento_id)


@inspeccion_bp.route("/api/inspecciones")
@login_required
def filtrar_inspecciones():
    """Endpoint para filtrar inspecciones según criterios del pedido.txt"""
    fecha_inicio = request.args.get("fecha_inicio")
    fecha_fin = request.args.get("fecha_fin")
    establecimiento_id = request.args.get("establecimiento_id", type=int)
    inspector_id = request.args.get("inspector_id", type=int)
    encargado_id = request.args.get("encargado_id", type=int)
    estado = request.args.get("estado")

    return InspeccionesController.filtrar_inspecciones(
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
        establecimiento_id=establecimiento_id,
        inspector_id=inspector_id,
        encargado_id=encargado_id,
        estado=estado,
    )


@inspeccion_bp.route("/api/categorias")
@login_required
def obtener_categorias():
    return InspeccionesController.obtener_categorias()


@inspeccion_bp.route("/api/inspecciones/actualizar-tiempo-real", methods=["POST"])
@login_required
def actualizar_item_tiempo_real():
    """Endpoint para actualizaciones en tiempo real"""
    return InspeccionesController.actualizar_item_tiempo_real()


# =========================
# RUTAS DE ADMINISTRADOR
# =========================


@inspeccion_bp.route("/api/admin/puntuaciones", methods=["PUT"])
@login_required
@role_required(["Administrador"])
def editar_puntuacion_admin():
    """Permite al admin editar puntuaciones"""
    return InspeccionesController.editar_puntuacion_inspeccion()


@inspeccion_bp.route("/api/admin/establecimientos", methods=["POST"])
@login_required
@role_required(["Administrador"])
def crear_establecimiento_admin():
    """Permite al admin crear establecimientos"""
    return InspeccionesController.crear_establecimiento()


@inspeccion_bp.route("/api/admin/establecimientos", methods=["DELETE"])
@login_required
@role_required(["Administrador"])
def eliminar_establecimiento_admin():
    """Permite al admin eliminar establecimientos"""
    return InspeccionesController.eliminar_establecimiento()


@inspeccion_bp.route("/api/inspector/establecimientos", methods=["POST"])
@login_required
@role_required(["Inspector", "Administrador"])
def crear_establecimiento_inspector():
    """Permite al inspector crear establecimientos"""
    return InspeccionesController.crear_establecimiento_inspector()


@inspeccion_bp.route("/api/admin/usuarios/rol", methods=["PUT"])
@login_required
@role_required(["Administrador"])
def actualizar_rol_usuario_admin():
    """Permite al admin cambiar roles de usuarios"""
    return InspeccionesController.actualizar_rol_usuario()


@inspeccion_bp.route("/api/admin/usuarios")
@login_required
@role_required(["Administrador"])
def obtener_usuarios_admin():
    """Obtener todos los usuarios para administración"""
    return InspeccionesController.obtener_todos_los_usuarios()


@inspeccion_bp.route("/api/tipos-establecimiento")
@login_required
def obtener_tipos_establecimiento():
    """Obtener tipos de establecimiento"""
    return InspeccionesController.obtener_tipos_establecimiento()


# =========================
# RUTAS ESPECÍFICAS PARA ENCARGADOS
# =========================


@inspeccion_bp.route("/api/encargado/firmar", methods=["POST"])
@login_required
@role_required(["Encargado"])
def firmar_inspeccion():
    """El encargado solo puede poner su firma para aceptar puntuaciones"""
    try:
        data = request.get_json()
        inspeccion_id = data.get("inspeccion_id")
        firma_data = data.get("firma_data")  # Base64 de la firma

        if not all([inspeccion_id, firma_data]):
            return jsonify({"error": "Datos incompletos"}), 400

        # Verificar que el encargado tiene acceso a esta inspección
        from app.models.Inspecciones_models import Inspeccion

        inspeccion = Inspeccion.query.get(inspeccion_id)

        if not inspeccion:
            return jsonify({"error": "Inspección no encontrada"}), 404

        if inspeccion.encargado_id != session.get("user_id"):
            return (
                jsonify({"error": "No tiene autorización para firmar esta inspección"}),
                403,
            )

        # Guardar la firma
        inspeccion.firma_encargado = firma_data
        inspeccion.fecha_firma_encargado = datetime.now()

        from app.extensions import db

        db.session.commit()

        # Emitir evento de firma para notificar al inspector
        from app.extensions import socketio

        try:
            room = f"inspeccion_{inspeccion_id}"
            socketio.emit(
                "firma_recibida",
                {
                    "inspeccion_id": inspeccion_id,
                    "tipo_firma": "encargado",
                    "firmado_por": session.get("user_name"),
                    "timestamp": datetime.now().isoformat(),
                },
                to=room,
            )
        except Exception as e:
            pass  # Error silenciado en producción

        return jsonify({"mensaje": "Firma guardada exitosamente"})

    except Exception as e:
        from app.extensions import db

        db.session.rollback()
        return jsonify({"error": f"Error al guardar firma: {str(e)}"}), 500


@inspeccion_bp.route("/api/inspector/firmar", methods=["POST"])
@login_required
@role_required(["Inspector"])
def firmar_como_inspector():
    """El inspector puede firmar solo después de que el encargado haya firmado"""
    return InspeccionesController.firmar_como_inspector()


# ====== NUEVAS RUTAS: DASHBOARD PLAN SEMANAL ======

@inspeccion_bp.route("/api/dashboard/plan-semanal", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector", "Encargado", "Jefe de Establecimiento"])
def obtener_plan_semanal_dashboard():
    """
    API para obtener estadísticas del plan semanal
    PERMISOS: Administrador (todos), Inspector (todos), Encargado (solo su establecimiento), Jefe de Establecimiento (solo su establecimiento)
    """
    return InspeccionesController.obtener_plan_semanal()


@inspeccion_bp.route("/api/dashboard/configuracion-plan", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_configuracion_plan():
    """
    API para obtener configuración del plan semanal
    PERMISOS: Administrador e Inspector
    """
    return InspeccionesController.obtener_configuracion_plan()


@inspeccion_bp.route("/api/dashboard/configuracion-plan", methods=["PUT"])
@login_required
@role_required(["Administrador", "Inspector"])
def actualizar_configuracion_plan():
    """
    API para actualizar configuración del plan semanal
    PERMISOS: 
    - Administrador: puede actualizar toda la configuración
    - Inspector: solo puede actualizar meta_semanal_default
    """
    return InspeccionesController.actualizar_configuracion_plan()


@inspeccion_bp.route("/api/dashboard/actualizar-meta", methods=["PUT"])
@login_required
@role_required(["Administrador", "Inspector"])
def actualizar_meta_semanal():
    """
    API para actualizar meta semanal específica
    PERMISOS: Administrador e Inspector
    """
    return InspeccionesController.actualizar_meta_semanal()


@inspeccion_bp.route("/configuracion")
@login_required
@role_required(["Administrador", "Inspector"])
def configuracion_sistema():
    """
    Página de configuración del sistema
    PERMISOS: Administrador e Inspector
    """
    user_role = session.get("user_role")
    user_name = session.get("user_name")
    
    return render_template(
        "configuracion.html",
        user_role=user_role,
        user_name=user_name,
        title="Configuración del Sistema"
    )


@inspeccion_bp.route("/test-api")
def test_api_page():
    """
    Página de test para la API de configuración
    """
    return render_template("test_api.html")


# Ruta para la página del dashboard (frontend)
@inspeccion_bp.route("/dashboard")
@login_required
@role_required(["Administrador", "Inspector", "Encargado", "Jefe de Establecimiento"])
def dashboard_page():
    """
    Página del dashboard - Plan semanal
    PERMISOS: Administrador, Inspector, Encargado, Jefe de Establecimiento (con diferentes vistas)
    """
    user_role = session.get("user_role")
    user_name = session.get("user_name")
    
    return render_template(
        "dashboard.html",
        user_role=user_role,
        user_name=user_name,
        title="Dashboard - Plan Semanal"
    )


# API para obtener lista de establecimientos
@inspeccion_bp.route("/api/dashboard/establecimientos", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def api_get_establecimientos():
    """
    API para obtener la lista de establecimientos
    PERMISOS: Solo Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import Establecimiento
        from app.models.Usuario_models import TipoEstablecimiento

        # Obtener todos los establecimientos (activos e inactivos) con su tipo
        establecimientos = Establecimiento.query\
            .join(TipoEstablecimiento, Establecimiento.tipo_establecimiento_id == TipoEstablecimiento.id)\
            .all()

        # Convertir a formato JSON
        resultado = []
        for est in establecimientos:
            resultado.append({
                "id": est.id,
                "nombre": est.nombre,
                "tipo": est.tipo_establecimiento.nombre if est.tipo_establecimiento else "Sin tipo",
                "direccion": est.direccion or "",
                "distrito": "",  # Campo no existe en el modelo actual
                "telefono": est.telefono or "",
                "activo": est.activo,
                "fecha_creacion": est.created_at.isoformat() if est.created_at else None
            })

        return jsonify(resultado), 200

    except Exception as e:
        return jsonify({"error": "Error interno del servidor"}), 500


@inspeccion_bp.route("/api/inspecciones/pendientes", methods=["GET"])
@login_required
@role_required(["Inspector", "Administrador"])
def obtener_inspecciones_pendientes():
    """
    API para obtener inspecciones pendientes que pueden ser continuadas por cualquier inspector
    PERMISOS: Inspector y Administrador
    """
    return InspeccionesController.obtener_inspecciones_pendientes()


@inspeccion_bp.route("/api/inspecciones/retomar/<int:inspeccion_id>", methods=["POST"])
@login_required
@role_required(["Inspector", "Administrador"])
def retomar_inspeccion(inspeccion_id):
    """
    API para que un inspector retome una inspección pendiente de otro inspector
    PERMISOS: Inspector y Administrador
    """
    return InspeccionesController.retomar_inspeccion(inspeccion_id)


# =========================
# RUTAS CRUD PARA ESTABLECIMIENTOS
# =========================

@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_establecimiento(establecimiento_id):
    """
    API para obtener un establecimiento específico
    PERMISOS: Administrador e Inspector
    """
    import traceback

    try:
        from app.models.Inspecciones_models import Establecimiento
        from app.models.Usuario_models import TipoEstablecimiento

        # Log de entrada para debugging
        print(f"GET /api/establecimientos/{establecimiento_id} - Iniciando consulta")

        establecimiento = Establecimiento.query.get(establecimiento_id)
        print(f"Establecimiento encontrado: {establecimiento is not None}")

        if not establecimiento:
            print(f"Error: Establecimiento {establecimiento_id} no encontrado")
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos (solo puede ver establecimientos que le corresponden según rol)
        user_role = session.get("user_role")
        print(f"Rol de usuario: {user_role}")

        if user_role == "Inspector":
            # Los inspectores pueden ver todos los establecimientos
            pass
        elif user_role == "Administrador":
            # Los administradores pueden ver todos
            pass
        else:
            print("Error: Usuario no autorizado")
            return jsonify({"error": "No autorizado"}), 403

        # Preparar resultado
        try:
            resultado = {
                "id": establecimiento.id,
                "nombre": establecimiento.nombre,
                "tipo_establecimiento_id": establecimiento.tipo_establecimiento_id,
                "direccion": establecimiento.direccion or "",
                "distrito": "",  # Campo no implementado aún
                "telefono": establecimiento.telefono or "",
                "correo": establecimiento.correo or "",
                "activo": establecimiento.activo,
                "fecha_creacion": establecimiento.created_at.isoformat() if establecimiento.created_at else None
            }
            print(f"Resultado preparado: {resultado}")
        except Exception as e:
            print(f"Error al preparar resultado: {str(e)}")
            traceback.print_exc()
            return jsonify({"error": f"Error al preparar datos: {str(e)}"}), 500

        print("Establecimiento obtenido exitosamente")
        return jsonify(resultado), 200

    except Exception as e:
        # Log detallado del error
        print(f"ERROR al obtener establecimiento {establecimiento_id}: {str(e)}")
        print("Traceback completo:")
        traceback.print_exc()
        return jsonify({"error": f"Error interno del servidor: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/estadisticas", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_estadisticas_establecimiento(establecimiento_id):
    """
    API para obtener estadísticas de un establecimiento
    PERMISOS: Administrador e Inspector
    """
    import traceback

    try:
        from app.models.Inspecciones_models import (
            Establecimiento, Inspeccion, ItemEvaluacionEstablecimiento,
            EncargadoEstablecimiento, JefeEstablecimiento
        )

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Obtener estadísticas
        inspecciones_total = Inspeccion.query.filter_by(establecimiento_id=establecimiento_id).count()
        encargados_total = EncargadoEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).count()
        jefes_total = JefeEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).count()
        evaluaciones_total = ItemEvaluacionEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).count()

        # Inspecciones por estado
        inspecciones_pendientes = Inspeccion.query.filter_by(
            establecimiento_id=establecimiento_id, estado="pendiente"
        ).count()
        inspecciones_proceso = Inspeccion.query.filter_by(
            establecimiento_id=establecimiento_id, estado="en_proceso"
        ).count()
        inspecciones_completadas = Inspeccion.query.filter_by(
            establecimiento_id=establecimiento_id, estado="completada"
        ).count()

        # Inspecciones recientes (últimos 30 días)
        from datetime import datetime, timedelta
        fecha_limite = datetime.utcnow() - timedelta(days=30)
        inspecciones_recientes = Inspeccion.query.filter(
            Inspeccion.establecimiento_id == establecimiento_id,
            Inspeccion.created_at >= fecha_limite
        ).count()

        estadisticas = {
            "totales": {
                "inspecciones": inspecciones_total,
                "encargados": encargados_total,
                "jefes": jefes_total,
                "evaluaciones": evaluaciones_total
            },
            "inspecciones_por_estado": {
                "pendientes": inspecciones_pendientes,
                "en_proceso": inspecciones_proceso,
                "completadas": inspecciones_completadas
            },
            "inspecciones_recientes": inspecciones_recientes,
            "fecha_actualizacion": datetime.utcnow().isoformat()
        }

        return jsonify(estadisticas), 200

    except Exception as e:
        print(f"ERROR al obtener estadísticas del establecimiento {establecimiento_id}: {str(e)}")
        print("Traceback completo:")
        traceback.print_exc()
        return jsonify({"error": f"Error interno del servidor: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>", methods=["PUT"])
@login_required
@role_required(["Administrador", "Inspector"])
def actualizar_establecimiento(establecimiento_id):
    """
    API para actualizar un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import Establecimiento
        from app.extensions import db
        import traceback

        # Log de entrada para debugging
        print(f"PUT /api/establecimientos/{establecimiento_id} - Iniciando actualización")

        data = request.get_json()
        print(f"Datos recibidos: {data}")

        if not data:
            print("Error: No se recibieron datos JSON")
            return jsonify({"error": "Datos JSON requeridos"}), 400

        nombre = data.get("nombre", "").strip()
        tipo_establecimiento_id = data.get("tipo_establecimiento_id")
        direccion = data.get("direccion", "").strip()
        distrito = data.get("distrito", "").strip()  # Campo reservado para futuro
        telefono = data.get("telefono", "").strip()
        correo = data.get("correo", "").strip().lower()

        print(f"Campos extraídos - nombre: '{nombre}', tipo_id: {tipo_establecimiento_id}")

        # Validaciones
        if not nombre:
            print("Error: Nombre vacío")
            return jsonify({"error": "El nombre es obligatorio"}), 400

        if not tipo_establecimiento_id:
            print("Error: tipo_establecimiento_id vacío")
            return jsonify({"error": "El tipo de establecimiento es obligatorio"}), 400

        # Convertir tipo_establecimiento_id a integer
        try:
            tipo_establecimiento_id = int(tipo_establecimiento_id)
            print(f"tipo_establecimiento_id convertido a: {tipo_establecimiento_id}")
        except (ValueError, TypeError) as e:
            print(f"Error convirtiendo tipo_establecimiento_id: {e}")
            return jsonify({"error": "El tipo de establecimiento debe ser un número válido"}), 400

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            print(f"Error: Establecimiento {establecimiento_id} no encontrado")
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        print(f"Rol de usuario: {user_role}")
        if user_role not in ["Administrador", "Inspector"]:
            print("Error: Usuario no autorizado")
            return jsonify({"error": "No autorizado"}), 403

        # Verificar que el nombre no esté duplicado (excluyendo el propio establecimiento)
        establecimiento_existente = Establecimiento.query.filter(
            Establecimiento.nombre.ilike(nombre),
            Establecimiento.id != establecimiento_id,
            Establecimiento.activo == True
        ).first()

        if establecimiento_existente:
            print(f"Error: Nombre duplicado con establecimiento ID {establecimiento_existente.id}")
            return jsonify({"error": "Ya existe un establecimiento con este nombre"}), 409

        # Actualizar establecimiento
        print("Actualizando establecimiento...")
        establecimiento.nombre = nombre
        establecimiento.tipo_establecimiento_id = tipo_establecimiento_id
        establecimiento.direccion = direccion if direccion else None
        establecimiento.telefono = telefono if telefono else None
        establecimiento.correo = correo if correo else None

        db.session.commit()
        print("Establecimiento actualizado exitosamente")

        return jsonify({
            "mensaje": "Establecimiento actualizado exitosamente",
            "establecimiento": {
                "id": establecimiento.id,
                "nombre": establecimiento.nombre,
                "direccion": establecimiento.direccion,
                "telefono": establecimiento.telefono
            }
        }), 200

    except Exception as e:
        db.session.rollback()
        # Log detallado del error
        print(f"ERROR al actualizar establecimiento {establecimiento_id}: {str(e)}")
        print("Traceback completo:")
        return jsonify({"error": f"Error interno del servidor: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/estado", methods=["PUT"])
@login_required
@role_required(["Administrador", "Inspector"])
def cambiar_estado_establecimiento(establecimiento_id):
    """
    API para habilitar/deshabilitar un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import Establecimiento
        from app.extensions import db

        data = request.get_json()
        activo = data.get("activo")

        if activo is None:
            return jsonify({"error": "Estado 'activo' es requerido"}), 400

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Actualizar estado
        establecimiento.activo = bool(activo)
        db.session.commit()

        estado_texto = "habilitado" if activo else "deshabilitado"
        return jsonify({
            "mensaje": f"Establecimiento {estado_texto} exitosamente",
            "activo": establecimiento.activo
        }), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al cambiar estado: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>", methods=["DELETE"])
@login_required
@role_required(["Administrador"])
def eliminar_establecimiento(establecimiento_id):
    """
    API para eliminar permanentemente un establecimiento
    PERMISOS: Solo Administrador (acción destructiva)
    """
    try:
        from app.models.Inspecciones_models import (
            Establecimiento, Inspeccion, ItemEvaluacionEstablecimiento,
            EncargadoEstablecimiento, PlanSemanal, FirmaEncargadoPorJefe, JefeEstablecimiento
        )
        from app.extensions import db

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar que no tenga inspecciones asociadas
        inspecciones_count = Inspeccion.query.filter_by(establecimiento_id=establecimiento_id).count()
        if inspecciones_count > 0:
            return jsonify({
                "error": f"No se puede eliminar el establecimiento porque tiene {inspecciones_count} inspección(es) asociada(s)"
            }), 409

        # Eliminar registros relacionados en orden para evitar conflictos de foreign keys
        # 1. Eliminar items de evaluación del establecimiento
        ItemEvaluacionEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).delete()

        # 2. Eliminar encargados asignados
        EncargadoEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).delete()

        # 3. Eliminar planes semanales
        PlanSemanal.query.filter_by(establecimiento_id=establecimiento_id).delete()

        # 4. Eliminar firmas de encargados
        FirmaEncargadoPorJefe.query.filter_by(establecimiento_id=establecimiento_id).delete()

        # 5. Eliminar jefes asignados
        JefeEstablecimiento.query.filter_by(establecimiento_id=establecimiento_id).delete()

        # Finalmente, eliminar el establecimiento
        db.session.delete(establecimiento)
        db.session.commit()

        return jsonify({"mensaje": "Establecimiento eliminado exitosamente"}), 200

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al eliminar establecimiento: {str(e)}"}), 500


# =========================
# RUTAS PARA GESTIÓN DE ITEMS DE ESTABLECIMIENTOS
# =========================

@inspeccion_bp.route("/establecimientos/<int:establecimiento_id>/items/gestionar", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def gestionar_items_establecimiento(establecimiento_id):
    """
    Página para gestionar items de evaluación de un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import Establecimiento
        from app.models.Usuario_models import TipoEstablecimiento

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            flash("Establecimiento no encontrado", "error")
            return redirect(url_for("inspeccion.index"))

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            flash("No autorizado", "error")
            return redirect(url_for("inspeccion.index"))

        return render_template(
            "admin_gestionar_items_establecimiento.html",
            establecimiento=establecimiento,
            user_role=user_role
        )

    except Exception as e:
        flash(f"Error al cargar la página: {str(e)}", "error")
        return redirect(url_for("inspeccion.index"))


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/plantillas/<int:plantilla_id>", methods=["POST"])
@login_required
@role_required(["Administrador", "Inspector"])
def agregar_plantilla_completa_establecimiento(establecimiento_id, plantilla_id):
    """
    Agregar toda una plantilla completa a un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import (
            Establecimiento, ItemEvaluacionEstablecimiento, ItemEvaluacionBase
        )
        from app.models.Plantillas_models import PlantillaChecklist, ItemPlantillaChecklist
        from app.extensions import db

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Verificar que la plantilla existe y está activa
        plantilla = PlantillaChecklist.query.get(plantilla_id)
        if not plantilla or not plantilla.activo:
            return jsonify({"error": "Plantilla no encontrada o inactiva"}), 404

        # Obtener todos los items de la plantilla
        items_plantilla = ItemPlantillaChecklist.query.filter_by(
            plantilla_id=plantilla_id,
            activo=True
        ).all()

        if not items_plantilla:
            return jsonify({"error": "La plantilla no tiene items activos"}), 400

        # Obtener IDs de items que ya están ACTIVOS en el establecimiento
        # Solo excluimos items que ya están activos, permitiendo reactivar items inactivos
        items_activos_existentes = ItemEvaluacionEstablecimiento.query.filter_by(
            establecimiento_id=establecimiento_id,
            activo=True
        ).with_entities(ItemEvaluacionEstablecimiento.item_base_id).all()

        items_activos_ids = [item.item_base_id for item in items_activos_existentes]

        # Filtrar items que no están ya activos en el establecimiento
        items_a_agregar = [item for item in items_plantilla if item.item_base_id not in items_activos_ids]

        if not items_a_agregar:
            # Verificar si hay items inactivos que se pueden reactivar
            items_inactivos = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                activo=False
            ).join(ItemEvaluacionBase).all()

            items_plantilla_ids = [item.item_base_id for item in items_plantilla]
            items_inactivos_plantilla = [item for item in items_inactivos if item.item_base_id in items_plantilla_ids]

            if items_inactivos_plantilla:
                # Reactivar items inactivos
                reactivados = 0
                for item in items_inactivos_plantilla:
                    item.activo = True
                    # Actualizar con datos de la plantilla si es necesario
                    item_plantilla = next((ip for ip in items_plantilla if ip.item_base_id == item.item_base_id), None)
                    if item_plantilla:
                        item.descripcion_personalizada = item_plantilla.descripcion_personalizada
                        item.factor_ajuste = item_plantilla.factor_ajuste
                    reactivados += 1

                db.session.commit()
                return jsonify({
                    "success": True,
                    "message": f'Se reactivaron {reactivados} items de la plantilla "{plantilla.nombre}" en el establecimiento',
                    "items_agregados": reactivados
                })
            else:
                return jsonify({
                    "success": True,
                    "message": f'Todos los items de la plantilla "{plantilla.nombre}" ya existen y están activos en el establecimiento',
                    "items_agregados": 0
                })

        # Agregar los items uno por uno
        items_agregados = 0
        errores = []

        for item_plantilla in items_a_agregar:
            try:
                # Verificar nuevamente si ya existe (por si acaso hay concurrencia)
                existing_item = ItemEvaluacionEstablecimiento.query.filter_by(
                    establecimiento_id=establecimiento_id,
                    item_base_id=item_plantilla.item_base_id
                ).first()

                if existing_item:
                    if existing_item.activo:
                        continue  # Ya existe y está activo
                    else:
                        # Reactivar el item existente
                        existing_item.activo = True
                        existing_item.descripcion_personalizada = item_plantilla.descripcion_personalizada
                        existing_item.factor_ajuste = item_plantilla.factor_ajuste
                        db.session.commit()
                        items_agregados += 1
                else:
                    # Crear nuevo item
                    nuevo_item = ItemEvaluacionEstablecimiento(
                        establecimiento_id=establecimiento_id,
                        item_base_id=item_plantilla.item_base_id,
                        descripcion_personalizada=item_plantilla.descripcion_personalizada,
                        factor_ajuste=item_plantilla.factor_ajuste,
                        activo=True
                    )
                    db.session.add(nuevo_item)
                    items_agregados += 1

            except Exception as e:
                errores.append(f"Error con item {item_plantilla.item_base.descripcion}: {str(e)}")
                continue

        # Commit final
        try:
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al guardar los cambios: {str(e)}"}), 500

        # Preparar mensaje de respuesta
        mensaje = f'Se agregaron {items_agregados} items de la plantilla "{plantilla.nombre}" al establecimiento'
        if errores:
            mensaje += f". Errores encontrados: {len(errores)}"

        return jsonify({
            "success": True,
            "message": mensaje,
            "items_agregados": items_agregados,
            "errores": errores if errores else None
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al agregar plantilla completa: {str(e)}"}), 500
    """
    Agregar item individual de plantilla a un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import (
            Establecimiento, ItemEvaluacionEstablecimiento, ItemEvaluacionBase
        )
        from app.models.Plantillas_models import ItemPlantillaChecklist
        from app.extensions import db

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Obtener datos del JSON
        data = request.get_json()
        item_plantilla_id = data.get('item_plantilla_id')

        if not item_plantilla_id:
            return jsonify({"error": "ID del item de plantilla es obligatorio"}), 400

        # Verificar que el item de plantilla existe y está activo
        item_plantilla = ItemPlantillaChecklist.query.get(item_plantilla_id)
        if not item_plantilla or not item_plantilla.activo:
            return jsonify({"error": "Item de plantilla no encontrado o inactivo"}), 404

        # Verificar si ya existe el item en el establecimiento
        # La restricción de unicidad es sobre (establecimiento_id, item_base_id), sin importar el estado activo
        existing_item = ItemEvaluacionEstablecimiento.query.filter_by(
            establecimiento_id=establecimiento_id,
            item_base_id=item_plantilla.item_base_id
        ).first()

        if existing_item:
            # Si ya existe, verificar si está activo
            if existing_item.activo:
                # Si está activo, retornar éxito sin crear duplicado
                return jsonify({
                    "success": True,
                    "message": f'El item "{item_plantilla.item_base.descripcion}" ya existe en el establecimiento',
                    "item_id": existing_item.id
                })
            else:
                # Si existe pero está inactivo, reactivarlo
                existing_item.activo = True
                existing_item.descripcion_personalizada = item_plantilla.descripcion_personalizada
                existing_item.factor_ajuste = item_plantilla.factor_ajuste
                db.session.commit()

                return jsonify({
                    "success": True,
                    "message": f'Item "{item_plantilla.item_base.descripcion}" reactivado exitosamente en el establecimiento',
                    "item_id": existing_item.id
                })

        # Crear nuevo item para el establecimiento
        nuevo_item = ItemEvaluacionEstablecimiento(
            establecimiento_id=establecimiento_id,
            item_base_id=item_plantilla.item_base_id,
            descripcion_personalizada=item_plantilla.descripcion_personalizada,
            factor_ajuste=item_plantilla.factor_ajuste,
            activo=True
        )

        db.session.add(nuevo_item)
        db.session.commit()

        return jsonify({
            "success": True,
            "message": f'Item "{item_plantilla.item_base.descripcion}" agregado exitosamente al establecimiento',
            "item_id": nuevo_item.id
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al agregar item: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/items/<int:item_id>", methods=["DELETE"])
@login_required
@role_required(["Administrador", "Inspector"])
def eliminar_item_establecimiento(establecimiento_id, item_id):
    """
    Eliminar item específico de un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import (
            Establecimiento, ItemEvaluacionEstablecimiento, InspeccionDetalle
        )
        from app.extensions import db

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Verificar que el item existe y pertenece al establecimiento
        item = ItemEvaluacionEstablecimiento.query.filter_by(
            id=item_id,
            establecimiento_id=establecimiento_id,
            activo=True
        ).first()

        if not item:
            return jsonify({"error": "Item no encontrado en este establecimiento"}), 404

        # Verificar que no esté siendo usado en inspecciones
        inspecciones_count = InspeccionDetalle.query.filter_by(
            item_establecimiento_id=item_id
        ).count()

        if inspecciones_count > 0:
            return jsonify({
                "error": f"No se puede eliminar el item porque está siendo usado en {inspecciones_count} inspección(es)"
            }), 409

        # Desactivar item (no eliminar físicamente)
        item.activo = False
        db.session.commit()

        return jsonify({
            "success": True,
            "message": f'Item "{item.item_base.descripcion}" eliminado exitosamente del establecimiento'
        })

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Error al eliminar item: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/items/disponibles", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_items_disponibles_establecimiento(establecimiento_id):
    """
    Obtener items de plantillas que pueden ser agregados a un establecimiento
    Muestra todos los items disponibles en plantillas, incluyendo aquellos ya asignados
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import Establecimiento, ItemEvaluacionEstablecimiento
        from app.models.Plantillas_models import ItemPlantillaChecklist, PlantillaChecklist
        from app.models.Usuario_models import TipoEstablecimiento

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Obtener items de plantillas que pueden ser agregados
        # NOTA: Permitimos agregar múltiples instancias del mismo item base a diferentes establecimientos
        # Esto permite configuraciones personalizadas por establecimiento
        query = request.args.get('query', '').strip()
        plantilla_id = request.args.get('plantilla_id', type=int)

        # Obtener IDs de items que ya están ACTIVOS en el establecimiento
        # Mostramos todos los items de plantillas disponibles, el endpoint de agregar
        # se encargará de reactivar items existentes o informar duplicados
        items_activos_existentes = ItemEvaluacionEstablecimiento.query.filter_by(
            establecimiento_id=establecimiento_id,
            activo=True
        ).with_entities(ItemEvaluacionEstablecimiento.item_base_id).all()

        items_activos_ids = [item.item_base_id for item in items_activos_existentes]

        items_query = ItemPlantillaChecklist.query.filter_by(activo=True)

        # Filtrar por plantilla si se especifica
        if plantilla_id:
            items_query = items_query.filter_by(plantilla_id=plantilla_id)

        # Aplicar búsqueda por texto si existe
        if query and len(query) >= 2:
            from app.models.Inspecciones_models import ItemEvaluacionBase
            items_query = items_query.filter(
                db.or_(
                    ItemPlantillaChecklist.item_base.has(db.func.lower(ItemEvaluacionBase.descripcion).like(f'%{query.lower()}%')),
                    ItemPlantillaChecklist.item_base.has(db.func.lower(ItemEvaluacionBase.codigo).like(f'%{query.lower()}%'))
                )
            )

        # Unir con plantillas y ordenar
        items = items_query.join(PlantillaChecklist)\
            .order_by(PlantillaChecklist.nombre, ItemPlantillaChecklist.orden)\
            .limit(100)\
            .all()

        # Filtrar duplicados por item_base_id en Python (más simple y confiable)
        seen_base_ids = set()
        unique_items = []
        for item in items:
            if item.item_base_id not in seen_base_ids:
                seen_base_ids.add(item.item_base_id)
                unique_items.append(item)

        # Limitar a 50 items únicos
        items = unique_items[:50]

        # Preparar resultado
        resultado = []
        for item in items:
            # Verificar si este item ya está asignado al establecimiento
            ya_asignado = item.item_base_id in items_activos_ids
            
            resultado.append({
                'id': item.id,
                'item_base_id': item.item_base_id,
                'codigo': item.item_base.codigo,
                'descripcion': item.item_base.descripcion,
                'descripcion_personalizada': item.descripcion_personalizada,
                'categoria': item.item_base.categoria.nombre,
                'riesgo': item.riesgo,
                'puntaje_minimo': item.item_base.puntaje_minimo,
                'puntaje_maximo': item.item_base.puntaje_maximo,
                'plantilla': item.plantilla.nombre,
                'tipo_establecimiento': item.plantilla.tipo_establecimiento.nombre,
                'ya_asignado': ya_asignado
            })

        return jsonify({
            'success': True,
            'items': resultado
        })

    except Exception as e:
        return jsonify({"error": f"Error al obtener items disponibles: {str(e)}"}), 500


@inspeccion_bp.route("/api/plantillas", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_plantillas():
    """
    Obtener lista de plantillas activas para filtros
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Plantillas_models import PlantillaChecklist, ItemPlantillaChecklist

        plantillas = PlantillaChecklist.query.filter_by(activo=True)\
            .order_by(PlantillaChecklist.nombre)\
            .all()

        resultado = []
        for plantilla in plantillas:
            # Contar items activos de la plantilla
            items_count = ItemPlantillaChecklist.query.filter_by(
                plantilla_id=plantilla.id,
                activo=True
            ).count()

            resultado.append({
                'id': plantilla.id,
                'nombre': plantilla.nombre,
                'tipo': plantilla.tipo_establecimiento.nombre if plantilla.tipo_establecimiento else 'Sin tipo',
                'descripcion': plantilla.descripcion,
                'items_count': items_count
            })

        return jsonify({
            'success': True,
            'plantillas': resultado
        })

    except Exception as e:
        return jsonify({"error": f"Error al obtener plantillas: {str(e)}"}), 500


@inspeccion_bp.route("/api/establecimientos/<int:establecimiento_id>/items/actuales", methods=["GET"])
@login_required
@role_required(["Administrador", "Inspector"])
def obtener_items_actuales_establecimiento(establecimiento_id):
    """
    Obtener items actuales asignados a un establecimiento
    PERMISOS: Administrador e Inspector
    """
    try:
        from app.models.Inspecciones_models import (
            Establecimiento, ItemEvaluacionEstablecimiento, ItemEvaluacionBase
        )
        from app.models.Plantillas_models import ItemPlantillaChecklist

        # Verificar que el establecimiento existe
        establecimiento = Establecimiento.query.get(establecimiento_id)
        if not establecimiento:
            return jsonify({"error": "Establecimiento no encontrado"}), 404

        # Verificar permisos
        user_role = session.get("user_role")
        if user_role not in ["Administrador", "Inspector"]:
            return jsonify({"error": "No autorizado"}), 403

        # Obtener items activos del establecimiento
        items = ItemEvaluacionEstablecimiento.query.filter_by(
            establecimiento_id=establecimiento_id,
            activo=True
        ).join(ItemEvaluacionBase)\
         .order_by(ItemEvaluacionBase.categoria_id, ItemEvaluacionBase.orden)\
         .all()

        # Preparar resultado
        resultado = []
        for item in items:
            # Determinar el riesgo basado en el item de plantilla o base
            riesgo = 'Medio'  # Valor por defecto
            item_plantilla = ItemPlantillaChecklist.query.filter_by(
                item_base_id=item.item_base_id,
                activo=True
            ).first()
            if item_plantilla:
                riesgo = item_plantilla.riesgo

            resultado.append({
                'id': item.id,
                'item_base_id': item.item_base_id,
                'codigo': item.item_base.codigo,
                'descripcion': item.item_base.descripcion,
                'descripcion_personalizada': item.descripcion_personalizada,
                'categoria': item.item_base.categoria.nombre,
                'riesgo': riesgo,
                'puntaje_minimo': item.item_base.puntaje_minimo,
                'puntaje_maximo': item.item_base.puntaje_maximo,
                'factor_ajuste': item.factor_ajuste,
                'activo': item.activo,
                'item_base': {
                    'id': item.item_base.id,
                    'codigo': item.item_base.codigo,
                    'descripcion': item.item_base.descripcion,
                    'categoria': {
                        'id': item.item_base.categoria.id,
                        'nombre': item.item_base.categoria.nombre
                    }
                }
            })

        return jsonify({
            'success': True,
            'items': resultado,
            'total': len(resultado)
        })

    except Exception as e:
        return jsonify({"error": f"Error al obtener items actuales: {str(e)}"}), 500
