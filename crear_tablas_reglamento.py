"""
Descripción: Crear tablas del reglamento usando SQLAlchemy directamente
Lógica: Usa db.create_all() para crear las tablas desde los modelos
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.extensions import db
from app.models.Inspecciones_models import ItemReglamentoRestaurante, ReunionReglamento, EvaluacionReglamento
from sqlalchemy import text

app = create_app()

with app.app_context():
    print("Creando tablas del reglamento...")
    
    # Crear las tablas
    ItemReglamentoRestaurante.__table__.create(db.engine, checkfirst=True)
    print("Tabla items_reglamento_restaurante creada")
    
    ReunionReglamento.__table__.create(db.engine, checkfirst=True)
    print("Tabla reuniones_reglamento creada")
    
    EvaluacionReglamento.__table__.create(db.engine, checkfirst=True)
    print("Tabla evaluaciones_reglamento creada")
    
    print("\nTablas creadas exitosamente!")
    print("\nAhora insertando datos iniciales...")
    
    # Insertar items del reglamento
    items_data = [
        # A. ASISTENCIA PUNTUAL A LA REUNION DE COORDINACION
        ('A-1', 'Asistencia puntual a la reunión de coordinación semanal (lunes 9:00 am)', 'Asistencia a reuniones', 'Mayor', 5),
        
        # B. ASISTENCIA DE ENCARGADOS
        ('B-1', 'El encargado deberá asistir obligatoriamente todos los días que esté programado', 'Asistencia de encargados', 'Mayor', 5),
        ('B-2', 'Los encargados deben permanecer durante todo el horario laboral', 'Asistencia de encargados', 'Menor', 3),
        
        # C. PERSONAL DE COCINA Y SERVICIO
        ('C-1', 'Personal de cocina completo según programación', 'Personal', 'Menor', 2),
        ('C-2', 'Personal de servicio completo según programación', 'Personal', 'Menor', 2),
        ('C-3', 'Personal con uniforme completo y limpio', 'Personal', 'Menor', 1),
        
        # D. LIMPIEZA Y ORDEN
        ('D-1', 'Área de cocina limpia y ordenada', 'Limpieza', 'Mayor', 3),
        ('D-2', 'Área de comedor limpia y ordenada', 'Limpieza', 'Mayor', 3),
        ('D-3', 'Baños limpios y abastecidos', 'Limpieza', 'Menor', 2),
        ('D-4', 'Eliminación adecuada de basura', 'Limpieza', 'Menor', 2),
        
        # E. CALIDAD DE ALIMENTOS
        ('E-1', 'Alimentos en buen estado y frescos', 'Calidad', 'Crítico', 5),
        ('E-2', 'Temperaturas de conservación adecuadas', 'Calidad', 'Mayor', 4),
        ('E-3', 'Etiquetado y rotulado correcto', 'Calidad', 'Menor', 2),
        
        # F. SERVICIO AL CLIENTE
        ('F-1', 'Atención cordial y respetuosa', 'Servicio', 'Mayor', 3),
        ('F-2', 'Tiempo de espera menor a 20 minutos', 'Servicio', 'Menor', 2),
        ('F-3', 'Entrega de libro de reclamaciones cuando se solicite', 'Servicio', 'Crítico', 5),
        
        # G. DOCUMENTACIÓN
        ('G-1', 'Certificado de fumigación vigente', 'Documentación', 'Mayor', 3),
        ('G-2', 'Carnets de sanidad del personal vigentes', 'Documentación', 'Menor', 1),
        ('G-3', 'Contratos laborales al día', 'Documentación', 'Mayor', 3),
        
        # H. PAGOS
        ('H-1', 'Pago de alquiler en fechas establecidas', 'Pagos', 'Crítico', 5),
        ('H-2', 'Pago de impuestos al día', 'Pagos', 'Mayor', 4),
        ('H-3', 'Pago a proveedores al día', 'Pagos', 'Mayor', 4),
        
        # I. OTROS
        ('I-1', 'Cumplimiento de acuerdos de reuniones', 'Otros', 'Mayor', 3),
        ('I-2', 'Respeto entre concesionarios y personal', 'Otros', 'Crítico', 5),
        ('I-3', 'Uso de comandas aprobadas', 'Otros', 'Menor', 2),
    ]
    
    for idx, (codigo, descripcion, categoria, riesgo, puntaje) in enumerate(items_data, 1):
        item = ItemReglamentoRestaurante(
            codigo=codigo,
            descripcion=descripcion,
            categoria=categoria,
            riesgo=riesgo,
            puntaje=puntaje,
            orden=idx,
            activo=True
        )
        db.session.add(item)
    
    db.session.commit()
    
    # Verificar
    total = db.session.query(ItemReglamentoRestaurante).count()
    print(f"\nTotal de items insertados: {total}")
    
    print("\nInicialización completada exitosamente!")
