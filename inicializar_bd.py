#!/usr/bin/env python3
"""
Script de inicialización de la base de datos para el sistema de Alimentos y Bebidas
Este script crea todas las tablas necesarias según los modelos definidos
y datos iniciales básicos para el funcionamiento del sistema.

Descripción: Recrear la estructura completa de la base de datos del sistema
de inspecciones de alimentos y bebidas, incluyendo usuarios, establecimientos,
categorías de evaluación, configuraciones y datos iniciales necesarios.

Lógica: Se utiliza SQLAlchemy para crear todas las tablas desde los modelos
definidos en el sistema. Se incluyen datos básicos como roles, categorías
de evaluación estándar y configuraciones del sistema.

Ejemplo de uso:
python inicializar_bd.py
"""

import sys
import os
from datetime import datetime, date

# Agregar el directorio raíz al path para importar la aplicación
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from app.extensions import db

# Importar todos los modelos para asegurar que SQLAlchemy los reconozca
from app.models.Usuario_models import Rol, Usuario, TipoEstablecimiento
from app.models.Inspecciones_models import (
    InspectorEstablecimiento, Establecimiento, EncargadoEstablecimiento,
    JefeEstablecimiento, FirmaEncargadoPorJefe, PlanSemanal,
    ConfiguracionEvaluacion, CategoriaEvaluacion, ItemEvaluacionBase,
    ItemEvaluacionEstablecimiento, Inspeccion, InspeccionDetalle, EvidenciaInspeccion
)
from app.models.ConfiguracionPermisos_models import (
    PermisoRol, PermisoUsuario, AuditoriaAcciones, ConfiguracionSistema,
    inicializar_configuraciones_basicas, inicializar_permisos_basicos
)

def crear_base_datos():
    """Crear todas las tablas de la base de datos"""
    try:
        print("Creando estructura de base de datos...")
        
        # Eliminar tablas existentes si existen (solo para desarrollo)
        print("Eliminando tablas existentes...")
        db.drop_all()
        
        # Crear todas las tablas
        print("Creando nuevas tablas...")
        db.create_all()
        
        print("Estructura de base de datos creada exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al crear la base de datos: {str(e)}")
        return False

def crear_roles_basicos():
    """Crear los roles básicos del sistema"""
    try:
        print("Creando roles básicos...")
        
        roles_basicos = [
            {
                'nombre': 'Administrador',
                'descripcion': 'Acceso completo al sistema, gestión de usuarios y configuraciones',
                'permisos': {
                    'usuarios': ['crear', 'editar', 'eliminar', 'ver'],
                    'establecimientos': ['crear', 'editar', 'eliminar', 'ver'],
                    'inspecciones': ['crear', 'editar', 'eliminar', 'ver'],
                    'configuracion': ['crear', 'editar', 'eliminar', 'ver']
                }
            },
            {
                'nombre': 'Inspector',
                'descripcion': 'Puede realizar inspecciones y gestionar sus propias evaluaciones',
                'permisos': {
                    'inspecciones': ['crear', 'editar', 'ver'],
                    'establecimiento': ['ver']
                }
            },
            {
                'nombre': 'Encargado',
                'descripcion': 'Encargado de establecimiento, puede firmar inspecciones',
                'permisos': {
                    'inspecciones': ['ver', 'firmar'],
                    'establecimiento': ['ver']
                }
            },
            {
                'nombre': 'Jefe de Establecimiento',
                'descripcion': 'Gestiona encargados y supervisa inspecciones de su establecimiento',
                'permisos': {
                    'encargados': ['gestionar'],
                    'inspecciones': ['ver'],
                    'establecimiento': ['editar', 'ver']
                }
            }
        ]
        
        for rol_data in roles_basicos:
            rol_existente = Rol.query.filter_by(nombre=rol_data['nombre']).first()
            if not rol_existente:
                rol = Rol(
                    nombre=rol_data['nombre'],
                    descripcion=rol_data['descripcion'],
                    permisos=rol_data['permisos']
                )
                db.session.add(rol)
        
        db.session.commit()
        print("Roles básicos creados exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al crear roles básicos: {str(e)}")
        db.session.rollback()
        return False

def crear_tipos_establecimiento():
    """Crear tipos de establecimiento básicos"""
    try:
        print("Creando tipos de establecimiento...")
        
        tipos_establecimiento = [
            {
                'nombre': 'Restaurante',
                'descripcion': 'Establecimiento de preparación y venta de comidas'
            },
            {
                'nombre': 'Cafetería',
                'descripcion': 'Establecimiento de venta de bebidas calientes y comidas ligeras'
            },
            {
                'nombre': 'Panadería',
                'descripcion': 'Establecimiento de elaboración y venta de productos de panadería'
            },
            {
                'nombre': 'Supermercado',
                'descripcion': 'Establecimiento de venta de alimentos y productos diversos'
            },
            {
                'nombre': 'Bar',
                'descripcion': 'Establecimiento de venta de bebidas y comidas rápidas'
            },
            {
                'nombre': 'Hotel',
                'descripcion': 'Establecimiento hotelero con servicio de alimentos y bebidas'
            }
        ]
        
        for tipo_data in tipos_establecimiento:
            tipo_existente = TipoEstablecimiento.query.filter_by(nombre=tipo_data['nombre']).first()
            if not tipo_existente:
                tipo = TipoEstablecimiento(
                    nombre=tipo_data['nombre'],
                    descripcion=tipo_data['descripcion']
                )
                db.session.add(tipo)
        
        db.session.commit()
        print("Tipos de establecimiento creados exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al crear tipos de establecimiento: {str(e)}")
        db.session.rollback()
        return False

def crear_categorias_evaluacion():
    """Crear categorías base para las evaluaciones"""
    try:
        print("Creando categorías de evaluación...")
        
        categorias = [
            {
                'nombre': 'Higiene Personal',
                'descripcion': 'Evaluación de la higiene del personal manipulador de alimentos',
                'orden': 1
            },
            {
                'nombre': 'Infraestructura y Equipos',
                'descripcion': 'Estado de las instalaciones, equipos y utensilios',
                'orden': 2
            },
            {
                'nombre': 'Manipulación de Alimentos',
                'descripcion': 'Procesos de manipulación, preparación y conservación',
                'orden': 3
            },
            {
                'nombre': 'Almacenamiento',
                'descripcion': 'Condiciones de almacenamiento de materias primas y productos',
                'orden': 4
            },
            {
                'nombre': 'Limpieza y Desinfección',
                'descripcion': 'Procedimientos de limpieza y desinfección',
                'orden': 5
            },
            {
                'nombre': 'Control de Plagas',
                'descripcion': 'Medidas de prevención y control de plagas',
                'orden': 6
            },
            {
                'nombre': 'Documentación',
                'descripcion': 'Registros, certificados y documentación requerida',
                'orden': 7
            }
        ]
        
        for cat_data in categorias:
            categoria_existente = CategoriaEvaluacion.query.filter_by(nombre=cat_data['nombre']).first()
            if not categoria_existente:
                categoria = CategoriaEvaluacion(
                    nombre=cat_data['nombre'],
                    descripcion=cat_data['descripcion'],
                    orden=cat_data['orden']
                )
                db.session.add(categoria)
        
        db.session.commit()
        print("Categorías de evaluación creadas exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al crear categorías de evaluación: {str(e)}")
        db.session.rollback()
        return False

def crear_items_evaluacion_base():
    """Crear items base de evaluación por categoría"""
    try:
        print("Creando items base de evaluación...")
        
        # Obtener categorías creadas
        categorias = {cat.nombre: cat.id for cat in CategoriaEvaluacion.query.all()}
        
        items_base = [
            # Higiene Personal
            {'categoria': 'Higiene Personal', 'codigo': 'HP001', 
             'descripcion': 'El personal usa uniforme limpio y completo', 'riesgo': 'Mayor'},
            {'categoria': 'Higiene Personal', 'codigo': 'HP002', 
             'descripcion': 'El personal mantiene las uñas cortas y limpias', 'riesgo': 'Menor'},
            {'categoria': 'Higiene Personal', 'codigo': 'HP003', 
             'descripcion': 'El personal se lava las manos correctamente', 'riesgo': 'Crítico'},
            
            # Infraestructura y Equipos
            {'categoria': 'Infraestructura y Equipos', 'codigo': 'IE001', 
             'descripcion': 'Las superficies de trabajo están limpias', 'riesgo': 'Mayor'},
            {'categoria': 'Infraestructura y Equipos', 'codigo': 'IE002', 
             'descripcion': 'Los equipos funcionan correctamente', 'riesgo': 'Menor'},
            {'categoria': 'Infraestructura y Equipos', 'codigo': 'IE003', 
             'descripcion': 'Existe sistema de ventilación adecuado', 'riesgo': 'Mayor'},
            
            # Manipulación de Alimentos
            {'categoria': 'Manipulación de Alimentos', 'codigo': 'MA001', 
             'descripcion': 'Los alimentos se mantienen a temperaturas seguras', 'riesgo': 'Crítico'},
            {'categoria': 'Manipulación de Alimentos', 'codigo': 'MA002', 
             'descripcion': 'Se evita la contaminación cruzada', 'riesgo': 'Crítico'},
            {'categoria': 'Manipulación de Alimentos', 'codigo': 'MA003', 
             'descripcion': 'Los alimentos están protegidos de contaminantes', 'riesgo': 'Mayor'},
            
            # Almacenamiento
            {'categoria': 'Almacenamiento', 'codigo': 'AL001', 
             'descripcion': 'Los productos se almacenan ordenadamente', 'riesgo': 'Menor'},
            {'categoria': 'Almacenamiento', 'codigo': 'AL002', 
             'descripcion': 'Se respeta el sistema PEPS (primero en entrar, primero en salir)', 'riesgo': 'Mayor'},
            
            # Limpieza y Desinfección
            {'categoria': 'Limpieza y Desinfección', 'codigo': 'LD001', 
             'descripcion': 'Existen procedimientos escritos de limpieza', 'riesgo': 'Mayor'},
            {'categoria': 'Limpieza y Desinfección', 'codigo': 'LD002', 
             'descripcion': 'Se utilizan productos químicos aprobados', 'riesgo': 'Mayor'},
            
            # Control de Plagas
            {'categoria': 'Control de Plagas', 'codigo': 'CP001', 
             'descripcion': 'No hay evidencia de presencia de plagas', 'riesgo': 'Crítico'},
            {'categoria': 'Control de Plagas', 'codigo': 'CP002', 
             'descripcion': 'Existen medidas preventivas contra plagas', 'riesgo': 'Mayor'},
            
            # Documentación
            {'categoria': 'Documentación', 'codigo': 'DOC001', 
             'descripcion': 'Se mantienen registros de control de temperatura', 'riesgo': 'Mayor'},
            {'categoria': 'Documentación', 'codigo': 'DOC002', 
             'descripcion': 'El personal cuenta con certificados de salud vigentes', 'riesgo': 'Mayor'}
        ]
        
        for item_data in items_base:
            categoria_id = categorias.get(item_data['categoria'])
            if categoria_id:
                item_existente = ItemEvaluacionBase.query.filter_by(codigo=item_data['codigo']).first()
                if not item_existente:
                    item = ItemEvaluacionBase(
                        categoria_id=categoria_id,
                        codigo=item_data['codigo'],
                        descripcion=item_data['descripcion'],
                        riesgo=item_data['riesgo'],
                        puntaje_minimo=0,
                        puntaje_maximo=4
                    )
                    db.session.add(item)
        
        db.session.commit()
        print("Items base de evaluación creados exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al crear items base de evaluación: {str(e)}")
        db.session.rollback()
        return False

def crear_usuario_admin():
    """Crear usuario administrador por defecto"""
    try:
        print("Creando usuario administrador...")
        
        # Obtener rol de administrador
        rol_admin = Rol.query.filter_by(nombre='Administrador').first()
        if not rol_admin:
            print("Error: No se encontró el rol de Administrador")
            return False
        
        # Verificar si ya existe un administrador
        admin_existente = Usuario.query.filter_by(correo='admin@chancay.gob.pe').first()
        if not admin_existente:
            admin = Usuario(
                nombre='Administrador',
                apellido='Sistema',
                correo='admin@chancay.gob.pe',
                rol_id=rol_admin.id,
                activo=True,
                dni='00000000',
                telefono='000000000'
            )
            admin.set_password('admin123')  # Cambiar en producción
            db.session.add(admin)
            
            db.session.commit()
            print("Usuario administrador creado exitosamente.")
            print("Credenciales: admin@chancay.gob.pe / admin123")
            print("IMPORTANTE: Cambiar la contraseña en producción")
        else:
            print("Usuario administrador ya existe.")
        
        return True
        
    except Exception as e:
        print(f"Error al crear usuario administrador: {str(e)}")
        db.session.rollback()
        return False

def inicializar_configuraciones_basicas_local():
    """Inicializar configuraciones básicas del sistema"""
    try:
        print("Inicializando configuraciones básicas...")
        
        configuraciones_basicas = [
            {
                'clave': 'meta_semanal_default',
                'valor': '3',
                'descripcion': 'Meta de inspecciones por semana por defecto',
                'modificable_por_inspector': True
            },
            {
                'clave': 'dias_recordatorio',
                'valor': '1,3,5',
                'descripcion': 'Días de la semana para recordatorios (1=Lunes, 7=Domingo)',
                'modificable_por_inspector': False
            },
            {
                'clave': 'hora_recordatorio',
                'valor': '09:00',
                'descripcion': 'Hora para envío de recordatorios',
                'modificable_por_inspector': False
            },
            {
                'clave': 'zona_horaria',
                'valor': 'America/Lima',
                'descripcion': 'Zona horaria del sistema',
                'modificable_por_inspector': False
            },
            {
                'clave': 'notificaciones_email',
                'valor': 'true',
                'descripcion': 'Activar notificaciones por email',
                'modificable_por_inspector': False
            },
            {
                'clave': 'tiempo_sesion',
                'valor': '240',
                'descripcion': 'Tiempo de sesión en minutos',
                'modificable_por_inspector': False
            },
            {
                'clave': 'intentos_login',
                'valor': '5',
                'descripcion': 'Número máximo de intentos de login',
                'modificable_por_inspector': False
            }
        ]
        
        for config_data in configuraciones_basicas:
            # Solo crear si no existe
            existing = ConfiguracionEvaluacion.query.filter_by(clave=config_data['clave']).first()
            if not existing:
                config = ConfiguracionEvaluacion(**config_data)
                db.session.add(config)
        
        db.session.commit()
        print("Configuraciones básicas inicializadas exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al inicializar configuraciones básicas: {str(e)}")
        db.session.rollback()
        return False

def inicializar_permisos_basicos_local():
    """Inicializar permisos básicos por rol"""
    try:
        print("Inicializando permisos básicos...")
        
        permisos_inspector = [
            # Inspecciones
            {'recurso': 'inspecciones', 'accion': 'crear'},
            {'recurso': 'inspecciones', 'accion': 'editar', 'condicion': {'propias': True}},
            {'recurso': 'inspecciones', 'accion': 'ver'},
            # Configuración limitada
            {'recurso': 'configuracion', 'accion': 'editar', 'condicion': {'solo_meta_semanal': True}},
            {'recurso': 'configuracion', 'accion': 'ver'},
            # Establecimientos
            {'recurso': 'establecimientos', 'accion': 'ver'},
        ]
        
        permisos_encargado = [
            # Inspecciones propias
            {'recurso': 'inspecciones', 'accion': 'ver', 'condicion': {'propias': True}},
            {'recurso': 'inspecciones', 'accion': 'firmar', 'condicion': {'propias': True}},
            # Establecimiento propio
            {'recurso': 'establecimientos', 'accion': 'ver', 'condicion': {'propios': True}},
        ]
        
        permisos_admin = [
            # Control total
            {'recurso': '*', 'accion': '*'},
        ]
        
        permisos_jefe = [
            # Gestión de establecimiento
            {'recurso': 'establecimientos', 'accion': 'ver', 'condicion': {'propios': True}},
            {'recurso': 'establecimientos', 'accion': 'editar', 'condicion': {'propios': True}},
            {'recurso': 'encargados', 'accion': 'gestionar', 'condicion': {'establecimiento_propio': True}},
            {'recurso': 'inspecciones', 'accion': 'ver', 'condicion': {'establecimiento_propio': True}},
            {'recurso': 'firmas', 'accion': 'cargar'},
        ]
        
        # Mapear roles con sus permisos
        roles_permisos = {
            'Inspector': permisos_inspector,
            'Encargado': permisos_encargado,
            'Administrador': permisos_admin,
            'Jefe de Establecimiento': permisos_jefe
        }
        
        for nombre_rol, permisos in roles_permisos.items():
            rol = Rol.query.filter_by(nombre=nombre_rol).first()
            if rol:
                for permiso_data in permisos:
                    # Solo crear si no existe
                    existing = PermisoRol.query.filter_by(
                        rol_id=rol.id,
                        recurso=permiso_data['recurso'],
                        accion=permiso_data['accion']
                    ).first()
                    
                    if not existing:
                        permiso = PermisoRol(
                            rol_id=rol.id,
                            recurso=permiso_data['recurso'],
                            accion=permiso_data['accion'],
                            condicion=permiso_data.get('condicion')
                        )
                        db.session.add(permiso)
        
        db.session.commit()
        print("Permisos básicos inicializados exitosamente.")
        return True
        
    except Exception as e:
        print(f"Error al inicializar permisos básicos: {str(e)}")
        db.session.rollback()
        return False

def main():
    """Función principal para inicializar la base de datos"""
    print("="*60)
    print("INICIALIZACIÓN DE BASE DE DATOS - ALIMENTOS Y BEBIDAS")
    print("="*60)
    
    # Crear la aplicación Flask
    app = create_app()
    
    with app.app_context():
        try:
            # Verificar conexión a la base de datos
            print("Verificando conexión a la base de datos...")
            with db.engine.connect() as connection:
                connection.execute(db.text("SELECT 1"))
            print("Conexión a la base de datos exitosa.")
            
            # Ejecutar procesos de inicialización
            pasos = [
                ("Crear estructura de base de datos", crear_base_datos),
                ("Crear roles básicos", crear_roles_basicos),
                ("Crear tipos de establecimiento", crear_tipos_establecimiento),
                ("Crear categorías de evaluación", crear_categorias_evaluacion),
                ("Crear items base de evaluación", crear_items_evaluacion_base),
                ("Crear usuario administrador", crear_usuario_admin),
                ("Inicializar configuraciones básicas", lambda: inicializar_configuraciones_basicas_local()),
                ("Inicializar permisos básicos", lambda: inicializar_permisos_basicos_local())
            ]
            
            exitos = 0
            for descripcion, funcion in pasos:
                print(f"\n{descripcion}...")
                if funcion():
                    exitos += 1
                    print(f"✓ {descripcion} completado")
                else:
                    print(f"✗ Error en: {descripcion}")
            
            print("\n" + "="*60)
            print(f"RESUMEN: {exitos}/{len(pasos)} procesos completados exitosamente")
            
            if exitos == len(pasos):
                print("¡Base de datos inicializada completamente!")
                print("\nPuedes ahora:")
                print("1. Ejecutar la aplicación con: python run.py")
                print("2. Acceder con las credenciales de administrador")
                print("3. Crear establecimientos e inspectores desde el panel administrativo")
            else:
                print("Hubo algunos errores. Revisa los mensajes anteriores.")
            
            print("="*60)
            
        except Exception as e:
            print(f"Error de conexión a la base de datos: {str(e)}")
            print("Verifica tu configuración en el archivo .env")
            return False
    
    return True

if __name__ == "__main__":
    main()