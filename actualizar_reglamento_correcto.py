"""
Descripción: Script para actualizar los items del reglamento según la tabla correcta
Lógica: Elimina los items anteriores e inserta los correctos con codigo, infraccion, riesgo y puntaje
Ejemplo de uso: python actualizar_reglamento_correcto.py
"""

from app import create_app
from app.extensions import db
from app.models.Inspecciones_models import ItemReglamentoRestaurante

app = create_app()

with app.app_context():
    # Eliminar items anteriores
    ItemReglamentoRestaurante.query.delete()
    db.session.commit()
    print("Items anteriores eliminados")
    
    # Datos correctos según la tabla
    items_correctos = [
        # Checklist (3 veces por semana)
        {"codigo": "A-01", "descripcion": "Obtener una calificacion Regular x checklist", "categoria": "Checklist (3 veces por semana)", "riesgo": "Mayor", "puntaje": 3, "orden": 1},
        {"codigo": "A-02", "descripcion": "Obtener una calificacion Mala x checklist", "categoria": "Checklist (3 veces por semana)", "riesgo": "Crítico", "puntaje": 5, "orden": 2},
        {"codigo": "A-03", "descripcion": "Incumplir 2 veces seguidas o alternadas en una misma semana el mismo item del check list", "categoria": "Checklist (3 veces por semana)", "riesgo": "Mayor", "puntaje": 3, "orden": 3},
        {"codigo": "A-04", "descripcion": "Incumplir las observaciones inopinadas (por el personal encargado)", "categoria": "Checklist (3 veces por semana)", "riesgo": "Menor", "puntaje": 1, "orden": 4},
        
        # Satisfacción al cliente - Encuestas
        {"codigo": "A-05", "descripcion": "Obtener un porcentaje menor al 85% en las evaluaciones de satisfaccion del cliente.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Menor", "puntaje": 1, "orden": 5},
        {"codigo": "A-06", "descripcion": "Obtener un % menor al 90% en las recomendaciones de los clientes, segun las encuestas.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Menor", "puntaje": 1, "orden": 6},
        {"codigo": "A-07", "descripcion": "Si se acumulan 10 comentarios negativos en las encuestas de lunes a viernes.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Menor", "puntaje": 1, "orden": 7},
        {"codigo": "A-08", "descripcion": "Si se acumulan 15 comentarios negativos en las encuestas de sabado y domingo.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Menor", "puntaje": 1, "orden": 8},
        {"codigo": "A-09", "descripcion": "No entregar el libro de reclamaciones, cuando sea requerido por los clientes", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Mayor", "puntaje": 3, "orden": 9},
        {"codigo": "A-10", "descripcion": "Quejas graves de clientes ya sean en las encuestas o directamente (puede implicar o no libro de reclamaciones).", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Crítico", "puntaje": 5, "orden": 10},
        {"codigo": "A-11", "descripcion": "Realizar publicidad engañosa sea por no respetar los precios establecidos en las cartas y/o no cumplir con las promociones y/o cortesias ofrecidas.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Mayor", "puntaje": 3, "orden": 11},
        {"codigo": "A-12", "descripcion": "El tiempo de espera de un pedido de comida durar como máximo de 20 minutos y llegar a las 20 demoras se le para la venta.", "categoria": "Satisfacción al cliente - Encuestas", "riesgo": "Mayor", "puntaje": 3, "orden": 12},
        
        # Incumplimientos Laborales
        {"codigo": "A-13", "descripcion": "Permitir que sus trabajadores fijos laboren sin contar con el respectivo carnet de sanidad.", "categoria": "Incumplimientos Laborales", "riesgo": "Menor", "puntaje": 1, "orden": 13},
        {"codigo": "A-14", "descripcion": "Contratar trabajadores menores de edad y/o personal extranjero que no cuente con la documentacion correspondiente para trabajar en el pais.", "categoria": "Incumplimientos Laborales", "riesgo": "Mayor", "puntaje": 3, "orden": 14},
        {"codigo": "A-15", "descripcion": "Prohibido contratar personal que este en lista roja", "categoria": "Incumplimientos Laborales", "riesgo": "Mayor", "puntaje": 3, "orden": 15},
        {"codigo": "A-16", "descripcion": "Contratar al personal de los demas concesionarios y/o del castillo mientras los mismos se encuentren laborando en dichas otras entidades y/o antes que se cumplan los 3 meses desde que culmino su relacion laboral con su anterior empleador o previa coordinacion con el concesionario anterior.", "categoria": "Incumplimientos Laborales", "riesgo": "Menor", "puntaje": 1, "orden": 16},
        {"codigo": "A-17", "descripcion": "No tener el personal en planilla y con contratos.", "categoria": "Incumplimientos Laborales", "riesgo": "Menor", "puntaje": 1, "orden": 17},
        
        # Otros incumplimientos
        {"codigo": "A-18", "descripcion": "Incumplimiento de los acuerdos adoptados en las reuniones semanales.", "categoria": "Otros incumplimientos", "riesgo": "Mayor", "puntaje": 3, "orden": 18},
        {"codigo": "A-19", "descripcion": "No cumplir con la programacion semanal del personal acordado en reunion. De lunes a viernes. De sabado o de Domingo o feriado", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 19},
        {"codigo": "A-20", "descripcion": "Realizar sus operaciones sin contar con el certificado de fumigacion vigente.", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 20},
        {"codigo": "A-21", "descripcion": "No preparar el chancho al palo con los parametros de seguridad establecidos. (segun compromiso firmado)", "categoria": "Otros incumplimientos", "riesgo": "Mayor", "puntaje": 3, "orden": 21},
        {"codigo": "A-22", "descripcion": "Ingreso de mercaderia en horarios no establecido. (6:00-10:00 y de 5:00-7:00)", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 22},
        {"codigo": "A-23", "descripcion": "Depositar desperdicios o basura en espacios no permitidos y dejar el espacio sucio. (en el deposito del castillo, mas no en los tachos dentro del castillo).", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 23},
        {"codigo": "A-24", "descripcion": "Anular cupos o tickets sin la autorizacion o sin previa autorizacion del Castillo.", "categoria": "Otros incumplimientos", "riesgo": "Mayor", "puntaje": 3, "orden": 24},
        {"codigo": "A-25", "descripcion": "Usar tickets o comandas distintas a las aprobadas.", "categoria": "Otros incumplimientos", "riesgo": "Mayor", "puntaje": 3, "orden": 25},
        {"codigo": "A-26", "descripcion": "Inasistencia injustificada de los dueños de los restaurantes o establecimientos concesionados a las reuniones semanales, reuniones extraordinarias y/o capacitaciones programadas.", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 26},
        {"codigo": "A-27", "descripcion": "No respetar el monto acordado para los descuentos a los turistas.", "categoria": "Otros incumplimientos", "riesgo": "Mayor", "puntaje": 3, "orden": 27},
        {"codigo": "A-28", "descripcion": "Falta de respeto entre concesionarios y/o personal.", "categoria": "Otros incumplimientos", "riesgo": "Crítico", "puntaje": 5, "orden": 28},
        {"codigo": "A-29", "descripcion": "Tomar objetos ajenos del restaurante que no le pertenecen.", "categoria": "Otros incumplimientos", "riesgo": "Menor", "puntaje": 1, "orden": 29},
        {"codigo": "A-30", "descripcion": "Adulterar las fechas de rotulado", "categoria": "Otros incumplimientos", "riesgo": "Crítico", "puntaje": 5, "orden": 30},
        
        # Incumplimiento en pagos
        {"codigo": "A-31", "descripcion": "No cumplir con el pago de impuestos (fecha de pagos entre el dia 25 al 30 de cada mes). Enviar los documentos de SUNAT.", "categoria": "Incumplimiento en pagos", "riesgo": "Menor", "puntaje": 1, "orden": 31},
        {"codigo": "A-32", "descripcion": "No cumplir con el pago a sus proveedores o personal que pueda generar mala reputacion al Castillo.", "categoria": "Incumplimiento en pagos", "riesgo": "Crítico", "puntaje": 5, "orden": 32},
        {"codigo": "A-33", "descripcion": "No cumplir con el pago del alquiler segun las fechas establecidas. (50% hasta e dia 7 y el 50% restante hasta el dia 15)", "categoria": "Incumplimiento en pagos", "riesgo": "Crítico", "puntaje": 5, "orden": 33},
    ]
    
    # Insertar items correctos
    for item_data in items_correctos:
        nuevo_item = ItemReglamentoRestaurante(
            codigo=item_data["codigo"],
            descripcion=item_data["descripcion"],
            categoria=item_data["categoria"],
            riesgo=item_data["riesgo"],
            puntaje=item_data["puntaje"],
            orden=item_data["orden"],
            activo=True
        )
        db.session.add(nuevo_item)
    
    db.session.commit()
    
    # Verificar
    total = ItemReglamentoRestaurante.query.count()
    print(f"\nItems insertados correctamente: {total}")
    
    # Mostrar resumen por categoria
    categorias = db.session.query(
        ItemReglamentoRestaurante.categoria,
        db.func.count(ItemReglamentoRestaurante.id)
    ).group_by(ItemReglamentoRestaurante.categoria).all()
    
    print("\nResumen por categoria:")
    for cat, count in categorias:
        print(f"  - {cat}: {count} items")
