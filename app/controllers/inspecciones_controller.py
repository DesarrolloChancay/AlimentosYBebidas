from flask import json, jsonify, request, session
from datetime import datetime, date
import os
from werkzeug.utils import secure_filename
import pytz
from sqlalchemy import text, func
from app.extensions import socketio

def safe_timestamp():
    """Función para generar timestamp de manera segura en Windows"""
    try:
        # Usar strftime para evitar problemas con isoformat en Windows
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    except Exception as e:
        print(f"Error generando timestamp: {e}")
        # Fallback a timestamp unix como string
        return str(int(datetime.now().timestamp()))
from app.models.Inspecciones_models import (
    Establecimiento, EncargadoEstablecimiento, CategoriaEvaluacion,
    ItemEvaluacionEstablecimiento, Inspeccion, InspeccionDetalle,
    EvidenciaInspeccion, ItemEvaluacionBase, 
    InspectorEstablecimiento
)
from app.models.Usuario_models import Usuario, TipoEstablecimiento, Rol
from app.extensions import db

# Almacenamiento temporal en memoria para datos de inspección
# En producción usar Redis
inspecciones_temporales = {}
datos_tiempo_real = {}  # Para almacenar datos temporales entre inspector y encargado

class InspeccionesController:
    EVIDENCIAS_FOLDER = 'app/static/evidencias'
    FIRMAS_FOLDER = 'app/static/firmas'
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
    
    @staticmethod
    def allowed_file(filename):
        return '.' in filename and filename.rsplit('.', 1)[1].lower() in InspeccionesController.ALLOWED_EXTENSIONS
    
    @staticmethod
    def guardar_firma(file, tipo, inspeccion_id):
        if file and InspeccionesController.allowed_file(file.filename):
            # Crear directorio si no existe
            if not os.path.exists(InspeccionesController.FIRMAS_FOLDER):
                os.makedirs(InspeccionesController.FIRMAS_FOLDER)
            
            # Generar nombre único para la firma
            filename = f"firma_{tipo}_{inspeccion_id}_{secure_filename(file.filename)}"
            filepath = os.path.join(InspeccionesController.FIRMAS_FOLDER, filename)

            # Guardar archivo
            file.save(filepath)

            # Devolver ruta relativa para almacenar en la base de datos
            return os.path.join('static/firmas', filename)
        return None

    @staticmethod
    def obtener_establecimientos():
        try:
            user_role = session.get('user_role')
            user_id = session.get('user_id')
            
            # Admin puede ver todos los establecimientos
            if user_role == 'Administrador':
                establecimientos = Establecimiento.query.filter_by(activo=True).all()
            
            # Inspector solo ve establecimientos asignados
            elif user_role == 'Inspector':
                establecimientos = db.session.query(Establecimiento).join(
                    InspectorEstablecimiento,
                    Establecimiento.id == InspectorEstablecimiento.establecimiento_id
                ).filter(
                    InspectorEstablecimiento.inspector_id == user_id,
                    InspectorEstablecimiento.activo == True,
                    Establecimiento.activo == True,
                    InspectorEstablecimiento.fecha_asignacion <= date.today()
                ).filter(
                    (InspectorEstablecimiento.fecha_fin_asignacion.is_(None)) | 
                    (InspectorEstablecimiento.fecha_fin_asignacion >= date.today())
                ).all()
            
            # Encargado solo ve sus establecimientos
            elif user_role == 'Encargado':
                establecimientos = db.session.query(Establecimiento).join(
                    EncargadoEstablecimiento,
                    Establecimiento.id == EncargadoEstablecimiento.establecimiento_id
                ).filter(
                    EncargadoEstablecimiento.usuario_id == user_id,
                    EncargadoEstablecimiento.activo == True,
                    Establecimiento.activo == True,
                    EncargadoEstablecimiento.fecha_inicio <= date.today()
                ).filter(
                    (EncargadoEstablecimiento.fecha_fin.is_(None)) | 
                    (EncargadoEstablecimiento.fecha_fin >= date.today())
                ).all()
            
            else:
                return jsonify({'error': 'Rol no autorizado'}), 403
            
            data = []
            fecha_actual = date.today()
            
            for e in establecimientos:
                # Obtener el encargado actual del establecimiento
                encargado = EncargadoEstablecimiento.query.filter(
                    EncargadoEstablecimiento.establecimiento_id == e.id,
                    EncargadoEstablecimiento.activo == True,
                    EncargadoEstablecimiento.fecha_inicio <= fecha_actual,
                    (EncargadoEstablecimiento.fecha_fin.is_(None) | (EncargadoEstablecimiento.fecha_fin >= fecha_actual))
                ).order_by(
                    EncargadoEstablecimiento.es_principal.desc(),
                    EncargadoEstablecimiento.fecha_inicio.desc()
                ).first()

                data.append({
                    'id': e.id,
                    'nombre': e.nombre,
                    'direccion': e.direccion,
                    'tipo_establecimiento': e.tipo_establecimiento.nombre if e.tipo_establecimiento else None,
                    'encargado_actual': {
                        'id': encargado.usuario.id,
                        'nombre': f"{encargado.usuario.nombre} {encargado.usuario.apellido or ''}".strip(),
                        'correo': encargado.usuario.correo,
                        'telefono': encargado.usuario.telefono
                    } if encargado else None
                })
            
            return jsonify(data)
        except Exception as e:
            return jsonify({'error': f'Error al obtener establecimientos: {str(e)}'}), 500

    @staticmethod
    def obtener_plan_semanal():
        try:
            # Configurar zona horaria de Lima
            lima_tz = pytz.timezone('America/Lima')
            
            # Obtener la fecha actual en Lima
            fecha_actual = datetime.now(lima_tz)
            
            # Obtener semana y año
            semana_actual = fecha_actual.isocalendar()[1]
            ano_actual = fecha_actual.year
            
            # Obtener establecimientos activos primero
            establecimientos = Establecimiento.query.filter_by(activo=True).order_by(Establecimiento.nombre).all()
            
            # Si no hay establecimientos, devolver lista vacía
            if not establecimientos:
                return jsonify([])

            # Obtener inspecciones de la semana actual
            inspecciones = {}
            sql_inspecciones = text("""
                SELECT 
                    establecimiento_id,
                    COUNT(*) as total_inspecciones
                FROM inspecciones i
                WHERE WEEK(CONVERT_TZ(i.fecha, 'UTC', 'America/Lima'), 1) = :semana
                AND YEAR(CONVERT_TZ(i.fecha, 'UTC', 'America/Lima')) = :ano
                AND i.estado = 'completada'
                GROUP BY establecimiento_id
            """)
            result = db.session.execute(sql_inspecciones, {'semana': semana_actual, 'ano': ano_actual})
            
            # Crear diccionario de inspecciones por establecimiento
            for row in result:
                inspecciones[row.establecimiento_id] = row.total_inspecciones

            # Crear lista de plan semanal
            plan_semanal = []
            for establecimiento in establecimientos:
                inspecciones_realizadas = inspecciones.get(establecimiento.id, 0)
                plan_semanal.append({
                    'establecimiento': establecimiento.nombre,
                    'realizadas': inspecciones_realizadas,
                    'meta': 3,  # Meta fija de 3 evaluaciones
                    'texto': f"{inspecciones_realizadas}/3 esta semana"
                })
            
            return jsonify(plan_semanal)
        except Exception as e:
            return jsonify({'error': str(e)}), 500
            
    @staticmethod
    def obtener_categorias():
        try:
            categorias = CategoriaEvaluacion.query.filter_by(activo=True).order_by(CategoriaEvaluacion.orden).all()
            data = [{
                'id': c.id,
                'nombre': c.nombre,
                'descripcion': c.descripcion,
                'orden': c.orden,
                'lista_items': []
            } for c in categorias]
            return jsonify(data)
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def obtener_items_establecimiento(establecimiento_id):
        try:
            # Obtener todos los items del establecimiento con sus categorías
            items = db.session.query(
                ItemEvaluacionEstablecimiento,
                ItemEvaluacionBase,
                CategoriaEvaluacion
            ).join(
                ItemEvaluacionBase,
                ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id
            ).join(
                CategoriaEvaluacion,
                ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id
            ).filter(
                ItemEvaluacionEstablecimiento.establecimiento_id == establecimiento_id,
                ItemEvaluacionEstablecimiento.activo == True,
                ItemEvaluacionBase.activo == True,
                CategoriaEvaluacion.activo == True
            ).order_by(
                CategoriaEvaluacion.orden,
                ItemEvaluacionBase.orden
            ).all()

            # Organizar los datos en un formato más limpio
            categorias = {}
            for item, item_base, categoria in items:
                if categoria.id not in categorias:
                    categorias[categoria.id] = {
                        'id': categoria.id,
                        'nombre': categoria.nombre,
                        'descripcion': categoria.descripcion,
                        'orden': categoria.orden,
                        'items': []
                    }
                
                categorias[categoria.id]['items'].append({
                    'id': item.id,
                    'item_base_id': item_base.id,
                    'codigo': item_base.codigo,
                    'puntaje_minimo': item_base.puntaje_minimo,
                    'puntaje_maximo': int(item_base.puntaje_maximo * float(item.factor_ajuste)),  # Aplicar factor
                    'descripcion': item.descripcion_personalizada or item_base.descripcion,
                    'riesgo': item_base.riesgo,
                    'orden': item_base.orden,
                    'factor_ajuste': float(item.factor_ajuste)
                })
            
            # Convertir a lista ordenada por orden
            categorias_lista = list(categorias.values())
            categorias_lista.sort(key=lambda x: x['orden'])
            
            return jsonify({
                'success': True,
                'categorias': categorias_lista
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def calcular_puntajes_inspeccion(inspeccion_id):
        """Calcula automáticamente los puntajes de una inspección"""
        try:
            # Obtener todos los detalles de la inspección
            detalles = db.session.query(
                InspeccionDetalle,
                ItemEvaluacionEstablecimiento,
                ItemEvaluacionBase
            ).join(
                ItemEvaluacionEstablecimiento,
                InspeccionDetalle.item_establecimiento_id == ItemEvaluacionEstablecimiento.id
            ).join(
                ItemEvaluacionBase,
                ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id
            ).filter(
                InspeccionDetalle.inspeccion_id == inspeccion_id
            ).all()
            
            puntaje_total = 0
            puntaje_maximo_posible = 0
            puntos_criticos_perdidos = 0
            
            for detalle, item_est, item_base in detalles:
                # Calcular puntaje máximo con factor de ajuste
                puntaje_max = int(item_base.puntaje_maximo * float(item_est.factor_ajuste))
                puntaje_maximo_posible += puntaje_max
                
                # Sumar puntaje obtenido
                if detalle.score is not None:
                    puntaje_total += float(detalle.score)
                    
                    # Contar puntos críticos perdidos
                    if item_base.riesgo == 'Crítico' and float(detalle.score) < puntaje_max:
                        puntos_criticos_perdidos += (puntaje_max - float(detalle.score))
            
            # Calcular porcentaje
            porcentaje = (puntaje_total / puntaje_maximo_posible * 100) if puntaje_maximo_posible > 0 else 0
            
            # Actualizar la inspección
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if inspeccion:
                inspeccion.puntaje_total = puntaje_total
                inspeccion.puntaje_maximo_posible = puntaje_maximo_posible
                inspeccion.porcentaje_cumplimiento = round(porcentaje, 2)
                inspeccion.puntos_criticos_perdidos = puntos_criticos_perdidos
                db.session.commit()
            
            return {
                'puntaje_total': puntaje_total,
                'puntaje_maximo_posible': puntaje_maximo_posible,
                'porcentaje_cumplimiento': round(porcentaje, 2),
                'puntos_criticos_perdidos': puntos_criticos_perdidos
            }
            
        except Exception as e:
            db.session.rollback()
            raise Exception(f"Error calculando puntajes: {str(e)}")

    @staticmethod
    def guardar_inspeccion_parcial():
        """Guardar datos temporales del formulario en memoria del servidor"""
        try:
            data = request.json
            user_id = session.get('user_id')
            
            if not user_id:
                return jsonify({'error': 'Sesión no válida'}), 401
            
            if not data:
                return jsonify({'error': 'No hay datos para guardar'}), 400
            
            # Crear clave única para el usuario
            clave_temporal = f"user_{user_id}"
            
            # Guardar en memoria del servidor
            inspecciones_temporales[clave_temporal] = {
                'data': data,
                'timestamp': safe_timestamp(),
                'user_id': user_id
            }
            
                # Actualizar datos tiempo real SOLO SI HAY CAMBIOS
            establecimiento_id = data.get('establecimiento_id')
            if establecimiento_id:
                clave_tiempo_real = f"establecimiento_{establecimiento_id}"
                
                # Obtener datos anteriores para comparar
                datos_anteriores = datos_tiempo_real.get(clave_tiempo_real, {})
                items_anteriores = datos_anteriores.get('items', {})
                observaciones_anteriores = datos_anteriores.get('observaciones', '')
                
                # Verificar si hay cambios reales
                items_actuales = data.get('items', {})
                observaciones_actuales = data.get('observaciones', '')
                
                hay_cambios = (
                    items_actuales != items_anteriores or 
                    observaciones_actuales != observaciones_anteriores
                )
                
                if hay_cambios:
                    if clave_tiempo_real not in datos_tiempo_real:
                        datos_tiempo_real[clave_tiempo_real] = {}
                    
                    # Calcular resumen automáticamente basado en los items
                    resumen_calculado = {}
                    if items_actuales:
                        try:
                            # Obtener información de items para cálculo correcto
                            from app.models.Inspecciones_models import ItemEvaluacionEstablecimiento
                            
                            puntaje_total = 0
                            puntaje_maximo_posible = 0
                            puntos_criticos_perdidos = 0
                            items_evaluados = 0
                            total_items = 0
                            
                            # Obtener total de items disponibles para este establecimiento
                            total_items_query = ItemEvaluacionEstablecimiento.query.filter_by(
                                establecimiento_id=establecimiento_id
                            ).count()
                            total_items = total_items_query
                            
                            for item_id_str, item_data in items_actuales.items():
                                try:
                                    # Evitar procesar items con ID 'undefined'
                                    if item_id_str == 'undefined' or not item_id_str.isdigit():
                                        print(f"Ignorando item con ID inválido: {item_id_str}")
                                        continue
                                        
                                    item_id = int(item_id_str)
                                    # Buscar el item del establecimiento que contiene el factor de ajuste
                                    item_est = ItemEvaluacionEstablecimiento.query.filter_by(
                                        establecimiento_id=establecimiento_id,
                                        id=item_id
                                    ).first()
                                    
                                    if item_est and item_est.item_base and 'rating' in item_data and item_data['rating'] is not None:
                                        item_base = item_est.item_base
                                        # Aplicar factor de ajuste al puntaje máximo
                                        puntaje_max_ajustado = int(item_base.puntaje_maximo * float(item_est.factor_ajuste))
                                        puntaje_maximo_posible += puntaje_max_ajustado
                                        
                                        rating = int(item_data['rating'])
                                        # Incrementar items evaluados para cualquier rating válido (incluso 0)
                                        items_evaluados += 1
                                        # El puntaje obtenido es directamente el rating seleccionado
                                        puntaje_obtenido = float(rating)
                                        puntaje_total += puntaje_obtenido
                                        
                                        # Calcular puntos críticos perdidos
                                        if item_base.riesgo == 'Crítico' and rating < puntaje_max_ajustado:
                                            puntos_criticos_perdidos += puntaje_max_ajustado - rating
                                except (ValueError, TypeError) as ve:
                                    print(f"Error procesando item {item_id_str}: {ve}")
                                    continue
                            
                            porcentaje = (puntaje_total / puntaje_maximo_posible * 100) if puntaje_maximo_posible > 0 else 0
                            
                            resumen_calculado = {
                                'puntaje_total': round(puntaje_total, 2),
                                'puntaje_maximo_posible': round(puntaje_maximo_posible, 2),
                                'porcentaje_cumplimiento': round(porcentaje, 2),
                                'puntos_criticos_perdidos': round(puntos_criticos_perdidos, 2),
                                'items_evaluados': items_evaluados,
                                'total_items': total_items
                            }
                        except Exception as e:
                            print(f"Error calculando resumen temporal: {e}")
                            resumen_calculado = {}
                    
                    datos_tiempo_real[clave_tiempo_real].update({
                        'establecimiento_id': establecimiento_id,
                        'inspector_id': user_id,
                        'items': items_actuales,
                        'observaciones': observaciones_actuales,
                        'resumen': resumen_calculado,
                        'ultima_actualizacion': safe_timestamp()
                    })
                    
                    # SOLO emitir actualización en tiempo real cuando HAY CAMBIOS
                    try:
                        room = f"establecimiento_{establecimiento_id}"
                        socketio.emit('inspeccion_tiempo_real', {
                            'establecimiento_id': establecimiento_id,
                            'inspector_id': user_id,
                            'items': items_actuales,
                            'observaciones': observaciones_actuales,
                            'resumen': resumen_calculado,
                            'timestamp': safe_timestamp()
                        }, to=room)
                        
                        print(f"Rating en tiempo real: Cambios detectados y enviados por Inspector a room {room}")
                    except Exception as e:
                        print(f"Error emitiendo tiempo real: {str(e)}")
                else:
                    print("No hay cambios - omitiendo emisión tiempo real")
            
            return jsonify({
                'mensaje': 'Datos guardados temporalmente',
                'timestamp': inspecciones_temporales[clave_temporal]['timestamp']
            })
            
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def recuperar_inspeccion_temporal():
        """Recuperar datos temporales del formulario desde memoria del servidor"""
        try:
            user_id = session.get('user_id')
            
            if not user_id:
                return jsonify({'error': 'Sesión no válida'}), 401
            
            clave_temporal = f"user_{user_id}"
            datos_guardados = inspecciones_temporales.get(clave_temporal)
            
            if datos_guardados:
                return jsonify({
                    'data': datos_guardados['data'],
                    'timestamp': datos_guardados['timestamp'],
                    'encontrado': True
                })
            else:
                return jsonify({
                    'data': {},
                    'encontrado': False
                })
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def limpiar_inspeccion_temporal():
        """Borrar datos temporales al guardar la inspección"""
        try:
            user_id = session.get('user_id')
            
            if not user_id:
                return jsonify({'error': 'Sesión no válida'}), 401
            
            clave_temporal = f"user_{user_id}"
            
            # Limpiar datos temporales del usuario
            if clave_temporal in inspecciones_temporales:
                del inspecciones_temporales[clave_temporal]
            
            return jsonify({'mensaje': 'Datos temporales eliminados'})
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def obtener_datos_tiempo_real_encargado(establecimiento_id):
        """Obtener datos en tiempo real para que el encargado vea lo que califica el inspector"""
        try:
            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            datos = datos_tiempo_real.get(clave_tiempo_real, {})
            
            return jsonify({
                'encontrado': bool(datos),
                'datos': datos
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def obtener_datos_tiempo_real_establecimiento(establecimiento_id):
        """Obtener datos actuales de tiempo real para un establecimiento específico"""
        try:
            user_id = session.get('user_id')
            user_role = session.get('user_role')
            
            # Verificar permisos
            if user_role not in ['Encargado', 'Admin']:
                return jsonify({'error': 'Sin permisos para ver datos en tiempo real'}), 403
            
            clave_tiempo_real = f"establecimiento_{establecimiento_id}"
            datos = datos_tiempo_real.get(clave_tiempo_real, {})
            
            if datos:
                return jsonify(datos)
            else:
                return jsonify({})  # Retornar objeto vacío si no hay datos
        except Exception as e:
            return jsonify({'error': str(e)}), 500

    @staticmethod
    def _guardar_archivo(archivo, folder):
        if not os.path.exists(folder):
            os.makedirs(folder)
        
        filename = secure_filename(archivo.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{filename}"
        filepath = os.path.join(folder, filename)
        archivo.save(filepath)
        return filepath.replace('app/static/', '')

    @staticmethod
    def guardar_inspeccion():
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({'error': 'No se recibieron datos'}), 400
            
            # Validar datos requeridos
            establecimiento_id = data.get('establecimiento_id')
            inspector_id = session.get('user_id')
            fecha = data.get('fecha')
            observaciones = data.get('observaciones', '')
            items_data = data.get('items', {})
            accion = data.get('accion', 'guardar')  # guardar o completar
            
            if not all([establecimiento_id, inspector_id, fecha]):
                return jsonify({'error': 'Faltan datos requeridos'}), 400
            
            # Obtener encargado actual del establecimiento
            fecha_obj = datetime.strptime(fecha, '%Y-%m-%d').date()
            encargado = EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= fecha_obj,
                (EncargadoEstablecimiento.fecha_fin.is_(None) | 
                 (EncargadoEstablecimiento.fecha_fin >= fecha_obj))
            ).first()
            
            # Crear o actualizar la inspección
            inspeccion_id = data.get('inspeccion_id')
            
            if inspeccion_id:
                # Actualizar inspección existente
                inspeccion = Inspeccion.query.get(inspeccion_id)
                if not inspeccion:
                    return jsonify({'error': 'Inspección no encontrada'}), 404
            else:
                # Crear nueva inspección
                inspeccion = Inspeccion(
                    establecimiento_id=establecimiento_id,
                    inspector_id=inspector_id,
                    encargado_id=encargado.usuario_id if encargado else None,
                    fecha=fecha_obj
                )
                db.session.add(inspeccion)
                db.session.flush()  # Para obtener el ID
            
            # Actualizar datos básicos
            inspeccion.observaciones = observaciones
            inspeccion.estado = 'completada' if accion == 'completar' else 'en_proceso'
            
            if accion == 'completar':
                inspeccion.hora_fin = datetime.now().time()
            elif not inspeccion.hora_inicio:
                inspeccion.hora_inicio = datetime.now().time()
            
            # Guardar o actualizar detalles de items
            for item_id, item_data in items_data.items():
                rating = item_data.get('rating')
                observacion_item = item_data.get('observacion', '')
                
                if rating is not None:
                    # Buscar detalle existente
                    detalle = InspeccionDetalle.query.filter_by(
                        inspeccion_id=inspeccion.id,
                        item_establecimiento_id=item_id
                    ).first()
                    
                    if not detalle:
                        detalle = InspeccionDetalle(
                            inspeccion_id=inspeccion.id,
                            item_establecimiento_id=item_id
                        )
                        db.session.add(detalle)
                    
                    detalle.rating = rating
                    detalle.score = float(rating)  # Por ahora score = rating
                    detalle.observacion_item = observacion_item
                    
                    # Emitir actualización en tiempo real para que el encargado vea los cambios
                    try:
                        room = f"inspeccion_{inspeccion.id}"
                        socketio.emit('item_actualizado', {
                            'inspeccion_id': inspeccion.id,
                            'item_id': item_id,
                            'rating': rating,
                            'observacion': observacion_item,
                            'actualizado_por': session.get('user_role', 'Inspector'),
                            'timestamp': safe_timestamp()
                        }, to=room)
                    except Exception as e:
                        print(f"Error emitiendo actualización Socket.IO: {str(e)}")
            
            # Emitir actualización de observaciones generales si cambiaron
            if observaciones:
                try:
                    room = f"inspeccion_{inspeccion.id}"
                    socketio.emit('observaciones_actualizadas', {
                        'inspeccion_id': inspeccion.id,
                        'observaciones': observaciones,
                        'actualizado_por': session.get('user_role', 'Inspector'),
                        'timestamp': safe_timestamp()
                    }, to=room)
                except Exception as e:
                    print(f"Error emitiendo observaciones Socket.IO: {str(e)}")
            
            # Calcular puntajes automáticamente
            if accion == 'completar':
                puntajes = InspeccionesController.calcular_puntajes_inspeccion(inspeccion.id)
                
                # Emitir cambio de estado cuando se completa
                try:
                    room = f"inspeccion_{inspeccion.id}"
                    socketio.emit('estado_inspeccion_cambiado', {
                        'inspeccion_id': inspeccion.id,
                        'estado': 'completada',
                        'puntajes': puntajes,
                        'cambiado_por': session.get('user_role', 'Inspector'),
                        'timestamp': safe_timestamp()
                    }, to=room)
                except Exception as e:
                    print(f"Error emitiendo cambio estado Socket.IO: {str(e)}")
            
            db.session.commit()
            
            # Limpiar datos temporales
            if 'inspeccion_temporal' in session:
                del session['inspeccion_temporal']
            
            return jsonify({
                'mensaje': 'Inspección guardada exitosamente',
                'inspeccion_id': inspeccion.id,
                'estado': inspeccion.estado,
                'puntajes': puntajes if accion == 'completar' else None
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al guardar inspección: {str(e)}'}), 500

    @staticmethod
    def obtener_inspeccion(inspeccion_id):
        try:
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({'error': 'Inspección no encontrada'}), 404
            
            # Obtener detalles de la inspección
            detalles = db.session.query(
                InspeccionDetalle,
                ItemEvaluacionEstablecimiento,
                ItemEvaluacionBase,
                CategoriaEvaluacion
            ).join(
                ItemEvaluacionEstablecimiento,
                InspeccionDetalle.item_establecimiento_id == ItemEvaluacionEstablecimiento.id
            ).join(
                ItemEvaluacionBase,
                ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id
            ).join(
                CategoriaEvaluacion,
                ItemEvaluacionBase.categoria_id == CategoriaEvaluacion.id
            ).filter(
                InspeccionDetalle.inspeccion_id == inspeccion_id
            ).order_by(
                CategoriaEvaluacion.orden,
                ItemEvaluacionBase.orden
            ).all()
            
            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(inspeccion_id=inspeccion_id).all()
            
            # Formatear respuesta
            data = {
                'id': inspeccion.id,
                'establecimiento_id': inspeccion.establecimiento_id,
                'establecimiento_nombre': inspeccion.establecimiento.nombre,
                'inspector_id': inspeccion.inspector_id,
                'encargado_id': inspeccion.encargado_id,
                'fecha': inspeccion.fecha.isoformat(),
                'hora_inicio': inspeccion.hora_inicio.isoformat() if inspeccion.hora_inicio else None,
                'hora_fin': inspeccion.hora_fin.isoformat() if inspeccion.hora_fin else None,
                'observaciones': inspeccion.observaciones,
                'estado': inspeccion.estado,
                'puntaje_total': float(inspeccion.puntaje_total) if inspeccion.puntaje_total else None,
                'puntaje_maximo_posible': float(inspeccion.puntaje_maximo_posible) if inspeccion.puntaje_maximo_posible else None,
                'porcentaje_cumplimiento': float(inspeccion.porcentaje_cumplimiento) if inspeccion.porcentaje_cumplimiento else None,
                'puntos_criticos_perdidos': inspeccion.puntos_criticos_perdidos,
                'detalles': [],
                'evidencias': []
            }
            
            # Agregar detalles
            for detalle, item_est, item_base, categoria in detalles:
                data['detalles'].append({
                    'item_id': item_est.id,
                    'codigo': item_base.codigo,
                    'descripcion': item_est.descripcion_personalizada or item_base.descripcion,
                    'categoria': categoria.nombre,
                    'riesgo': item_base.riesgo,
                    'rating': detalle.rating,
                    'score': float(detalle.score) if detalle.score else None,
                    'observacion': detalle.observacion_item
                })
            
            # Agregar evidencias
            for evidencia in evidencias:
                data['evidencias'].append({
                    'id': evidencia.id,
                    'filename': evidencia.filename,
                    'ruta_archivo': evidencia.ruta_archivo,
                    'descripcion': evidencia.descripcion,
                    'mime_type': evidencia.mime_type
                })
            
            return jsonify(data)
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener inspección: {str(e)}'}), 500

    @staticmethod
    def obtener_encargado_actual(establecimiento_id):
        try:
            fecha_actual = date.today()
            encargado = EncargadoEstablecimiento.query.filter(
                EncargadoEstablecimiento.establecimiento_id == establecimiento_id,
                EncargadoEstablecimiento.activo == True,
                EncargadoEstablecimiento.fecha_inicio <= fecha_actual,
                (EncargadoEstablecimiento.fecha_fin.is_(None) | 
                 (EncargadoEstablecimiento.fecha_fin >= fecha_actual))
            ).order_by(
                EncargadoEstablecimiento.es_principal.desc(),
                EncargadoEstablecimiento.fecha_inicio.desc()
            ).first()
            
            if not encargado:
                return jsonify({'error': 'No hay encargado asignado para este establecimiento'}), 404
            
            return jsonify({
                'id': encargado.usuario.id,
                'nombre': f"{encargado.usuario.nombre} {encargado.usuario.apellido or ''}".strip(),
                'correo': encargado.usuario.correo,
                'telefono': encargado.usuario.telefono,
                'es_principal': encargado.es_principal
            })
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener encargado: {str(e)}'}), 500

    @staticmethod
    def filtrar_inspecciones(fecha_inicio=None, fecha_fin=None, establecimiento_id=None, 
                            inspector_id=None, encargado_id=None, estado=None):
        """Filtrar inspecciones según criterios del pedido.txt"""
        try:
            query = Inspeccion.query
            
            # Aplicar filtros
            if fecha_inicio:
                query = query.filter(Inspeccion.fecha >= fecha_inicio)
            if fecha_fin:
                query = query.filter(Inspeccion.fecha <= fecha_fin)
            if establecimiento_id:
                query = query.filter(Inspeccion.establecimiento_id == establecimiento_id)
            if inspector_id:
                query = query.filter(Inspeccion.inspector_id == inspector_id)
            if encargado_id:
                query = query.filter(Inspeccion.encargado_id == encargado_id)
            if estado:
                query = query.filter(Inspeccion.estado == estado)
            
            # Verificar permisos según rol
            user_role = session.get('user_role')
            user_id = session.get('user_id')
            
            if user_role == 'Inspector':
                # Solo inspecciones del inspector
                query = query.filter(Inspeccion.inspector_id == user_id)
            elif user_role == 'Encargado':
                # Solo inspecciones de sus establecimientos
                query = query.filter(Inspeccion.encargado_id == user_id)
            # Admin puede ver todas
            
            inspecciones = query.order_by(Inspeccion.fecha.desc()).all()
            
            data = []
            for inspeccion in inspecciones:
                data.append({
                    'id': inspeccion.id,
                    'fecha': inspeccion.fecha.isoformat(),
                    'establecimiento': inspeccion.establecimiento.nombre,
                    'inspector': f"{inspeccion.inspector.nombre} {inspeccion.inspector.apellido or ''}".strip(),
                    'encargado': f"{inspeccion.encargado.nombre} {inspeccion.encargado.apellido or ''}".strip() if inspeccion.encargado else None,
                    'estado': inspeccion.estado,
                    'puntaje_total': float(inspeccion.puntaje_total) if inspeccion.puntaje_total else None,
                    'porcentaje_cumplimiento': float(inspeccion.porcentaje_cumplimiento) if inspeccion.porcentaje_cumplimiento else None
                })
            
            return jsonify(data)
            
        except Exception as e:
            return jsonify({'error': f'Error al filtrar inspecciones: {str(e)}'}), 500

    @staticmethod
    def actualizar_item_tiempo_real():
        """Endpoint para actualizaciones en tiempo real sin guardar en BD"""
        try:
            data = request.get_json()
            inspeccion_id = data.get('inspeccion_id')
            item_id = data.get('item_id')
            rating = data.get('rating')
            observacion = data.get('observacion', '')
            
            if not all([inspeccion_id, item_id, rating is not None]):
                return jsonify({'error': 'Datos incompletos'}), 400
            
            # Emitir actualización en tiempo real
            room = f"inspeccion_{inspeccion_id}"
            socketio.emit('item_actualizado', {
                'inspeccion_id': inspeccion_id,
                'item_id': item_id,
                'rating': rating,
                'observacion': observacion,
                'actualizado_por': session.get('user_role', 'Inspector'),
                'timestamp': safe_timestamp()
            }, to=room)
            
            return jsonify({'mensaje': 'Actualización enviada en tiempo real'})
            
        except Exception as e:
            return jsonify({'error': f'Error en actualización tiempo real: {str(e)}'}), 500

    # =========================
    # FUNCIONES DE ADMINISTRADOR
    # =========================
    
    @staticmethod
    def editar_puntuacion_inspeccion():
        """Permite al admin editar puntuaciones de cualquier inspección"""
        try:
            data = request.get_json()
            inspeccion_id = data.get('inspeccion_id')
            item_id = data.get('item_id')
            nueva_puntuacion = data.get('puntuacion')
            observacion = data.get('observacion', '')
            
            if not all([inspeccion_id, item_id, nueva_puntuacion is not None]):
                return jsonify({'error': 'Datos incompletos'}), 400
            
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({'error': 'No autorizado'}), 403
            
            # Buscar el detalle de inspección
            detalle = InspeccionDetalle.query.filter_by(
                inspeccion_id=inspeccion_id,
                item_establecimiento_id=item_id
            ).first()
            
            if not detalle:
                return jsonify({'error': 'Detalle de inspección no encontrado'}), 404
            
            # Actualizar puntuación
            detalle.rating = nueva_puntuacion
            detalle.score = float(nueva_puntuacion)
            detalle.observacion_item = observacion
            
            # Recalcular puntajes totales
            puntajes = InspeccionesController.calcular_puntajes_inspeccion(inspeccion_id)
            
            db.session.commit()
            
            return jsonify({
                'mensaje': 'Puntuación actualizada exitosamente',
                'puntajes': puntajes
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al editar puntuación: {str(e)}'}), 500

    @staticmethod
    def crear_establecimiento():
        """Permite al admin crear nuevos establecimientos"""
        try:
            data = request.get_json()
            nombre = data.get('nombre')
            direccion = data.get('direccion')
            tipo_establecimiento_id = data.get('tipo_establecimiento_id')
            telefono = data.get('telefono', '')
            correo = data.get('correo', '')
            
            if not all([nombre, direccion, tipo_establecimiento_id]):
                return jsonify({'error': 'Faltan datos requeridos'}), 400
            
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({'error': 'No autorizado'}), 403
            
            # Crear establecimiento
            establecimiento = Establecimiento(
                nombre=nombre,
                direccion=direccion,
                tipo_establecimiento_id=tipo_establecimiento_id,
                telefono=telefono,
                correo=correo,
                activo=True
            )
            
            db.session.add(establecimiento)
            db.session.commit()
            
            return jsonify({
                'mensaje': 'Establecimiento creado exitosamente',
                'establecimiento_id': establecimiento.id
            })
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al crear establecimiento: {str(e)}'}), 500

    @staticmethod
    def eliminar_establecimiento():
        """Permite al admin eliminar establecimientos"""
        try:
            data = request.get_json()
            establecimiento_id = data.get('establecimiento_id')
            
            if not establecimiento_id:
                return jsonify({'error': 'ID de establecimiento requerido'}), 400
            
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({'error': 'No autorizado'}), 403
            
            establecimiento = Establecimiento.query.get(establecimiento_id)
            if not establecimiento:
                return jsonify({'error': 'Establecimiento no encontrado'}), 404
            
            # Soft delete - marcar como inactivo
            establecimiento.activo = False
            db.session.commit()
            
            return jsonify({'mensaje': 'Establecimiento eliminado exitosamente'})
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al eliminar establecimiento: {str(e)}'}), 500

    @staticmethod
    def actualizar_rol_usuario():
        """Permite al admin cambiar roles de usuarios"""
        try:
            data = request.get_json()
            usuario_id = data.get('usuario_id')
            nuevo_rol_id = data.get('rol_id')
            
            if not all([usuario_id, nuevo_rol_id]):
                return jsonify({'error': 'Datos incompletos'}), 400
            
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({'error': 'No autorizado'}), 403
            
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({'error': 'Usuario no encontrado'}), 404
            
            rol = Rol.query.get(nuevo_rol_id)
            if not rol:
                return jsonify({'error': 'Rol no encontrado'}), 404
            
            usuario.rol_id = nuevo_rol_id
            db.session.commit()
            
            return jsonify({'mensaje': f'Rol actualizado a {rol.nombre} exitosamente'})
            
        except Exception as e:
            db.session.rollback()
            return jsonify({'error': f'Error al actualizar rol: {str(e)}'}), 500

    @staticmethod
    def obtener_todos_los_usuarios():
        """Obtener lista de todos los usuarios para administración"""
        try:
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({'error': 'No autorizado'}), 403
            
            usuarios = db.session.query(Usuario, Rol).join(Rol).all()
            
            data = []
            for usuario, rol in usuarios:
                data.append({
                    'id': usuario.id,
                    'nombre': usuario.nombre,
                    'apellido': usuario.apellido,
                    'correo': usuario.correo,
                    'telefono': usuario.telefono,
                    'rol_id': rol.id,
                    'rol_nombre': rol.nombre,
                    'activo': usuario.activo,
                    'fecha_creacion': usuario.fecha_creacion.isoformat() if usuario.fecha_creacion else None
                })
            
            return jsonify(data)
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener usuarios: {str(e)}'}), 500

    @staticmethod
    def obtener_tipos_establecimiento():
        """Obtener tipos de establecimiento disponibles"""
        try:
            tipos = TipoEstablecimiento.query.filter_by(activo=True).all()
            
            data = [{
                'id': tipo.id,
                'nombre': tipo.nombre,
                'descripcion': tipo.descripcion
            } for tipo in tipos]
            
            return jsonify(data)
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener tipos: {str(e)}'}), 500

    @staticmethod
    def obtener_inspeccion_completa(inspeccion_id):
        """Obtener inspección completa con todos los detalles"""
        try:
            # Obtener la inspección
            inspeccion = Inspeccion.query.get(inspeccion_id)
            if not inspeccion:
                return jsonify({'error': 'Inspección no encontrada'}), 404
            
            # Obtener el establecimiento
            establecimiento = Establecimiento.query.get(inspeccion.establecimiento_id)
            
            # Obtener el inspector
            inspector = Usuario.query.get(inspeccion.inspector_id) if inspeccion.inspector_id else None
            
            # Obtener el encargado
            encargado = Usuario.query.get(inspeccion.encargado_id) if inspeccion.encargado_id else None
            
            # Obtener detalles de la inspección
            detalles = InspeccionDetalle.query.filter_by(inspeccion_id=inspeccion_id).all()
            
            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(inspeccion_id=inspeccion_id).all()
            
            # Organizar datos
            data = {
                'id': inspeccion.id,
                'fecha': inspeccion.fecha.isoformat(),
                'estado': inspeccion.estado,
                'observaciones': inspeccion.observaciones,
                'puntaje_total': float(inspeccion.puntaje_total or 0),
                'puntaje_maximo_posible': float(inspeccion.puntaje_maximo_posible or 0),
                'porcentaje_cumplimiento': float(inspeccion.porcentaje_cumplimiento or 0),
                'puntos_criticos_perdidos': float(inspeccion.puntos_criticos_perdidos or 0),
                'fecha_creacion': inspeccion.fecha_creacion.isoformat() if inspeccion.fecha_creacion else None,
                'fecha_completada': inspeccion.fecha_completada.isoformat() if inspeccion.fecha_completada else None,
                
                'establecimiento': {
                    'id': establecimiento.id,
                    'nombre': establecimiento.nombre,
                    'direccion': establecimiento.direccion,
                    'telefono': establecimiento.telefono
                } if establecimiento else None,
                
                'inspector': {
                    'id': inspector.id,
                    'nombre': f"{inspector.nombre} {inspector.apellido or ''}".strip(),
                    'correo': inspector.correo
                } if inspector else None,
                
                'encargado': {
                    'id': encargado.id,
                    'nombre': f"{encargado.nombre} {encargado.apellido or ''}".strip(),
                    'correo': encargado.correo
                } if encargado else None,
                
                'detalles': [{
                    'item_id': detalle.item_evaluacion_id,
                    'puntaje_obtenido': float(detalle.puntaje_obtenido or 0),
                    'observacion_item': detalle.observacion_item,
                    'item': {
                        'codigo': detalle.item_evaluacion.codigo if detalle.item_evaluacion else None,
                        'descripcion': detalle.item_evaluacion.descripcion if detalle.item_evaluacion else None,
                        'puntaje_maximo': float(detalle.item_evaluacion.puntaje_maximo or 0) if detalle.item_evaluacion else 0
                    }
                } for detalle in detalles],
                
                'evidencias': [{
                    'id': evidencia.id,
                    'descripcion': evidencia.descripcion,
                    'ruta_archivo': evidencia.ruta_archivo,
                    'fecha_subida': evidencia.fecha_subida.isoformat() if evidencia.fecha_subida else None
                } for evidencia in evidencias],
                
                'firmas': {
                    'inspector': {
                        'ruta': inspeccion.firma_inspector,
                        'fecha': inspeccion.fecha_firma_inspector.isoformat() if inspeccion.fecha_firma_inspector else None
                    } if inspeccion.firma_inspector else None,
                    'encargado': {
                        'ruta': inspeccion.firma_encargado,
                        'fecha': inspeccion.fecha_firma_encargado.isoformat() if inspeccion.fecha_firma_encargado else None
                    } if inspeccion.firma_encargado else None
                }
            }
            
            return jsonify(data)
            
        except Exception as e:
            return jsonify({'error': f'Error al obtener inspección: {str(e)}'}), 500

    @staticmethod
    def buscar_inspecciones():
        """Buscar inspecciones con filtros"""
        try:
            user_id = session.get('user_id')
            user_role = session.get('user_role')
            
            # Parámetros de filtro
            establecimiento_id = request.args.get('establecimiento_id')
            fecha_desde = request.args.get('fecha_desde')
            fecha_hasta = request.args.get('fecha_hasta')
            estado = request.args.get('estado')
            
            # Construir query base
            query = db.session.query(
                Inspeccion.id,
                Inspeccion.fecha,
                Inspeccion.estado,
                Inspeccion.puntaje_total,
                Inspeccion.puntaje_maximo_posible,
                Inspeccion.porcentaje_cumplimiento,
                Inspeccion.observaciones,
                Establecimiento.nombre.label('establecimiento_nombre'),
                Usuario.nombre.label('inspector_nombre')
            ).join(
                Establecimiento, Inspeccion.establecimiento_id == Establecimiento.id
            ).outerjoin(
                Usuario, Inspeccion.inspector_id == Usuario.id
            )
            
            # Filtros de permisos según rol
            if user_role == 'Inspector':
                query = query.filter(Inspeccion.inspector_id == user_id)
            elif user_role == 'Encargado':
                # El encargado solo ve inspecciones de su establecimiento
                encargado_establecimiento = EncargadoEstablecimiento.query.filter_by(
                    usuario_id=user_id
                ).first()
                if encargado_establecimiento:
                    query = query.filter(Inspeccion.establecimiento_id == encargado_establecimiento.establecimiento_id)
                else:
                    return jsonify([])  # No hay establecimientos asignados
            
            # Aplicar filtros de búsqueda
            if establecimiento_id:
                query = query.filter(Inspeccion.establecimiento_id == establecimiento_id)
            
            if fecha_desde:
                query = query.filter(Inspeccion.fecha >= fecha_desde)
            
            if fecha_hasta:
                query = query.filter(Inspeccion.fecha <= fecha_hasta)
            
            if estado:
                query = query.filter(Inspeccion.estado == estado)
            
            # Ordenar por fecha descendente
            query = query.order_by(Inspeccion.fecha.desc())
            
            # Ejecutar query
            inspecciones = query.all()
            
            # Convertir a diccionario
            resultado = []
            for insp in inspecciones:
                # Contar items evaluados
                items_evaluados = db.session.query(InspeccionDetalle).filter_by(
                    inspeccion_id=insp.id
                ).count()
                
                resultado.append({
                    'id': insp.id,
                    'fecha': insp.fecha.isoformat() if insp.fecha else None,
                    'estado': insp.estado,
                    'puntaje_total': insp.puntaje_total,
                    'puntaje_maximo': insp.puntaje_maximo_posible,
                    'porcentaje_cumplimiento': insp.porcentaje_cumplimiento,
                    'observaciones': insp.observaciones,
                    'establecimiento_nombre': insp.establecimiento_nombre,
                    'inspector_nombre': insp.inspector_nombre,
                    'items_evaluados': items_evaluados
                })
            
            return jsonify(resultado)
            
        except Exception as e:
            return jsonify({'error': f'Error en búsqueda: {str(e)}'}), 500

    @staticmethod
    def obtener_detalle_inspeccion(inspeccion_id):
        """Obtener detalle completo de una inspección"""
        try:
            user_id = session.get('user_id')
            user_role = session.get('user_role')
            
            # Buscar la inspección
            inspeccion = Inspeccion.query.get_or_404(inspeccion_id)
            
            # Verificar permisos
            if user_role == 'Inspector' and inspeccion.inspector_id != user_id:
                return jsonify({'error': 'Sin permisos para ver esta inspección'}), 403
            elif user_role == 'Encargado':
                encargado_establecimiento = EncargadoEstablecimiento.query.filter_by(
                    usuario_id=user_id,
                    establecimiento_id=inspeccion.establecimiento_id
                ).first()
                if not encargado_establecimiento:
                    return jsonify({'error': 'Sin permisos para ver esta inspección'}), 403
            
            # Obtener datos relacionados
            establecimiento = Establecimiento.query.get(inspeccion.establecimiento_id)
            inspector = Usuario.query.get(inspeccion.inspector_id) if inspeccion.inspector_id else None
            
            # Obtener detalles de items
            detalles = db.session.query(
                InspeccionDetalle.rating,
                InspeccionDetalle.score,
                ItemEvaluacionEstablecimiento.factor_ajuste,
                ItemEvaluacionBase.descripcion,
                ItemEvaluacionBase.riesgo,
                ItemEvaluacionBase.puntaje_maximo
            ).join(
                ItemEvaluacionEstablecimiento,
                InspeccionDetalle.item_establecimiento_id == ItemEvaluacionEstablecimiento.id
            ).join(
                ItemEvaluacionBase,
                ItemEvaluacionEstablecimiento.item_base_id == ItemEvaluacionBase.id
            ).filter(
                InspeccionDetalle.inspeccion_id == inspeccion_id
            ).all()
            
            # Obtener evidencias
            evidencias = EvidenciaInspeccion.query.filter_by(
                inspeccion_id=inspeccion_id
            ).all()
            
            # Obtener total de items disponibles para el establecimiento
            total_items_disponibles = ItemEvaluacionEstablecimiento.query.filter_by(
                establecimiento_id=inspeccion.establecimiento_id
            ).count()
            
            resultado = {
                'id': inspeccion.id,
                'fecha': inspeccion.fecha.isoformat() if inspeccion.fecha else None,
                'estado': inspeccion.estado,
                'puntaje_total': inspeccion.puntaje_total,
                'puntaje_maximo': inspeccion.puntaje_maximo_posible,
                'porcentaje_cumplimiento': inspeccion.porcentaje_cumplimiento,
                'observaciones': inspeccion.observaciones,
                'establecimiento_nombre': establecimiento.nombre if establecimiento else None,
                'inspector_nombre': inspector.nombre if inspector else None,
                'items_evaluados': len(detalles),
                'total_items': total_items_disponibles,
                'detalles_items': [
                    {
                        'descripcion': detalle.descripcion,
                        'riesgo': detalle.riesgo,
                        'puntaje_maximo': detalle.puntaje_maximo,
                        'factor_ajuste': float(detalle.factor_ajuste),
                        'rating': detalle.rating,
                        'score': float(detalle.score) if detalle.score else 0
                    } for detalle in detalles
                ],
                'evidencias': [
                    {
                        'nombre_archivo': evidencia.filename,
                        'ruta_archivo': evidencia.ruta_archivo,
                        'descripcion': evidencia.descripcion
                    } for evidencia in evidencias
                ]
            }
            
            return jsonify(resultado)
            
        except Exception as e:
            return jsonify({'error': f'Error obteniendo detalle: {str(e)}'}), 500
