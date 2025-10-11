#!/usr/bin/env python3
"""
Script para explorar y gestionar la base de datos de Alimentos y Bebidas
Permite explorar la estructura actual y crear plantillas de checklists
"""

import os
import sys
from datetime import datetime
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import Error

# Agregar el directorio raíz al path para importar módulos de la app
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Cargar variables de entorno
load_dotenv()

def conectar_db():
    """Establece conexión con la base de datos MySQL"""
    try:
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME'),
            port=int(os.getenv('DB_PORT'))
        )
        if connection.is_connected():
            print("✅ Conexión exitosa a la base de datos MySQL")
            return connection
    except Error as e:
        print(f"❌ Error al conectar a MySQL: {e}")
        return None

def ejecutar_query(connection, query, params=None, fetch=True):
    """Ejecuta una consulta SQL"""
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params or ())

        if fetch:
            result = cursor.fetchall()
            cursor.close()
            return result
        else:
            connection.commit()
            cursor.close()
            return True
    except Error as e:
        print(f"❌ Error ejecutando query: {e}")
        return None

def mostrar_estructura_bd(connection):
    """Muestra la estructura general de la base de datos"""
    print("\n" + "="*60)
    print("📊 ESTRUCTURA DE LA BASE DE DATOS")
    print("="*60)

    # Mostrar tablas
    tablas = ejecutar_query(connection, """
        SELECT TABLE_NAME as table_name, TABLE_COMMENT as table_comment
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
        ORDER BY TABLE_NAME
    """)

    if tablas:
        print(f"\n📋 TABLAS EN LA BASE DE DATOS ({len(tablas)}):")
        for tabla in tablas:
            print(f"  • {tabla['table_name']}")

def explorar_establecimientos(connection):
    """Explora los establecimientos existentes"""
    print("\n" + "="*60)
    print("🏢 ESTABLECIMIENTOS EXISTENTES")
    print("="*60)

    establecimientos = ejecutar_query(connection, """
        SELECT e.id, e.nombre, e.direccion, te.nombre as tipo,
               COUNT(iee.id) as items_checklist
        FROM establecimientos e
        LEFT JOIN tipos_establecimiento te ON e.tipo_establecimiento_id = te.id
        LEFT JOIN items_evaluacion_establecimiento iee ON e.id = iee.establecimiento_id
        WHERE e.activo = 1
        GROUP BY e.id, e.nombre, e.direccion, te.nombre
        ORDER BY e.nombre
    """)

    if establecimientos:
        print(f"\n🏪 {len(establecimientos)} establecimientos encontrados:")
        for est in establecimientos:
            print(f"\n  🏢 {est['nombre']} (ID: {est['id']})")
            print(f"     📍 {est['direccion'] or 'Sin dirección'}")
            print(f"     🍽️  Tipo: {est['tipo'] or 'Sin tipo'}")
            print(f"     📋 Items en checklist: {est['items_checklist']}")
    else:
        print("❌ No se encontraron establecimientos")

def explorar_tipos_establecimiento(connection):
    """Explora los tipos de establecimiento"""
    print("\n" + "="*60)
    print("🏷️  TIPOS DE ESTABLECIMIENTO")
    print("="*60)

    tipos = ejecutar_query(connection, """
        SELECT id, nombre, descripcion,
               (SELECT COUNT(*) FROM establecimientos WHERE tipo_establecimiento_id = te.id AND activo = 1) as establecimientos
        FROM tipos_establecimiento te
        WHERE activo = 1
        ORDER BY nombre
    """)

    if tipos:
        print(f"\n🏷️ {len(tipos)} tipos de establecimiento:")
        for tipo in tipos:
            print(f"\n  • {tipo['nombre']} (ID: {tipo['id']})")
            print(f"    📝 {tipo['descripcion'] or 'Sin descripción'}")
            print(f"    🏢 Establecimientos: {tipo['establecimientos']}")
    else:
        print("❌ No se encontraron tipos de establecimiento")

def explorar_categorias_items(connection):
    """Explora las categorías y items base de evaluación"""
    print("\n" + "="*60)
    print("📂 CATEGORÍAS E ITEMS DE EVALUACIÓN")
    print("="*60)

    categorias = ejecutar_query(connection, """
        SELECT c.id, c.nombre, c.descripcion,
               COUNT(ib.id) as items_base
        FROM categorias_evaluacion c
        LEFT JOIN items_evaluacion_base ib ON c.id = ib.categoria_id
        WHERE c.activo = 1
        GROUP BY c.id, c.nombre, c.descripcion
        ORDER BY c.orden, c.nombre
    """)

    if categorias:
        print(f"\n📂 {len(categorias)} categorías encontradas:")
        for cat in categorias:
            print(f"\n  📁 {cat['nombre']} (ID: {cat['id']})")
            print(f"     📝 {cat['descripcion'] or 'Sin descripción'}")
            print(f"     📋 Items base: {cat['items_base']}")

            # Mostrar items de esta categoría
            items = ejecutar_query(connection, """
                SELECT codigo, descripcion, riesgo, puntaje_maximo
                FROM items_evaluacion_base
                WHERE categoria_id = %s AND activo = 1
                ORDER BY orden, codigo
            """, (cat['id'],))

            if items:
                print("     Items:")
                for item in items:
                    print(f"       • {item['codigo']}: {item['descripcion'][:50]}... (Riesgo: {item['riesgo']}, Máx: {item['puntaje_maximo']})")

def crear_tabla_plantillas(connection):
    """Crea la tabla de plantillas de checklist si no existe"""
    print("\n" + "="*60)
    print("🔧 CREANDO TABLA DE PLANTILLAS")
    print("="*60)

    # Crear tabla de plantillas
    query_plantillas = """
    CREATE TABLE IF NOT EXISTS plantillas_checklist (
        id INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(150) NOT NULL,
        descripcion TEXT,
        tipo_establecimiento_id INT,
        tamano_local ENUM('pequeno', 'mediano', 'grande') DEFAULT 'mediano',
        tipo_restaurante VARCHAR(100),
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (tipo_establecimiento_id) REFERENCES tipos_establecimiento(id),
        UNIQUE KEY unique_plantilla (nombre, tipo_establecimiento_id, tamano_local)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    """

    # Crear tabla de items de plantilla
    query_items_plantilla = """
    CREATE TABLE IF NOT EXISTS items_plantilla_checklist (
        id INT AUTO_INCREMENT PRIMARY KEY,
        plantilla_id INT NOT NULL,
        item_base_id INT NOT NULL,
        descripcion_personalizada TEXT,
        factor_ajuste DECIMAL(3,2) DEFAULT 1.00,
        obligatorio BOOLEAN DEFAULT TRUE,
        orden INT DEFAULT 0,
        activo BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plantilla_id) REFERENCES plantillas_checklist(id) ON DELETE CASCADE,
        FOREIGN KEY (item_base_id) REFERENCES items_evaluacion_base(id),
        UNIQUE KEY unique_item_plantilla (plantilla_id, item_base_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    """

    try:
        ejecutar_query(connection, query_plantillas, fetch=False)
        print("✅ Tabla 'plantillas_checklist' creada/verificada")

        ejecutar_query(connection, query_items_plantilla, fetch=False)
        print("✅ Tabla 'items_plantilla_checklist' creada/verificada")

        return True
    except Exception as e:
        print(f"❌ Error creando tablas: {e}")
        return False

def crear_plantillas_basicas(connection):
    """Crea plantillas básicas de checklist"""
    print("\n" + "="*60)
    print("📝 CREANDO PLANTILLAS BÁSICAS")
    print("="*60)

    # Obtener tipos de establecimiento
    tipos = ejecutar_query(connection, """
        SELECT id, nombre FROM tipos_establecimiento WHERE activo = 1
    """)

    if not tipos:
        print("❌ No hay tipos de establecimiento. Creando tipos básicos...")

        # Crear tipos básicos
        tipos_basicos = [
            ("Restaurante", "Establecimiento de comida preparada y servida"),
            ("Cafetería", "Establecimiento de bebidas y comidas ligeras"),
            ("Bar", "Establecimiento de bebidas alcohólicas"),
            ("Comida Rápida", "Establecimiento de comida rápida"),
            ("Supermercado", "Establecimiento de venta de alimentos")
        ]

        for nombre, desc in tipos_basicos:
            ejecutar_query(connection, """
                INSERT INTO tipos_establecimiento (nombre, descripcion)
                VALUES (%s, %s)
            """, (nombre, desc), fetch=False)

        tipos = ejecutar_query(connection, """
            SELECT id, nombre FROM tipos_establecimiento WHERE activo = 1
        """)

    # Crear plantillas para cada tipo
    plantillas = [
        ("Checklist Básico Pequeño", "Plantilla básica para locales pequeños", "pequeno", None),
        ("Checklist Estándar Mediano", "Plantilla estándar para locales medianos", "mediano", None),
        ("Checklist Completo Grande", "Plantilla completa para locales grandes", "grande", None),
        ("Checklist Restaurante Casual", "Para restaurantes de comida casual", "mediano", "casual"),
        ("Checklist Restaurante Fino", "Para restaurantes de alta cocina", "grande", "fino"),
        ("Checklist Bar Estándar", "Para bares y pubs", "mediano", "bar"),
    ]

    for tipo in tipos:
        for nombre_pl, desc, tamano, tipo_rest in plantillas:
            nombre_completo = f"{tipo['nombre']} - {nombre_pl}"

            # Insertar plantilla
            plantilla_id = ejecutar_query(connection, """
                INSERT INTO plantillas_checklist (nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante)
                VALUES (%s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE id=LAST_INSERT_ID(id)
            """, (nombre_completo, desc, tipo['id'], tamano, tipo_rest), fetch=False)

            # Obtener ID de la plantilla insertada
            plantilla_insertada = ejecutar_query(connection, """
                SELECT id FROM plantillas_checklist
                WHERE nombre = %s AND tipo_establecimiento_id = %s
            """, (nombre_completo, tipo['id']))

            if plantilla_insertada:
                plantilla_id = plantilla_insertada[0]['id']

                # Agregar items base a la plantilla
                items_base = ejecutar_query(connection, """
                    SELECT id, categoria_id FROM items_evaluacion_base
                    WHERE activo = 1 ORDER BY categoria_id, orden
                """)

                if items_base:
                    # Para locales pequeños, usar solo items críticos y mayores
                    if tamano == "pequeno":
                        items_filtrados = [item for item in items_base if item['categoria_id'] <= 3]  # Primeras 3 categorías
                    elif tamano == "grande":
                        items_filtrados = items_base  # Todos los items
                    else:  # mediano
                        items_filtrados = items_base[:len(items_base)//2]  # Mitad de los items

                    for i, item in enumerate(items_filtrados):
                        ejecutar_query(connection, """
                            INSERT INTO items_plantilla_checklist (plantilla_id, item_base_id, orden)
                            VALUES (%s, %s, %s)
                            ON DUPLICATE KEY UPDATE activo = 1
                        """, (plantilla_id, item['id'], i), fetch=False)

                print(f"✅ Plantilla creada: {nombre_completo}")

def mostrar_plantillas_creadas(connection):
    """Muestra las plantillas creadas"""
    print("\n" + "="*60)
    print("📋 PLANTILLAS CREADAS")
    print("="*60)

    plantillas = ejecutar_query(connection, """
        SELECT p.id, p.nombre, p.descripcion, p.tamano_local, p.tipo_restaurante,
               te.nombre as tipo_establecimiento,
               COUNT(ip.id) as items
        FROM plantillas_checklist p
        LEFT JOIN tipos_establecimiento te ON p.tipo_establecimiento_id = te.id
        LEFT JOIN items_plantilla_checklist ip ON p.id = ip.plantilla_id AND ip.activo = 1
        WHERE p.activo = 1
        GROUP BY p.id, p.nombre, p.descripcion, p.tamano_local, p.tipo_restaurante, te.nombre
        ORDER BY te.nombre, p.tamano_local, p.nombre
    """)

    if plantillas:
        print(f"\n📝 {len(plantillas)} plantillas disponibles:")
        tipo_actual = None

        for plantilla in plantillas:
            if tipo_actual != plantilla['tipo_establecimiento']:
                tipo_actual = plantilla['tipo_establecimiento']
                print(f"\n🏷️  {tipo_actual}:")

            print(f"  • {plantilla['nombre']}")
            print(f"    📏 Tamaño: {plantilla['tamano_local'].title()}")
            if plantilla['tipo_restaurante']:
                print(f"    🍽️  Tipo: {plantilla['tipo_restaurante'].title()}")
            print(f"    📋 Items: {plantilla['items']}")
            print(f"    📝 {plantilla['descripcion']}")
    else:
        print("❌ No se encontraron plantillas")

def menu_principal():
    """Menú principal del script"""
    print("\n" + "="*80)
    print("🍽️  GESTOR DE ESTABLECIMIENTOS Y CHECKLISTS - ALIMENTOS Y BEBIDAS")
    print("="*80)
    print("1. Explorar estructura de la base de datos")
    print("2. Ver establecimientos existentes")
    print("3. Ver tipos de establecimiento")
    print("4. Ver categorías e items de evaluación")
    print("5. Crear sistema de plantillas de checklist")
    print("6. Crear plantillas básicas")
    print("7. Ver plantillas disponibles")
    print("8. Salir")
    print("="*80)

    while True:
        try:
            opcion = input("\nSeleccione una opción (1-8): ").strip()

            if opcion == "1":
                connection = conectar_db()
                if connection:
                    mostrar_estructura_bd(connection)
                    connection.close()

            elif opcion == "2":
                connection = conectar_db()
                if connection:
                    explorar_establecimientos(connection)
                    connection.close()

            elif opcion == "3":
                connection = conectar_db()
                if connection:
                    explorar_tipos_establecimiento(connection)
                    connection.close()

            elif opcion == "4":
                connection = conectar_db()
                if connection:
                    explorar_categorias_items(connection)
                    connection.close()

            elif opcion == "5":
                connection = conectar_db()
                if connection:
                    if crear_tabla_plantillas(connection):
                        print("✅ Sistema de plantillas creado exitosamente")
                    connection.close()

            elif opcion == "6":
                connection = conectar_db()
                if connection:
                    crear_plantillas_basicas(connection)
                    connection.close()

            elif opcion == "7":
                connection = conectar_db()
                if connection:
                    mostrar_plantillas_creadas(connection)
                    connection.close()

            elif opcion == "8":
                print("👋 ¡Hasta luego!")
                break

            else:
                print("❌ Opción no válida. Intente nuevamente.")

        except KeyboardInterrupt:
            print("\n👋 ¡Hasta luego!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        # Modo automático con argumentos
        opcion = sys.argv[1]
        connection = conectar_db()
        if connection:
            if opcion == "1":
                mostrar_estructura_bd(connection)
            elif opcion == "2":
                explorar_establecimientos(connection)
            elif opcion == "3":
                explorar_tipos_establecimiento(connection)
            elif opcion == "4":
                explorar_categorias_items(connection)
            elif opcion == "5":
                if crear_tabla_plantillas(connection):
                    print("✅ Sistema de plantillas creado exitosamente")
            elif opcion == "6":
                crear_plantillas_basicas(connection)
            elif opcion == "7":
                mostrar_plantillas_creadas(connection)
            connection.close()
    else:
        # Modo interactivo
        menu_principal()
