"""
Descripción: Script para revisar la estructura de la base de datos y el sistema de puntajes
Lógica: Conecta a MySQL usando las credenciales del archivo .env y consulta las tablas
        relacionadas con items, calificaciones y puntajes para entender el nuevo sistema
Ejemplo de Uso:
    python revisar_db.py
"""

import os
from dotenv import load_dotenv
import pymysql
from pymysql.cursors import DictCursor

# Cargar variables de entorno
load_dotenv()

def conectar_db():
    """
    Descripción: Establece conexión con la base de datos MySQL
    Lógica: Utiliza las credenciales del archivo .env para conectarse
    """
    return pymysql.connect(
        host=os.getenv('DB_HOST'),
        port=int(os.getenv('DB_PORT', 3306)),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME'),
        charset='utf8mb4',
        cursorclass=DictCursor
    )

def revisar_estructura_items():
    """
    Descripción: Revisa la estructura de la tabla de items base y establecimiento
    Lógica: Consulta la estructura de las tablas items_evaluacion_base e items_evaluacion_establecimiento
    """
    conn = conectar_db()
    try:
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print("ESTRUCTURA DE LA TABLA 'items_evaluacion_base'")
            print("="*80)
            cursor.execute("DESCRIBE items_evaluacion_base")
            for row in cursor.fetchall():
                print(f"Campo: {row['Field']:30} Tipo: {row['Type']:20} Null: {row['Null']:5}")
            
            print("\n" + "="*80)
            print("EJEMPLOS DE ITEMS BASE POR TIPO")
            print("="*80)
            cursor.execute("""
                SELECT id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, activo
                FROM items_evaluacion_base 
                ORDER BY riesgo, id
                LIMIT 20
            """)
            for row in cursor.fetchall():
                print(f"\nID: {row['id']}")
                print(f"  Código: {row['codigo']}")
                print(f"  Descripción: {row['descripcion'][:60]}...")
                print(f"  Riesgo: {row['riesgo']}")
                print(f"  Puntaje Mínimo: {row['puntaje_minimo']}")
                print(f"  Puntaje Máximo: {row['puntaje_maximo']}")
                print(f"  Activo: {row['activo']}")
                
            print("\n" + "="*80)
            print("ESTRUCTURA DE LA TABLA 'items_evaluacion_establecimiento'")
            print("="*80)
            cursor.execute("DESCRIBE items_evaluacion_establecimiento")
            for row in cursor.fetchall():
                print(f"Campo: {row['Field']:30} Tipo: {row['Type']:20} Null: {row['Null']:5}")
    finally:
        conn.close()

def revisar_calificaciones():
    """
    Descripción: Revisa la configuración de evaluaciones
    Lógica: Consulta las configuraciones disponibles para cada tipo de item
    """
    conn = conectar_db()
    try:
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print("ESTRUCTURA DE LA TABLA 'configuracion_evaluaciones'")
            print("="*80)
            cursor.execute("DESCRIBE configuracion_evaluaciones")
            for row in cursor.fetchall():
                print(f"Campo: {row['Field']:30} Tipo: {row['Type']:20} Null: {row['Null']:5}")
            
            print("\n" + "="*80)
            print("CONFIGURACIONES DE EVALUACIÓN DISPONIBLES")
            print("="*80)
            cursor.execute("""
                SELECT id, tipo_item, opcion, puntaje, descripcion, activo
                FROM configuracion_evaluaciones 
                ORDER BY tipo_item, opcion
            """)
            
            tipo_actual = None
            for row in cursor.fetchall():
                if tipo_actual != row['tipo_item']:
                    tipo_actual = row['tipo_item']
                    print(f"\n--- TIPO: {tipo_actual} ---")
                print(f"  Opción: {row['opcion']:2} | Puntaje: {row['puntaje']:2} | Descripción: {row['descripcion']:30} | Activo: {row['activo']}")
    finally:
        conn.close()

def revisar_inspecciones_detalle():
    """
    Descripción: Revisa cómo se están guardando las calificaciones en las inspecciones
    Lógica: Consulta ejemplos de inspeccion_detalles para ver los puntajes asignados
    """
    conn = conectar_db()
    try:
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print("ESTRUCTURA DE LA TABLA 'inspeccion_detalles'")
            print("="*80)
            cursor.execute("DESCRIBE inspeccion_detalles")
            for row in cursor.fetchall():
                print(f"Campo: {row['Field']:30} Tipo: {row['Type']:20} Null: {row['Null']:5}")
            
            print("\n" + "="*80)
            print("EJEMPLOS DE CALIFICACIONES EN INSPECCIONES (Últimas 10)")
            print("="*80)
            cursor.execute("""
                SELECT 
                    id.id,
                    id.inspeccion_id,
                    iee.nombre as item_nombre,
                    iee.tipo as item_tipo,
                    id.calificacion,
                    id.puntaje_obtenido,
                    id.puntaje_maximo,
                    id.observaciones
                FROM inspeccion_detalles id
                JOIN items_evaluacion_establecimiento iee ON id.item_id = iee.id
                ORDER BY id.id DESC
                LIMIT 10
            """)
            for row in cursor.fetchall():
                print(f"\nID Detalle: {row['id']} | Inspección: {row['inspeccion_id']}")
                print(f"  Item: {row['item_nombre']}")
                print(f"  Tipo: {row['item_tipo']}")
                print(f"  Calificación: {row['calificacion']}")
                print(f"  Puntaje Obtenido: {row['puntaje_obtenido']}")
                print(f"  Puntaje Máximo: {row['puntaje_maximo']}")
                if row['observaciones']:
                    print(f"  Observaciones: {row['observaciones']}")
    finally:
        conn.close()

def revisar_logica_puntajes():
    """
    Descripción: Analiza la lógica actual de cálculo de puntajes
    Lógica: Consulta diferentes combinaciones para entender cómo se calculan los puntajes
    """
    conn = conectar_db()
    try:
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print("ANÁLISIS DE LÓGICA DE PUNTAJES")
            print("="*80)
            
            # Para cada tipo de item, ver qué calificaciones tienen
            tipos = ['Critico', 'Mayor', 'Menor']
            for tipo in tipos:
                print(f"\n--- TIPO: {tipo} ---")
                cursor.execute("""
                    SELECT DISTINCT id.calificacion, id.puntaje_obtenido, id.puntaje_maximo
                    FROM inspeccion_detalles id
                    JOIN items_evaluacion_establecimiento iee ON id.item_id = iee.id
                    WHERE iee.tipo = %s
                    ORDER BY id.calificacion
                """, (tipo,))
                
                resultados = cursor.fetchall()
                if resultados:
                    print(f"  Calificaciones encontradas:")
                    for row in resultados:
                        print(f"    Calificación: {row['calificacion']:2} -> Puntaje: {row['puntaje_obtenido']}/{row['puntaje_maximo']}")
                else:
                    print(f"  No hay inspecciones registradas con items de tipo {tipo}")
                
                # Ver qué valores tienen configurados los items de este tipo
                cursor.execute("""
                    SELECT DISTINCT puntaje_critico, puntaje_mayor, puntaje_menor
                    FROM items_evaluacion_establecimiento
                    WHERE tipo = %s AND activo = 1
                    LIMIT 5
                """, (tipo,))
                
                print(f"  Valores configurados en items:")
                for row in cursor.fetchall():
                    if tipo == 'Critico':
                        print(f"    Puntaje Crítico: {row['puntaje_critico']}")
                    elif tipo == 'Mayor':
                        print(f"    Puntaje Mayor: {row['puntaje_mayor']}")
                    else:
                        print(f"    Puntaje Menor: {row['puntaje_menor']}")
    finally:
        conn.close()

def main():
    """
    Descripción: Función principal que ejecuta todas las revisiones
    Lógica: Llama a cada función de revisión en orden
    """
    print("\n" + "="*80)
    print("REVISIÓN DE BASE DE DATOS - SISTEMA DE CALIFICACIONES")
    print("="*80)
    
    try:
        revisar_estructura_items()
        revisar_calificaciones()
        revisar_inspecciones_detalle()
        revisar_logica_puntajes()
        
        print("\n" + "="*80)
        print("REVISIÓN COMPLETADA")
        print("="*80)
        print("\nNUEVO SISTEMA DE CALIFICACIONES:")
        print("  - Crítico: Opciones 1 y 8 (1 = Cumple, 8 = No Cumple)")
        print("  - Mayor: Opciones 1, 2 y 3")
        print("  - Menor: Opciones 1, 2 y 3")
        print("\n")
        
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
