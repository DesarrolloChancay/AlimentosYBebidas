"""
Descripción: Configurar items del reglamento con tipo de validación y lógica
Lógica: Actualiza cada item según su comportamiento específico
Ejemplo de uso: python configurar_items_reglamento.py
"""

from app import create_app
from app.extensions import db
from app.models.Inspecciones_models import ItemReglamentoRestaurante

app = create_app()

with app.app_context():
    # Items con lógica inversa (SI es malo, NO es bueno)
    items_logica_inversa = [
        'A-01',  # Obtener calificación Regular (SI obtuve Regular = malo)
        'A-02',  # Obtener calificación Mala (SI obtuve Mala = malo)
        'A-03',  # Incumplir 2 veces (SI incumplí = malo)
        'A-04',  # Incumplir observaciones (SI incumplí = malo)
        'A-09',  # No entregar libro (SI no entregué = malo)
        'A-10',  # Quejas graves (SI hubo quejas = malo)
        'A-11',  # Publicidad engañosa (SI hice = malo)
        'A-12',  # Demoras en pedidos (SI llegué a 20 demoras = malo)
        'A-13',  # Trabajadores sin carnet (SI permitieron = malo)
        'A-14',  # Menores/extranjeros (SI contraté = malo)
        'A-15',  # Personal lista roja (SI contraté = malo)
        'A-16',  # Contratar personal de otros (SI contraté = malo)
        'A-17',  # Sin planilla (SI no tienen = malo)
        'A-18',  # Incumplir acuerdos (SI incumplí = malo)
        'A-19',  # No cumplir programación semanal (SI ocurrió = malo)
        'A-20',  # Sin fumigación (SI operé sin certificado = malo)
        'A-21',  # Chancho inseguro (SI preparé mal = malo)
        'A-22',  # Ingreso fuera de horario (SI ingresé = malo)
        'A-23',  # Basura mal depositada (SI deposité mal = malo)
        'A-24',  # Anular sin autorización (SI anulé = malo)
        'A-25',  # Tickets no aprobados (SI usé = malo)
        'A-26',  # Inasistencia (SI falté = malo)
        'A-27',  # No respetar descuentos (SI no respeté = malo)
        'A-28',  # Falta de respeto (SI hubo = malo)
        'A-29',  # Tomar objetos ajenos (SI tomé = malo)
        'A-30',  # Adulterar fechas (SI adulteré = malo)
        'A-31',  # No pagar impuestos (SI no pagué = malo)
        'A-32',  # No pagar proveedores (SI no pagué = malo)
        'A-33',  # No pagar alquiler (SI no pagué = malo)
    ]
    
    # Items con validación numérica (porcentaje)
    items_numericos = {
        'A-05': {  # Satisfacción < 85%
            'tipo_validacion': 'porcentaje',
            'valor_umbral': 85,
            'operador_comparacion': '<',
            'logica_inversa': False  # NO es bueno porque SI cumplió con tener menos de 85%
        },
        'A-06': {  # Recomendación < 90%
            'tipo_validacion': 'porcentaje',
            'valor_umbral': 90,
            'operador_comparacion': '<',
            'logica_inversa': False
        },
        'A-07': {  # 10 comentarios negativos L-V
            'tipo_validacion': 'numerico',
            'valor_umbral': 10,
            'operador_comparacion': '>=',
            'logica_inversa': False
        },
        'A-08': {  # 15 comentarios negativos S-D
            'tipo_validacion': 'numerico',
            'valor_umbral': 15,
            'operador_comparacion': '>=',
            'logica_inversa': False
        },
    }
    
    # Items con cumplimiento programado (lógica NORMAL: SI=bueno)
    items_normal = []
    
    print("Configurando items...")
    
    # Configurar items con lógica inversa simple
    for codigo in items_logica_inversa:
        item = ItemReglamentoRestaurante.query.filter_by(codigo=codigo).first()
        if item:
            item.tipo_validacion = 'si_no'
            item.logica_inversa = True
            print(f"  ✓ {codigo}: Lógica inversa (SI=malo, NO=bueno)")
    
    # Configurar items con validación numérica
    for codigo, config in items_numericos.items():
        item = ItemReglamentoRestaurante.query.filter_by(codigo=codigo).first()
        if item:
            item.tipo_validacion = config['tipo_validacion']
            item.valor_umbral = config['valor_umbral']
            item.operador_comparacion = config['operador_comparacion']
            item.logica_inversa = config['logica_inversa']
            print(f"  ✓ {codigo}: {config['tipo_validacion']} (umbral: {config['operador_comparacion']}{config['valor_umbral']})")
    
    # Configurar items con lógica NORMAL (SI=bueno, NO=malo)
    for codigo in items_normal:
        item = ItemReglamentoRestaurante.query.filter_by(codigo=codigo).first()
        if item:
            item.tipo_validacion = 'si_no'
            item.logica_inversa = False
            print(f"  ✓ {codigo}: Lógica normal (SI=bueno, NO=malo)")
    
    db.session.commit()
    
    print("\n✅ Configuración completada")
    
    # Resumen
    total_inversa = ItemReglamentoRestaurante.query.filter_by(logica_inversa=True).count()
    total_numerica = ItemReglamentoRestaurante.query.filter(
        ItemReglamentoRestaurante.tipo_validacion.in_(['numerico', 'porcentaje'])
    ).count()
    
    print(f"\nResumen:")
    print(f"  - Items con lógica inversa (SI=malo): {total_inversa}")
    print(f"  - Items con validación numérica: {total_numerica}")
    print(f"  - Items con SI/NO normal: {33 - total_inversa - total_numerica}")
