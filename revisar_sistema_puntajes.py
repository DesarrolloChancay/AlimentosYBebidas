"""
Descripción: Script simplificado para revisar el sistema de calificaciones
Lógica: Muestra la configuración actual de puntajes y cómo funciona el nuevo sistema
Ejemplo de Uso:
    python revisar_sistema_puntajes.py
"""

import os
from dotenv import load_dotenv
import pymysql
from pymysql.cursors import DictCursor

load_dotenv()

def conectar():
    return pymysql.connect(
        host=os.getenv('DB_HOST'),
        port=int(os.getenv('DB_PORT', 3306)),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME'),
        charset='utf8mb4',
        cursorclass=DictCursor
    )

print("\n" + "="*80)
print("SISTEMA DE CALIFICACIONES - ANÁLISIS COMPLETO")
print("="*80)

conn = conectar()

try:
    with conn.cursor() as cur:
        # 1. Ver estructura de configuracion_evaluaciones
        print("\n1. TABLA 'configuracion_evaluaciones'")
        print("-" * 80)
        cur.execute("DESCRIBE configuracion_evaluaciones")
        for row in cur.fetchall():
            print(f"  {row['Field']:30} {row['Type']:25} Null: {row['Null']}")
        
        # 2. Ver datos de configuracion_evaluaciones
        print("\n2. CONFIGURACIONES ACTUALES")
        print("-" * 80)
        cur.execute("SELECT * FROM configuracion_evaluaciones ORDER BY id")
        for row in cur.fetchall():
            print(f"\nID: {row['id']}")
            for key, value in row.items():
                if key != 'id':
                    print(f"  {key}: {value}")
        
        # 3. Ver ejemplos de items_evaluacion_base por tipo de riesgo
        print("\n3. ITEMS BASE POR TIPO DE RIESGO")
        print("-" * 80)
        for riesgo in ['Crítico', 'Mayor', 'Menor']:
            cur.execute("""
                SELECT COUNT(*) as total, MIN(puntaje_minimo) as min, MAX(puntaje_maximo) as max
                FROM items_evaluacion_base 
                WHERE riesgo = %s AND activo = 1
            """, (riesgo,))
            stats = cur.fetchone()
            print(f"\n{riesgo}:")
            print(f"  Total items: {stats['total']}")
            print(f"  Puntaje mínimo: {stats['min']}")
            print(f"  Puntaje máximo: {stats['max']}")
            
            # Mostrar un ejemplo
            cur.execute("""
                SELECT codigo, descripcion, puntaje_minimo, puntaje_maximo
                FROM items_evaluacion_base 
                WHERE riesgo = %s AND activo = 1
                LIMIT 1
            """, (riesgo,))
            ejemplo = cur.fetchone()
            if ejemplo:
                print(f"  Ejemplo: {ejemplo['codigo']} - {ejemplo['descripcion'][:50]}...")
                print(f"    Rango de puntaje: {ejemplo['puntaje_minimo']} - {ejemplo['puntaje_maximo']}")
        
        # 4. Ver datos reales de inspecciones
        print("\n4. ANÁLISIS DE INSPECCIONES REALES")
        print("-" * 80)
        cur.execute("""
            SELECT 
                iee.riesgo,
                COUNT(DISTINCT id.id) as total_evaluaciones,
                MIN(id.calificacion) as cal_min,
                MAX(id.calificacion) as cal_max,
                AVG(id.puntaje_obtenido) as puntaje_prom
            FROM inspeccion_detalles id
            JOIN items_evaluacion_establecimiento iee ON id.item_id = iee.id
            GROUP BY iee.riesgo
        """)
        for row in cur.fetchall():
            print(f"\n{row['riesgo']}:")
            print(f"  Evaluaciones: {row['total_evaluaciones']}")
            print(f"  Calificaciones usadas: {row['cal_min']} - {row['cal_max']}")
            print(f"  Puntaje promedio: {row['puntaje_prom']:.2f}")
        
        # 5. Ver ejemplos concretos de calificaciones
        print("\n5. EJEMPLOS DE CALIFICACIONES RECIENTES")
        print("-" * 80)
        cur.execute("""
            SELECT 
                iee.riesgo,
                iee.codigo,
                iee.descripcion,
                id.calificacion,
                id.puntaje_obtenido,
                id.puntaje_maximo
            FROM inspeccion_detalles id
            JOIN items_evaluacion_establecimiento iee ON id.item_id = iee.id
            ORDER BY id.id DESC
            LIMIT 15
        """)
        for row in cur.fetchall():
            print(f"\n[{row['riesgo']}] {row['codigo']} - {row['descripcion'][:40]}...")
            print(f"  Calificación: {row['calificacion']} | Puntaje: {row['puntaje_obtenido']}/{row['puntaje_maximo']}")
        
        print("\n" + "="*80)
        print("CONCLUSIONES DEL NUEVO SISTEMA:")
        print("="*80)
        print("\nSegún tu descripción, el nuevo sistema debería ser:")
        print("  - CRÍTICO: Solo opciones 1 y 8 (donde 1=cumple con puntaje 1, 8=no cumple con puntaje 8)")
        print("  - MAYOR: Opciones 1, 2 y 3")
        print("  - MENOR: Opciones 1, 2 y 3")
        print("\nPero en la base de datos actual veo:")
        
        # Resumen final
        cur.execute("""
            SELECT DISTINCT iee.riesgo, id.calificacion, id.puntaje_obtenido
            FROM inspeccion_detalles id
            JOIN items_evaluacion_establecimiento iee ON id.item_id = iee.id
            ORDER BY iee.riesgo, id.calificacion
        """)
        
        actual = {}
        for row in cur.fetchall():
            riesgo = row['riesgo']
            if riesgo not in actual:
                actual[riesgo] = []
            actual[riesgo].append(f"cal={row['calificacion']}→punt={row['puntaje_obtenido']}")
        
        for riesgo, valores in actual.items():
            print(f"\n  {riesgo}: {', '.join(set(valores))}")
        
        print("\n")

finally:
    conn.close()
