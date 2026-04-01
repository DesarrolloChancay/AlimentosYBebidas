"""
Descripción: Script para actualizar el sistema de puntajes según las nuevas reglas
Lógica: 
    - Crítico: Solo opciones 1 y 8 (1=Cumple con puntaje 1, 8=No Cumple con puntaje 8)
    - Mayor: Opciones 1, 2 y 3
    - Menor: Opciones 1, 2 y 3

Ejemplo de Uso:
    python actualizar_sistema_puntajes.py
"""

import os
from dotenv import load_dotenv
import pymysql

load_dotenv()

def actualizar_puntajes():
    """
    Descripción: Actualiza los puntajes de los items base según el nuevo sistema
    Lógica: Modifica la base de datos para reflejar las nuevas reglas de puntaje
    """
    conn = pymysql.connect(
        host=os.getenv('DB_HOST'),
        port=int(os.getenv('DB_PORT', 3306)),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME'),
        charset='utf8mb4'
    )
    
    try:
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print("ACTUALIZANDO SISTEMA DE PUNTAJES")
            print("="*80)
            
            # 1. Actualizar items Críticos: puntaje_minimo=1, puntaje_maximo=8
            print("\n1. Actualizando items CRÍTICOS (puntaje 1-8)...")
            cursor.execute("""
                UPDATE items_evaluacion_base 
                SET puntaje_minimo = 1, puntaje_maximo = 8
                WHERE riesgo = 'Crítico'
            """)
            criticos_actualizados = cursor.rowcount
            print(f"   ✓ {criticos_actualizados} items críticos actualizados")
            
            # 2. Actualizar items Mayor: puntaje_minimo=1, puntaje_maximo=3
            print("\n2. Actualizando items MAYOR (puntaje 1-3)...")
            cursor.execute("""
                UPDATE items_evaluacion_base 
                SET puntaje_minimo = 1, puntaje_maximo = 3
                WHERE riesgo = 'Mayor'
            """)
            mayor_actualizados = cursor.rowcount
            print(f"   ✓ {mayor_actualizados} items mayor actualizados")
            
            # 3. Actualizar items Menor: puntaje_minimo=1, puntaje_maximo=3
            print("\n3. Actualizando items MENOR (puntaje 1-3)...")
            cursor.execute("""
                UPDATE items_evaluacion_base 
                SET puntaje_minimo = 1, puntaje_maximo = 3
                WHERE riesgo = 'Menor'
            """)
            menor_actualizados = cursor.rowcount
            print(f"   ✓ {menor_actualizados} items menor actualizados")
            
            # Confirmar cambios
            conn.commit()
            
            print("\n" + "="*80)
            print("ACTUALIZACIÓN COMPLETADA EXITOSAMENTE")
            print("="*80)
            print(f"\nTotal de items actualizados: {criticos_actualizados + mayor_actualizados + menor_actualizados}")
            
            # Verificar los cambios
            print("\n" + "-"*80)
            print("VERIFICACIÓN DE CAMBIOS:")
            print("-"*80)
            cursor.execute("""
                SELECT riesgo, COUNT(*) as total, 
                       MIN(puntaje_minimo) as min_puntaje, 
                       MAX(puntaje_maximo) as max_puntaje
                FROM items_evaluacion_base
                WHERE activo = 1
                GROUP BY riesgo
            """)
            
            for row in cursor.fetchall():
                riesgo, total, min_p, max_p = row
                print(f"\n{riesgo}:")
                print(f"  Total items: {total}")
                print(f"  Rango de puntaje: {min_p} - {max_p}")
            
            print("\n" + "="*80)
            print("NUEVO SISTEMA IMPLEMENTADO:")
            print("="*80)
            print("\n✓ Crítico: Opciones 1 y 8")
            print("  - 1 = Cumple (puntaje 1)")
            print("  - 8 = No cumple (puntaje 8)")
            print("\n✓ Mayor: Opciones 1, 2 y 3")
            print("  - 1 = Excelente")
            print("  - 2 = Bueno")
            print("  - 3 = Regular")
            print("\n✓ Menor: Opciones 1, 2 y 3")
            print("  - 1 = Excelente")
            print("  - 2 = Bueno")
            print("  - 3 = Regular")
            print("\n")
            
    except Exception as e:
        conn.rollback()
        print(f"\n❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
    finally:
        conn.close()

if __name__ == "__main__":
    print("\n⚠️  ADVERTENCIA: Este script modificará los puntajes en la base de datos.")
    respuesta = input("¿Desea continuar? (si/no): ").strip().lower()
    
    if respuesta == 'si':
        actualizar_puntajes()
    else:
        print("\n❌ Operación cancelada.")
