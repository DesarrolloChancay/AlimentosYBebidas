"""
Descripción: Controlador para gestionar el Reglamento de Restaurante
Lógica: Maneja las reuniones semanales, evaluaciones de cumplimiento y cálculo de sanciones
Ejemplo de uso:
    - Crear reunión semanal cada lunes
    - Evaluar items del checklist (Cumple/No Cumple)
    - Calcular sanciones por número de platos
"""

from flask import Blueprint, render_template, request, jsonify, session
from app.extensions import db
from app.models.Inspecciones_models import (
    ItemReglamento,
    ReglamentoRestaurante,
    EvaluacionReglamento,
    Establecimiento,
    Inspeccion,
    JefeEstablecimiento,
)
from app.utils.auth_decorators import login_required
from datetime import datetime, timedelta
from sqlalchemy import func, and_

reglamento_bp = Blueprint("reglamento", __name__, url_prefix="/reglamento")


def calcular_sancion_por_platos(total_puntos):
    """
    Descripcion: Calcula la sancion en numero de platos segun la tabla
    Logica:
    - De 1 a 2: Llamado de atencion
    - De 3 a 4: 5 platos
    - De 5 a 6: 10 platos
    - De 7 a 8: 15 platos
    - De 9 a 10: 20 platos
    - De 11 a mas: 25 platos
    """
    if total_puntos <= 2:
        return {"platos": 0, "descripcion": "Llamado de atencion"}
    elif 3 <= total_puntos <= 4:
        return {"platos": 5, "descripcion": "5 platos"}
    elif 5 <= total_puntos <= 6:
        return {"platos": 10, "descripcion": "10 platos"}
    elif 7 <= total_puntos <= 8:
        return {"platos": 15, "descripcion": "15 platos"}
    elif 9 <= total_puntos <= 10:
        return {"platos": 20, "descripcion": "20 platos"}
    else:
        return {"platos": 25, "descripcion": "25 platos"}

@reglamento_bp.route("/dashboard")
@login_required
def dashboard():
    """
    Descripción: Dashboard principal del reglamento
    Lógica: Muestra reuniones pendientes y completadas
    """
    try:
        user_id = session.get("user_id")
        user_role = session.get("user_role")

        # Solo Inspectores y Administradores pueden acceder
        if user_role not in ["Inspector", "Administrador"]:
            return (
                "Acceso denegado. Solo inspectores pueden gestionar el reglamento.",
                403,
            )

        # Obtener todos los establecimientos para que el inspector elija
        establecimientos = Establecimiento.query.filter_by(activo=True).all()

        # Si hay un establecimiento seleccionado en la URL
        establecimiento_id = request.args.get("establecimiento_id", type=int)

        if establecimiento_id:
            establecimiento = Establecimiento.query.get_or_404(establecimiento_id)

            # Obtener reuniones del establecimiento
            reuniones = (
                ReglamentoRestaurante.query.filter_by(
                    establecimiento_id=establecimiento_id
                )
                .order_by(ReglamentoRestaurante.fecha_reunion.desc())
                .limit(10)
                .all()
            )

            return render_template(
                "reglamento/dashboard.html",
                establecimiento=establecimiento,
                reuniones=reuniones,
            )
        else:
            # Mostrar selector de establecimiento
            return render_template(
                "reglamento/seleccionar_establecimiento.html",
                establecimientos=establecimientos,
            )

    except Exception as e:
        return f"Error: {str(e)}", 500


@reglamento_bp.route("/crear-reunion", methods=["POST"])
@login_required
def crear_reunion():
    """
    Descripción: Crear una nueva reunión semanal
    Lógica: Se ejecuta cada lunes para evaluar la semana anterior (lunes a domingo)
    Ejemplo:
        - Hoy es lunes 11/nov/2025
        - Se crea reunión para evaluar del lunes 4/nov al domingo 10/nov
    """
    try:
        data = request.get_json()
        establecimiento_id = data.get("establecimiento_id")

        if not establecimiento_id:
            return jsonify({"error": "Establecimiento requerido"}), 400

        # Calcular fechas de la semana ANTERIOR
        hoy = datetime.now().date()
        # Si hoy es lunes (weekday=0), evaluar semana anterior
        dias_hasta_lunes_actual = hoy.weekday()  # 0=lunes, 6=domingo
        lunes_actual = hoy - timedelta(days=dias_hasta_lunes_actual)

        # Semana a evaluar es la anterior al lunes actual
        lunes_semana_anterior = lunes_actual - timedelta(days=7)
        domingo_semana_anterior = lunes_semana_anterior + timedelta(days=6)

        # Número de semana ISO
        semana = lunes_semana_anterior.isocalendar()[1]
        ano = lunes_semana_anterior.year

        # Verificar si ya existe una reunión para esta semana
        reunion_existente = ReglamentoRestaurante.query.filter_by(
            establecimiento_id=establecimiento_id, semana=semana, ano=ano
        ).first()

        if reunion_existente:
            return (
                jsonify(
                    {
                        "error": "Ya existe una reunión para esta semana",
                        "reunion_id": reunion_existente.id,
                    }
                ),
                409,
            )

        # Contar inspecciones de la semana anterior
        inspecciones = Inspeccion.query.filter(
            Inspeccion.establecimiento_id == establecimiento_id,
            Inspeccion.fecha >= lunes_semana_anterior,
            Inspeccion.fecha <= domingo_semana_anterior,
            Inspeccion.estado == "completada",
        ).count()

        # Crear nueva reunión
        nueva_reunion = ReglamentoRestaurante(
            establecimiento_id=establecimiento_id,
            semana=semana,
            ano=ano,
            fecha_reunion=hoy,
            fecha_inicio_semana=lunes_semana_anterior,
            fecha_fin_semana=domingo_semana_anterior,
            total_inspecciones=inspecciones,
            estado="pendiente",
        )

        db.session.add(nueva_reunion)
        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Reunión creada exitosamente",
                "reunion_id": nueva_reunion.id,
                "semana_evaluada": f"Semana {semana} ({lunes_semana_anterior.strftime('%d/%m')} - {domingo_semana_anterior.strftime('%d/%m/%Y')})",
            }
        )

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500


@reglamento_bp.route("/reunion/<int:reunion_id>")
@login_required
def ver_reunion(reunion_id):
    """
    Descripción: Ver y editar una reunión específica
    Lógica: Muestra el checklist de items para marcar Cumple/No Cumple
    """
    try:
        reunion = ReglamentoRestaurante.query.get_or_404(reunion_id)

        # Obtener todos los items del reglamento
        items = ItemReglamento.query.all()

        # Obtener evaluaciones existentes
        evaluaciones = {}
        for eval in reunion.evaluaciones:
            evaluaciones[eval.item_id] = {
                "cumple": eval.cumple,
                "numero_infracciones": eval.numero_infracciones,
                "observacion": eval.observacion,
            }

        # Agrupar items por categoría
        items_por_tipo = {}
        for item in items:
            if item.categoria not in items_por_tipo:
                items_por_tipo[item.categoria] = []
            items_por_tipo[item.categoria].append(item)

        return render_template(
            "reglamento/reunion_detalle.html",
            reunion=reunion,
            items_por_tipo=items_por_tipo,
            evaluaciones=evaluaciones,
        )

    except Exception as e:
        return f"Error: {str(e)}", 500


@reglamento_bp.route("/guardar-evaluacion", methods=["POST"])
@login_required
def guardar_evaluacion():
    """
    Descripcion: Guardar evaluacion de items del checklist
    Logica: Actualiza o crea evaluaciones y calcula sanciones
    Ejemplo:
        {
            "reunion_id": 1,
            "evaluaciones": [
                {"item_id": 1, "estado": "no_cumple", "infracciones_detectadas": 2, "observaciones": "..."},
                {"item_id": 2, "estado": "cumple"}
            ]
        }
    """
    try:
        data = request.get_json()
        reunion_id = data.get("reunion_id")
        evaluaciones_data = data.get("evaluaciones", [])

        if not reunion_id:
            return jsonify({"error": "Reunion requerida"}), 400

        reunion = ReglamentoRestaurante.query.get_or_404(reunion_id)

        # Eliminar evaluaciones anteriores
        EvaluacionReglamento.query.filter_by(reunion_id=reunion_id).delete()

        total_infracciones = 0
        total_puntos = 0

        def evaluar_condicion(valor, operador, umbral):
            if operador == '<':
                return valor < umbral
            if operador == '<=':
                return valor <= umbral
            if operador == '>':
                return valor > umbral
            if operador == '>=':
                return valor >= umbral
            if operador == '=':
                return valor == umbral
            return False

        # Crear nuevas evaluaciones
        for eval_data in evaluaciones_data:
            item_id = eval_data.get("item_id")
            if not item_id:
                continue

            item = ItemReglamento.query.get(item_id)
            if not item:
                continue

            cumple = bool(eval_data.get("cumple", True))
            numero_infracciones = int(eval_data.get("numero_infracciones") or 0)
            valor_medido = eval_data.get("valor_medido")
            observacion = eval_data.get("observacion", "")

            incumplimiento = False

            if item.tipo_validacion in ["numerico", "porcentaje"] and valor_medido is not None:
                try:
                    valor_float = float(valor_medido)
                except (TypeError, ValueError):
                    valor_float = None

                if valor_float is not None and item.valor_umbral is not None and item.operador_comparacion:
                    condicion = evaluar_condicion(valor_float, item.operador_comparacion, float(item.valor_umbral))
                    incumplimiento = not condicion if item.logica_inversa else condicion
                else:
                    incumplimiento = False

                cumple = not incumplimiento
            else:
                incumplimiento = not cumple

            if incumplimiento:
                if numero_infracciones <= 0:
                    numero_infracciones = 1
            else:
                numero_infracciones = 0

            if incumplimiento:
                total_infracciones += numero_infracciones
                total_puntos += (item.puntaje or 0) * numero_infracciones

            nueva_eval = EvaluacionReglamento(
                reunion_id=reunion_id,
                item_id=item_id,
                cumple=cumple,
                numero_infracciones=numero_infracciones,
                valor_medido=valor_medido,
                observacion=observacion,
            )

            db.session.add(nueva_eval)

        # Calcular sancion
        sancion = calcular_sancion_por_platos(total_puntos)

        # Actualizar reunion
        reunion.estado = "completada"
        reunion.total_infracciones = total_infracciones
        reunion.total_platos_sancion = sancion.get("platos", 0)

        db.session.commit()

        return jsonify(
            {
                "success": True,
                "message": "Evaluacion guardada exitosamente",
                "total_infracciones": total_infracciones,
                "total_puntos": total_puntos,
                "sancion": sancion,
            }
        )

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

@reglamento_bp.route("/items")
@login_required
def listar_items():
    """
    Descripción: Listar todos los items del reglamento
    Lógica: Para mostrar en el checklist
    """
    try:
        items = ItemReglamento.query.all()

        items_data = []
        for item in items:
            items_data.append(
                {
                    "id": item.id,
                    "codigo": item.codigo,
                    "descripcion": item.descripcion,
                    "categoria": item.categoria,
                    "riesgo": item.riesgo,
                    "puntaje": item.puntaje,
                }
            )

        return jsonify(items_data)

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@reglamento_bp.route("/historial/<int:establecimiento_id>")
@login_required
def historial_reuniones(establecimiento_id):
    """
    Descripción: Ver historial de reuniones de un establecimiento
    Lógica: Muestra todas las reuniones con sus sanciones
    """
    try:
        establecimiento = Establecimiento.query.get_or_404(establecimiento_id)

        reuniones = (
            ReglamentoRestaurante.query.filter_by(establecimiento_id=establecimiento_id)
            .order_by(ReglamentoRestaurante.created_at.desc())
            .all()
        )
        reuniones_data = []
        for reunion in reuniones:
            # Contar infracciones totales de esta reunión
            total_infr = sum(
                e.numero_infracciones for e in reunion.evaluaciones if not e.cumple
            )

            reuniones_data.append(
                {
                    "id": reunion.id,
                    "semana": reunion.semana,
                    "ano": reunion.ano,
                    "fecha_reunion": (
                        reunion.fecha_reunion.strftime("%d/%m/%Y")
                        if reunion.fecha_reunion
                        else "N/A"
                    ),
                    "estado": reunion.estado,
                    "total_infracciones": total_infr,
                }
            )

        return render_template(
            "reglamento/historial.html",
            establecimiento=establecimiento,
            reuniones=reuniones_data,
        )

    except Exception as e:
        return f"Error: {str(e)}", 500
