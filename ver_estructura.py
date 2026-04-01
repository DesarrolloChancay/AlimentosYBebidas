"""
Descripción: Script final para revisar items_evaluacion_establecimiento
Lógica: Muestra la estructura y datos de items en establecimientos
"""

import os
from dotenv import load_dotenv
import pymysql
from pymysql.cursors import DictCursor

load_dotenv()

conn = pymysql.connect(
    host=os.getenv('DB_HOST'),
    port=int(os.getenv('DB_PORT', 3306)),
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    database=os.getenv('DB_NAME'),
    charset='utf8mb4',
    cursorclass=DictCursor
)

try:
    with conn.cursor() as cur:
        print("\n" + "="*80)
        print("ESTRUCTURA: items_evaluacion_establecimiento")
        print("="*80)
        cur.execute("DESCRIBE items_evaluacion_establecimiento")
        for row in cur.fetchall():
            print(f"{row['Field']:35} {row['Type']:30} Null: {row['Null']}")
        
        print("\n" + "="*80)
        print("ESTRUCTURA: inspeccion_detalles")
        print("="*80)
        cur.execute("DESCRIBE inspeccion_detalles")
        for row in cur.fetchall():
            print(f"{row['Field']:35} {row['Type']:30} Null: {row['Null']}")
        
        print("\n" + "="*80)
        print("EJEMPLOS DE INSPECCIONES GUARDADAS (Últimas 10)")
        print("="*80)
        cur.execute("""
            SELECT 
                id.id, 
                id.inspeccion_id, 
                id.item_establecimiento_id,
                id.rating as calificacion, 
                id.score as puntaje,
                ieb.riesgo,
                ieb.codigo,
                ieb.descripcion
            FROM inspeccion_detalles id
            JOIN items_evaluacion_establecimiento iee ON id.item_establecimiento_id = iee.id
            JOIN items_evaluacion_base ieb ON iee.item_base_id = ieb.id
            ORDER BY id.id DESC
            LIMIT 10
        """)
        for row in cur.fetchall():
            print(f"\nID: {row['id']} | Inspección: {row['inspeccion_id']}")
            print(f"  [{row['riesgo']}] {row['codigo']} - {row['descripcion'][:50]}...")
            print(f"  Calificación (rating): {row['calificacion']} | Puntaje (score): {row['puntaje']}")
        
        # Análisis por tipo de riesgo
        print("\n" + "="*80)
        print("ANÁLISIS DE CALIFICACIONES POR TIPO DE RIESGO")
        print("="*80)
        cur.execute("""
            SELECT 
                ieb.riesgo,
                MIN(id.rating) as rating_min,
                MAX(id.rating) as rating_max,
                AVG(id.score) as score_promedio,
                COUNT(*) as total
            FROM inspeccion_detalles id
            JOIN items_evaluacion_establecimiento iee ON id.item_establecimiento_id = iee.id
            JOIN items_evaluacion_base ieb ON iee.item_base_id = ieb.id
            GROUP BY ieb.riesgo
        """)
        for row in cur.fetchall():
            print(f"\n{row['riesgo']}:")
            print(f"  Evaluaciones totales: {row['total']}")
            print(f"  Rating usado: {row['rating_min']} - {row['rating_max']}")
            print(f"  Score promedio: {row['score_promedio']:.2f}")
        
        print("\n" + "="*80)
        print("RESUMEN DEL SISTEMA ACTUAL")
        print("="*80)
        print("\nITEMS BASE (items_evaluacion_base):")
        print("  - Crítico: Rango de puntaje 1-8")
        print("  - Mayor: Rango de puntaje 1-4")
        print("  - Menor: Rango de puntaje 1-2")
        print("\nNUEVO SISTEMA PROPUESTO:")
        print("  - Crítico: Solo opciones 1 y 8")
        print("  - Mayor: Opciones 1, 2 y 3")
        print("  - Menor: Opciones 1, 2 y 3")
        print("\n")

finally:
    conn.close()
