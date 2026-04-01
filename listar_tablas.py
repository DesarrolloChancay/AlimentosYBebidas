"""
Descripción: Script para listar todas las tablas de la base de datos
Lógica: Conecta a MySQL y muestra todas las tablas disponibles
Ejemplo de Uso:
    python listar_tablas.py
"""

import os
from dotenv import load_dotenv
import pymysql
from pymysql.cursors import DictCursor

# Cargar variables de entorno
load_dotenv()

def listar_tablas():
    """
    Descripción: Lista todas las tablas de la base de datos
    Lógica: Conecta a MySQL y ejecuta SHOW TABLES
    """
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
        with conn.cursor() as cursor:
            print("\n" + "="*80)
            print(f"TABLAS EN LA BASE DE DATOS '{os.getenv('DB_NAME')}'")
            print("="*80)
            
            cursor.execute("SHOW TABLES")
            tablas = cursor.fetchall()
            
            if tablas:
                for i, tabla in enumerate(tablas, 1):
                    nombre_tabla = list(tabla.values())[0]
                    print(f"{i}. {nombre_tabla}")
                    
                    # Mostrar cantidad de registros
                    cursor.execute(f"SELECT COUNT(*) as total FROM `{nombre_tabla}`")
                    total = cursor.fetchone()['total']
                    print(f"   Registros: {total}")
                    
                print(f"\nTotal de tablas: {len(tablas)}")
            else:
                print("No se encontraron tablas en la base de datos.")
            
            print("="*80 + "\n")
    finally:
        conn.close()

if __name__ == "__main__":
    try:
        listar_tablas()
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback
        traceback.print_exc()
