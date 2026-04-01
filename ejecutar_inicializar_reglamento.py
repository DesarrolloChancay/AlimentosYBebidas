"""
Descripción: Script para ejecutar la inicialización del reglamento de restaurante en MySQL
Lógica: Lee el archivo SQL y lo ejecuta en la base de datos configurada
Ejemplo: python ejecutar_inicializar_reglamento.py
"""

import sys
import os

# Agregar el directorio raíz al path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.extensions import db
from sqlalchemy import text

def ejecutar_sql_file(filename):
    """
    Descripción: Ejecuta un archivo SQL en la base de datos
    Lógica: Lee el archivo y ejecuta cada statement
    """
    app = create_app()
    
    with app.app_context():
        try:
            # Leer el archivo SQL
            with open(filename, 'r', encoding='utf-8') as f:
                sql_content = f.read()
            
            # Dividir en statements individuales
            statements = sql_content.split(';')
            
            print(f"Ejecutando {len(statements)} statements...")
            
            for i, statement in enumerate(statements, 1):
                statement = statement.strip()
                if statement and not statement.startswith('--'):
                    try:
                        db.session.execute(text(statement))
                        print(f"Statement {i}/{len(statements)} ejecutado correctamente")
                    except Exception as e:
                        print(f"Error en statement {i}: {str(e)}")
                        print(f"Statement: {statement[:100]}...")
                        # Continuar con el siguiente statement
                        continue
            
            db.session.commit()
            print("\nInicialización completada exitosamente!")
            
            # Verificar los datos insertados
            result = db.session.execute(text("SELECT COUNT(*) as total FROM items_reglamento"))
            total = result.fetchone()[0]
            print(f"Total de items insertados: {total}")
            
        except Exception as e:
            print(f"Error general: {str(e)}")
            db.session.rollback()
            return False
        
        return True

if __name__ == '__main__':
    sql_file = 'data/inicializar_reglamento_restaurante_mysql.sql'
    
    if not os.path.exists(sql_file):
        print(f"Error: No se encontró el archivo {sql_file}")
        sys.exit(1)
    
    print(f"Ejecutando script SQL: {sql_file}\n")
    success = ejecutar_sql_file(sql_file)
    
    if success:
        print("\nProceso completado exitosamente")
        sys.exit(0)
    else:
        print("\nProceso terminó con errores")
        sys.exit(1)
