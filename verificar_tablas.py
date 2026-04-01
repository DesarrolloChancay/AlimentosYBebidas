"""
Descripción: Verificar qué tablas de reglamento existen en la base de datos
Lógica: Consulta SHOW TABLES para ver las tablas existentes
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from app.extensions import db
from sqlalchemy import text

app = create_app()

with app.app_context():
    # Ver todas las tablas
    result = db.session.execute(text("SHOW TABLES"))
    tables = result.fetchall()
    
    print("Tablas en la base de datos:")
    print("="*50)
    for table in tables:
        print(f"  - {table[0]}")
    
    print("\nBuscando tablas relacionadas con 'reglamento':")
    print("="*50)
    for table in tables:
        if 'reglamento' in table[0].lower():
            print(f"  - {table[0]}")
            
            # Ver estructura de la tabla
            desc = db.session.execute(text(f"DESCRIBE {table[0]}"))
            print(f"\n    Estructura de {table[0]}:")
            for col in desc:
                print(f"      {col[0]} ({col[1]})")
            print()
