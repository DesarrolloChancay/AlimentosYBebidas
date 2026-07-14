from flask import json, jsonify, request, session, current_app
from datetime import datetime, date, timedelta
import logging
import os
import base64
import re
import uuid
from werkzeug.utils import secure_filename
import pytz
from sqlalchemy import text, func, or_
from app.extensions import socketio, db
from app.models.Inspecciones_models import (
    Inspeccion,
    InspeccionDetalle,
    ItemEvaluacionEstablecimiento,
    ItemEvaluacionBase,
    CategoriaEvaluacion,
    EvidenciaInspeccion,
    Establecimiento,
    EncargadoEstablecimiento,
    JefeEstablecimiento,
)
from app.models.Usuario_models import Usuario
from app.utils.roles import (
    ROL_ADMINISTRADOR,
    ROL_AYUDANTE_INSPECTOR,
    ROL_ENCARGADO,
    ROL_INSPECTOR,
    ROL_JEFE_ESTABLECIMIENTO,
    ROLES_EDITOR_INSPECCION,
)
from app.utils.security import (
    is_allowed_image_filename,
    save_validated_base64_image,
    save_validated_image_bytes,
    save_validated_upload_image,
)
from app.utils.media import (
    normalize_signature_reference,
    private_signature_dir,
    signature_db_path,
    signature_public_url,
)


def safe_timestamp():
    """Función para generar timestamp de manera segura en Windows"""
    try:
        # Usar strftime para evitar problemas con isoformat en Windows
        return datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    except Exception as e:
        # Fallback a timestamp unix como string
        return str(int(datetime.now().timestamp()))


def guardar_firma_como_archivo(firma_base64, tipo_firma, inspeccion_id, usuario_id):
    """
    Convierte firma base64 a archivo y retorna la ruta
    Args:
        firma_base64: String con datos base64 de la imagen
        tipo_firma: 'inspector' o 'encargado'
        inspeccion_id: ID de la inspección
        usuario_id: ID del usuario
    Returns:
        String con la ruta relativa del archivo guardado
    """
    try:
        if not firma_base64 or not firma_base64.startswith("data:image/"):
            return None

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        firmas_dir = private_signature_dir("inspecciones")
        stored_image = save_validated_base64_image(
            firma_base64,
            f"firma_{tipo_firma}.png",
            firmas_dir,
            f"firma_{tipo_firma}_{inspeccion_id}_{usuario_id}_{timestamp}",
            max_size=3 * 1024 * 1024,
        )

        return signature_db_path("inspecciones", stored_image.filename)

    except Exception as e:
        return None


from app.models.Inspecciones_models import (
    Establecimiento,
    EncargadoEstablecimiento,
    JefeEstablecimiento,
    FirmaEncargadoPorJefe,
    PlanSemanal,
    ConfiguracionEvaluacion,
    CategoriaEvaluacion,
    ItemEvaluacionEstablecimiento,
    Inspeccion,
    InspeccionDetalle,
    EvidenciaInspeccion,
    ItemEvaluacionBase,
    InspectorEstablecimiento,
)
from app.models.Usuario_models import Usuario, TipoEstablecimiento, Rol
from app.extensions import db

# Almacenamiento temporal en memoria para datos de inspección
# En producción usar Redis
inspecciones_temporales = {}
datos_tiempo_real = {}  # Para almacenar datos temporales entre inspector y encargado


class InspeccionesController:
    EVIDENCIAS_FOLDER = "app/static/evidencias"
    FIRMAS_FOLDER = "firmas"
    ALLOWED_EXTENSIONS = {"png", "jpg", "jpeg", "webp", "avif"}
    MOTIVO_SIN_FIRMA_INICIO = "[[MOTIVO_SIN_FIRMA_ENCARGADO]]"
    MOTIVO_SIN_FIRMA_FIN = "[[/MOTIVO_SIN_FIRMA_ENCARGADO]]"

    @staticmethod
    def _normalizar_motivo_sin_firma(motivo):
        if motivo is None:
            return None

        motivo_normalizado = str(motivo).strip()
        return motivo_normalizado or None

    @staticmethod
    def _patron_motivo_sin_firma():
        return re.compile(
            rf"{re.escape(InspeccionesController.MOTIVO_SIN_FIRMA_INICIO)}\s*(.*?)\s*{re.escape(InspeccionesController.MOTIVO_SIN_FIRMA_FIN)}",
            re.DOTALL,
        )

    @staticmethod
    def _es_firma_base64_valida(firma):
        return isinstance(firma, str) and firma.startswith("data:image/")

    @staticmethod
    def _nombre_mostrable_usuario(usuario):
        if not usuario:
            return None

        nombre = f"{getattr(usuario, 'nombre', '')} {getattr(usuario, 'apellido', '')}".strip()
        return nombre or getattr(usuario, "username", None) or f"Usuario {getattr(usuario, 'id', '')}".strip()

    @staticmethod
    def _obtener_encargado_activo_establecimiento(establecimiento_id, fecha_referencia=None):
        fecha_obj = fecha_referencia or datetime.now().date()
        return EncargadoEstablecimiento.query.filter(
            EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
            EncargadoEstablecimiento.activo == True,
            EncargadoEstablecimiento.fecha_inicio <= fecha_obj,
            (
                EncargadoEstablecimiento.fecha_fin.is_(None)
                | (EncargadoEstablecimiento.fecha_fin >= fecha_obj)
            ),
        ).order_by(EncargadoEstablecimiento.es_principal.desc(), EncargadoEstablecimiento.id.asc()).first()

    @staticmethod
    def _parsear_fecha_referencia(fecha_referencia=None):
        if isinstance(fecha_referencia, datetime):
            return fecha_referencia.date()
        if isinstance(fecha_referencia, date):
            return fecha_referencia
        if isinstance(fecha_referencia, str):
            fecha_texto = fecha_referencia.strip()
            if fecha_texto:
                for formato in ("%Y-%m-%d", "%d/%m/%Y"):
                    try:
                        return datetime.strptime(fecha_texto, formato).date()
                    except ValueError:
                        continue
        return datetime.now().date()

    @staticmethod
    def _obtener_firmantes_habilitados_establecimiento(
        establecimiento_id, fecha_referencia=None
    ):
        fecha_obj = InspeccionesController._parsear_fecha_referencia(
            fecha_referencia
        )

        firmantes = []
        firmantes_vistos = set()

        encargados = (
            EncargadoEstablecimiento.query.join(
                Usuario, EncargadoEstablecimiento.usuario_id == Usuario.id
            )
            .filter(
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                Usuario.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= fecha_obj,
                (
                    EncargadoEstablecimiento.fecha_fin.is_(None)
                    | (EncargadoEstablecimiento.fecha_fin >= fecha_obj)
                ),
            )
            .order_by(
                EncargadoEstablecimiento.es_principal.desc(),
                EncargadoEstablecimiento.fecha_inicio.desc(),
                EncargadoEstablecimiento.id.asc(),
            )
            .all()
        )

        for asignacion in encargados:
            usuario = asignacion.usuario
            if not usuario:
                continue

            clave = (usuario.id, "Encargado")
            if clave in firmantes_vistos:
                continue

            nombre = (
                InspeccionesController._nombre_mostrable_usuario(usuario)
                or f"Usuario {usuario.id}"
            )
            es_principal = bool(asignacion.es_principal)
            firmantes.append(
                {
                    "usuario_id": usuario.id,
                    "nombre": nombre,
                    "rol": "Encargado",
                    "es_principal": es_principal,
                    "label": (
                        f"{nombre} (Encargado principal)"
                        if es_principal
                        else f"{nombre} (Encargado)"
                    ),
                }
            )
            firmantes_vistos.add(clave)

        jefes = (
            JefeEstablecimiento.query.join(
                Usuario, JefeEstablecimiento.usuario_id == Usuario.id
            )
            .filter(
                JefeEstablecimiento.establecimiento_id == establecimiento_id,
                JefeEstablecimiento.activo == True,
                Usuario.activo == True,
                JefeEstablecimiento.fecha_inicio <= fecha_obj,
                (
                    JefeEstablecimiento.fecha_fin.is_(None)
                    | (JefeEstablecimiento.fecha_fin >= fecha_obj)
                ),
            )
            .order_by(
                JefeEstablecimiento.es_principal.desc(),
                JefeEstablecimiento.fecha_inicio.desc(),
                JefeEstablecimiento.id.asc(),
            )
            .all()
        )

        for asignacion in jefes:
            usuario = asignacion.usuario
            if not usuario:
                continue

            clave = (usuario.id, "Jefe de Establecimiento")
            if clave in firmantes_vistos:
                continue

            nombre = (
                InspeccionesController._nombre_mostrable_usuario(usuario)
                or f"Usuario {usuario.id}"
            )
            es_principal = bool(asignacion.es_principal)
            firmantes.append(
                {
                    "usuario_id": usuario.id,
                    "nombre": nombre,
                    "rol": "Jefe de Establecimiento",
                    "es_principal": es_principal,
                    "label": (
                        f"{nombre} (Jefe principal)"
                        if es_principal
                        else f"{nombre} (Jefe)"
                    ),
                }
            )
            firmantes_vistos.add(clave)

        return firmantes

    @staticmethod
    def _obtener_firmante_habilitado_establecimiento(
        establecimiento_id, usuario_id, rol=None, fecha_referencia=None
    ):
        try:
            usuario_id = int(usuario_id)
        except (TypeError, ValueError):
            return None

        rol_normalizado = (rol or "").strip()
        for firmante in InspeccionesController._obtener_firmantes_habilitados_establecimiento(
            establecimiento_id, fecha_referencia=fecha_referencia
        ):
            if firmante["usuario_id"] != usuario_id:
                continue
            if rol_normalizado and firmante["rol"] != rol_normalizado:
                continue
            return firmante

        return None

    @staticmethod
    def _extraer_motivo_sin_firma_desde_observaciones(observaciones):
        if not observaciones:
            return None

        match = InspeccionesController._patron_motivo_sin_firma().search(
            str(observaciones)
        )
        if not match:
            return None

        return InspeccionesController._normalizar_motivo_sin_firma(match.group(1))

    @staticmethod
    def _limpiar_metadatos_observaciones(observaciones):
        if not observaciones:
            return ""

        observaciones_limpias = InspeccionesController._patron_motivo_sin_firma().sub(
            "", str(observaciones)
        )
        observaciones_limpias = re.sub(r"\n{3,}", "\n\n", observaciones_limpias)
        return observaciones_limpias.strip()

    @staticmethod
    def _combinar_observaciones_con_motivo(observaciones, motivo):
        observaciones_limpias = InspeccionesController._limpiar_metadatos_observaciones(
            observaciones
        )
        motivo_normalizado = InspeccionesController._normalizar_motivo_sin_firma(
            motivo
        )

        if not motivo_normalizado:
            return observaciones_limpias

        bloque_motivo = (
            f"{InspeccionesController.MOTIVO_SIN_FIRMA_INICIO}\n"
            f"{motivo_normalizado}\n"
            f"{InspeccionesController.MOTIVO_SIN_FIRMA_FIN}"
        )

        if not observaciones_limpias:
            return bloque_motivo

        return f"{observaciones_limpias}\n\n{bloque_motivo}"

    @staticmethod
    def _obtener_observaciones_y_motivo(inspeccion):
        observaciones = getattr(inspeccion, "observaciones", "") or ""
        return (
            InspeccionesController._limpiar_metadatos_observaciones(observaciones),
            InspeccionesController._extraer_motivo_sin_firma_desde_observaciones(
                observaciones
            ),
        )

    @staticmethod
    def _construir_resultado_guardado(
        inspeccion,
        mensaje="Inspección guardada exitosamente",
        puntajes=None,
        evidencias_guardadas_count=None,
        limpiar_temporal=True,
        resetear_formulario=True,
        actualizar_plan_semanal=True,
        duplicado_omitido=False,
    ):
        observaciones_resultado, motivo_resultado = (
            InspeccionesController._obtener_observaciones_y_motivo(inspeccion)
        )

        if puntajes is None and inspeccion.estado == "completada":
            try:
                puntajes = InspeccionesController.calcular_puntajes_inspeccion(
                    inspeccion.id
                )
            except Exception:
                puntajes = None

        if evidencias_guardadas_count is None:
            evidencias_guardadas_count = EvidenciaInspeccion.query.filter_by(
                inspeccion_id=inspeccion.id
            ).count()

        return {
            "mensaje": mensaje,
            "inspeccion_id": inspeccion.id,
            "estado": inspeccion.estado,
            "puntajes": puntajes,
            "observaciones": observaciones_resultado,
            "motivo_sin_firma_encargado": motivo_resultado,
            "finalizada_sin_firma_encargado": bool(
                motivo_resultado and not inspeccion.firma_encargado
            ),
            "evidencias_guardadas": evidencias_guardadas_count,
            "limpiar_temporal": limpiar_temporal,
            "resetear_formulario": resetear_formulario,
            "actualizar_plan_semanal": actualizar_plan_semanal,
            "duplicado_omitido": duplicado_omitido,
        }

    @staticmethod
    def _obtener_configuracion_calificacion(riesgo):
        riesgo_normalizado = (riesgo or "").strip()
        if riesgo_normalizado == "Crítico":
            return {
                "puntaje_minimo": 1,
                "puntaje_maximo": 8,
                "opciones_validas": {1, 8},
                "etiquetas_calificacion": {1: "Cumple", 8: "No cumple"},
                "porcentaje_por_rating": {1: 100, 8: 0},
            }

        return {
            "puntaje_minimo": 1,
            "puntaje_maximo": 3,
            "opciones_validas": {1, 2, 3},
            "etiquetas_calificacion": {
                1: "Excelente",
                2: "Bueno",
                3: "Regular",
            },
            "porcentaje_por_rating": {1: 100, 2: 75, 3: 50},
        }

    @staticmethod
    def _normalizar_rating_por_riesgo(riesgo, rating):
        config = InspeccionesController._obtener_configuracion_calificacion(riesgo)

        try:
            rating_normalizado = int(rating)
        except (TypeError, ValueError):
            return False, None, config

        return rating_normalizado in config["opciones_validas"], rating_normalizado, config

    @staticmethod
    def _calcular_metricas_rating(riesgo, rating):
        es_valido, rating_normalizado, config = (
            InspeccionesController._normalizar_rating_por_riesgo(riesgo, rating)
        )
        if not es_valido:
            return None

        return {
            "rating": rating_normalizado,
            "puntaje": float(rating_normalizado),
            "puntaje_maximo": float(config["puntaje_maximo"]),
            "porcentaje_cumplimiento": float(
                config["porcentaje_por_rating"][rating_normalizado]
            ),
            "criticos_no_conformes": 1
            if (riesgo or "").strip() == "Crítico" and rating_normalizado == 8
            else 0,
        }

    @staticmethod
    def _calcular_resumen_desde_evaluaciones(evaluaciones, total_items=None):
        puntaje_total = 0.0
        suma_porcentaje_cumplimiento = 0.0
        puntos_criticos_perdidos = 0
        items_calificados = 0
        puntaje_maximo_posible = 0.0

        for evaluacion in evaluaciones:
            riesgo = evaluacion.get("riesgo")
            puntaje_maximo_posible += float(
                InspeccionesController._obtener_configuracion_calificacion(riesgo)[
                    "puntaje_maximo"
                ]
            )

            detalle = evaluacion.get("detalle") or {}
            rating = detalle.get("rating")
            if rating is None:
                continue

            metricas = InspeccionesController._calcular_metricas_rating(riesgo, rating)
            if not metricas:
                continue

            puntaje_total += metricas["puntaje"]
            suma_porcentaje_cumplimiento += metricas["porcentaje_cumplimiento"]
            puntos_criticos_perdidos += metricas["criticos_no_conformes"]
            items_calificados += 1

        if total_items is None:
            total_items = len(evaluaciones)

        porcentaje_cumplimiento = (
            round(suma_porcentaje_cumplimiento / items_calificados, 2)
            if items_calificados > 0
            else 0
        )
        puntaje_promedio_item = (
            round(puntaje_total / items_calificados, 2)
            if items_calificados > 0
            else 0
        )

        return {
            "puntaje_total": round(puntaje_total, 2),
            "puntaje_maximo_posible": round(puntaje_maximo_posible, 2),
            "puntaje_promedio_item": puntaje_promedio_item,
            "porcentaje_cumplimiento": porcentaje_cumplimiento,
            "puntos_criticos_perdidos": puntos_criticos_perdidos,
            "items_calificados": items_calificados,
            "total_items": total_items,
        }

    @staticmethod
    def _obtener_items_activos_establecimiento(establecimiento_id):
        if not establecimiento_id:
            return []

        return (
            db.session.query(ItemEvaluacionEstablecimiento, ItemEvaluacionBase)
            .join(
                ItemEvaluacionBase,
                ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
            )
            .filter(
                ItemEvaluacionEstablecimiento.establecimiento_id == establecimiento_id,
                ItemEvaluacionEstablecimiento.activo == True,
                ItemEvaluacionBase.activo == True,
            )
            .all()
        )

    @staticmethod
    def allowed_file(filename):
        return is_allowed_image_filename(filename)

    @staticmethod
    def _build_static_relative_path(filepath):
        """Normaliza la ruta de un archivo hacia el directorio /static"""
        try:
            static_root = current_app.static_folder
        except RuntimeError:
            static_root = None

        if not static_root:
            static_root = os.path.join(os.getcwd(), "app", "static")

        # Asegurar rutas absolutas para un cálculo consistente
        static_root = os.path.abspath(static_root)
        absolute_path = os.path.abspath(filepath)

        relative_path = os.path.relpath(absolute_path, static_root)
        relative_path = relative_path.replace("\\", "/")

        # Garantizar que la ruta comience con "static/"
        if not relative_path.startswith("static/"):
            relative_path = f"static/{relative_path.lstrip('/')}"

        return relative_path

    @staticmethod
    def _obtener_establecimientos_autorizados(user_id, user_role):
        """Devuelve los establecimientos que el usuario puede consultar o editar."""
        if not user_id or not user_role:
            return []

        hoy = date.today()

        if user_role in [ROL_ADMINISTRADOR, ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR]:
            return [
                establecimiento.id
                for establecimiento in Establecimiento.query.filter_by(activo=True).all()
            ]

        if user_role == ROL_ENCARGADO:
            asignaciones = (
                EncargadoEstablecimiento.query.filter_by(
                    usuario_id=user_id,
                    activo=True,
                )
                .filter(EncargadoEstablecimiento.fecha_inicio <= hoy)
                .filter(
                    or_(
                        EncargadoEstablecimiento.fecha_fin.is_(None),
                        EncargadoEstablecimiento.fecha_fin >= hoy,
                    )
                )
                .all()
            )
            return list(
                {
                    asignacion.establecimiento_id
                    for asignacion in asignaciones
                    if asignacion.establecimiento_id
                }
            )

        if user_role == ROL_JEFE_ESTABLECIMIENTO:
            asignaciones = (
                JefeEstablecimiento.query.filter_by(
                    usuario_id=user_id,
                    activo=True,
                )
                .all()
            )
            return list(
                {
                    asignacion.establecimiento_id
                    for asignacion in asignaciones
                    if asignacion.establecimiento_id
                }
            )

        return []

    @staticmethod
    def _usuario_tiene_acceso_establecimiento(user_id, user_role, establecimiento_id):
        """Valida que el usuario tenga acceso al establecimiento solicitado."""
        if not establecimiento_id:
            return False

        try:
            establecimiento_id = int(establecimiento_id)
        except (TypeError, ValueError):
            return False

        establecimientos_autorizados = (
            InspeccionesController._obtener_establecimientos_autorizados(
                user_id, user_role
            )
        )
        return establecimiento_id in establecimientos_autorizados

    @staticmethod
    def _normalize_evidence_url(ruta):
        """Convierte rutas antiguas de evidencias a la ruta autenticada /evidencias/..."""
        if not ruta:
            return None

        ruta = ruta.replace("\\", "/").strip()

        # Eliminar prefijos redundantes
        if ruta.startswith("./"):
            ruta = ruta[2:]

        ruta = ruta.lstrip("/")

        if ruta.startswith("static/"):
            ruta_sin_prefix = ruta[len("static/") :]
        else:
            ruta_sin_prefix = ruta

        if ruta_sin_prefix.startswith("evidencias"):
            resto = ruta_sin_prefix[len("evidencias") :]
            resto = resto.lstrip("/")
            ruta_normalizada = f"/evidencias/{resto}"
        else:
            ruta_normalizada = f"/static/{ruta_sin_prefix}" if ruta_sin_prefix else "/static"

        # Evitar dobles barras
        ruta_normalizada = ruta_normalizada.replace("//", "/")

        return ruta_normalizada

    @staticmethod
    def guardar_firma(file, tipo, inspeccion_id):
        if file and InspeccionesController.allowed_file(file.filename):
            try:
                stored_image = save_validated_upload_image(
                    file,
                    private_signature_dir("inspecciones"),
                    f"firma_{tipo}_{inspeccion_id}",
                    max_size=3 * 1024 * 1024,
                )
                return signature_db_path("inspecciones", stored_image.filename)
            except ValueError:
                return None
        return None

    @staticmethod
    def crear_directorio_evidencias(establecimiento_id, fecha):
        """Crear estructura de directorios para evidencias organizadas por establecimiento y fecha"""
        try:
            # Obtener nombre del establecimiento para el directorio
            from app.models.Inspecciones_models import Establecimiento

            establecimiento = Establecimiento.query.get(establecimiento_id)
            nombre_establecimiento = (
                establecimiento.nombre.replace(" ", "_").replace("/", "_")
                if establecimiento
                else f"establecimiento_{establecimiento_id}"
            )

            # Convertir fecha a string si es datetime
            if hasattr(fecha, "strftime"):
                fecha_str = fecha.strftime("%Y-%m-%d")
            else:
                fecha_str = str(fecha)

            # Crear ruta: evidencias/nombre_establecimiento/YYYY-MM-DD/
            directorio = os.path.join(
                InspeccionesController.EVIDENCIAS_FOLDER,
                nombre_establecimiento,
                fecha_str,
            )


            if not os.path.exists(directorio):
                os.makedirs(directorio)

            return directorio
        except Exception as e:
            return None

    @staticmethod
    def guardar_evidencia(file, establecimiento_id, fecha, inspeccion_id):
        """Guardar una evidencia fotográfica organizándola por establecimiento y fecha"""
        if file and InspeccionesController.allowed_file(file.filename):
            try:
                directorio = InspeccionesController.crear_directorio_evidencias(
                    establecimiento_id, fecha
                )
                if not directorio:
                    return None

                timestamp = datetime.now().strftime("%H%M%S_%f")[:-3]
                stored_image = save_validated_upload_image(
                    file,
                    directorio,
                    f"evidencia_{inspeccion_id}_{timestamp}",
                )
                ruta_relativa = InspeccionesController._build_static_relative_path(
                    stored_image.filepath
                )

                return {
                    "filename": stored_image.filename,
                    "ruta_archivo": ruta_relativa,
                    "tamano_bytes": stored_image.size,
                    "mime_type": stored_image.mime_type,
                }
            except Exception as e:
                return None
        return None

    @staticmethod
    def procesar_evidencia_base64(
        evidencia_data, establecimiento_id, fecha, inspeccion_id
    ):
        """Procesar evidencia desde datos base64"""
        try:

            # Extraer información de la evidencia
            filename = evidencia_data.get("name", f"evidencia_{inspeccion_id}.jpg")
            base64_data = evidencia_data.get("data", "")
            mime_type = evidencia_data.get("type", "image/jpeg")


            if not base64_data:
                return None

            directorio = InspeccionesController.crear_directorio_evidencias(
                establecimiento_id, fecha
            )
            if not directorio:
                return None

            timestamp = datetime.now().strftime("%H%M%S_%f")[:-3]
            if "," not in base64_data:
                base64_data = f"data:{mime_type};base64,{base64_data}"

            stored_image = save_validated_base64_image(
                base64_data,
                filename,
                directorio,
                f"evidencia_{inspeccion_id}_{timestamp}",
            )
            ruta_relativa = InspeccionesController._build_static_relative_path(
                stored_image.filepath
            )

            resultado = {
                "filename": stored_image.filename,
                "ruta_archivo": ruta_relativa,
                "tamano_bytes": stored_image.size,
                "mime_type": stored_image.mime_type,
            }

            return resultado

        except Exception as e:
            import traceback

            traceback.print_exc()
            return None

    @staticmethod
    def guardar_evidencias_inspeccion(
        evidencias_files, inspeccion_id, establecimiento_id, fecha
    ):
        """Guardar múltiples evidencias para una inspección"""
        evidencias_guardadas = []

        try:
            for file in evidencias_files:
                evidencia_info = InspeccionesController.guardar_evidencia(
                    file, establecimiento_id, fecha, inspeccion_id
                )

                if evidencia_info:
                    # Crear registro en la base de datos
                    evidencia = EvidenciaInspeccion(
                        inspeccion_id=inspeccion_id,
                        filename=evidencia_info["filename"],
                        ruta_archivo=evidencia_info["ruta_archivo"],
                        mime_type=evidencia_info["mime_type"],
                        tamano_bytes=evidencia_info["tamano_bytes"],
                    )

                    db.session.add(evidencia)
                    evidencias_guardadas.append(evidencia_info)

            # Confirmar cambios en la base de datos
            db.session.commit()
            return evidencias_guardadas

        except Exception as e:
            db.session.rollback()
            return []

    @staticmethod
    def obtener_establecimientos():
        try:
            user_role = session.get("user_role")
            user_id = session.get("user_id")

            # Admin e Inspector pueden ver todos los establecimientos
            if user_role in [ROL_ADMINISTRADOR, ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR]:
                establecimientos = Establecimiento.query.filter_by(activo=True).all()

            # Inspector solo ve establecimientos asignados (DESCOMENTAR SI QUIERES RESTRICCIONES)
            # elif user_role == "Inspector":
            #     establecimientos = (
            #         db.session.query(Establecimiento)
            #         .join(
            #             InspectorEstablecimiento,
            #             Establecimiento.id
            #             == InspectorEstablecimiento.establecimiento_id,
            #         )
            #         .filter(
            #             InspectorEstablecimiento.inspector_id == user_id,
            #             InspectorEstablecimiento.activo == True,
            #             Establecimiento.activo == True,
            #             InspectorEstablecimiento.fecha_asignacion <= date.today(),
            #         )
            #         .filter(
            #             (InspectorEstablecimiento.fecha_fin_asignacion.is_(None))
            #             | (
            #                 InspectorEstablecimiento.fecha_fin_asignacion
            #                 >= date.today()
            #             )
            #         )
            #         .all()
            #     )

            # Encargado solo ve sus establecimientos
            elif user_role == ROL_ENCARGADO:
                establecimientos = (
                    db.session.query(Establecimiento)
                    .join(
                        EncargadoEstablecimiento,
                        Establecimiento.id
                        == EncargadoEstablecimiento.establecimiento_id,
                    )
                    .filter(
                        EncargadoEstablecimiento.usuario_id == user_id,
                        EncargadoEstablecimiento.activo == True,
                        Establecimiento.activo == True,
                        EncargadoEstablecimiento.fecha_inicio <= date.today(),
                    )
                    .filter(
                        (EncargadoEstablecimiento.fecha_fin.is_(None))
                        | (EncargadoEstablecimiento.fecha_fin >= date.today())
                    )
                    .all()
                )

            # Jefe de Establecimiento solo ve su establecimiento asignado
            elif user_role == ROL_JEFE_ESTABLECIMIENTO:
                establecimiento_ids = (
                    InspeccionesController._obtener_establecimientos_autorizados(
                        user_id, user_role
                    )
                )
                establecimientos = (
                    Establecimiento.query.filter(
                        Establecimiento.id.in_(establecimiento_ids),
                        Establecimiento.activo == True,
                    ).all()
                    if establecimiento_ids
                    else []
                )

            else:
                return jsonify({"error": "Rol no autorizado"}), 403

            data = []
            fecha_actual = date.today()

            for e in establecimientos:
                
                # Obtener tipo de establecimiento de manera segura
                tipo_establecimiento_nombre = None
                try:
                    if hasattr(e, 'tipo_establecimiento') and e.tipo_establecimiento:
                        tipo_establecimiento_nombre = e.tipo_establecimiento.nombre
                except Exception as tipo_error:
                    import logging
                    logging.error(f"Error obteniendo tipo de establecimiento: {str(tipo_error)}")

                # FILTRADO POR META SEMANAL: Solo para inspectores
                if user_role == "Inspector":
                    try:
                        # Calcular semana actual (LUNES A DOMINGO)
                        import pytz
                        lima_tz = pytz.timezone("America/Lima")
                        fecha_obj = datetime.now(lima_tz)
                        semana_actual = fecha_obj.isocalendar()[1]
                        ano_actual = fecha_obj.year

                        # Obtener plan semanal del establecimiento
                        plan_semanal = InspeccionesController.obtener_o_crear_plan_semanal(
                            e.id, semana_actual, ano_actual
                        )

                        # Contar inspecciones completadas en la semana actual
                        from sqlalchemy import func
                        inicio_semana = fecha_obj.date() - timedelta(days=fecha_obj.weekday())  # Lunes de esta semana
                        fin_semana = inicio_semana + timedelta(days=6)  # Domingo de esta semana

                        inspecciones_completadas = Inspeccion.query.filter(
                            func.date(Inspeccion.fecha) >= inicio_semana,
                            func.date(Inspeccion.fecha) <= fin_semana,
                            Inspeccion.establecimiento_id == e.id,
                            Inspeccion.estado == 'completada'
                        ).count()

                        # Si ya alcanzó la meta semanal, saltar este establecimiento
                        if inspecciones_completadas >= plan_semanal.evaluaciones_meta:
                            continue

                    except Exception as meta_error:
                        import logging
                        logging.warning(f"Error verificando meta semanal para establecimiento {e.id}: {str(meta_error)}")
                        # En caso de error, incluir el establecimiento para no bloquear funcionalidad

                # Obtener el encargado actual del establecimiento
                try:
                    encargado = (
                        EncargadoEstablecimiento.query.filter(
                            EncargadoEstablecimiento.establecimiento_id == e.id,
                            EncargadoEstablecimiento.activo == True,
                            EncargadoEstablecimiento.fecha_inicio <= fecha_actual,
                            (
                                EncargadoEstablecimiento.fecha_fin.is_(None)
                                | (EncargadoEstablecimiento.fecha_fin >= fecha_actual)
                            ),
                        )
                        .order_by(
                            EncargadoEstablecimiento.es_principal.desc(),
                            EncargadoEstablecimiento.fecha_inicio.desc(),
                        )
                        .first()
                    )
                except Exception as encargado_error:
                    encargado = None

                data.append(
                    {
                        "id": e.id,
                        "nombre": e.nombre,
                        "direccion": e.direccion,
                        "tipo_establecimiento_id": e.tipo_establecimiento_id,
                        "tipo_establecimiento": tipo_establecimiento_nombre,
                        "encargado_actual": (
                            {
                                "id": encargado.usuario.id,
                                "nombre": f"{encargado.usuario.nombre} {encargado.usuario.apellido or ''}".strip(),
                                "correo": encargado.usuario.correo,
                                "telefono": encargado.usuario.telefono,
                            }
                            if encargado
                            else None
                        ),
                    }
                )

            return jsonify(data)
        except Exception as e:
            import traceback
            return (
                jsonify({"error": f"Error al obtener establecimientos: {str(e)}"}),
                500,
            )

    @staticmethod
    def obtener_categorias():
        try:
            categorias = (
                CategoriaEvaluacion.query.filter_by(activo=True)
                .order_by(CategoriaEvaluacion.orden)
                .all()
            )
            data = [
                {
                    "id": c.id,
                    "nombre": c.nombre,
                    "descripcion": c.descripcion,
                    "orden": c.orden,
                    "lista_items": [],
                }
                for c in categorias
            ]
            return jsonify({"success": True, "categorias": data})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 500

    @staticmethod
    def obtener_items_establecimiento(establecimiento_id):
        try:
            # Obtener todos los items del establecimiento con sus categorías
            items = (
                db.session.query(
                    ItemEvaluacionEstablecimiento,
                    ItemEvaluacionBase,
                    CategoriaEvaluacion,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(
                    ItemEvaluacionEstablecimiento.establecimiento_id
                    == establecimiento_id,
                    ItemEvaluacionEstablecimiento.activo == True,
                    ItemEvaluacionBase.activo == True,
                    CategoriaEvaluacion.activo == True,
                )
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Organizar los datos en un formato más limpio
            categorias = {}
            for item, item_base, categoria in items:
                if categoria.id not in categorias:
                    categorias[categoria.id] = {
                        "id": categoria.id,
                        "nombre": categoria.nombre,
                        "descripcion": categoria.descripcion,
                        "orden": categoria.orden,
                        "items": [],
                    }

                categorias[categoria.id]["items"].append(
                    {
                        "id": item.id,
                        "item_base_id": item_base.id,
                        "codigo": item_base.codigo,
                        "puntaje_minimo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_minimo"],
                        "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_maximo"],
                        "descripcion": item.descripcion_personalizada
                        or item_base.descripcion,
                        "riesgo": item_base.riesgo,
                        "orden": item_base.orden,
                        "factor_ajuste": float(item.factor_ajuste),
                    }
                )

            # Convertir a lista ordenada por orden
            categorias_lista = list(categorias.values())
            categorias_lista.sort(key=lambda x: x["orden"])

            return jsonify({"success": True, "categorias": categorias_lista})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def calcular_puntajes_inspeccion(inspeccion_id):
        """Calcula automáticamente los puntajes de una inspección"""
        try:
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                raise Exception("Inspección no encontrada")

            items_configurados = (
                InspeccionesController._obtener_items_activos_establecimiento(
                    inspeccion.establecimiento_id
                )
            )
            puntaje_maximo_posible = sum(
                InspeccionesController._obtener_configuracion_calificacion(
                    item_base.riesgo
                )["puntaje_maximo"]
                for _, item_base in items_configurados
            )
            total_items = len(items_configurados)

            # Obtener todos los detalles de la inspección
            detalles = (
                db.session.query(
                    InspeccionDetalle, ItemEvaluacionEstablecimiento, ItemEvaluacionBase
                )
                .join(
                    ItemEvaluacionEstablecimiento,
                    InspeccionDetalle.item_establecimiento_id
                    == ItemEvaluacionEstablecimiento.id,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .filter(InspeccionDetalle.inspeccion_id == inspeccion_id)
                .all()
            )

            puntaje_total = 0
            suma_porcentaje_cumplimiento = 0
            puntos_criticos_perdidos = 0
            items_calificados = 0

            for detalle, item_est, item_base in detalles:
                metricas_rating = InspeccionesController._calcular_metricas_rating(
                    item_base.riesgo,
                    detalle.rating if detalle.rating is not None else detalle.score,
                )
                if not metricas_rating:
                    continue

                puntaje_total += metricas_rating["puntaje"]
                suma_porcentaje_cumplimiento += metricas_rating[
                    "porcentaje_cumplimiento"
                ]
                puntos_criticos_perdidos += metricas_rating["criticos_no_conformes"]
                items_calificados += 1

            porcentaje = (
                (suma_porcentaje_cumplimiento / items_calificados)
                if items_calificados > 0
                else 0
            )
            puntaje_promedio_item = (
                round(puntaje_total / items_calificados, 2)
                if items_calificados > 0
                else 0
            )

            inspeccion.puntaje_total = puntaje_total
            inspeccion.puntaje_maximo_posible = puntaje_maximo_posible
            inspeccion.porcentaje_cumplimiento = round(porcentaje, 2)
            inspeccion.puntos_criticos_perdidos = puntos_criticos_perdidos
            db.session.commit()

            return {
                "puntaje_total": puntaje_total,
                "puntaje_maximo_posible": puntaje_maximo_posible,
                "puntaje_promedio_item": puntaje_promedio_item,
                "porcentaje_cumplimiento": round(porcentaje, 2),
                "puntos_criticos_perdidos": puntos_criticos_perdidos,
                "items_calificados": items_calificados,
                "total_items": total_items,
            }

        except Exception as e:
            db.session.rollback()
            raise Exception(f"Error calculando puntajes: {str(e)}")

    @staticmethod
    def guardar_inspeccion_parcial():
        """Guardar datos temporales del formulario en memoria del servidor"""
        try:
            # Manejar tanto JSON como texto plano (sendBeacon)
            if request.is_json:
                data = request.get_json(silent=True) or {}
            else:
                # Para sendBeacon que envía como texto plano
                import json

                data = json.loads(request.data.decode("utf-8"))

            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            if not data:
                return jsonify({"error": "No hay datos para guardar"}), 400

            if user_role not in ROLES_EDITOR_INSPECCION:
                return jsonify({"error": "No autorizado para editar inspecciones"}), 403

            # Crear clave única para el establecimiento (cambio para permitir colaboración cross-inspector)
            establecimiento_id = data.get("establecimiento_id")
            if not establecimiento_id:
                return jsonify({"error": "ID de establecimiento requerido"}), 400

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            establecimiento_id = int(establecimiento_id)
            data["establecimiento_id"] = establecimiento_id

            # Agregar el inspector_id a los datos si no existe (para rastrear quién está trabajando)
            if 'inspector_id' not in data:
                data['inspector_id'] = user_id

            clave_temporal = f"establecimiento_{establecimiento_id}"

            # Guardar en memoria del servidor
            inspecciones_temporales[clave_temporal] = {
                "data": data,
                "timestamp": safe_timestamp(),
                "user_id": user_id,
            }

            # Debug logging

            # Actualizar datos tiempo real SOLO SI HAY CAMBIOS
            establecimiento_id = data.get("establecimiento_id")
            if establecimiento_id:
                clave_tiempo_real = f"establecimiento_{establecimiento_id}"

                # Obtener datos anteriores para comparar
                datos_anteriores = datos_tiempo_real.get(clave_tiempo_real, {})
                items_anteriores = datos_anteriores.get("items", {})
                observaciones_anteriores = datos_anteriores.get("observaciones", "")

                # Verificar si hay cambios reales
                items_actuales = data.get("items", {})
                observaciones_actuales = data.get("observaciones", "")
                items_cambiaron = items_actuales != items_anteriores
                observaciones_cambiaron = (
                    observaciones_actuales != observaciones_anteriores
                )

                hay_cambios = items_cambiaron or observaciones_cambiaron

                if hay_cambios:
                    if clave_tiempo_real not in datos_tiempo_real:
                        datos_tiempo_real[clave_tiempo_real] = {}

                    estado_actual_tiempo_real = datos_tiempo_real[clave_tiempo_real]

                    # Reiniciar confirmacion del encargado solo cuando cambian items/puntajes del checklist
                    if items_cambiaron and estado_actual_tiempo_real.get("confirmada_por_encargado"):
                        estado_actual_tiempo_real["confirmada_por_encargado"] = False
                        estado_actual_tiempo_real["confirmador_id"] = None
                        estado_actual_tiempo_real["confirmador_nombre"] = None
                        estado_actual_tiempo_real["confirmador_rol"] = None
                        estado_actual_tiempo_real["fecha_confirmacion"] = None

                    # Calcular resumen automáticamente basado en los items
                    resumen_calculado = {}
                    if items_actuales:
                        try:
                            puntaje_total = 0
                            suma_porcentaje_cumplimiento = 0
                            puntos_criticos_perdidos = 0
                            items_evaluados = 0
                            items_configurados = (
                                InspeccionesController._obtener_items_activos_establecimiento(
                                    establecimiento_id
                                )
                            )
                            items_por_id = {
                                item_est.id: item_base
                                for item_est, item_base in items_configurados
                            }
                            total_items = len(items_configurados)
                            puntaje_maximo_posible = sum(
                                InspeccionesController._obtener_configuracion_calificacion(
                                    item_base.riesgo
                                )["puntaje_maximo"]
                                for item_base in items_por_id.values()
                            )

                            for item_id_str, item_data in items_actuales.items():
                                try:
                                    # Evitar procesar items con ID 'undefined'
                                    if (
                                        item_id_str == "undefined"
                                        or not item_id_str.isdigit()
                                    ):
                                        continue

                                    item_id = int(item_id_str)
                                    item_base = items_por_id.get(item_id)
                                    if not item_base:
                                        continue

                                    if (
                                        "rating" not in item_data
                                        or item_data["rating"] is None
                                    ):
                                        continue

                                    metricas_rating = (
                                        InspeccionesController._calcular_metricas_rating(
                                            item_base.riesgo, item_data["rating"]
                                        )
                                    )
                                    if not metricas_rating:
                                        continue

                                    items_evaluados += 1
                                    puntaje_total += metricas_rating["puntaje"]
                                    suma_porcentaje_cumplimiento += metricas_rating[
                                        "porcentaje_cumplimiento"
                                    ]
                                    puntos_criticos_perdidos += metricas_rating[
                                        "criticos_no_conformes"
                                    ]
                                except (ValueError, TypeError):
                                    continue

                            porcentaje = (
                                (suma_porcentaje_cumplimiento / items_evaluados)
                                if items_evaluados > 0
                                else 0
                            )
                            puntaje_promedio_item = (
                                round(puntaje_total / items_evaluados, 2)
                                if items_evaluados > 0
                                else 0
                            )

                            resumen_calculado = {
                                "puntaje_total": round(puntaje_total, 2),
                                "puntaje_maximo_posible": round(
                                    puntaje_maximo_posible, 2
                                ),
                                "puntaje_promedio_item": puntaje_promedio_item,
                                "porcentaje_cumplimiento": round(porcentaje, 2),
                                "puntos_criticos_perdidos": round(
                                    puntos_criticos_perdidos, 2
                                ),
                                "items_calificados": items_evaluados,
                                "items_evaluados": items_evaluados,
                                "total_items": total_items,
                            }
                        except Exception as e:
                            resumen_calculado = {}

                    estado_actual_tiempo_real.update(
                        {
                            "establecimiento_id": establecimiento_id,
                            "inspector_id": user_id,
                            "items": items_actuales,
                            "observaciones": observaciones_actuales,
                            "resumen": resumen_calculado,
                            "ultima_actualizacion": safe_timestamp(),
                        }
                    )

                    # SOLO emitir actualización en tiempo real cuando HAY CAMBIOS
                    try:
                        room = f"establecimiento_{establecimiento_id}"
                        socketio.emit(
                            "inspeccion_tiempo_real",
                            {
                                "establecimiento_id": establecimiento_id,
                                "inspector_id": user_id,
                                "items": items_actuales,
                                "observaciones": observaciones_actuales,
                                "resumen": resumen_calculado,
                                "confirmada_por_encargado": estado_actual_tiempo_real.get("confirmada_por_encargado", False),
                                "confirmador_nombre": estado_actual_tiempo_real.get("confirmador_nombre"),
                                "confirmador_rol": estado_actual_tiempo_real.get("confirmador_rol"),
                                "firma_data": estado_actual_tiempo_real.get("firma_encargado"),
                                "firma_temporal": bool(estado_actual_tiempo_real.get("firma_temporal")),
                                "timestamp": safe_timestamp(),
                            },
                            to=room,
                        )

                        # Tiempo real: Cambios detectados y enviados por Inspector
                    except Exception as e:
                        pass  # Error silenciado en producción
                else:
                    pass  # No hay cambios - omitiendo emisión tiempo real

            return jsonify(
                {
                    "mensaje": "Datos guardados temporalmente",
                    "timestamp": inspecciones_temporales[clave_temporal]["timestamp"],
                }
            )

        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def recuperar_inspeccion_temporal():
        """Recuperar datos temporales del formulario desde memoria del servidor"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            establecimiento_ids = (
                InspeccionesController._obtener_establecimientos_autorizados(
                    user_id, user_role
                )
            )
            establecimiento_solicitado = request.args.get(
                "establecimiento_id", type=int
            )

            if establecimiento_solicitado is not None:
                if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                    user_id, user_role, establecimiento_solicitado
                ):
                    return jsonify({"error": "Sin acceso a este establecimiento"}), 403
                establecimiento_ids = [establecimiento_solicitado]

            # Buscar datos temporales por establecimiento (cambio para permitir colaboración cross-inspector)
            datos_guardados = None
            for establecimiento_id in establecimiento_ids:
                clave_temporal = f"establecimiento_{establecimiento_id}"
                datos_establecimiento = inspecciones_temporales.get(clave_temporal)
                if datos_establecimiento:
                    datos_guardados = datos_establecimiento
                    break

            if datos_guardados:
                return jsonify(datos_guardados["data"])
            else:
                return jsonify({})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def obtener_estado_sincronizado_establecimiento(establecimiento_id):
        """Obtener el estado sincronizado del establecimiento para Inspector y Encargado"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            # Buscar datos temporales de cualquier usuario en este establecimiento
            datos_establecimiento = None
            max_items = 0

            # Buscar el estado con más datos (más avanzado)
            for clave, datos in inspecciones_temporales.items():
                if datos.get("data", {}).get("establecimiento_id") == int(
                    establecimiento_id
                ):
                    items_count = len(datos["data"].get("items", {}))
                    if items_count > max_items:
                        max_items = items_count
                        datos_establecimiento = datos["data"]

            # Si no hay datos temporales, buscar en datos de tiempo real
            if not datos_establecimiento:
                clave_tiempo_real = f"establecimiento_{establecimiento_id}"
                datos_tiempo_real_est = datos_tiempo_real.get(clave_tiempo_real)
                if datos_tiempo_real_est:
                    datos_establecimiento = datos_tiempo_real_est

            if datos_establecimiento:
                return jsonify(datos_establecimiento)
            else:
                return jsonify({})

        except Exception as e:
            return jsonify({"error": str(e)}), 500
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def limpiar_inspeccion_temporal():
        """Borrar datos temporales al guardar la inspección"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")
            payload = request.get_json(silent=True) or {}
            establecimiento_id = request.args.get("establecimiento_id") or payload.get(
                "establecimiento_id"
            )

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            # Limpiar datos temporales del establecimiento (cambio para permitir colaboración cross-inspector)
            if establecimiento_id:
                if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                    user_id, user_role, establecimiento_id
                ):
                    return (
                        jsonify({"error": "Sin acceso a este establecimiento"}),
                        403,
                    )

                # Limpiar inspecciones_temporales
                clave_temporal = f"establecimiento_{establecimiento_id}"
                if clave_temporal in inspecciones_temporales:
                    del inspecciones_temporales[clave_temporal]
                    logging.info(f"Datos temporales eliminados: {clave_temporal}")

                # Limpiar datos_tiempo_real
                clave_tiempo_real = f"establecimiento_{establecimiento_id}"
                if clave_tiempo_real in datos_tiempo_real:
                    del datos_tiempo_real[clave_tiempo_real]
                    logging.info(f"Datos tiempo real eliminados: {clave_tiempo_real}")

            return jsonify({"mensaje": "Datos temporales eliminados"})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def obtener_datos_temporales_establecimiento(establecimiento_id):
        """
        Obtener datos temporales de inspección para un establecimiento específico
        PERMISOS: Inspector y Administrador
        """
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            # Verificar permisos
            if user_role not in [ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR, ROL_ADMINISTRADOR]:
                return jsonify({"error": "No autorizado"}), 403

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            # Buscar datos temporales para este establecimiento
            clave_temporal = f"establecimiento_{establecimiento_id}"
            datos_temporales = inspecciones_temporales.get(clave_temporal)

            if datos_temporales:
                return jsonify(datos_temporales["data"])
            else:
                return jsonify({})

        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def obtener_datos_tiempo_real_encargado(establecimiento_id):
        """Obtener datos en tiempo real para que el encargado vea lo que califica el inspector"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            datos = datos_tiempo_real.get(clave_tiempo_real, {})

            return jsonify({"encontrado": bool(datos), "datos": datos})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def obtener_datos_tiempo_real_establecimiento(establecimiento_id):
        """Obtener datos actuales de tiempo real para un establecimiento específico"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            # Verificar permisos
            if user_role not in ["Encargado", "Administrador", "Jefe de Establecimiento"]:
                return (
                    jsonify({"error": "Sin permisos para ver datos en tiempo real"}),
                    403,
                )

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            datos = datos_tiempo_real.get(clave_tiempo_real, {})

            # Si no hay datos en tiempo real, intentar obtener el estado actual desde la base de datos
            if not datos or len(datos) == 0:
                try:
                    # Buscar inspección temporal más reciente para este establecimiento
                    from app.models.Inspecciones_models import Inspeccion, InspeccionDetalle, ItemEvaluacionEstablecimiento, ItemEvaluacionBase

                    # Buscar la inspección más reciente en proceso para este establecimiento
                    inspeccion_temporal = Inspeccion.query.filter_by(
                        establecimiento_id=establecimiento_id,
                        estado='en_proceso'
                    ).order_by(Inspeccion.updated_at.desc()).first()

                    if inspeccion_temporal:
                        # Obtener detalles de la inspección temporal
                        detalles = InspeccionDetalle.query.filter_by(
                            inspeccion_id=inspeccion_temporal.id
                        ).all()

                        # Construir datos de items
                        items_data = {}
                        for detalle in detalles:
                            if detalle.rating is not None:
                                items_data[str(detalle.item_establecimiento_id)] = {
                                    'rating': detalle.rating,
                                    'observacion': detalle.observacion_item or '',
                                    'puntaje_maximo': InspeccionesController._obtener_configuracion_calificacion(
                                        detalle.item_establecimiento.item_base.riesgo
                                    )['puntaje_maximo'],
                                    'riesgo': detalle.item_establecimiento.item_base.riesgo
                                }

                        # Calcular resumen
                        resumen = InspeccionesController.calcular_puntajes_inspeccion(inspeccion_temporal.id) or {}

                        # Construir respuesta con datos de la BD
                        datos = {
                            'establecimiento_id': establecimiento_id,
                            'actualizado_por': 'Inspector',
                            'resumen': {
                                'puntaje_total': resumen.get('puntaje_total', 0),
                                'puntaje_maximo_posible': resumen.get('puntaje_maximo_posible', 0),
                                'porcentaje_cumplimiento': resumen.get('porcentaje_cumplimiento', 0),
                                'puntos_criticos_perdidos': resumen.get('puntos_criticos_perdidos', 0),
                                'total_items': resumen.get('total_items', 0),
                                'items_calificados': resumen.get('items_calificados', 0)
                            },
                            'items': items_data,
                            'observaciones': inspeccion_temporal.observaciones or '',
                            'timestamp': inspeccion_temporal.updated_at.isoformat() if inspeccion_temporal.updated_at else None
                        }

                except Exception as db_error:
                    # Si hay error consultando BD, continuar con datos vacíos
                    pass

            if datos and len(datos) > 0:
                return jsonify(datos)
            else:
                return jsonify({})  # Retornar objeto vacío si no hay datos
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def _guardar_archivo(archivo, folder):
        if not os.path.exists(folder):
            os.makedirs(folder)

        filename = secure_filename(archivo.filename)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_{filename}"
        filepath = os.path.join(folder, filename)
        archivo.save(filepath)
        return filepath.replace("app/static/", "")

    @staticmethod
    def guardar_inspeccion():
        try:
            import logging
            logging.info("=== INICIO guardar_inspeccion ===")
            
            data = request.get_json()
            logging.info(f"Datos recibidos: {data}")

            if not data:
                logging.error("No se recibieron datos")
                return jsonify({"error": "No se recibieron datos"}), 400

            # Validar datos requeridos
            establecimiento_id = data.get("establecimiento_id")
            inspector_id = session.get("user_id")
            fecha = data.get("fecha")
            observaciones = data.get("observaciones", "")
            observaciones_limpias = (
                InspeccionesController._limpiar_metadatos_observaciones(observaciones)
            )
            items_data = data.get("items", {})
            accion = data.get("accion")  # guardar o completar
            print("La accion es:", accion)
            firma_inspector = data.get("firma_inspector")  # Firma del inspector
            firma_encargado = data.get("firma_encargado")  # Firma del encargado
            motivo_sin_firma_encargado = (
                InspeccionesController._normalizar_motivo_sin_firma(
                    data.get("motivo_sin_firma_encargado")
                )
            )
            completar_sin_firma_encargado = str(
                data.get("completar_sin_firma_encargado", "")
            ).strip().lower() in {"1", "true", "t", "yes", "si", "sí"}
            evidencias_data = data.get(
                "evidencias", []
            )  # Lista de evidencias en base64

            logging.info(f"establecimiento_id: {establecimiento_id}")
            logging.info(f"inspector_id: {inspector_id}")
            logging.info(f"fecha: {fecha}")
            logging.info(f"accion: {accion}")

            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            estado_tiempo_real_actual = datos_tiempo_real.get(clave_tiempo_real)
            confirmada_por_encargado_tiempo_real = bool(
                estado_tiempo_real_actual.get("confirmada_por_encargado")
            ) if estado_tiempo_real_actual else False
            confirmador_id_tiempo_real = (
                estado_tiempo_real_actual.get("confirmador_id")
                if estado_tiempo_real_actual
                else None
            )
            confirmador_rol_tiempo_real = (
                estado_tiempo_real_actual.get("confirmador_rol")
                if estado_tiempo_real_actual
                else None
            )

            if (
                accion == "completar"
                and not firma_encargado
                and estado_tiempo_real_actual
                and confirmada_por_encargado_tiempo_real
                and estado_tiempo_real_actual.get("firma_encargado")
            ):
                firma_encargado = estado_tiempo_real_actual.get("firma_encargado")
                logging.info("Usando firma temporal/confirmada del encargado desde el estado en tiempo real")

            if (
                accion == "completar"
                and estado_tiempo_real_actual is not None
                and not confirmada_por_encargado_tiempo_real
            ):
                completar_sin_firma_encargado = True

            if not all([establecimiento_id, inspector_id, fecha]):
                logging.error("Faltan datos requeridos")
                return jsonify({"error": "Faltan datos requeridos"}), 400

            # Identificar tipo de firma recibida (base64, ruta de archivo, o diccionario precargado)
            firma_encargado_base64 = None
            firma_encargado_ruta = None
            firma_encargado_dict = None
            if isinstance(firma_encargado, str):
                if firma_encargado.startswith("data:image/"):
                    firma_encargado_base64 = firma_encargado
                    logging.info("Firma del encargado detectada como base64")
                elif firma_encargado.startswith((
                    "img/firmas/",
                    "static/img/firmas/",
                    "static/firmas/",
                    "firmas/",
                    "/static/img/firmas/",
                    "/static/firmas/",
                    "/media/firmas/",
                    "media/firmas/",
                )):
                    firma_encargado_ruta = normalize_signature_reference(firma_encargado)
                    logging.info(f"Firma del encargado detectada como ruta: {firma_encargado_ruta}")
                else:
                    logging.warning(f"Firma del encargado no reconocida: {firma_encargado[:50]}...")
            elif isinstance(firma_encargado, dict):
                firma_encargado_dict = firma_encargado
                logging.info(f"Firma del encargado detectada como diccionario precargado: {firma_encargado_dict}")
            else:
                logging.warning(f"Firma del encargado no es string ni dict: {type(firma_encargado)}")
                logging.warning(f"Contenido de firma_encargado: {firma_encargado}")
                    
            firma_inspector_base64 = None
            firma_inspector_ruta = None
            firma_inspector_dict = None
            if isinstance(firma_inspector, str):
                if firma_inspector.startswith("data:image/"):
                    firma_inspector_base64 = firma_inspector
                    logging.info("Firma del inspector detectada como base64")
                elif firma_inspector.startswith((
                    "img/firmas/",
                    "static/img/firmas/",
                    "static/firmas/",
                    "firmas/",
                    "/static/img/firmas/",
                    "/static/firmas/",
                    "/media/firmas/",
                    "media/firmas/",
                )):
                    firma_inspector_ruta = normalize_signature_reference(firma_inspector)
                    logging.info(f"Firma del inspector detectada como ruta: {firma_inspector_ruta}")
                else:
                    logging.warning(f"Firma del inspector no reconocida: {firma_inspector[:50]}...")
            elif isinstance(firma_inspector, dict):
                firma_inspector_dict = firma_inspector
                logging.info(f"Firma del inspector detectada como diccionario precargado: {firma_inspector_dict}")
            else:
                logging.warning(f"Firma del inspector no es string ni dict: {type(firma_inspector)}")
                logging.warning(f"Contenido de firma_inspector: {firma_inspector}")

            # Obtener encargado actual del establecimiento
            fecha_obj = datetime.strptime(fecha, "%Y-%m-%d").date()
            logging.info(f"Fecha parseada: {fecha_obj}")
            
            encargado = EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= fecha_obj,
                (
                    EncargadoEstablecimiento.fecha_fin.is_(None)
                    | (EncargadoEstablecimiento.fecha_fin >= fecha_obj)
                ),
            ).first()
            
            logging.info(f"Encargado encontrado: {encargado}")

            if encargado:
                encargado_id = encargado.usuario_id
                logging.info(f"encargado_id: {encargado_id}")
            else:
                encargado_id = None
                logging.info("No se encontró encargado")

            if confirmada_por_encargado_tiempo_real and confirmador_id_tiempo_real:
                try:
                    encargado_id = int(confirmador_id_tiempo_real)
                    logging.info(
                        "Usando firmante confirmado en tiempo real como encargado de la inspección: %s (%s)",
                        encargado_id,
                        confirmador_rol_tiempo_real or "Sin rol",
                    )
                except (TypeError, ValueError):
                    logging.warning(
                        "confirmador_id_tiempo_real inválido al guardar inspección: %s",
                        confirmador_id_tiempo_real,
                    )

            # Crear o actualizar la inspección
            inspeccion_id_raw = data.get("inspeccion_id")
            inspeccion_id = None
            if inspeccion_id_raw not in (None, "", False):
                try:
                    inspeccion_id = int(inspeccion_id_raw)
                except (TypeError, ValueError):
                    logging.warning(
                        "inspeccion_id invalido recibido en guardar_inspeccion: %s",
                        inspeccion_id_raw,
                    )
                    inspeccion_id = None

            # ✅ VALIDACIÓN PLAN SEMANAL: Verificar que no se exceda la meta semanal antes de crear inspección
            if not inspeccion_id:  # Solo validar para nuevas inspecciones
                try:
                    # Importar módulos necesarios para cálculo de semana
                    import pytz
                    from sqlalchemy import func
                    
                    # ZONA HORARIA LIMA, PERÚ
                    lima_tz = pytz.timezone("America/Lima")
                    fecha_obj = datetime.strptime(fecha, "%Y-%m-%d").date()
                    
                    # Calcular semana (LUNES A DOMINGO) de la fecha de inspección
                    dias_hasta_lunes = fecha_obj.weekday()  # weekday(): 0=Lunes, 1=Martes, ..., 6=Domingo
                    inicio_semana = fecha_obj - timedelta(days=dias_hasta_lunes)
                    fin_semana = inicio_semana + timedelta(days=6)
                    
                    # Contar inspecciones completadas en esta semana para el establecimiento
                    inspecciones_semana = Inspeccion.query.filter(
                        func.date(Inspeccion.fecha) >= inicio_semana,
                        func.date(Inspeccion.fecha) <= fin_semana,
                        Inspeccion.establecimiento_id == establecimiento_id,
                        Inspeccion.estado == 'completada'
                    ).count()
                    
                    # Obtener meta semanal del establecimiento
                    semana_actual = fecha_obj.isocalendar()[1]
                    ano_actual = fecha_obj.year
                    
                    plan_semanal = InspeccionesController.obtener_o_crear_plan_semanal(
                        establecimiento_id, semana_actual, ano_actual
                    )
                    
                    meta_semanal = plan_semanal.evaluaciones_meta
                    
                    # Verificar si se excedería la meta
                    if inspecciones_semana >= meta_semanal:
                        return jsonify({
                            "error": f"No se puede crear la inspección. El establecimiento ya alcanzó la meta semanal de {meta_semanal} inspecciones completadas para la semana del {inicio_semana.strftime('%d/%m/%Y')} al {fin_semana.strftime('%d/%m/%Y')}.",
                            "detalles": {
                                "inspecciones_completadas": inspecciones_semana,
                                "meta_semanal": meta_semanal,
                                "semana_inicio": inicio_semana.isoformat(),
                                "semana_fin": fin_semana.isoformat()
                            }
                        }), 400
                        
                except Exception as e:
                    # No fallar la creación por error en validación, solo loggear
                    import logging
                    logging.warning(f"Error en validación de plan semanal: {str(e)}")

            inspeccion = None
            if inspeccion_id:
                # Actualizar inspección existente si sigue siendo válida para este flujo.
                inspeccion = Inspeccion.query.get(inspeccion_id)

                if not inspeccion:
                    logging.warning(
                        "Inspeccion %s no encontrada al guardar. Se creara una nueva.",
                        inspeccion_id,
                    )
                    inspeccion_id = None
                elif int(inspeccion.establecimiento_id) != int(establecimiento_id):
                    logging.warning(
                        "Inspeccion %s pertenece al establecimiento %s y se intento guardar para %s. Se creara una nueva.",
                        inspeccion_id,
                        inspeccion.establecimiento_id,
                        establecimiento_id,
                    )
                    inspeccion = None
                    inspeccion_id = None
                elif inspeccion.estado == "completada":
                    if accion == "completar":
                        logging.warning(
                            "Inspeccion %s ya estaba completada. Se omitira el guardado duplicado.",
                            inspeccion_id,
                        )
                        return jsonify(
                            InspeccionesController._construir_resultado_guardado(
                                inspeccion,
                                mensaje="La inspección ya había sido completada previamente. Se omitió el guardado duplicado.",
                                limpiar_temporal=True,
                                resetear_formulario=True,
                                actualizar_plan_semanal=False,
                                duplicado_omitido=True,
                            )
                        )

                    logging.warning(
                        "Inspeccion %s ya estaba completada. Se creara una nueva.",
                        inspeccion_id,
                    )
                    inspeccion = None
                    inspeccion_id = None

            if not inspeccion:
                # Crear nueva inspección
                inspeccion = Inspeccion(
                    establecimiento_id=establecimiento_id,
                    inspector_id=inspector_id,
                    encargado_id=encargado_id,
                    fecha=fecha_obj,
                )
                db.session.add(inspeccion)
                db.session.flush()  # Para obtener el ID

            # Actualizar datos básicos
            inspeccion.observaciones = observaciones_limpias
            if confirmada_por_encargado_tiempo_real and encargado_id:
                inspeccion.encargado_id = encargado_id
            elif inspeccion.encargado_id is None:
                inspeccion.encargado_id = encargado_id

            firma_encargado_existente = inspeccion.firma_encargado
            firma_inspector_existente = inspeccion.firma_inspector

            # DEBUG: Agregar logs para depuración
            import logging
            logging.info(f"DEBUG - Acción recibida: {accion}")
            logging.info(f"DEBUG - Firma_encargado_base64: {bool(firma_encargado_base64)}")
            logging.info(f"DEBUG - Firma_encargado_ruta: {firma_encargado_ruta}")
            logging.info(f"DEBUG - Firma_encargado_existente: {firma_encargado_existente}")
            logging.info(f"DEBUG - Firma_inspector_base64: {bool(firma_inspector_base64)}")
            logging.info(f"DEBUG - Firma_inspector_ruta: {firma_inspector_ruta}")
            logging.info(f"DEBUG - Firma_inspector_existente: {firma_inspector_existente}")

            # Manejar firmas y estado según la acción
            if accion == "completar":
                # Para completar, procesar las firmas según el formato recibido
                firmas_procesadas = True

                if completar_sin_firma_encargado:
                    # Finalizar sin aprobación del encargado implica no persistir su firma en la inspección.
                    inspeccion.firma_encargado = None
                    inspeccion.fecha_firma_encargado = None
                else:
                    # Procesar firma del encargado
                    if firma_encargado_base64:
                        # Firma en base64 - guardar como archivo
                        firmante_encargado_id = (
                            inspeccion.encargado_id
                            or encargado_id
                            or inspector_id
                        )
                        ruta_firma_encargado = guardar_firma_como_archivo(
                            firma_encargado_base64,
                            "encargado",
                            inspeccion.id,
                            firmante_encargado_id,
                        )
                        logging.info(f"Procesando firma_encargado_base64, ruta resultante: {ruta_firma_encargado}")
                        if ruta_firma_encargado:
                            inspeccion.firma_encargado = ruta_firma_encargado
                            inspeccion.fecha_firma_encargado = datetime.now()
                            logging.info(f"Firma del encargado guardada: {ruta_firma_encargado}")
                        else:
                            logging.error("ERROR: No se pudo guardar firma del encargado desde base64")
                            firmas_procesadas = False
                    elif firma_encargado_ruta:
                        ruta_normalizada = normalize_signature_reference(firma_encargado_ruta)
                        if ruta_normalizada:
                            inspeccion.firma_encargado = ruta_normalizada
                            if not inspeccion.fecha_firma_encargado:
                                inspeccion.fecha_firma_encargado = datetime.now()
                            logging.info(f"Firma del encargado desde ruta: {inspeccion.firma_encargado}")
                        else:
                            firmas_procesadas = False
                    elif firma_encargado_dict:
                        # Firma precargada desde diccionario
                        ruta_firma = firma_encargado_dict.get('ruta')
                        if ruta_firma:
                            ruta_normalizada = normalize_signature_reference(ruta_firma)
                            if ruta_normalizada:
                                inspeccion.firma_encargado = ruta_normalizada
                                if not inspeccion.fecha_firma_encargado:
                                    inspeccion.fecha_firma_encargado = datetime.now()
                                logging.info(f"Firma del encargado desde diccionario precargado: {inspeccion.firma_encargado}")
                            else:
                                firmas_procesadas = False
                        else:
                            logging.error("ERROR: Diccionario de firma del encargado no contiene ruta")
                            firmas_procesadas = False

                # Procesar firma del inspector
                if firma_inspector_base64:
                    # Firma en base64 - guardar como archivo
                    ruta_firma_inspector = guardar_firma_como_archivo(
                        firma_inspector_base64,
                        "inspector",
                        inspeccion.id,
                        inspector_id,
                    )
                    logging.info(f"Procesando firma_inspector_base64, ruta resultante: {ruta_firma_inspector}")
                    if ruta_firma_inspector:
                        inspeccion.firma_inspector = ruta_firma_inspector
                        inspeccion.fecha_firma_inspector = datetime.now()
                        logging.info(f"Firma del inspector guardada: {ruta_firma_inspector}")
                    else:
                        logging.error("ERROR: No se pudo guardar firma del inspector desde base64")
                        firmas_procesadas = False
                elif firma_inspector_ruta:
                    ruta_normalizada = normalize_signature_reference(firma_inspector_ruta)
                    if ruta_normalizada:
                        inspeccion.firma_inspector = ruta_normalizada
                        if not inspeccion.fecha_firma_inspector:
                            inspeccion.fecha_firma_inspector = datetime.now()
                        logging.info(f"Firma del inspector desde ruta: {inspeccion.firma_inspector}")
                    else:
                        firmas_procesadas = False
                elif firma_inspector_dict:
                    # Firma precargada desde diccionario
                    ruta_firma = firma_inspector_dict.get('ruta')
                    if ruta_firma:
                        ruta_normalizada = normalize_signature_reference(ruta_firma)
                        if ruta_normalizada:
                            inspeccion.firma_inspector = ruta_normalizada
                            if not inspeccion.fecha_firma_inspector:
                                inspeccion.fecha_firma_inspector = datetime.now()
                            logging.info(f"Firma del inspector desde diccionario precargado: {inspeccion.firma_inspector}")
                        else:
                            firmas_procesadas = False
                    else:
                        logging.error("ERROR: Diccionario de firma del inspector no contiene ruta")
                        firmas_procesadas = False

                # Verificar firmas requeridas después del procesamiento
                logging.info(f"Después del procesamiento - firma_encargado: {inspeccion.firma_encargado}")
                logging.info(f"Después del procesamiento - firma_inspector: {inspeccion.firma_inspector}")

                if not inspeccion.firma_inspector:
                    logging.error("ERROR: Falta la firma del inspector después del procesamiento")
                    firmas_procesadas = False

                if completar_sin_firma_encargado or not inspeccion.firma_encargado:
                    if not motivo_sin_firma_encargado:
                        return (
                            jsonify(
                                {
                                    "error": "Debe ingresar un motivo obligatorio para finalizar sin la firma del encargado"
                                }
                            ),
                            400,
                        )
                    inspeccion.observaciones = (
                        InspeccionesController._combinar_observaciones_con_motivo(
                            observaciones_limpias,
                            motivo_sin_firma_encargado,
                        )
                    )
                else:
                    inspeccion.observaciones = (
                        InspeccionesController._combinar_observaciones_con_motivo(
                            observaciones_limpias,
                            None,
                        )
                    )

                if not firmas_procesadas:
                    return jsonify({"error": "Error al procesar las firmas"}), 500

                inspeccion.estado = "completada"
                inspeccion.hora_fin = datetime.now().time()
                logging.info("DEBUG - Estado establecido a 'completada'")
            else:
                # Para guardar borrador (accion != "completar"):
                # - SOLO procesar firma del inspector (quien está trabajando)
                # - NO procesar firma del encargado (solo se procesa al completar)
                # - Estado: "en_proceso" (borrador)

                # Procesar SOLO firma del inspector (no del encargado en borradores)
                if not inspeccion.firma_inspector:
                    if firma_inspector_base64:
                        # Guardar firma del inspector desde base64
                        ruta_firma_inspector = guardar_firma_como_archivo(
                            firma_inspector_base64,
                            "inspector",
                            inspeccion.id,
                            inspector_id,
                        )
                        if ruta_firma_inspector:
                            inspeccion.firma_inspector = ruta_firma_inspector
                            inspeccion.fecha_firma_inspector = datetime.now()
                            logging.info(f"Firma del inspector guardada (borrador): {ruta_firma_inspector}")
                    elif firma_inspector_ruta:
                        ruta_normalizada = normalize_signature_reference(firma_inspector_ruta)
                        if ruta_normalizada:
                            inspeccion.firma_inspector = ruta_normalizada
                            if not inspeccion.fecha_firma_inspector:
                                inspeccion.fecha_firma_inspector = datetime.now()
                            logging.info(f"Firma del inspector desde ruta (borrador): {inspeccion.firma_inspector}")
                    elif firma_inspector_dict:
                        # Firma precargada desde diccionario
                        ruta_firma = firma_inspector_dict.get('ruta')
                        if ruta_firma:
                            ruta_normalizada = normalize_signature_reference(ruta_firma)
                            if ruta_normalizada:
                                inspeccion.firma_inspector = ruta_normalizada
                                if not inspeccion.fecha_firma_inspector:
                                    inspeccion.fecha_firma_inspector = datetime.now()
                                logging.info(f"Firma del inspector desde diccionario (borrador): {inspeccion.firma_inspector}")

                # NO procesar firma del encargado en borradores
                # La firma del encargado solo se procesa al completar (accion == "completar")
                logging.info("Guardando borrador - firma del encargado NO se procesa (solo al completar)")

                inspeccion.estado = "en_proceso"
                if not inspeccion.hora_inicio:
                    inspeccion.hora_inicio = datetime.now().time()
                logging.info("DEBUG - Estado establecido a 'en_proceso' (borrador)")

            items_procesados = 0
            items_establecimiento = (
                InspeccionesController._obtener_items_activos_establecimiento(
                    establecimiento_id
                )
            )
            items_validos_por_id = {
                item_est.id: item_base for item_est, item_base in items_establecimiento
            }

            # Guardar o actualizar detalles de items
            for item_id_raw, item_data in items_data.items():
                rating = item_data.get("rating")
                observacion_item = item_data.get("observacion", "")

                if rating is not None:
                    try:
                        item_id = int(item_id_raw)
                    except (TypeError, ValueError):
                        continue

                    item_base = items_validos_por_id.get(item_id)
                    if not item_base:
                        continue

                    es_valido, rating_normalizado, _ = (
                        InspeccionesController._normalizar_rating_por_riesgo(
                            item_base.riesgo, rating
                        )
                    )
                    if not es_valido:
                        db.session.rollback()
                        return (
                            jsonify(
                                {
                                    "error": (
                                        f"Calificación inválida para el item "
                                        f"{item_base.codigo}. Revise la escala aplicada."
                                    )
                                }
                            ),
                            400,
                        )

                    items_procesados += 1
                    # Buscar detalle existente
                    detalle = InspeccionDetalle.query.filter_by(
                        inspeccion_id=inspeccion.id, item_establecimiento_id=item_id
                    ).first()

                    if not detalle:
                        detalle = InspeccionDetalle(
                            inspeccion_id=inspeccion.id, item_establecimiento_id=item_id
                        )
                        db.session.add(detalle)

                    detalle.rating = rating_normalizado
                    detalle.score = float(rating_normalizado)
                    detalle.observacion_item = observacion_item

                    # Emitir actualización en tiempo real para que el encargado vea los cambios
                    try:
                        room = f"inspeccion_{inspeccion.id}"
                        socketio.emit(
                            "item_actualizado",
                            {
                                "inspeccion_id": inspeccion.id,
                                "item_id": item_id,
                                "rating": rating_normalizado,
                                "riesgo": item_base.riesgo,
                                "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                                    item_base.riesgo
                                )["puntaje_maximo"],
                                "observacion": observacion_item,
                                "actualizado_por": session.get(
                                    "user_role", "Inspector"
                                ),
                                "timestamp": safe_timestamp(),
                            },
                            to=room,
                        )
                    except Exception as e:
                        pass  # Error silenciado

            pass  # Items procesados exitosamente

            # Emitir actualización de observaciones generales si cambiaron
            if observaciones:
                try:
                    room = f"inspeccion_{inspeccion.id}"
                    socketio.emit(
                        "observaciones_actualizadas",
                        {
                            "inspeccion_id": inspeccion.id,
                            "observaciones": observaciones,
                            "actualizado_por": session.get("user_role", "Inspector"),
                            "timestamp": safe_timestamp(),
                        },
                        to=room,
                    )
                except Exception as e:
                    pass  # Error silenciado

            # Procesar evidencias si las hay
            evidencias_guardadas = []
            if evidencias_data and len(evidencias_data) > 0:
                for i, evidencia in enumerate(evidencias_data):
                    try:
                        # Procesar evidencia en base64
                        evidencia_info = (
                            InspeccionesController.procesar_evidencia_base64(
                                evidencia, establecimiento_id, fecha, inspeccion.id
                            )
                        )

                        if evidencia_info:
                            # Crear registro en la base de datos
                            evidencia_bd = EvidenciaInspeccion(
                                inspeccion_id=inspeccion.id,
                                filename=evidencia_info["filename"],
                                ruta_archivo=evidencia_info["ruta_archivo"],
                                mime_type=evidencia_info["mime_type"],
                                tamano_bytes=evidencia_info["tamano_bytes"],
                            )

                            db.session.add(evidencia_bd)

                            # Flush para obtener el ID generado
                            try:
                                db.session.flush()
                            except Exception as flush_error:
                                pass

                            evidencias_guardadas.append(evidencia_info)
                    except Exception as e:
                        import logging
                        logging.error(f"Error procesando evidencia: {str(e)}")
                        continue

            # Calcular puntajes automáticamente
            puntajes = None
            if accion == "completar":
                puntajes = InspeccionesController.calcular_puntajes_inspeccion(
                    inspeccion.id
                )

                # ✅ ORM: Actualizar plan semanal cuando se completa inspección
                try:
                    fecha_inspeccion = inspeccion.fecha
                    semana = fecha_inspeccion.isocalendar()[1]
                    ano = fecha_inspeccion.year
                    
                    plan = InspeccionesController.obtener_o_crear_plan_semanal(
                        establecimiento_id, semana, ano
                    )
                    
                    # Contar inspecciones completadas esta semana
                    from sqlalchemy import func
                    
                    # Calcular inicio y fin de semana
                    inicio_ano = datetime(ano, 1, 1)
                    inicio_semana = inicio_ano + timedelta(weeks=semana-1)
                    fin_semana = inicio_semana + timedelta(days=6)
                    
                    inspecciones_semana = Inspeccion.query.filter(
                        func.date(Inspeccion.fecha) >= inicio_semana.date(),
                        func.date(Inspeccion.fecha) <= fin_semana.date(),
                        Inspeccion.establecimiento_id == establecimiento_id,
                        Inspeccion.estado == 'completada'
                    ).count()
                    
                    plan.evaluaciones_realizadas = inspecciones_semana
                    
                    # Obtener nombre del establecimiento para el evento
                    establecimiento_obj = Establecimiento.query.get(establecimiento_id)
                    establecimiento_nombre = establecimiento_obj.nombre if establecimiento_obj else f'Establecimiento {establecimiento_id}'
                    
                    # Emitir evento para actualización en tiempo real
                    if socketio:
                        socketio.emit('plan_semanal_actualizado', {
                            'tipo': 'inspeccion_completada',
                            'establecimiento_id': establecimiento_id,
                            'establecimiento': establecimiento_nombre,
                            'evaluaciones_realizadas': inspecciones_semana,
                            'meta_semanal': plan.evaluaciones_meta
                        }, room=f'establecimiento_{establecimiento_id}')
                        
                    
                except Exception as e:
                    # No fallar la inspección por esto
                    pass

                # Emitir cambio de estado cuando se completa
                try:
                    room = f"inspeccion_{inspeccion.id}"
                    socketio.emit(
                        "estado_inspeccion_cambiado",
                        {
                            "inspeccion_id": inspeccion.id,
                            "estado": "completada",
                            "puntajes": puntajes,
                            "cambiado_por": session.get("user_role", "Inspector"),
                            "timestamp": safe_timestamp(),
                        },
                        to=room,
                    )
                except Exception as e:
                    import logging
                    logging.warning(f"No se pudo emitir cambio de estado: {str(e)}")
            db.session.commit()
            logging.info(f"DEBUG - Inspección guardada con estado: {inspeccion.estado}")

            # Limpiar datos temporales completamente después de guardar exitosamente
            try:
                # Limpiar sesión del servidor
                if "inspeccion_temporal" in session:
                    del session["inspeccion_temporal"]

                # Limpiar datos temporales del usuario en la base de datos
                InspeccionesController.limpiar_datos_temporales_usuario(
                    inspector_id, establecimiento_id
                )

            except Exception as e:
                import logging
                logging.error(f"Error limpiando datos temporales: {str(e)}")

            # Emitir señal de limpieza para todos los usuarios conectados al establecimiento
            try:
                room = f"establecimiento_{establecimiento_id}"
                socketio.emit(
                    "inspeccion_guardada_resetear",
                    {
                        "establecimiento_id": establecimiento_id,
                        "inspeccion_id": inspeccion.id,
                        "accion": accion,
                        "timestamp": safe_timestamp(),
                    },
                    to=room,
                )
            except Exception as e:
                import logging
                logging.warning(f"No se pudo emitir señal de reseteo: {str(e)}")

            resultado = InspeccionesController._construir_resultado_guardado(
                inspeccion,
                mensaje="Inspección guardada exitosamente",
                puntajes=puntajes,
                evidencias_guardadas_count=len(evidencias_guardadas),
                limpiar_temporal=True,
                resetear_formulario=True,
                actualizar_plan_semanal=True,
            )
            return jsonify(resultado)

        except Exception as e:
            db.session.rollback()
            import traceback
            import logging
            logging.error(f"Error en guardar_inspeccion: {str(e)}")
            logging.error(f"Traceback completo: {traceback.format_exc()}")
            return jsonify({"error": f"Error al guardar inspección: {str(e)}"}), 500

    @staticmethod
    def subir_evidencias():
        """Subir evidencias fotográficas para una inspección"""
        try:
            # Verificar que el usuario esté autenticado
            if not session.get("user_id"):
                return jsonify({"error": "Usuario no autenticado"}), 401

            # Obtener datos del formulario
            inspeccion_id = request.form.get("inspeccion_id")
            establecimiento_id = request.form.get("establecimiento_id")
            fecha = request.form.get("fecha")

            if not all([inspeccion_id, establecimiento_id, fecha]):
                return jsonify({"error": "Faltan datos requeridos"}), 400

            # Obtener archivos subidos
            evidencias_files = request.files.getlist("evidencias")

            if not evidencias_files:
                return jsonify({"error": "No se recibieron archivos"}), 400

            # Guardar evidencias
            evidencias_guardadas = InspeccionesController.guardar_evidencias_inspeccion(
                evidencias_files, int(inspeccion_id), int(establecimiento_id), fecha
            )

            if evidencias_guardadas:
                return jsonify(
                    {
                        "mensaje": "Evidencias guardadas exitosamente",
                        "evidencias": evidencias_guardadas,
                        "total": len(evidencias_guardadas),
                    }
                )
            else:
                return jsonify({"error": "No se pudieron guardar las evidencias"}), 500

        except Exception as e:
            return jsonify({"error": f"Error al subir evidencias: {str(e)}"}), 500

    @staticmethod
    def obtener_inspeccion(inspeccion_id):
        try:
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({"error": "Inspección no encontrada"}), 404

            observaciones_limpias, motivo_sin_firma_encargado = (
                InspeccionesController._obtener_observaciones_y_motivo(inspeccion)
            )

            # Obtener detalles de la inspección
            detalles = (
                db.session.query(
                    InspeccionDetalle,
                    ItemEvaluacionEstablecimiento,
                    ItemEvaluacionBase,
                    CategoriaEvaluacion,
                )
                .join(
                    ItemEvaluacionEstablecimiento,
                    InspeccionDetalle.item_establecimiento_id
                    == ItemEvaluacionEstablecimiento.id,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(InspeccionDetalle.inspeccion_id == inspeccion_id)
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(
                inspeccion_id=inspeccion_id
            ).all()

            # Formatear respuesta
            data = {
                "id": inspeccion.id,
                "establecimiento_id": inspeccion.establecimiento_id,
                "establecimiento_nombre": inspeccion.establecimiento.nombre,
                "inspector_id": inspeccion.inspector_id,
                "encargado_id": inspeccion.encargado_id,
                "fecha": inspeccion.fecha.isoformat(),
                "hora_inicio": (
                    inspeccion.hora_inicio.isoformat()
                    if inspeccion.hora_inicio
                    else None
                ),
                "hora_fin": (
                    inspeccion.hora_fin.isoformat() if inspeccion.hora_fin else None
                ),
                "observaciones": observaciones_limpias,
                "motivo_sin_firma_encargado": motivo_sin_firma_encargado,
                "finalizada_sin_firma_encargado": bool(
                    motivo_sin_firma_encargado and not inspeccion.firma_encargado
                ),
                "estado": inspeccion.estado,
                "puntaje_total": (
                    float(inspeccion.puntaje_total)
                    if inspeccion.puntaje_total
                    else None
                ),
                "puntaje_maximo_posible": (
                    float(inspeccion.puntaje_maximo_posible)
                    if inspeccion.puntaje_maximo_posible
                    else None
                ),
                "porcentaje_cumplimiento": (
                    float(inspeccion.porcentaje_cumplimiento)
                    if inspeccion.porcentaje_cumplimiento
                    else None
                ),
                "puntos_criticos_perdidos": inspeccion.puntos_criticos_perdidos,
                "detalles": [],
                "evidencias": [],
            }

            # Agregar detalles
            for detalle, item_est, item_base, categoria in detalles:
                data["detalles"].append(
                    {
                        "item_id": item_est.id,
                        "codigo": item_base.codigo,
                        "descripcion": item_est.descripcion_personalizada
                        or item_base.descripcion,
                        "categoria": categoria.nombre,
                        "riesgo": item_base.riesgo,
                        "rating": detalle.rating,
                        "score": float(detalle.score) if detalle.score else None,
                        "observacion": detalle.observacion_item,
                    }
                )

            # Agregar evidencias
            for evidencia in evidencias:
                data["evidencias"].append(
                    {
                        "id": evidencia.id,
                        "filename": evidencia.filename,
                        "ruta_archivo": InspeccionesController._normalize_evidence_url(
                            evidencia.ruta_archivo
                        ),
                        "descripcion": evidencia.descripcion,
                        "mime_type": evidencia.mime_type,
                    }
                )

            return jsonify(data)

        except Exception as e:
            return jsonify({"error": f"Error al obtener inspección: {str(e)}"}), 500

    @staticmethod
    def obtener_encargado_actual(establecimiento_id):
        try:
            fecha_actual = date.today()
            encargado = (
                EncargadoEstablecimiento.query.filter(
                    EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                    EncargadoEstablecimiento.activo == True,
                    EncargadoEstablecimiento.fecha_inicio <= fecha_actual,
                    (
                        EncargadoEstablecimiento.fecha_fin.is_(None)
                        | (EncargadoEstablecimiento.fecha_fin >= fecha_actual)
                    ),
                )
                .order_by(
                    EncargadoEstablecimiento.es_principal.desc(),
                    EncargadoEstablecimiento.fecha_inicio.desc(),
                )
                .first()
            )

            if not encargado:
                return (
                    jsonify(
                        {"error": "No hay encargado asignado para este establecimiento"}
                    ),
                    404,
                )

            return jsonify(
                {
                    "id": encargado.usuario.id,
                    "nombre": f"{encargado.usuario.nombre} {encargado.usuario.apellido or ''}".strip(),
                    "correo": encargado.usuario.correo,
                    "telefono": encargado.usuario.telefono,
                    "es_principal": encargado.es_principal,
                }
            )

        except Exception as e:
            return jsonify({"error": f"Error al obtener encargado: {str(e)}"}), 500

    @staticmethod
    def obtener_firmantes_establecimiento(establecimiento_id):
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")
            fecha_referencia = request.args.get("fecha")

            if not user_id:
                return jsonify({"error": "Sesión no válida"}), 401

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            firmantes = (
                InspeccionesController._obtener_firmantes_habilitados_establecimiento(
                    establecimiento_id,
                    fecha_referencia=fecha_referencia,
                )
            )

            return jsonify(
                {
                    "success": True,
                    "firmantes": firmantes,
                    "fecha_referencia": InspeccionesController._parsear_fecha_referencia(
                        fecha_referencia
                    ).isoformat(),
                }
            )
        except Exception as e:
            return jsonify(
                {"error": f"Error al obtener firmantes habilitados: {str(e)}"}
            ), 500

    @staticmethod
    def filtrar_inspecciones(
        fecha_inicio=None,
        fecha_fin=None,
        establecimiento_id=None,
        inspector_id=None,
        encargado_id=None,
        estado=None,
    ):
        """Filtrar inspecciones según criterios del pedido.txt"""
        try:
            query = Inspeccion.query

            # Aplicar filtros
            if fecha_inicio:
                query = query.filter(Inspeccion.fecha >= fecha_inicio)
            if fecha_fin:
                query = query.filter(Inspeccion.fecha <= fecha_fin)
            if establecimiento_id:
                query = query.filter(
                    Inspeccion.establecimiento_id == establecimiento_id
                )
            if inspector_id:
                query = query.filter(Inspeccion.inspector_id == inspector_id)
            if encargado_id:
                query = query.filter(Inspeccion.encargado_id == encargado_id)
            if estado:
                query = query.filter(Inspeccion.estado == estado)

            # Verificar permisos según rol
            user_role = session.get("user_role")
            user_id = session.get("user_id")

            if user_role == "Inspector":
                # Solo inspecciones del inspector
                query = query.filter(Inspeccion.inspector_id == user_id)
            elif user_role == "Encargado":
                # Solo inspecciones de sus establecimientos
                query = query.filter(Inspeccion.encargado_id == user_id)
            # Admin puede ver todas

            inspecciones = query.order_by(Inspeccion.fecha.desc()).all()

            data = []
            for inspeccion in inspecciones:
                data.append(
                    {
                        "id": inspeccion.id,
                        "fecha": inspeccion.fecha.isoformat(),
                        "hora_inicio": (
                            inspeccion.hora_inicio.strftime("%H:%M")
                            if inspeccion.hora_inicio
                            else inspeccion.created_at.strftime("%H:%M")
                        ),
                        "establecimiento": inspeccion.establecimiento.nombre,
                        "inspector": f"{inspeccion.inspector.nombre} {inspeccion.inspector.apellido or ''}".strip(),
                        "encargado": (
                            f"{inspeccion.encargado.nombre} {inspeccion.encargado.apellido or ''}".strip()
                            if inspeccion.encargado
                            else None
                        ),
                        "estado": inspeccion.estado,
                        "puntaje_total": (
                            float(inspeccion.puntaje_total)
                            if inspeccion.puntaje_total
                            else None
                        ),
                        "porcentaje_cumplimiento": (
                            float(inspeccion.porcentaje_cumplimiento)
                            if inspeccion.porcentaje_cumplimiento
                            else None
                        ),
                    }
                )

            return jsonify(data)

        except Exception as e:
            return jsonify({"error": f"Error al filtrar inspecciones: {str(e)}"}), 500

    @staticmethod
    def actualizar_item_tiempo_real():
        """Endpoint para actualizaciones en tiempo real sin guardar en BD"""
        try:
            data = request.get_json()
            inspeccion_id = data.get("inspeccion_id")
            item_id = data.get("item_id")
            rating = data.get("rating")
            observacion = data.get("observacion", "")

            if not all([inspeccion_id, item_id, rating is not None]):
                return jsonify({"error": "Datos incompletos"}), 400

            # Emitir actualización en tiempo real
            room = f"inspeccion_{inspeccion_id}"
            socketio.emit(
                "item_actualizado",
                {
                    "inspeccion_id": inspeccion_id,
                    "item_id": item_id,
                    "rating": rating,
                    "observacion": observacion,
                    "actualizado_por": session.get("user_role", "Inspector"),
                    "timestamp": safe_timestamp(),
                },
                to=room,
            )

            return jsonify({"mensaje": "Actualización enviada en tiempo real"})

        except Exception as e:
            return (
                jsonify({"error": f"Error en actualización tiempo real: {str(e)}"}),
                500,
            )

    # =========================
    # FUNCIONES DE ADMINISTRADOR
    # =========================

    @staticmethod
    def editar_puntuacion_inspeccion():
        """Permite al admin editar puntuaciones de cualquier inspección"""
        try:
            data = request.get_json()
            inspeccion_id = data.get("inspeccion_id")
            item_id = data.get("item_id")
            nueva_puntuacion = data.get("puntuacion")
            observacion = data.get("observacion", "")

            if not all([inspeccion_id, item_id, nueva_puntuacion is not None]):
                return jsonify({"error": "Datos incompletos"}), 400

            # Verificar que es admin
            if session.get("user_role") != "Administrador":
                return jsonify({"error": "No autorizado"}), 403

            # Buscar el detalle de inspección
            detalle = InspeccionDetalle.query.filter_by(
                inspeccion_id=inspeccion_id, item_establecimiento_id=item_id
            ).first()

            if not detalle:
                return jsonify({"error": "Detalle de inspección no encontrado"}), 404

            item_base = detalle.item_establecimiento.item_base
            es_valido, rating_normalizado, _ = (
                InspeccionesController._normalizar_rating_por_riesgo(
                    item_base.riesgo, nueva_puntuacion
                )
            )
            if not es_valido:
                db.session.rollback()
                return (
                    jsonify(
                        {
                            "error": (
                                f"Calificación inválida para el item {item_base.codigo}"
                            )
                        }
                    ),
                    400,
                )

            # Actualizar puntuación
            detalle.rating = rating_normalizado
            detalle.score = float(rating_normalizado)
            detalle.observacion_item = observacion

            # Recalcular puntajes totales
            puntajes = InspeccionesController.calcular_puntajes_inspeccion(
                inspeccion_id
            )

            db.session.commit()

            return jsonify(
                {"mensaje": "Puntuación actualizada exitosamente", "puntajes": puntajes}
            )

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al editar puntuación: {str(e)}"}), 500

    @staticmethod
    def crear_establecimiento():
        """Permite al admin crear nuevos establecimientos"""
        try:
            data = request.get_json()
            nombre = data.get("nombre")
            direccion = data.get("direccion")
            tipo_establecimiento_id = data.get("tipo_establecimiento_id")
            telefono = data.get("telefono", "")
            correo = data.get("correo", "")

            if not all([nombre, direccion, tipo_establecimiento_id]):
                return jsonify({"error": "Faltan datos requeridos"}), 400

            # Verificar que es admin
            if session.get("user_role") != "Administrador":
                return jsonify({"error": "No autorizado"}), 403

            # Crear establecimiento
            establecimiento = Establecimiento(
                nombre=nombre,
                direccion=direccion,
                tipo_establecimiento_id=tipo_establecimiento_id,
                telefono=telefono,
                correo=correo,
                activo=True,
            )

            db.session.add(establecimiento)
            db.session.commit()

            return jsonify(
                {
                    "mensaje": "Establecimiento creado exitosamente",
                    "establecimiento_id": establecimiento.id,
                }
            )

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al crear establecimiento: {str(e)}"}), 500

    @staticmethod
    def eliminar_establecimiento():
        """Permite al admin eliminar establecimientos"""
        try:
            data = request.get_json()
            establecimiento_id = data.get("establecimiento_id")

            if not establecimiento_id:
                return jsonify({"error": "ID de establecimiento requerido"}), 400

            # Verificar que es admin
            if session.get("user_role") != "Administrador":
                return jsonify({"error": "No autorizado"}), 403

            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                return jsonify({"error": "Establecimiento no encontrado"}), 404

            # Soft delete - marcar como inactivo
            establecimiento.activo = False
            db.session.commit()

            return jsonify({"mensaje": "Establecimiento eliminado exitosamente"})

        except Exception as e:
            db.session.rollback()
            return (
                jsonify({"error": f"Error al eliminar establecimiento: {str(e)}"}),
                500,
            )

    @staticmethod
    def crear_establecimiento_inspector():
        """Permite al inspector crear nuevos establecimientos con validaciones adicionales"""
        try:
            data = request.get_json()
            nombre = data.get("nombre")
            direccion = data.get("direccion", "")  # Hacer dirección opcional
            tipo_establecimiento_id = data.get("tipo_establecimiento_id")
            telefono = data.get("telefono", "")
            correo = data.get("correo", "")

            # Validar solo nombre y tipo_establecimiento_id como obligatorios
            if not all([nombre, tipo_establecimiento_id]):
                return jsonify({"error": "Faltan datos requeridos"}), 400

            # Verificar que sea inspector o admin
            user_role = session.get("user_role")
            if user_role not in ["Inspector", "Administrador"]:
                return jsonify({"error": "No autorizado"}), 403

            # Validaciones adicionales para inspectores
            if user_role == "Inspector":
                # Verificar que el nombre no esté duplicado (solo para inspectores)
                establecimiento_existente = Establecimiento.query.filter_by(
                    nombre=nombre.strip(), activo=True
                ).first()
                if establecimiento_existente:
                    return jsonify({"error": "Ya existe un establecimiento con este nombre"}), 400

                # Limitar la cantidad de establecimientos que puede crear un inspector (opcional)
                user_id = session.get("user_id")
                establecimientos_creados = Establecimiento.query.filter_by(
                    created_at=db.func.current_timestamp()  # Solo del día actual
                ).count()
                if establecimientos_creados >= 5:  # Máximo 5 por día
                    return jsonify({"error": "Ha alcanzado el límite diario de establecimientos creados"}), 429

            # Crear establecimiento vacío (sin items automáticos)
            establecimiento = Establecimiento(
                nombre=nombre.strip(),
                direccion=direccion.strip(),
                tipo_establecimiento_id=tipo_establecimiento_id,
                telefono=telefono.strip() if telefono else "",
                correo=correo.strip().lower() if correo else "",
                activo=True,
            )

            db.session.add(establecimiento)
            db.session.commit()

            # Crear plan semanal por defecto (sin items automáticos)
            try:
                import pytz
                lima_tz = pytz.timezone("America/Lima")
                utc_now = datetime.utcnow().replace(tzinfo=pytz.utc)
                lima_now = utc_now.astimezone(lima_tz)
                semana_actual = lima_now.isocalendar()[1]
                ano_actual = lima_now.year

                plan_semanal = InspeccionesController.obtener_o_crear_plan_semanal(
                    establecimiento.id, semana_actual, ano_actual
                )

                db.session.commit()

            except Exception as e:
                # No fallar la creación del establecimiento por esto
                import logging
                logging.warning(f"No se pudo crear plan semanal automáticamente: {str(e)}")

            return jsonify(
                {
                    "mensaje": "Establecimiento creado exitosamente",
                    "establecimiento_id": establecimiento.id,
                    "establecimiento": {
                        "id": establecimiento.id,
                        "nombre": establecimiento.nombre,
                        "direccion": establecimiento.direccion,
                        "telefono": establecimiento.telefono,
                        "correo": establecimiento.correo
                    }
                }
            )

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al crear establecimiento: {str(e)}"}), 500

    @staticmethod
    def completar_establecimiento(establecimiento_id):
        """
        Completar la creación de un establecimiento después de agregar items
        """
        try:
            # Verificar que el establecimiento existe
            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                return jsonify({"error": "Establecimiento no encontrado"}), 404

            # Verificar permisos
            user_role = session.get("user_role")
            if user_role not in ["Administrador", "Inspector"]:
                return jsonify({"error": "No autorizado"}), 403

            # Verificar que tenga al menos un item activo
            items_count = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                activo=True
            ).count()

            if items_count == 0:
                return jsonify({"error": "El establecimiento debe tener al menos un item antes de completarse"}), 400

            # El establecimiento ya está activo por defecto, solo confirmamos que está completo
            # Podríamos agregar un campo 'completado' si fuera necesario en el futuro

            return jsonify({
                "success": True,
                "message": f"Establecimiento '{establecimiento.nombre}' completado exitosamente",
                "establecimiento_id": establecimiento.id,
                "items_count": items_count
            })

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al completar establecimiento: {str(e)}"}), 500

    @staticmethod
    def actualizar_rol_usuario():
        """Permite al admin cambiar roles de usuarios"""
        try:
            data = request.get_json()
            usuario_id = data.get("usuario_id")
            nuevo_rol_id = data.get("rol_id")

            if not all([usuario_id, nuevo_rol_id]):
                return jsonify({"error": "Datos incompletos"}), 400

            # Verificar que es admin
            if session.get("user_role") != "Administrador":
                return jsonify({"error": "No autorizado"}), 403

            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({"error": "Usuario no encontrado"}), 404

            rol = Rol.query.get(nuevo_rol_id)
            if not rol:
                return jsonify({"error": "Rol no encontrado"}), 404

            usuario.rol_id = nuevo_rol_id
            db.session.commit()

            return jsonify({"mensaje": f"Rol actualizado a {rol.nombre} exitosamente"})

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al actualizar rol: {str(e)}"}), 500

    @staticmethod
    def obtener_todos_los_usuarios():
        """Obtener lista de todos los usuarios para administración"""
        try:
            # Verificar que es admin
            if session.get("user_role") != "Administrador":
                return jsonify({"error": "No autorizado"}), 403

            usuarios = db.session.query(Usuario, Rol).join(Rol).all()

            data = []
            for usuario, rol in usuarios:
                data.append(
                    {
                        "id": usuario.id,
                        "nombre": usuario.nombre,
                        "apellido": usuario.apellido,
                        "correo": usuario.correo,
                        "telefono": usuario.telefono,
                        "rol_id": rol.id,
                        "rol_nombre": rol.nombre,
                        "activo": usuario.activo,
                        "fecha_creacion": (
                            usuario.fecha_creacion.isoformat()
                            if usuario.fecha_creacion
                            else None
                        ),
                    }
                )

            return jsonify(data)

        except Exception as e:
            return jsonify({"error": f"Error al obtener usuarios: {str(e)}"}), 500

    @staticmethod
    def obtener_tipos_establecimiento():
        """Obtener tipos de establecimiento disponibles"""
        try:
            tipos = TipoEstablecimiento.query.filter_by(activo=True).all()

            data = [
                {"id": tipo.id, "nombre": tipo.nombre, "descripcion": tipo.descripcion}
                for tipo in tipos
            ]

            return jsonify(data)

        except Exception as e:
            return jsonify({"error": f"Error al obtener tipos: {str(e)}"}), 500

    @staticmethod
    def obtener_inspeccion_completa(inspeccion_id, return_json=True):
        """Obtener inspección completa con todos los detalles"""
        try:
            # Obtener la inspección
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                if return_json:
                    return jsonify({"error": "Inspección no encontrada"}), 404
                else:
                    return None, "Inspección no encontrada"

            # Obtener el establecimiento
            establecimiento = Establecimiento.query.get(inspeccion.establecimiento_id)

            # Obtener el inspector
            inspector = (
                Usuario.query.get(inspeccion.inspector_id)
                if inspeccion.inspector_id
                else None
            )

            # Obtener el encargado
            encargado = (
                Usuario.query.get(inspeccion.encargado_id)
                if inspeccion.encargado_id
                else None
            )

            # Obtener detalles de la inspección con items y categorías
            detalles_query = (
                db.session.query(
                    InspeccionDetalle,
                    ItemEvaluacionEstablecimiento,
                    ItemEvaluacionBase,
                    CategoriaEvaluacion,
                )
                .join(
                    ItemEvaluacionEstablecimiento,
                    InspeccionDetalle.item_establecimiento_id
                    == ItemEvaluacionEstablecimiento.id,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(InspeccionDetalle.inspeccion_id == inspeccion_id)
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Organizar items por categoría, evitando duplicados
            categorias_dict = {}
            items_procesados_por_base = {}  # Track de items por item_base_id y categoría
            duplicados_encontrados = 0  # Contador de duplicados para debugging
            
            for detalle, item_est, item_base, categoria in detalles_query:
                # Crear clave única basada en categoria + item_base_id (no en detalle.id)
                # Esto evita que se muestren duplicados cuando hay múltiples item_establecimiento
                # para el mismo item_base
                item_key = f"{categoria.id}_{item_base.id}"
                
                # Si ya procesamos este item_base en esta categoría, saltar
                if item_key in items_procesados_por_base:
                    duplicados_encontrados += 1
                    continue
                
                items_procesados_por_base[item_key] = detalle.id
                
                if categoria.id not in categorias_dict:
                    categorias_dict[categoria.id] = {
                        "id": categoria.id,
                        "nombre": categoria.nombre,
                        "descripcion": categoria.descripcion,
                        "evaluaciones": [],  # Cambiado de "items" a "evaluaciones"
                    }

                item_data = {
                    "configuracion_calificacion": InspeccionesController._obtener_configuracion_calificacion(
                        item_base.riesgo
                    ),
                    "id": item_base.id,
                    "codigo": item_base.codigo,
                    "descripcion": item_base.descripcion,
                    "riesgo": item_base.riesgo,
                    "puntaje_minimo": InspeccionesController._obtener_configuracion_calificacion(
                        item_base.riesgo
                    )["puntaje_minimo"],
                    "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                        item_base.riesgo
                    )["puntaje_maximo"],
                    "opciones_calificacion": sorted(
                        InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["opciones_validas"]
                    ),
                    "etiquetas_calificacion": InspeccionesController._obtener_configuracion_calificacion(
                        item_base.riesgo
                    )["etiquetas_calificacion"],
                    "detalle": (
                        {
                            "rating": detalle.rating,
                            "score": float(detalle.score or 0),
                            "observacion_item": detalle.observacion_item,
                        }
                        if detalle
                        else None
                    ),
                }
                categorias_dict[categoria.id]["evaluaciones"].append(item_data)
            
            # Log para debugging
            if duplicados_encontrados > 0:
                print(f"⚠️  Se omitieron {duplicados_encontrados} items duplicados en inspeccion_id {inspeccion_id}")

            categorias = list(categorias_dict.values())
            evaluaciones_unicas = [
                evaluacion
                for categoria in categorias
                for evaluacion in categoria["evaluaciones"]
            ]
            resumen_calculado = InspeccionesController._calcular_resumen_desde_evaluaciones(
                evaluaciones_unicas
            )

            # Listas para los modales de "Críticos" y "Observados" (Bloque E, 10/07)
            items_criticos_fallados = []
            items_observados = []
            puntos_extra_criticos = 0
            puntos_extra_observados = 0
            for evaluacion in evaluaciones_unicas:
                detalle_item = evaluacion.get("detalle")
                if not detalle_item or detalle_item.get("rating") is None:
                    continue
                rating = detalle_item["rating"]
                riesgo = evaluacion.get("riesgo")
                puntaje_minimo_item = evaluacion.get("puntaje_minimo") or 0
                config_item = InspeccionesController._obtener_configuracion_calificacion(riesgo)
                item_resumen = {
                    "codigo": evaluacion.get("codigo"),
                    "descripcion": evaluacion.get("descripcion"),
                    "riesgo": riesgo,
                    "rating": rating,
                    "etiqueta": evaluacion.get("etiquetas_calificacion", {}).get(rating, str(rating)),
                    "puntos_extra": rating - puntaje_minimo_item,
                    "porcentaje": config_item["porcentaje_por_rating"].get(rating),
                }
                if riesgo == "Crítico" and rating == evaluacion.get("puntaje_maximo"):
                    items_criticos_fallados.append(item_resumen)
                    puntos_extra_criticos += rating - puntaje_minimo_item
                elif riesgo != "Crítico" and rating != evaluacion.get("puntaje_minimo"):
                    items_observados.append(item_resumen)
                    puntos_extra_observados += rating - puntaje_minimo_item

            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(
                inspeccion_id=inspeccion_id
            ).all()
            observaciones_limpias, motivo_sin_firma_encargado = (
                InspeccionesController._obtener_observaciones_y_motivo(inspeccion)
            )

            # Organizar datos
            data = {
                "id": inspeccion.id,
                "fecha": inspeccion.fecha.isoformat(),
                "estado": inspeccion.estado,
                "observaciones": observaciones_limpias,
                "motivo_sin_firma_encargado": motivo_sin_firma_encargado,
                "finalizada_sin_firma_encargado": bool(
                    motivo_sin_firma_encargado and not inspeccion.firma_encargado
                ),
                "puntaje_total": resumen_calculado["puntaje_total"],
                "puntaje_maximo_posible": resumen_calculado["puntaje_maximo_posible"],
                "puntaje_promedio_item": resumen_calculado["puntaje_promedio_item"],
                "porcentaje_cumplimiento": resumen_calculado[
                    "porcentaje_cumplimiento"
                ],
                "puntos_criticos_perdidos": resumen_calculado[
                    "puntos_criticos_perdidos"
                ],
                "items_calificados": resumen_calculado["items_calificados"],
                "total_items": resumen_calculado["total_items"],
                "calificacion_cualitativa": InspeccionesController._calcular_calificacion_global(
                    resumen_calculado["puntaje_total"],
                    resumen_calculado["items_calificados"],
                    resumen_calculado["puntos_criticos_perdidos"],
                ),
                "items_criticos_fallados": items_criticos_fallados,
                "items_observados": items_observados,
                "total_observados": len(items_observados),
                "puntos_extra_criticos": puntos_extra_criticos,
                "puntos_extra_observados": puntos_extra_observados,
                "hora_inicio": (
                    inspeccion.hora_inicio.strftime("%H:%M")
                    if inspeccion.hora_inicio
                    else None
                ),
                "hora_fin": (
                    inspeccion.hora_fin.strftime("%H:%M")
                    if inspeccion.hora_fin
                    else None
                ),
                "firma_inspector": inspeccion.firma_inspector,
                "firma_encargado": inspeccion.firma_encargado,
                "fecha_firma_inspector": inspeccion.fecha_firma_inspector,
                "fecha_firma_encargado": inspeccion.fecha_firma_encargado,
                "establecimiento": (
                    {
                        "id": establecimiento.id,
                        "nombre": establecimiento.nombre,
                        "direccion": establecimiento.direccion,
                        "telefono": establecimiento.telefono,
                    }
                    if establecimiento
                    else None
                ),
                "inspector": (
                    {
                        "id": inspector.id,
                        "nombre": f"{inspector.nombre} {inspector.apellido or ''}".strip(),
                        "correo": inspector.correo,
                    }
                    if inspector
                    else None
                ),
                "encargado": (
                    {
                        "id": encargado.id,
                        "nombre": f"{encargado.nombre} {encargado.apellido or ''}".strip(),
                        "correo": encargado.correo,
                    }
                    if encargado
                    else None
                ),
                "categorias": categorias,
                "evidencias": [
                    {
                        "id": evidencia.id,
                        "descripcion": evidencia.descripcion,
                        "url_archivo": InspeccionesController._normalize_evidence_url(
                            evidencia.ruta_archivo
                        ),
                        "ruta_archivo": InspeccionesController._normalize_evidence_url(
                            evidencia.ruta_archivo
                        ),
                        "ruta_archivo_original": evidencia.ruta_archivo,
                        "fecha_subida": (
                            evidencia.uploaded_at.isoformat()
                            if evidencia.uploaded_at
                            else None
                        ),
                    }
                    for evidencia in evidencias
                ],
            }

            if return_json:
                return jsonify(data)
            else:
                return data, None

        except Exception as e:
            error_msg = f"Error al obtener inspección: {str(e)}"
            if return_json:
                return jsonify({"error": error_msg}), 500
            else:
                return None, error_msg

    @staticmethod
    def buscar_inspecciones():
        """Buscar inspecciones con filtros incluyendo encargado"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            # Crear alias para el encargado
            from sqlalchemy.orm import aliased

            UsuarioEncargado = aliased(Usuario)

            # Parámetros de filtro
            establecimiento_id = request.args.get("establecimiento_id", type=int)
            encargado_id = request.args.get("encargado_id", type=int)  # Nuevo filtro
            fecha_desde = request.args.get("fecha_desde")
            fecha_hasta = request.args.get("fecha_hasta")
            estado = request.args.get("estado")

            # Construir query base con JOIN para obtener información del encargado
            query = (
                db.session.query(
                    Inspeccion.id,
                    Inspeccion.fecha,
                    Inspeccion.hora_fin,  # Agregar hora_fin
                    Inspeccion.estado,
                    Inspeccion.puntaje_total,
                    Inspeccion.puntaje_maximo_posible,
                    Inspeccion.porcentaje_cumplimiento,
                    Inspeccion.observaciones,
                    Establecimiento.nombre.label("establecimiento_nombre"),
                    Usuario.nombre.label("inspector_nombre"),
                    func.coalesce(UsuarioEncargado.nombre, "Sin encargado").label(
                        "encargado_nombre"
                    ),
                )
                .join(
                    Establecimiento, Inspeccion.establecimiento_id == Establecimiento.id
                )
                .outerjoin(Usuario, Inspeccion.inspector_id == Usuario.id)
                .outerjoin(
                    UsuarioEncargado, Inspeccion.encargado_id == UsuarioEncargado.id
                )
            )

            # Filtros de permisos según rol
            if user_role == "Encargado":
                hoy = date.today()
                asignaciones = (
                    EncargadoEstablecimiento.query.filter(
                        EncargadoEstablecimiento.usuario_id == user_id,
                        EncargadoEstablecimiento.activo == True,
                        EncargadoEstablecimiento.fecha_inicio <= hoy,
                        or_(
                            EncargadoEstablecimiento.fecha_fin.is_(None),
                            EncargadoEstablecimiento.fecha_fin >= hoy,
                        ),
                    ).all()
                )

                establecimientos_permitidos = [
                    asignacion.establecimiento_id for asignacion in asignaciones
                ]

                if not establecimientos_permitidos:
                    return jsonify([])

                query = query.filter(
                    Inspeccion.establecimiento_id.in_(establecimientos_permitidos)
                )

            elif user_role == "Jefe de Establecimiento":
                hoy = date.today()
                jefaturas = (
                    JefeEstablecimiento.query.filter(
                        JefeEstablecimiento.usuario_id == user_id,
                        JefeEstablecimiento.activo == True,
                        JefeEstablecimiento.fecha_inicio <= hoy,
                        or_(
                            JefeEstablecimiento.fecha_fin.is_(None),
                            JefeEstablecimiento.fecha_fin >= hoy,
                        ),
                    ).all()
                )

                establecimientos_permitidos = [
                    jefatura.establecimiento_id for jefatura in jefaturas
                ]

                if not establecimientos_permitidos:
                    return jsonify([])

                query = query.filter(
                    Inspeccion.establecimiento_id.in_(establecimientos_permitidos)
                )

            # Aplicar filtros de búsqueda
            if establecimiento_id:
                query = query.filter(
                    Inspeccion.establecimiento_id == establecimiento_id
                )

            if encargado_id:  # Nuevo filtro por encargado
                query = query.filter(Inspeccion.encargado_id == encargado_id)

            if fecha_desde:
                query = query.filter(Inspeccion.fecha >= fecha_desde)

            if fecha_hasta:
                query = query.filter(Inspeccion.fecha <= fecha_hasta)

            if estado:
                query = query.filter(Inspeccion.estado == estado)

            # Ordenar por fecha descendente y luego por created_at descendente
            query = query.order_by(Inspeccion.fecha.desc(), Inspeccion.created_at.desc())

            # Ejecutar query
            inspecciones = query.all()

            # Convertir a diccionario
            resultado = []
            for insp in inspecciones:
                # Contar items evaluados
                items_evaluados = (
                    db.session.query(InspeccionDetalle)
                    .filter_by(inspeccion_id=insp.id)
                    .count()
                )

                # Combinar fecha y hora_fin para mostrar fecha completa
                fecha_completa = None
                if insp.fecha and insp.hora_fin:
                    # Crear datetime combinando fecha y hora_fin
                    fecha_completa = datetime.combine(insp.fecha, insp.hora_fin)
                elif insp.fecha:
                    # Si no hay hora_fin, usar solo la fecha
                    fecha_completa = datetime.combine(insp.fecha, datetime.min.time())

                resultado.append(
                    {
                        "id": insp.id,
                        "fecha": fecha_completa.isoformat() if fecha_completa else None,
                        "estado": insp.estado,
                        "puntaje_total": insp.puntaje_total,
                        "puntaje_maximo": insp.puntaje_maximo_posible,
                        "porcentaje_cumplimiento": insp.porcentaje_cumplimiento,
                        "observaciones": insp.observaciones,
                        "establecimiento_nombre": insp.establecimiento_nombre,
                        "inspector_nombre": insp.inspector_nombre,
                        "encargado_nombre": insp.encargado_nombre,
                        "items_evaluados": items_evaluados,
                    }
                )

            return jsonify(resultado)

        except Exception as e:
            return jsonify({"error": f"Error en búsqueda: {str(e)}"}), 500

    @staticmethod
    def obtener_lista_encargados():
        """Obtener lista de encargados para filtros, opcionalmente filtrados por establecimiento"""
        try:

            user_role = session.get("user_role")

            # Admin, Inspector y Jefe de Establecimiento pueden ver encargados
            if user_role not in ["Administrador", "Inspector", "Jefe de Establecimiento"]:
                return jsonify({"error": f"Rol no autorizado"}), 403

            # Obtener establecimiento_id de los parámetros de la query si existe
            establecimiento_id = request.args.get("establecimiento_id")

            # Si es Jefe de Establecimiento, obtener su establecimiento automáticamente
            if user_role == "Jefe de Establecimiento":
                user_id = session.get('user_id')
                jefe_query = db.session.execute(text("""
                    SELECT establecimiento_id 
                    FROM jefes_establecimientos 
                    WHERE usuario_id = :user_id AND activo = 1
                """), {'user_id': user_id})
                jefe_info = jefe_query.fetchone()
                if jefe_info:
                    establecimiento_id = str(jefe_info[0])  # Forzar filtro por su establecimiento
                else:
                    return jsonify([])

            # Importar modelos necesarios
            from app.models.Usuario_models import Usuario, Rol
            from app.models.Inspecciones_models import EncargadoEstablecimiento


            # Verificar la conexión de la base de datos
            try:
                db.session.execute(text("SELECT 1"))
            except Exception as db_error:
                return (
                    jsonify(
                        {
                            "error": "Error de conexión a la base de datos",
                            "details": str(db_error),
                        }
                    ),
                    500,
                )

            # Construir la consulta según si se solicita filtrar por establecimiento
            try:

                if establecimiento_id:
                    # Filtrar encargados por establecimiento específico
                    # INCLUIR encargados activos e inactivos para el establecimiento
                    encargados = (
                        db.session.query(Usuario)
                        .join(Rol, Usuario.rol_id == Rol.id)
                        .join(
                            EncargadoEstablecimiento,
                            Usuario.id == EncargadoEstablecimiento.usuario_id,
                        )
                        .filter(
                            Rol.nombre == "Encargado",
                            EncargadoEstablecimiento.establecimiento_id
                            == establecimiento_id,
                            # NO filtrar por Usuario.activo para mostrar todos los encargados del establecimiento
                        )
                        .order_by(Usuario.nombre)
                        .all()
                    )
                else:
                    # Lista completa de encargados activos (comportamiento original)
                    encargados = (
                        db.session.query(Usuario)
                        .join(Rol, Usuario.rol_id == Rol.id)
                        .filter(Rol.nombre == "Encargado", Usuario.activo == True)
                        .order_by(Usuario.nombre)
                        .all()
                    )


            except Exception as db_error:
                import traceback

                # Retornar lista vacía si hay problemas con la BD
                return jsonify([])

            # Formatear el resultado de manera segura
            try:
                resultado = []
                for i, encargado in enumerate(encargados):
                    try:
                        # Validación de seguridad: asegurar que los datos sean strings seguros
                        nombre_completo = f"{encargado.nombre or ''} {encargado.apellido or ''}".strip()
                        if (
                            len(nombre_completo) > 0
                        ):  # Solo agregar si hay nombre válido
                            elemento = {
                                "id": int(encargado.id),  # Asegurar que sea entero
                                "nombre": nombre_completo[
                                    :150
                                ],  # Limitar longitud para seguridad
                                "activo": bool(
                                    encargado.activo
                                ),  # Incluir estado para referencia
                            }
                            resultado.append(elemento)
                    except Exception as e:
                        continue

                return jsonify(resultado)

            except Exception as format_error:
                import traceback

                return jsonify([])

        except Exception as e:
            import traceback

            return jsonify({"error": f"Error obteniendo encargados: {str(e)}"}), 500

    @staticmethod
    def obtener_detalle_inspeccion(inspeccion_id):
        """Obtener detalle completo de una inspección"""
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            # Buscar la inspección
            inspeccion = Inspeccion.query.get_or_404(inspeccion_id)

            # Verificar permisos
            if user_role == "Inspector" and inspeccion.inspector_id != user_id:
                return jsonify({"error": "Sin permisos para ver esta inspección"}), 403
            elif user_role == "Encargado":
                encargado_establecimiento = EncargadoEstablecimiento.query.filter_by(
                    usuario_id=user_id, establecimiento_id=inspeccion.establecimiento_id
                ).first()
                if not encargado_establecimiento:
                    return (
                        jsonify({"error": "Sin permisos para ver esta inspección"}),
                        403,
                    )

            # Obtener datos relacionados
            establecimiento = Establecimiento.query.get(inspeccion.establecimiento_id)
            inspector = (
                Usuario.query.get(inspeccion.inspector_id)
                if inspeccion.inspector_id
                else None
            )

            # Obtener detalles de items con información de categorías
            detalles = (
                db.session.query(
                    InspeccionDetalle.rating,
                    InspeccionDetalle.score,
                    InspeccionDetalle.observacion_item,
                    ItemEvaluacionEstablecimiento.id.label('item_establecimiento_id'),
                    ItemEvaluacionEstablecimiento.factor_ajuste,
                    ItemEvaluacionBase.id.label('item_base_id'),
                    ItemEvaluacionBase.descripcion,
                    ItemEvaluacionBase.riesgo,
                    ItemEvaluacionBase.puntaje_maximo,
                    ItemEvaluacionBase.puntaje_minimo,
                    ItemEvaluacionBase.orden.label('orden_item'),
                    ItemEvaluacionBase.codigo.label('codigo_item'),
                    CategoriaEvaluacion.id.label('categoria_id'),
                    CategoriaEvaluacion.nombre.label('categoria_nombre'),
                    CategoriaEvaluacion.orden.label('orden_categoria'),
                )
                .join(
                    ItemEvaluacionEstablecimiento,
                    InspeccionDetalle.item_establecimiento_id
                    == ItemEvaluacionEstablecimiento.id,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(InspeccionDetalle.inspeccion_id == inspeccion_id)
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Agrupar detalles por categorías, evitando duplicados por item_base_id
            categorias_dict = {}
            items_procesados = {}  # Track por categoria + item_base_id
            duplicados_omitidos = 0
            
            for detalle in detalles:
                # Crear clave única para evitar duplicados del mismo item_base en la misma categoría
                item_key = f"{detalle.categoria_id}_{detalle.item_base_id}"
                
                # Si ya procesamos este item_base en esta categoría, saltar
                if item_key in items_procesados:
                    duplicados_omitidos += 1
                    continue
                
                items_procesados[item_key] = True
                
                categoria_nombre = detalle.categoria_nombre
                if categoria_nombre not in categorias_dict:
                    categorias_dict[categoria_nombre] = {
                        "nombre": categoria_nombre,
                        "orden": detalle.orden_categoria,
                        "evaluaciones": []
                    }

                categorias_dict[categoria_nombre]["evaluaciones"].append({
                    "codigo": detalle.codigo_item,
                    "descripcion": detalle.descripcion,
                    "riesgo": detalle.riesgo,
                    "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                        detalle.riesgo
                    )["puntaje_maximo"],
                    "puntaje_minimo": InspeccionesController._obtener_configuracion_calificacion(
                        detalle.riesgo
                    )["puntaje_minimo"],
                    "opciones_calificacion": sorted(
                        InspeccionesController._obtener_configuracion_calificacion(
                            detalle.riesgo
                        )["opciones_validas"]
                    ),
                    "orden": detalle.orden_item,
                    "detalle": {
                        "rating": detalle.rating,
                        "score": float(detalle.score) if detalle.score else 0,
                        "observacion_item": detalle.observacion_item
                    } if detalle.rating is not None else None,
                })
            
            # Log para debugging
            if duplicados_omitidos > 0:
                print(f"⚠️  Se omitieron {duplicados_omitidos} items duplicados en obtener_detalle_inspeccion para inspeccion_id {inspeccion_id}")

            # Convertir a lista ordenada por orden de categoría
            categorias = []
            for categoria_data in sorted(categorias_dict.values(), key=lambda x: x["orden"]):
                categorias.append({
                    "nombre": categoria_data["nombre"],
                    "evaluaciones": categoria_data["evaluaciones"]
                })

            evaluaciones_unicas = [
                evaluacion
                for categoria in categorias
                for evaluacion in categoria["evaluaciones"]
            ]
            resumen_calculado = InspeccionesController._calcular_resumen_desde_evaluaciones(
                evaluaciones_unicas,
                total_items=len(evaluaciones_unicas),
            )

            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(
                inspeccion_id=inspeccion_id
            ).all()

            # Obtener total de items disponibles para el establecimiento
            total_items_disponibles = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=inspeccion.establecimiento_id
            ).count()

            resultado = {
                "id": inspeccion.id,
                "fecha": inspeccion.fecha.isoformat() if inspeccion.fecha else None,
                "estado": inspeccion.estado,
                "puntaje_total": resumen_calculado["puntaje_total"],
                "puntaje_maximo": resumen_calculado["puntaje_maximo_posible"],
                "puntaje_promedio_item": resumen_calculado["puntaje_promedio_item"],
                "porcentaje_cumplimiento": resumen_calculado["porcentaje_cumplimiento"],
                "observaciones": inspeccion.observaciones,
                "establecimiento_nombre": (
                    establecimiento.nombre if establecimiento else None
                ),
                "inspector_nombre": inspector.nombre if inspector else None,
                "firma_inspector": signature_public_url(inspeccion.firma_inspector),
                "firma_encargado": signature_public_url(inspeccion.firma_encargado),
                "fecha_firma_inspector": inspeccion.fecha_firma_inspector.isoformat() if inspeccion.fecha_firma_inspector else None,
                "fecha_firma_encargado": inspeccion.fecha_firma_encargado.isoformat() if inspeccion.fecha_firma_encargado else None,
                "items_evaluados": resumen_calculado["items_calificados"],
                "total_items": resumen_calculado["total_items"] or total_items_disponibles,
                "puntos_criticos_perdidos": resumen_calculado["puntos_criticos_perdidos"],
                "categorias": categorias,
                "evidencias": [
                    {
                        "nombre_archivo": evidencia.filename,
                        "ruta_archivo": InspeccionesController._normalize_evidence_url(evidencia.ruta_archivo),
                        "descripcion": evidencia.descripcion,
                    }
                    for evidencia in evidencias
                ],
            }

            return jsonify(resultado)

        except Exception as e:
            return jsonify({"error": f"Error obteniendo detalle: {str(e)}"}), 500

    @staticmethod
    def firmar_como_inspector():
        """Permite al inspector firmar después de que el encargado haya firmado"""
        try:
            data = request.get_json()
            inspeccion_id = data.get("inspeccion_id")
            firma_data = data.get("firma_data")  # Base64 de la firma

            if not all([inspeccion_id, firma_data]):
                return jsonify({"error": "Faltan datos requeridos"}), 400

            user_id = session.get("user_id")
            user_role = session.get("user_role")

            # Verificar que sea inspector
            if user_role not in [ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR]:
                return (
                    jsonify({"error": "Solo los inspectores y ayudantes de inspector pueden usar esta función"}),
                    403,
                )

            # Obtener la inspección
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({"error": "Inspección no encontrada"}), 404

            # Verificar que el inspector actual sea el autor de la inspección
            if inspeccion.inspector_id != user_id:
                return (
                    jsonify(
                        {"error": "No tiene autorización para firmar esta inspección"}
                    ),
                    403,
                )

            # Verificar que el encargado ya haya firmado
            if not inspeccion.firma_encargado:
                return jsonify({"error": "El encargado debe firmar primero"}), 400

            # Verificar que el inspector no haya firmado ya
            if inspeccion.firma_inspector:
                return (
                    jsonify({"error": "El inspector ya ha firmado esta inspección"}),
                    400,
                )

            # Guardar la firma del inspector
            inspeccion.firma_inspector = firma_data
            inspeccion.fecha_firma_inspector = datetime.now()

            db.session.commit()

            # Emitir evento de firma para notificar cambios
            try:
                room = f"inspeccion_{inspeccion.id}"
                socketio.emit(
                    "firma_recibida",
                    {
                        "inspeccion_id": inspeccion.id,
                        "tipo_firma": "inspector",
                        "firmado_por": session.get("user_name"),
                        "timestamp": safe_timestamp(),
                        "ambas_firmas_completas": True,
                    },
                    to=room,
                )
            except Exception as e:
                pass  # Error silenciado

            return jsonify(
                {
                    "mensaje": "Firma del inspector guardada exitosamente",
                    "puede_completar": True,
                }
            )

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al guardar firma: {str(e)}"}), 500

    @staticmethod
    def limpiar_datos_temporales_usuario(user_id, establecimiento_id=None):
        """Limpiar todos los datos temporales de un usuario"""
        try:
            if establecimiento_id:
                # Limpiar datos específicos del establecimiento (formato correcto usado en guardar_inspeccion_parcial)
                clave_establecimiento = f"establecimiento_{establecimiento_id}"
                if clave_establecimiento in inspecciones_temporales:
                    del inspecciones_temporales[clave_establecimiento]

                # Limpiar datos de tiempo real del establecimiento
                clave_tiempo_real = f"establecimiento_{establecimiento_id}"
                if clave_tiempo_real in datos_tiempo_real:
                    del datos_tiempo_real[clave_tiempo_real]

                # Limpiar datos específicos del establecimiento y usuario (formato antiguo)
                clave_especifica = f"user_{user_id}_{establecimiento_id}"
                if clave_especifica in inspecciones_temporales:
                    del inspecciones_temporales[clave_especifica]

            # Limpiar datos generales del usuario (formato antiguo)
            clave_usuario = f"user_{user_id}"
            if clave_usuario in inspecciones_temporales:
                del inspecciones_temporales[clave_usuario]

        except Exception as e:
            import logging
            logging.error(f"Error en limpiar_datos_temporales_usuario: {str(e)}")

    @staticmethod
    def obtener_plan_semanal():
        """
        Obtener estadísticas del dashboard por establecimiento.
        SEGURIDAD: Control de permisos por rol
        ZONA HORARIA: Lima, Perú (UTC-5)
        PERÍODOS:
        - semanal: Lunes a Domingo
        - mensual: consolidado del mes calendario
        """
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")
            if user_role not in ["Administrador", "Inspector", "Encargado", "Jefe de Establecimiento"]:
                return jsonify({"error": "No autorizado"}), 403

            periodo_tipo = (request.args.get("periodo", "semanal", type=str) or "semanal").lower()
            if periodo_tipo not in ["semanal", "mensual"]:
                periodo_tipo = "semanal"

            semana_offset = request.args.get("semana_offset", 0, type=int)
            mes_offset = request.args.get("mes_offset", 0, type=int)
            establecimiento_filtro = request.args.get("establecimiento_id", type=int)

            from app.models.Inspecciones_models import EncargadoEstablecimiento

            lima_tz = pytz.timezone("America/Lima")
            utc_now = datetime.utcnow().replace(tzinfo=pytz.utc)
            lima_now = utc_now.astimezone(lima_tz)
            hoy = lima_now.date()

            if periodo_tipo == "mensual":
                inicio_periodo = InspeccionesController._sumar_meses_fecha(
                    date(hoy.year, hoy.month, 1), mes_offset
                )
                siguiente_mes = InspeccionesController._sumar_meses_fecha(inicio_periodo, 1)
                fin_periodo = siguiente_mes - timedelta(days=1)
                periodo_payload = {
                    "tipo": "mensual",
                    "inicio": inicio_periodo.isoformat(),
                    "fin": fin_periodo.isoformat(),
                    "offset": mes_offset,
                    "es_actual": mes_offset == 0,
                    "titulo": f"Consolidado mensual {inicio_periodo.strftime('%m/%Y')}",
                }
            else:
                dias_hasta_lunes = hoy.weekday()
                inicio_semana_actual = hoy - timedelta(days=dias_hasta_lunes)
                inicio_periodo = inicio_semana_actual + timedelta(weeks=semana_offset)
                fin_periodo = inicio_periodo + timedelta(days=6)
                periodo_payload = {
                    "tipo": "semanal",
                    "inicio": inicio_periodo.isoformat(),
                    "fin": fin_periodo.isoformat(),
                    "offset": semana_offset,
                    "es_actual": semana_offset == 0,
                    "titulo": f"Semana del {inicio_periodo.strftime('%d/%m/%Y')} al {fin_periodo.strftime('%d/%m/%Y')}",
                }

            establecimientos_permitidos = []

            if user_role == "Encargado":
                encargos = EncargadoEstablecimiento.query.filter_by(
                    usuario_id=user_id, activo=True
                ).all()
                establecimientos_permitidos = [
                    encargo.establecimiento_id for encargo in encargos
                ]

            elif user_role == "Jefe de Establecimiento":
                from sqlalchemy import text
                jefe_query = db.session.execute(text("""
                    SELECT establecimiento_id FROM jefes_establecimientos 
                    WHERE usuario_id = :user_id AND activo = 1
                """), {'user_id': user_id}).fetchone()

                if jefe_query:
                    establecimientos_permitidos = [jefe_query[0]]
            else:
                establecimientos_query = Establecimiento.query.filter_by(
                    activo=True
                ).all()
                establecimientos_permitidos = [est.id for est in establecimientos_query]

            if (
                establecimiento_filtro
                and establecimiento_filtro in establecimientos_permitidos
            ):
                establecimientos_permitidos = [establecimiento_filtro]

            if not establecimientos_permitidos:
                return jsonify(
                    {
                        "periodo": periodo_payload,
                        "establecimientos": [],
                        "resumen_general": {
                            "total_inspecciones": 0,
                            "promedio_cumplimiento": 0,
                            "total_metas": 0,
                            "establecimientos_completos": 0,
                            "establecimientos_pendientes": 0,
                        },
                        "chart_data": {
                            "labels": [],
                            "realizadas": [],
                            "pendientes": [],
                            "promedios": [],
                            "cumplimiento": [],
                        },
                    }
                )

            inspecciones_periodo = (
                db.session.query(Inspeccion)
                .filter(
                    func.date(Inspeccion.fecha) >= inicio_periodo,
                    func.date(Inspeccion.fecha) <= fin_periodo,
                    Inspeccion.establecimiento_id.in_(establecimientos_permitidos),
                    Inspeccion.estado == "completada",
                )
                .all()
            )

            estadisticas_por_establecimiento = {}
            establecimientos = (
                db.session.query(Establecimiento)
                .filter(Establecimiento.id.in_(establecimientos_permitidos))
                .all()
            )

            meta_default = InspeccionesController._obtener_meta_semanal_default()
            semanas_del_periodo = []
            planes_por_semana = {}

            if periodo_tipo == "mensual":
                semanas_del_periodo = InspeccionesController._obtener_semanas_en_periodo(
                    inicio_periodo, fin_periodo
                )
                if semanas_del_periodo:
                    semanas_ids = [sem["semana"] for sem in semanas_del_periodo]
                    anos_ids = [sem["ano"] for sem in semanas_del_periodo]
                    planes = PlanSemanal.query.filter(
                        PlanSemanal.establecimiento_id.in_(establecimientos_permitidos),
                        PlanSemanal.semana.in_(semanas_ids),
                        PlanSemanal.ano.in_(anos_ids),
                    ).all()
                    planes_por_semana = {
                        (plan.establecimiento_id, plan.semana, plan.ano): plan
                        for plan in planes
                    }

            cambios_plan_semanal = False

            # Bulk query: cantidad de items calificados por inspección (evita N+1)
            ids_periodo = [insp.id for insp in inspecciones_periodo]
            items_por_inspeccion = {}
            if ids_periodo:
                conteos = (
                    db.session.query(
                        InspeccionDetalle.inspeccion_id,
                        func.count(InspeccionDetalle.id)
                    )
                    .filter(InspeccionDetalle.inspeccion_id.in_(ids_periodo))
                    .group_by(InspeccionDetalle.inspeccion_id)
                    .all()
                )
                items_por_inspeccion = {insp_id: cnt for insp_id, cnt in conteos}

            for establecimiento in establecimientos:
                nombre_sanitizado = (
                    establecimiento.nombre[:150]
                    if establecimiento.nombre
                    else "Sin nombre"
                )

                inspecciones_establecimiento = [
                    insp for insp in inspecciones_periodo if insp.establecimiento_id == establecimiento.id
                ]
                total_inspecciones = len(inspecciones_establecimiento)

                calificaciones = [
                    insp.porcentaje_cumplimiento
                    for insp in inspecciones_establecimiento
                    if insp.porcentaje_cumplimiento
                ]

                promedio_calificacion = (
                    sum(calificaciones) / len(calificaciones) if calificaciones else 0
                )

                # Detalle de cada inspección realizada en el periodo (para explicar "1/5", "20%", etc. en el dashboard)
                inspecciones_realizadas_detalle = [
                    {
                        "id": insp.id,
                        "fecha": insp.fecha.isoformat() if insp.fecha else None,
                        "hora_inicio": (
                            insp.hora_inicio.strftime("%H:%M")
                            if insp.hora_inicio
                            else None
                        ),
                        "puntaje_total": (
                            round(insp.puntaje_total)
                            if insp.puntaje_total is not None
                            else None
                        ),
                        "calificacion": (
                            InspeccionesController._calcular_calificacion_global(
                                insp.puntaje_total,
                                items_por_inspeccion.get(insp.id, 0),
                                insp.puntos_criticos_perdidos or 0,
                            )
                            if insp.puntaje_total is not None
                            else None
                        ),
                    }
                    for insp in sorted(
                        inspecciones_establecimiento, key=lambda i: (i.fecha, i.created_at)
                    )
                ]

                # Calificación de la inspección más reciente del establecimiento
                insp_reciente = max(
                    inspecciones_establecimiento,
                    key=lambda i: (i.fecha, i.created_at),
                    default=None
                )
                if insp_reciente and insp_reciente.puntaje_total is not None:
                    items_calc = items_por_inspeccion.get(insp_reciente.id, 0)
                    criticos_fallados = insp_reciente.puntos_criticos_perdidos or 0
                    calificacion_reciente = InspeccionesController._calcular_calificacion_global(
                        insp_reciente.puntaje_total, items_calc, criticos_fallados
                    )
                    puntaje_reciente = round(insp_reciente.puntaje_total)
                else:
                    calificacion_reciente = None
                    puntaje_reciente = None

                if periodo_tipo == "mensual":
                    meta_periodo = 0
                    for semana in semanas_del_periodo:
                        plan = planes_por_semana.get(
                            (establecimiento.id, semana["semana"], semana["ano"])
                        )
                        meta_periodo += int(plan.evaluaciones_meta) if plan else meta_default
                    dias_restantes = (
                        max(0, (fin_periodo - hoy).days + 1)
                        if inicio_periodo <= hoy <= fin_periodo
                        else 0
                    )
                else:
                    semana_consultada = inicio_periodo.isocalendar()[1]
                    ano_consultado = inicio_periodo.year
                    plan_semanal = InspeccionesController.obtener_o_crear_plan_semanal(
                        establecimiento.id, semana_consultada, ano_consultado
                    )
                    meta_periodo = int(plan_semanal.evaluaciones_meta)
                    if plan_semanal.evaluaciones_realizadas != total_inspecciones:
                        plan_semanal.evaluaciones_realizadas = total_inspecciones
                        cambios_plan_semanal = True
                    dias_restantes = max(0, (fin_periodo - hoy).days + 1)

                porcentaje_cumplimiento_meta = (
                    min(100, (total_inspecciones / meta_periodo) * 100)
                    if meta_periodo > 0
                    else 0
                )

                estadisticas_por_establecimiento[establecimiento.id] = {
                    "establecimiento_id": int(establecimiento.id),
                    "nombre": nombre_sanitizado,
                    "meta_semanal": int(meta_periodo),
                    "meta_periodo": int(meta_periodo),
                    "inspecciones_realizadas": int(total_inspecciones),
                    "inspecciones_pendientes": max(
                        0, int(meta_periodo - total_inspecciones)
                    ),
                    "porcentaje_cumplimiento_meta": int(porcentaje_cumplimiento_meta),
                    "promedio_calificacion": int(promedio_calificacion),
                    "calificacion_reciente": calificacion_reciente,
                    "puntaje_reciente": puntaje_reciente,
                    "inspeccion_reciente_id": insp_reciente.id if insp_reciente else None,
                    "inspecciones_realizadas_detalle": inspecciones_realizadas_detalle,
                    "estado": (
                        "completo"
                        if total_inspecciones >= meta_periodo
                        else "pendiente"
                    ),
                    "dias_restantes": dias_restantes,
                }

            if cambios_plan_semanal:
                db.session.commit()

            total_inspecciones_general = sum(
                est["inspecciones_realizadas"]
                for est in estadisticas_por_establecimiento.values()
            )
            total_metas = sum(
                est["meta_periodo"] for est in estadisticas_por_establecimiento.values()
            )
            promedio_cumplimiento_general = (
                int((total_inspecciones_general / total_metas) * 100)
                if total_metas > 0
                else 0
            )

            chart_data = {
                "labels": [est["nombre"] for est in estadisticas_por_establecimiento.values()],
                "realizadas": [
                    est["inspecciones_realizadas"]
                    for est in estadisticas_por_establecimiento.values()
                ],
                "pendientes": [
                    est["inspecciones_pendientes"]
                    for est in estadisticas_por_establecimiento.values()
                ],
                "promedios": [
                    est["promedio_calificacion"]
                    for est in estadisticas_por_establecimiento.values()
                ],
                "cumplimiento": [
                    est["porcentaje_cumplimiento_meta"]
                    for est in estadisticas_por_establecimiento.values()
                ],
            }

            resultado = {
                "periodo": periodo_payload,
                "establecimientos": list(estadisticas_por_establecimiento.values()),
                "resumen_general": {
                    "total_inspecciones": total_inspecciones_general,
                    "total_metas": total_metas,
                    "promedio_cumplimiento": promedio_cumplimiento_general,
                    "establecimientos_completos": len(
                        [
                            est
                            for est in estadisticas_por_establecimiento.values()
                            if est["estado"] == "completo"
                        ]
                    ),
                    "establecimientos_pendientes": len(
                        [
                            est
                            for est in estadisticas_por_establecimiento.values()
                            if est["estado"] == "pendiente"
                        ]
                    ),
                },
                "chart_data": chart_data,
            }

            if periodo_tipo == "semanal":
                resultado["semana"] = {
                    "inicio": inicio_periodo.isoformat(),
                    "fin": fin_periodo.isoformat(),
                    "offset": semana_offset,
                    "es_actual": semana_offset == 0,
                }

            return jsonify(resultado)

        except Exception as e:
            logging.exception("Error obteniendo plan del dashboard: %s", str(e))
            return jsonify({"error": "Error obteniendo plan del dashboard"}), 500

    @staticmethod
    def _obtener_meta_semanal_default():
        try:
            config_meta = ConfiguracionEvaluacion.query.filter_by(
                clave="meta_semanal_default"
            ).first()
            return int(config_meta.valor) if config_meta else 3
        except Exception:
            return 3

    @staticmethod
    def _sumar_meses_fecha(fecha_base, offset_meses):
        total_meses = (fecha_base.year * 12) + fecha_base.month - 1 + offset_meses
        ano = total_meses // 12
        mes = (total_meses % 12) + 1
        return date(ano, mes, 1)

    @staticmethod
    def _obtener_semanas_en_periodo(fecha_inicio, fecha_fin):
        semanas = []
        inicio_semana = fecha_inicio - timedelta(days=fecha_inicio.weekday())

        while inicio_semana <= fecha_fin:
            fin_semana = inicio_semana + timedelta(days=6)
            semanas.append({
                "inicio": inicio_semana,
                "fin": fin_semana,
                "semana": inicio_semana.isocalendar()[1],
                "ano": inicio_semana.year,
            })
            inicio_semana += timedelta(days=7)

        return semanas

    @staticmethod
    def obtener_configuracion_plan():
        """
        ✅ ORM: Obtener configuración del plan semanal
        SEGURIDAD: Administrador puede ver todo, Inspector solo meta_semanal_default
        """
        try:
            user_role = session.get("user_role")

            # CONTROL DE PERMISOS: Admin ve todo, Inspector solo meta semanal
            if user_role not in ["Administrador", "Inspector"]:
                return jsonify({"error": "No autorizado"}), 403

            # Configuración por defecto (en caso de que no exista la tabla aún)
            config_dict = {
                "meta_semanal_default": 3,
                "dias_recordatorio": [1, 3, 5],  # Lunes, miércoles, viernes
                "hora_recordatorio": "09:00",
                "inicio_semana": "lunes",
                "zona_horaria": "America/Lima - Lima, Perú",
                "notificaciones_email": True,
                "notificaciones_navegador": True,
                "alertas_dashboard": True,
                "retener_logs": 90,
                "backup_automatico": "semanal",
                "tiempo_sesion": 240,
                "intentos_login": 5
            }
            
            try:
                # ✅ ORM: Intentar obtener configuraciones desde base de datos
                configuraciones = ConfiguracionEvaluacion.query.all()
                
                # Sobrescribir con valores de la base de datos si existen
                for config in configuraciones:
                    if config.clave == "meta_semanal_default":
                        config_dict["meta_semanal_default"] = int(config.valor)
                    elif config.clave == "dias_recordatorio":
                        config_dict["dias_recordatorio"] = [int(x) for x in config.valor.split(",")]
                    elif config.clave == "hora_recordatorio":
                        config_dict["hora_recordatorio"] = config.valor
                        
            except Exception as db_error:
                # Si la tabla no existe, usar valores por defecto
                import logging
                logging.warning(f"No se pudo cargar configuración de BD, usando defaults: {str(db_error)}")

            # Si es Inspector, solo devolver meta_semanal_default
            if user_role == "Inspector":
                return jsonify({
                    "meta_semanal_default": config_dict["meta_semanal_default"]
                })

            return jsonify(config_dict)

        except Exception as e:
            import traceback
            return jsonify({"error": "Error obteniendo configuración"}), 500

    @staticmethod
    def actualizar_configuracion_plan():
        """
        ✅ ORM: Actualizar configuración del plan semanal
        PERMISOS: 
        - Administrador: puede actualizar todo
        - Inspector: solo puede actualizar meta_semanal_default
        """
        try:
            user_role = session.get("user_role")
            
            # Verificar que el usuario esté autenticado
            if user_role not in ["Administrador", "Inspector"]:
                return jsonify({"error": "No tiene permisos para modificar la configuración"}), 403

            data = request.get_json()
            if not data:
                return jsonify({"error": "Datos requeridos"}), 400

            # Si es Inspector, solo puede actualizar meta_semanal_default
            if user_role == "Inspector":
                # Filtrar solo meta_semanal_default
                if "meta_semanal_default" not in data:
                    return jsonify({"error": "Inspector solo puede actualizar meta semanal"}), 403
                
                # Crear un nuevo dict con solo la meta
                data = {"meta_semanal_default": data["meta_semanal_default"]}

            try:
                # Actualizar o crear configuraciones
                for clave, valor in data.items():
                    if clave in ["meta_semanal_default", "dias_recordatorio", "hora_recordatorio"]:
                        config = ConfiguracionEvaluacion.query.filter_by(clave=clave).first()
                        
                        if clave == "dias_recordatorio":
                            valor_str = ",".join(map(str, valor))
                        else:
                            valor_str = str(valor)
                        
                        if config:
                            config.valor = valor_str
                            config.updated_at = datetime.utcnow()
                        else:
                            nueva_config = ConfiguracionEvaluacion(
                                clave=clave,
                                valor=valor_str,
                                descripcion=f"Configuración de {clave}",
                                modificable_por_inspector=(clave == "meta_semanal_default")
                            )
                            db.session.add(nueva_config)

                db.session.commit()
                
                # ✅ NUEVA POLÍTICA: Los cambios de meta afectan a la semana actual y futuras
                # - Semana actual: se actualiza con la nueva meta
                # - Semanas pasadas: mantienen su meta original (historial protegido)
                # - Semanas futuras: usarán la nueva meta por defecto
                
                # Si se cambió meta_semanal_default, actualizar planes de la semana actual
                if "meta_semanal_default" in data:
                    nueva_meta = int(data["meta_semanal_default"])
                    
                    # Obtener semana y año actual usando zona horaria de Lima
                    from pytz import timezone
                    lima_tz = timezone('America/Lima')
                    lima_now = datetime.now(lima_tz)
                    semana_actual = lima_now.isocalendar()[1]
                    ano_actual = lima_now.year
                    
                    # Actualizar todos los planes semanales de la semana actual
                    planes_actuales = PlanSemanal.query.filter_by(
                        semana=semana_actual,
                        ano=ano_actual
                    ).all()
                    
                    for plan in planes_actuales:
                        plan.evaluaciones_meta = nueva_meta
                    
                    if planes_actuales:
                        db.session.commit()
                
                return jsonify({"success": True, "message": "Configuración actualizada correctamente"})
                
            except Exception as db_error:
                # Si no se puede actualizar en BD, simular éxito para que la UI funcione
                return jsonify({"success": True, "message": "Configuración guardada (usando valores por defecto)"})

        except Exception as e:
            import traceback
            return jsonify({"error": "Error actualizando configuración"}), 500

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": "Error actualizando configuración"}), 500

    @staticmethod
    def obtener_o_crear_plan_semanal(establecimiento_id, semana, ano):
        """
        ✅ ORM: Obtener o crear plan semanal para un establecimiento
        IMPORTANTE: 
        - Semanas pasadas: mantienen su meta original (historial protegido)
        - Semana actual: puede ser actualizada cuando cambia la configuración global
        - Semanas futuras: usan la meta actual por defecto
        """
        plan = PlanSemanal.query.filter_by(
            establecimiento_id=establecimiento_id,
            semana=semana,
            ano=ano
        ).first()
        
        if not plan:
            # Obtener meta por defecto ACTUAL (solo para nuevos planes)
            config_meta = ConfiguracionEvaluacion.query.filter_by(
                clave="meta_semanal_default"
            ).first()
            meta_default = int(config_meta.valor) if config_meta else 3
            
            plan = PlanSemanal(
                establecimiento_id=establecimiento_id,
                semana=semana,
                ano=ano,
                evaluaciones_meta=meta_default,  # Meta congelada para este plan
                evaluaciones_realizadas=0
            )
            db.session.add(plan)
            db.session.commit()
        
        return plan

    @staticmethod
    def actualizar_meta_semanal():
        """
        ✅ ORM: Actualizar meta semanal específica (Inspector/Admin)
        """
        try:
            user_role = session.get("user_role")
            
            if user_role not in ["Administrador", "Inspector"]:
                return jsonify({"error": "No autorizado"}), 403

            data = request.get_json()
            establecimiento_id = data.get("establecimiento_id")
            nueva_meta = data.get("nueva_meta")
            semana = data.get("semana")
            ano = data.get("ano")

            if not all([establecimiento_id, nueva_meta, semana, ano]):
                return jsonify({"error": "Datos incompletos"}), 400

            # Validar meta
            if not isinstance(nueva_meta, int) or nueva_meta < 1 or nueva_meta > 10:
                return jsonify({"error": "Meta debe ser entre 1 y 10"}), 400

            # Obtener o crear plan semanal
            plan = InspeccionesController.obtener_o_crear_plan_semanal(
                establecimiento_id, semana, ano
            )
            
            plan.evaluaciones_meta = nueva_meta
            db.session.commit()

            return jsonify({
                "success": True,
                "message": f"Meta actualizada a {nueva_meta}",
                "nueva_meta": nueva_meta
            })

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": "Error actualizando meta"}), 500
        """
        ✅ ORM: Actualizar meta semanal específica (Inspector/Admin)
        """
        try:
            user_role = session.get("user_role")
            
            if user_role not in ["Administrador", "Inspector"]:
                return jsonify({"error": "No autorizado"}), 403

            data = request.get_json()
            establecimiento_id = data.get("establecimiento_id")
            nueva_meta = data.get("nueva_meta")
            semana = data.get("semana")
            ano = data.get("ano")

            if not all([establecimiento_id, nueva_meta, semana, ano]):
                return jsonify({"error": "Datos incompletos"}), 400

            # Validar meta
            if not isinstance(nueva_meta, int) or nueva_meta < 1 or nueva_meta > 10:
                return jsonify({"error": "Meta debe ser entre 1 y 10"}), 400

            # Obtener o crear plan semanal
            plan = InspeccionesController.obtener_o_crear_plan_semanal(
                establecimiento_id, semana, ano
            )
            
            plan.evaluaciones_meta = nueva_meta
            db.session.commit()

            return jsonify({
                "success": True,
                "message": f"Meta actualizada a {nueva_meta}",
                "nueva_meta": nueva_meta
            })

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": "Error actualizando meta"}), 500

    @staticmethod
    def confirmar_inspeccion_encargado():
        """
        Confirmar inspección por parte de un encargado o jefe.
        Solo el primero que confirme podrá hacerlo.
        """
        try:
            user_id = session.get("user_id")
            user_role = session.get("user_role")

            if user_role not in [ROL_ENCARGADO, ROL_JEFE_ESTABLECIMIENTO, ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR, ROL_ADMINISTRADOR]:
                return jsonify({"error": "No autorizado para confirmar inspecciones"}), 403

            data = request.get_json(silent=True) or {}
            establecimiento_id = data.get("establecimiento_id")
            firma_id = data.get("firma_id")
            firma_temporal_data = data.get("firma_temporal_data")
            firmante_usuario_id = data.get("firmante_usuario_id")
            firmante_rol = data.get("firmante_rol")
            fecha_referencia = data.get("fecha")
            confirmo_firma_encargado = str(
                data.get("confirmo_firma_encargado", "")
            ).strip().lower() in {"1", "true", "t", "yes", "si", "sí"}
            confirmacion_desde_editor = user_role in [ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR, ROL_ADMINISTRADOR]

            if not establecimiento_id:
                return jsonify({"error": "Establecimiento requerido"}), 400

            if not InspeccionesController._usuario_tiene_acceso_establecimiento(
                user_id, user_role, establecimiento_id
            ):
                return jsonify({"error": "Sin acceso a este establecimiento"}), 403

            if confirmacion_desde_editor:
                if not InspeccionesController._es_firma_base64_valida(firma_temporal_data):
                    return jsonify({
                        "error": "La firma temporal del encargado es obligatoria y debe enviarse desde el canvas."
                    }), 400

                if not confirmo_firma_encargado:
                    return jsonify({
                        "error": "Debe confirmar que el encargado está firmando desde esta pantalla."
                    }), 400

                if not firmante_usuario_id:
                    return jsonify({
                        "error": "Debe seleccionar qué encargado o jefe está firmando esta inspección."
                    }), 400
            elif firma_temporal_data:
                return jsonify({
                    "error": "La firma temporal desde pantalla solo puede registrarla Inspector, Ayudante de Inspector o Administrador."
                }), 403

            firma = None
            if firma_id:
                from app.models.Inspecciones_models import FirmaEncargadoPorJefe

                firma = FirmaEncargadoPorJefe.query.filter_by(
                    id=firma_id,
                    establecimiento_id=establecimiento_id,
                    activa=True,
                ).first()

                if not firma:
                    return jsonify({"error": "La firma seleccionada no es válida"}), 400

                if user_role == "Encargado" and firma.encargado_id != user_id:
                    return jsonify({"error": "La firma no pertenece al encargado actual"}), 403

                if user_role == "Jefe de Establecimiento" and firma.jefe_id != user_id:
                    return jsonify({"error": "La firma no pertenece al jefe actual"}), 403
             
            # Obtener estado de tiempo real del establecimiento
            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            
            if clave_tiempo_real not in datos_tiempo_real:
                return jsonify({"error": "No hay inspección activa para este establecimiento"}), 404
            
            estado = datos_tiempo_real[clave_tiempo_real]
            
            # Verificar si ya fue confirmada
            if estado.get("confirmada_por_encargado"):
                confirmador = estado.get("confirmador_nombre", "Otro encargado")
                return jsonify({
                    "error": f"Esta inspección ya fue confirmada por {confirmador}",
                    "confirmada": True,
                    "confirmador": confirmador
                }), 409  # Conflict

            usuario = Usuario.query.get(user_id)
            firma_temporal = False
            firma_encargado_data = None

            if confirmacion_desde_editor:
                firmante_seleccionado = (
                    InspeccionesController._obtener_firmante_habilitado_establecimiento(
                        establecimiento_id,
                        firmante_usuario_id,
                        rol=firmante_rol,
                        fecha_referencia=fecha_referencia,
                    )
                )

                if not firmante_seleccionado:
                    return jsonify({
                        "error": "El firmante seleccionado ya no está habilitado para este establecimiento."
                    }), 400

                nombre_confirmador = firmante_seleccionado["nombre"]
                confirmador_id = firmante_seleccionado["usuario_id"]
                confirmador_rol = firmante_seleccionado["rol"]
                firma_temporal = True
                firma_encargado_data = firma_temporal_data
                firma_id = None
            else:
                nombre_confirmador = (
                    InspeccionesController._nombre_mostrable_usuario(usuario)
                    or f"Usuario {user_id}"
                )
                confirmador_id = user_id
                confirmador_rol = user_role
                if firma:
                    firma_encargado_data = {
                        "id": firma.id,
                        "ruta": signature_public_url(firma.path_firma),
                        "encargado_id": firma.encargado_id,
                        "encargado_nombre": nombre_confirmador,
                    }

            # Marcar como confirmada
            estado["confirmada_por_encargado"] = True
            estado["confirmador_id"] = confirmador_id
            estado["confirmador_nombre"] = nombre_confirmador
            estado["confirmador_rol"] = confirmador_rol
            estado["firma_encargado_id"] = firma_id
            estado["firma_encargado"] = firma_encargado_data
            estado["firma_temporal"] = firma_temporal
            estado["fecha_confirmacion"] = safe_timestamp()
            
            
            # Notificar vía WebSocket a todos los conectados
            from app.socket_events import socketio

            socketio.emit('encargado_aprobo', {
                'establecimiento_id': establecimiento_id,
                'encargado_id': confirmador_id,
                'encargado_nombre': nombre_confirmador,
                'mensaje': f'{nombre_confirmador} ha confirmado la inspección',
                'firma_data': firma_encargado_data,
                'firma_temporal': firma_temporal,
                'confirmador_nombre': nombre_confirmador,
                'confirmador_rol': confirmador_rol,
                'confirmacion_desde_editor': confirmacion_desde_editor,
                'timestamp': estado["fecha_confirmacion"]
            }, room=f'establecimiento_{establecimiento_id}')
            
            return jsonify({
                "success": True,
                "message": f"Inspección confirmada por {nombre_confirmador}",
                "confirmador": nombre_confirmador,
                "confirmador_id": confirmador_id,
                "confirmador_nombre": nombre_confirmador,
                "confirmador_rol": confirmador_rol,
                "firma_data": firma_encargado_data,
                "firma_temporal": firma_temporal,
            })
            
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @staticmethod
    def obtener_inspecciones_pendientes():
        """
        ✅ ORM: Obtener inspecciones en estado 'en_process' que pueden ser continuadas por cualquier inspector
        Incluye también datos temporales de inspecciones no guardadas para colaboración cross-inspector
        """
        try:
            user_role = session.get("user_role")
            current_user_id = session.get("user_id")

            if user_role not in [ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR, ROL_ADMINISTRADOR]:
                return jsonify({"error": "No autorizado"}), 403

            # Solo mostrar inspecciones en_proceso del día actual
            hoy = datetime.now().date()

            inspecciones = db.session.query(Inspeccion)\
                .join(Establecimiento, Inspeccion.establecimiento_id == Establecimiento.id)\
                .join(Usuario, Inspeccion.inspector_id == Usuario.id)\
                .filter(
                    Inspeccion.estado == 'en_proceso',
                    Inspeccion.fecha == hoy
                ).order_by(Inspeccion.fecha.desc(), Inspeccion.created_at.desc()).all()

            inspecciones_data = []

            # Agregar inspecciones de base de datos
            for inspeccion in inspecciones:
                # Calcular progreso (items completados vs total)
                items_completados = 0
                total_items = 0

                if inspeccion.detalles:
                    for detalle in inspeccion.detalles:
                        total_items += 1
                        if detalle.rating is not None and detalle.rating > 0:
                            items_completados += 1

                progreso_porcentaje = int((items_completados / total_items) * 100) if total_items > 0 else 0

                # Verificar si es del inspector actual
                es_propia = inspeccion.inspector_id == current_user_id

                observaciones_limpias, motivo_sin_firma_encargado = (
                    InspeccionesController._obtener_observaciones_y_motivo(inspeccion)
                )

                inspecciones_data.append({
                    'id': inspeccion.id,
                    'tipo': 'base_datos',  # Indicar que viene de BD
                    'establecimiento': {
                        'id': inspeccion.establecimiento.id,
                        'nombre': inspeccion.establecimiento.nombre,
                        'direccion': inspeccion.establecimiento.direccion
                    },
                    'inspector_original': {
                        'nombre': f"{inspeccion.inspector.nombre} {inspeccion.inspector.apellido}",
                        'es_actual': es_propia
                    },
                    'fecha': inspeccion.fecha.strftime('%Y-%m-%d'),
                    'hora_inicio': (
                        inspeccion.hora_inicio.strftime('%H:%M')
                        if inspeccion.hora_inicio
                        else inspeccion.created_at.strftime('%H:%M')
                    ),
                    'created_at': inspeccion.created_at.strftime('%Y-%m-%d %H:%M'),
                    'progreso': {
                        'completados': items_completados,
                        'total': total_items,
                        'porcentaje': progreso_porcentaje
                    },
                    'observaciones': observaciones_limpias,
                    'motivo_sin_firma_encargado': motivo_sin_firma_encargado,
                    'tiene_firmas': bool(inspeccion.firma_inspector or inspeccion.firma_encargado)
                })

            # Agregar inspecciones temporales (datos no guardados)
            # Buscar en inspecciones_temporales para todos los establecimientos
            for clave_temporal, datos_temp in inspecciones_temporales.items():
                if clave_temporal.startswith('establecimiento_'):
                    try:
                        establecimiento_id = int(clave_temporal.replace('establecimiento_', ''))
                        datos = datos_temp.get('data', {})

                        # Solo incluir si hay datos significativos
                        if not datos or not datos.get('items'):
                            continue

                        # Calcular progreso de datos temporales
                        items_temp = datos.get('items', {})
                        items_completados_temp = len([r for r in items_temp.values() if r and r.get('rating') is not None and r['rating'] > 0])
                        total_items_temp = len(items_temp)

                        # Solo incluir si hay progreso significativo (>10% completado)
                        if total_items_temp == 0 or (items_completados_temp / total_items_temp) < 0.1:
                            continue

                        progreso_porcentaje_temp = int((items_completados_temp / total_items_temp) * 100) if total_items_temp > 0 else 0

                        # Obtener información del establecimiento
                        establecimiento = Establecimiento.query.get(establecimiento_id)
                        if not establecimiento:
                            continue

                        # Obtener inspector que está trabajando actualmente (último que guardó)
                        inspector_actual = None
                        clave_tiempo_real = f"establecimiento_{establecimiento_id}"
                        datos_tiempo_real_est = datos_tiempo_real.get(clave_tiempo_real)
                        if datos_tiempo_real_est and datos_tiempo_real_est.get('inspector_id'):
                            inspector_actual = Usuario.query.get(datos_tiempo_real_est['inspector_id'])
                        elif datos_temp.get('user_id'):
                            inspector_actual = Usuario.query.get(datos_temp['user_id'])

                        # Determinar si es del inspector actual
                        es_propia_temp = datos_temp.get('user_id') == current_user_id

                        inspecciones_data.append({
                            'id': f"temp_{establecimiento_id}",  # ID virtual para inspección temporal
                            'tipo': 'temporal',  # Indicar que es temporal
                            'establecimiento': {
                                'id': establecimiento.id,
                                'nombre': establecimiento.nombre,
                                'direccion': establecimiento.direccion
                            },
                            'inspector_original': {
                                'nombre': f"{inspector_actual.nombre} {inspector_actual.apellido}" if inspector_actual else "Inspector desconocido",
                                'es_actual': es_propia_temp
                            },
                            'fecha': datetime.now().strftime('%Y-%m-%d'),  # Fecha actual
                            'created_at': datos_temp.get('timestamp', datetime.now()).strftime('%Y-%m-%d %H:%M') if isinstance(datos_temp.get('timestamp'), datetime) else datetime.now().strftime('%Y-%m-%d %H:%M'),
                            'progreso': {
                                'completados': items_completados_temp,
                                'total': total_items_temp,
                                'porcentaje': progreso_porcentaje_temp
                            },
                            'observaciones': datos.get('observaciones', ''),
                            'tiene_firmas': bool(datos.get('firma_inspector') or datos.get('firma_encargado'))
                        })

                    except (ValueError, KeyError) as e:
                        # Saltar entradas malformadas
                        continue

            # Ordenar por fecha de creación descendente (más recientes primero)
            inspecciones_data.sort(key=lambda x: x['created_at'], reverse=True)

            return jsonify({
                'success': True,
                'inspecciones': inspecciones_data,
                'total': len(inspecciones_data)
            })

        except Exception as e:
            import traceback
            traceback.print_exc()
            return jsonify({"error": "Error interno del servidor"}), 500

    @staticmethod
    def retomar_inspeccion(inspeccion_id):
        """
        ✅ ORM: Permite a un inspector retomar una inspección pendiente
        Ahora también maneja inspecciones temporales (no guardadas en BD)
        """
        try:
            user_role = session.get("user_role")
            current_user_id = session.get("user_id")

            if user_role not in [ROL_INSPECTOR, ROL_AYUDANTE_INSPECTOR, ROL_ADMINISTRADOR]:
                return jsonify({"error": "No autorizado"}), 403

            # Convertir inspeccion_id a string de manera segura (maneja tanto str como int)
            if isinstance(inspeccion_id, int):
                inspeccion_id_str = str(inspeccion_id)
            elif isinstance(inspeccion_id, str):
                inspeccion_id_str = inspeccion_id
            else:
                return jsonify({"error": "ID de inspección inválido"}), 400

            # Verificar si es una inspección temporal (no guardada en BD)
            if inspeccion_id_str.startswith('temp_'):
                # Extraer establecimiento_id del ID temporal
                try:
                    establecimiento_id = int(inspeccion_id_str.replace('temp_', ''))
                except ValueError:
                    return jsonify({"error": "ID de inspección temporal inválido"}), 400

                # Buscar datos temporales para este establecimiento
                clave_temporal = f"establecimiento_{establecimiento_id}"
                datos_temporales = inspecciones_temporales.get(clave_temporal)

                if not datos_temporales or not datos_temporales.get('data'):
                    return jsonify({"error": "No se encontraron datos temporales para esta inspección"}), 404

                # Retornar datos temporales en el formato esperado
                datos = datos_temporales['data']
                inspeccion_data = {
                    'success': True,
                    'inspeccion': {
                        'id': inspeccion_id_str,  # Mantener el ID temporal como string
                        'establecimiento_id': establecimiento_id,
                        'fecha': datetime.now().strftime('%Y-%m-%d'),  # Fecha actual
                        'observaciones': datos.get('observaciones', ''),
                        'estado': 'temporal',  # Indicar que es temporal
                        'items': datos.get('items', {}),
                        'firma_inspector': datos.get('firma_inspector'),
                        'firma_encargado': datos.get('firma_encargado'),
                        'evidencias': []  # Los datos temporales no incluyen evidencias
                    }
                }

                return jsonify(inspeccion_data)

            # Para inspecciones normales de BD, convertir a int para la consulta
            try:
                inspeccion_id_int = int(inspeccion_id_str)
            except ValueError:
                return jsonify({"error": "ID de inspección inválido"}), 400

            # Buscar la inspección
            inspeccion = Inspeccion.query.get(inspeccion_id_int)
            if not inspeccion:
                return jsonify({"error": "Inspección no encontrada"}), 404

            # Verificar que esté en estado pendiente
            if inspeccion.estado != 'en_proceso':
                return jsonify({"error": f"La inspección está en estado '{inspeccion.estado}' y no puede ser retomada"}), 400

            # Cambiar el inspector responsable
            inspector_anterior = f"{inspeccion.inspector.nombre} {inspeccion.inspector.apellido}"
            inspeccion.inspector_id = current_user_id

            # Actualizar también los datos en tiempo real para que el encargado vea el cambio
            clave_tiempo_real = f"establecimiento_{inspeccion.establecimiento_id}"
            if clave_tiempo_real in datos_tiempo_real:
                datos_tiempo_real[clave_tiempo_real]["inspector_id"] = current_user_id
                datos_tiempo_real[clave_tiempo_real]["ultima_actualizacion"] = safe_timestamp()

                # Emitir actualización en tiempo real para notificar el cambio de inspector
                try:
                    room = f"establecimiento_{inspeccion.establecimiento_id}"
                    socketio.emit(
                        "inspector_cambiado",
                        {
                            "establecimiento_id": inspeccion.establecimiento_id,
                            "nuevo_inspector_id": current_user_id,
                            "inspector_anterior": inspector_anterior,
                            "timestamp": safe_timestamp(),
                        },
                        to=room,
                    )
                except Exception as e:
                    pass  # Error silenciado en producción

            db.session.commit()

            # Retornar datos completos de la inspección para cargar en la interfaz
            return InspeccionesController.obtener_inspeccion_detalle(inspeccion_id_int)

        except Exception as e:
            db.session.rollback()
            import traceback
            traceback.print_exc()
            return jsonify({"error": "Error interno del servidor"}), 500

    @staticmethod
    def obtener_inspeccion_detalle(inspeccion_id):
        """
        ✅ ORM: Obtener detalles completos de una inspección para cargar en la interfaz
        """
        try:
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({"error": "Inspección no encontrada"}), 404

            # Construir estructura de items similar a la que usa la interfaz
            items_data = {}
            for detalle in inspeccion.detalles:
                items_data[str(detalle.item_establecimiento_id)] = {
                    'rating': detalle.rating,
                    'observacion': detalle.observacion_item or ''
                }

            # Obtener evidencias si existen
            evidencias_urls = []
            if inspeccion.evidencias:
                for evidencia in inspeccion.evidencias:
                    evidencias_urls.append(
                        InspeccionesController._normalize_evidence_url(
                            evidencia.ruta_archivo
                        )
                    )

            observaciones_limpias, motivo_sin_firma_encargado = (
                InspeccionesController._obtener_observaciones_y_motivo(inspeccion)
            )

            inspeccion_data = {
                'success': True,
                'inspeccion': {
                    'id': inspeccion.id,
                    'establecimiento_id': inspeccion.establecimiento_id,
                    'fecha': inspeccion.fecha.strftime('%Y-%m-%d'),
                    'observaciones': observaciones_limpias,
                    'motivo_sin_firma_encargado': motivo_sin_firma_encargado,
                    'finalizada_sin_firma_encargado': bool(
                        motivo_sin_firma_encargado and not inspeccion.firma_encargado
                    ),
                    'estado': inspeccion.estado,
                    'items': items_data,
                    'firma_inspector': signature_public_url(inspeccion.firma_inspector),
                    'firma_encargado': signature_public_url(inspeccion.firma_encargado),
                    'evidencias': evidencias_urls
                }
            }

            return jsonify(inspeccion_data)

        except Exception as e:
            return jsonify({"error": "Error interno del servidor"}), 500

    @staticmethod
    def obtener_items_establecimiento_detallado(establecimiento_id):
        """
        Obtener items detallados de un establecimiento con información de origen
        """
        try:
            # Obtener todos los items del establecimiento con información detallada
            items = (
                db.session.query(
                    ItemEvaluacionEstablecimiento,
                    ItemEvaluacionBase,
                    CategoriaEvaluacion,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(
                    ItemEvaluacionEstablecimiento.establecimiento_id == establecimiento_id,
                    ItemEvaluacionEstablecimiento.activo == True,
                    ItemEvaluacionBase.activo == True,
                    CategoriaEvaluacion.activo == True,
                )
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Organizar los datos en un formato más limpio
            categorias = {}
            for item, item_base, categoria in items:
                if categoria.id not in categorias:
                    categorias[categoria.id] = {
                        "id": categoria.id,
                        "nombre": categoria.nombre,
                        "descripcion": categoria.descripcion,
                        "orden": categoria.orden,
                        "items": [],
                    }

                # Determinar el origen del item (si viene de plantilla o fue agregado individualmente)
                # Por ahora, todos los items se consideran agregados individualmente
                # En el futuro se podría agregar un campo para rastrear el origen
                origen = "Agregado individualmente"

                categorias[categoria.id]["items"].append(
                    {
                        "id": item.id,
                        "item_base_id": item_base.id,
                        "codigo": item_base.codigo,
                        "descripcion_base": item_base.descripcion,
                        "descripcion_personalizada": item.descripcion_personalizada,
                        "riesgo": item_base.riesgo,
                        "puntaje_minimo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_minimo"],
                        "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_maximo"],
                        "factor_ajuste": float(item.factor_ajuste),
                        "origen": origen,
                        "orden": item_base.orden,
                        "puede_eliminar": True,  # Por ahora todos pueden eliminarse
                    }
                )

            # Convertir a lista ordenada por orden
            categorias_lista = list(categorias.values())
            categorias_lista.sort(key=lambda x: x["orden"])

            return categorias_lista

        except Exception as e:
            raise Exception(f"Error obteniendo items detallados del establecimiento: {str(e)}")

    @staticmethod
    def agregar_item_a_establecimiento(establecimiento_id, item_plantilla_id):
        """
        Agregar un item individual de una plantilla a un establecimiento
        """
        try:
            from app.models.Plantillas_models import ItemPlantillaChecklist

            # Verificar que el establecimiento existe
            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                raise Exception("Establecimiento no encontrado")

            # Verificar que el item de plantilla existe
            item_plantilla = ItemPlantillaChecklist.query.get(item_plantilla_id)
            if not item_plantilla or not item_plantilla.activo:
                raise Exception("Item de plantilla no encontrado o inactivo")

            # Verificar que no esté duplicado
            existing_item = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                item_base_id=item_plantilla.item_base_id,
                activo=True
            ).first()

            if existing_item:
                raise Exception("Este item ya existe en el establecimiento")

            # Crear nuevo item
            nuevo_item = ItemEvaluacionEstablecimiento(
                establecimiento_id=establecimiento_id,
                item_base_id=item_plantilla.item_base_id,
                descripcion_personalizada=item_plantilla.descripcion_personalizada,
                factor_ajuste=item_plantilla.factor_ajuste,
                activo=True
            )

            db.session.add(nuevo_item)
            db.session.commit()

            return nuevo_item

        except Exception as e:
            db.session.rollback()
            raise Exception(f"Error agregando item al establecimiento: {str(e)}")

    @staticmethod
    def eliminar_item_de_establecimiento(establecimiento_id, item_id):
        """
        Eliminar un item específico de un establecimiento
        """
        try:
            # Verificar que el item existe y pertenece al establecimiento
            item = ItemEvaluacionEstablecimiento.query.filter_by(
                id=item_id,
                establecimiento_id=establecimiento_id,
                activo=True
            ).first()

            if not item:
                raise Exception("Item no encontrado en este establecimiento")

            # Verificar que no esté siendo usado en inspecciones
            inspecciones_count = InspeccionDetalle.query.filter_by(
                item_establecimiento_id=item_id
            ).count()

            if inspecciones_count > 0:
                raise Exception(f"El item está siendo usado en {inspecciones_count} inspección(es)")

            # Desactivar item
            item.activo = False
            db.session.commit()

            return True

        except Exception as e:
            db.session.rollback()
            raise Exception(f"Error eliminando item del establecimiento: {str(e)}")

    @staticmethod
    def obtener_items_establecimiento_detallado(establecimiento_id):
        """
        Obtener items detallados del establecimiento organizados por categorías
        """
        try:
            # Obtener todos los items del establecimiento con sus categorías
            items = (
                db.session.query(
                    ItemEvaluacionEstablecimiento,
                    ItemEvaluacionBase,
                    CategoriaEvaluacion,
                )
                .join(
                    ItemEvaluacionBase,
                    ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id,
                )
                .join(
                    CategoriaEvaluacion,
                    ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id,
                )
                .filter(
                    ItemEvaluacionEstablecimiento.establecimiento_id == establecimiento_id,
                    ItemEvaluacionEstablecimiento.activo == True,
                    ItemEvaluacionBase.activo == True,
                    CategoriaEvaluacion.activo == True,
                )
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)
                .all()
            )

            # Organizar los datos en un formato más limpio
            categorias = {}
            for item, item_base, categoria in items:
                if categoria.id not in categorias:
                    categorias[categoria.id] = {
                        "id": categoria.id,
                        "nombre": categoria.nombre,
                        "descripcion": categoria.descripcion,
                        "orden": categoria.orden,
                        "items": [],
                    }

                # Determinar origen del item
                origen = "Individual"
                if hasattr(item, 'item_plantilla') and item.item_plantilla:
                    origen = f"Plantilla: {item.item_plantilla.plantilla.nombre}"

                categorias[categoria.id]["items"].append(
                    {
                        "id": item.id,
                        "item_base_id": item_base.id,
                        "codigo": item_base.codigo,
                        "descripcion_base": item_base.descripcion,
                        "descripcion_personalizada": item.descripcion_personalizada,
                        "riesgo": item_base.riesgo,
                        "puntaje_minimo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_minimo"],
                        "puntaje_maximo": InspeccionesController._obtener_configuracion_calificacion(
                            item_base.riesgo
                        )["puntaje_maximo"],
                        "orden": item_base.orden,
                        "factor_ajuste": float(item.factor_ajuste),
                        "origen": origen,
                    }
                )

            # Convertir a lista ordenada por orden
            categorias_lista = list(categorias.values())
            categorias_lista.sort(key=lambda x: x["orden"])

            return categorias_lista

        except Exception as e:
            raise Exception(f"Error obteniendo items detallados del establecimiento: {str(e)}")

    @staticmethod
    def _calcular_calificacion_global(puntaje_total, items_calificados, criticos_fallados=0):
        """Devuelve EXCELENTE/MUY BIEN/REGULAR/MALO según puntos extra sobre el mínimo.

        Umbrales confirmados por Alfredo (llamada 10/07): Excelente 0-1, Muy bien 2-6,
        Regular 7-14, Malo >14. Si hay algún ítem crítico fallado, nunca puede salir
        Excelente ni Muy bien (bloqueo explícito, aunque un crítico fallado ya suma +7
        y empuja a Regular/Malo por el umbral solo).
        """
        puntos_extra = max(0, round(puntaje_total) - items_calificados)

        if criticos_fallados > 0:
            return "REGULAR" if puntos_extra <= 14 else "MALO"

        if puntos_extra <= 1:
            return "EXCELENTE"
        elif puntos_extra <= 6:
            return "MUY BIEN"
        elif puntos_extra <= 14:
            return "REGULAR"
        else:
            return "MALO"

    @staticmethod
    def descartar_inspeccion(inspeccion_id):
        """Elimina una inspección en_proceso del día actual. Solo el dueño o admin."""
        try:
            user_role = session.get("user_role")
            current_user_id = session.get("user_id")

            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({"error": "Inspección no encontrada"}), 404

            if inspeccion.estado != 'en_proceso':
                return jsonify({"error": "Solo se pueden descartar inspecciones en proceso"}), 400

            hoy = datetime.now().date()
            if inspeccion.fecha != hoy:
                return jsonify({"error": "Solo se pueden descartar inspecciones del día actual"}), 400

            if user_role != ROL_ADMINISTRADOR and inspeccion.inspector_id != current_user_id:
                return jsonify({"error": "No tienes permiso para descartar esta inspección"}), 403

            InspeccionDetalle.query.filter_by(inspeccion_id=inspeccion_id).delete()
            db.session.delete(inspeccion)
            db.session.commit()

            return jsonify({"success": True, "message": "Inspección descartada"})

        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Error al descartar inspección: {str(e)}"}), 500

    @staticmethod
    def obtener_items_disponibles_para_establecimiento(establecimiento_id, query=None, plantilla_id=None):
        """
        Obtener items de plantillas que pueden ser agregados a un establecimiento
        """
        try:
            from app.models.Plantillas_models import ItemPlantillaChecklist, PlantillaChecklist

            # Obtener IDs de items que ya están en el establecimiento
            items_existentes = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                activo=True
            ).with_entities(ItemEvaluacionEstablecimiento.item_base_id).all()

            items_existentes_ids = [item.item_base_id for item in items_existentes]

            # Construir query para items disponibles
            items_query = ItemPlantillaChecklist.query.filter_by(activo=True)

            # Filtrar por plantilla si se especifica
            if plantilla_id:
                items_query = items_query.filter_by(plantilla_id=plantilla_id)

            # Excluir items que ya están en el establecimiento
            if items_existentes_ids:
                items_query = items_query.filter(
                    ~ItemPlantillaChecklist.item_base_id.in_(items_existentes_ids)
                )

            # Aplicar búsqueda por texto
            if query and len(query) >= 2:
                items_query = items_query.filter(
                    or_(
                        ItemPlantillaChecklist.item_base.has(func.lower(ItemEvaluacionBase.descripcion).like(f'%{query.lower()}%')),
                        ItemPlantillaChecklist.item_base.has(func.lower(ItemEvaluacionBase.codigo).like(f'%{query.lower()}%'))
                    )
                )

            # Unir con plantillas y ordenar
            items = items_query.join(PlantillaChecklist)\
                .order_by(PlantillaChecklist.nombre, ItemPlantillaChecklist.orden)\
                .limit(50)\
                .all()

            # Preparar resultado
            resultado = []
            for item in items:
                resultado.append({
                    'id': item.id,
                    'item_base_id': item.item_base_id,
                    'codigo': item.item_base.codigo,
                    'descripcion': item.item_base.descripcion,
                    'descripcion_personalizada': item.descripcion_personalizada,
                    'categoria': item.item_base.categoria.nombre,
                    'riesgo': item.riesgo,
                    'puntaje_minimo': InspeccionesController._obtener_configuracion_calificacion(
                        item.riesgo
                    )['puntaje_minimo'],
                    'puntaje_maximo': InspeccionesController._obtener_configuracion_calificacion(
                        item.riesgo
                    )['puntaje_maximo'],
                    'plantilla': item.plantilla.nombre,
                    'tipo_establecimiento': item.plantilla.tipo_establecimiento.nombre
                })

            return resultado

        except Exception as e:
            raise Exception(f"Error obteniendo items disponibles: {str(e)}")

    @staticmethod
    def agregar_item_individual_a_establecimiento(establecimiento_id, item_base_id, descripcion_personalizada=None, factor_ajuste=1.00):
        """
        Agregar un item individual de la base de datos a un establecimiento
        """
        try:
            # Verificar que el establecimiento existe
            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                raise Exception("Establecimiento no encontrado")

            # Verificar que el item base existe y está activo
            item_base = ItemEvaluacionBase.query.filter_by(
                id=item_base_id,
                activo=True
            ).first()
            if not item_base:
                raise Exception("Item base no encontrado o inactivo")

            # Verificar que no esté duplicado
            existing_item = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                item_base_id=item_base_id,
                activo=True
            ).first()

            if existing_item:
                raise Exception("Este item ya existe en el establecimiento")

            # Crear nuevo item
            nuevo_item = ItemEvaluacionEstablecimiento(
                establecimiento_id=establecimiento_id,
                item_base_id=item_base_id,
                descripcion_personalizada=descripcion_personalizada,
                factor_ajuste=factor_ajuste,
                activo=True
            )

            db.session.add(nuevo_item)
            db.session.commit()

            return nuevo_item

        except Exception as e:
            db.session.rollback()
            raise Exception(f"Error agregando item individual al establecimiento: {str(e)}")

    @staticmethod
    def crear_item_personalizado_para_establecimiento(establecimiento_id, categoria_id, descripcion, riesgo, puntaje_minimo, puntaje_maximo, factor_ajuste=1.00):
        """
        Crear un nuevo item personalizado para un establecimiento
        """
        try:
            # Verificar que el establecimiento existe
            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                raise Exception("Establecimiento no encontrado")

            # Verificar que la categoría existe
            categoria = CategoriaEvaluacion.query.filter_by(
                id=categoria_id,
                activo=True
            ).first()
            if not categoria:
                raise Exception("Categoría no encontrada o inactiva")

            # Validar datos
            if not descripcion or not descripcion.strip():
                raise Exception("La descripción es obligatoria")

            if riesgo not in ["Crítico", "Mayor", "Menor"]:
                raise Exception("El riesgo debe ser: Crítico, Mayor o Menor")

            configuracion_calificacion = (
                InspeccionesController._obtener_configuracion_calificacion(riesgo)
            )
            puntaje_minimo = configuracion_calificacion["puntaje_minimo"]
            puntaje_maximo = configuracion_calificacion["puntaje_maximo"]

            # Generar código único para el item personalizado
            # Formato: X.Y donde X es el ID de la categoría e Y es el siguiente número disponible
            categoria_id_str = str(categoria_id)
            
            # Buscar todos los códigos de esta categoría para encontrar el último número usado
            codigos_categoria = db.session.query(ItemEvaluacionBase).filter(
                ItemEvaluacionBase.categoria_id == categoria_id,
                ItemEvaluacionBase.activo == True
            ).with_entities(ItemEvaluacionBase.codigo).all()
            
            # Extraer los números Y de los códigos X.Y
            numeros_usados = []
            for (codigo,) in codigos_categoria:
                try:
                    partes = codigo.split('.')
                    if len(partes) == 2 and partes[0] == categoria_id_str:
                        numero = int(partes[1])
                        numeros_usados.append(numero)
                except (ValueError, IndexError):
                    continue
            
            # Encontrar el siguiente número disponible
            if numeros_usados:
                nuevo_numero = max(numeros_usados) + 1
            else:
                nuevo_numero = 1
            
            codigo = f"{categoria_id}.{nuevo_numero}"

            # Crear nuevo item base personalizado
            nuevo_item_base = ItemEvaluacionBase(
                categoria_id=categoria_id,
                codigo=codigo,
                descripcion=descripcion.strip(),
                riesgo=riesgo,
                puntaje_minimo=puntaje_minimo,
                puntaje_maximo=puntaje_maximo,
                orden=999,  # Orden alto para items personalizados
                activo=True
            )

            db.session.add(nuevo_item_base)
            db.session.flush()  # Para obtener el ID

            # Crear item específico para el establecimiento
            item_establecimiento = ItemEvaluacionEstablecimiento(
                establecimiento_id=establecimiento_id,
                item_base_id=nuevo_item_base.id,
                descripcion_personalizada=None,  # Usar descripción base
                factor_ajuste=factor_ajuste,
                activo=True
            )

            db.session.add(item_establecimiento)
            db.session.commit()

            return jsonify({
                "success": True,
                "message": f"Item personalizado '{descripcion}' creado exitosamente",
                "item_id": item_establecimiento.id,
                "item_base_id": nuevo_item_base.id
            })

        except Exception as e:
            db.session.rollback()
            return jsonify({"success": False, "error": f"Error creando item personalizado: {str(e)}"}), 500

    @staticmethod
    def obtener_items_base_disponibles(establecimiento_id, categoria_id=None, query=None):
        """
        Obtener items base disponibles para agregar a un establecimiento
        """
        try:
            # Obtener IDs de items que ya están en el establecimiento
            items_existentes = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=establecimiento_id,
                activo=True
            ).with_entities(ItemEvaluacionEstablecimiento.item_base_id).all()

            items_existentes_ids = [item.item_base_id for item in items_existentes]

            # Construir query para items base disponibles
            items_query = ItemEvaluacionBase.query.filter_by(activo=True)

            # Excluir items que ya están en el establecimiento
            if items_existentes_ids:
                items_query = items_query.filter(
                    ~ItemEvaluacionBase.id.in_(items_existentes_ids)
                )

            # Filtrar por categoría si se especifica
            if categoria_id:
                items_query = items_query.filter_by(categoria_id=categoria_id)

            # Aplicar búsqueda por texto
            if query and len(query) >= 2:
                items_query = items_query.filter(
                    db.or_(
                        db.func.lower(ItemEvaluacionBase.descripcion).like(f'%{query.lower()}%'),
                        db.func.lower(ItemEvaluacionBase.codigo).like(f'%{query.lower()}%')
                    )
                )

            # Unir con categorías y ordenar
            items = items_query.join(CategoriaEvaluacion)\
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)\
                .limit(100)\
                .all()

            # Preparar resultado
            resultado = []
            for item in items:
                configuracion_calificacion = (
                    InspeccionesController._obtener_configuracion_calificacion(
                        item.riesgo
                    )
                )
                resultado.append({
                    'id': item.id,
                    'codigo': item.codigo,
                    'descripcion': item.descripcion,
                    'categoria': item.categoria.nombre,
                    'categoria_id': item.categoria.id,
                    'riesgo': item.riesgo,
                    'puntaje_minimo': configuracion_calificacion['puntaje_minimo'],
                    'puntaje_maximo': configuracion_calificacion['puntaje_maximo'],
                    'orden': item.orden
                })

            return jsonify({"success": True, "data": resultado})

        except Exception as e:
            return jsonify({"success": False, "error": f"Error obteniendo items base disponibles: {str(e)}"}), 500
