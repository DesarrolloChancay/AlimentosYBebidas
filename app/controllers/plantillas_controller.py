"""
Controlador para gestionar plantillas de checklists y creación de establecimientos
"""
from flask import render_template, request, jsonify, session, redirect, url_for, flash
from app.models.Plantillas_models import PlantillaChecklist, ItemPlantillaChecklist
from app.models.Inspecciones_models import (
    Establecimiento, ItemEvaluacionEstablecimiento, ItemEvaluacionBase, InspectorEstablecimiento, CategoriaEvaluacion
)
from app.models.Usuario_models import Usuario, TipoEstablecimiento
from app.models.Usuario_models import Usuario
from app.extensions import db
from datetime import datetime
import traceback
import json


class PlantillasController:
    """
    Controlador para gestionar plantillas de checklists
    """

    @staticmethod
    def listar_plantillas():
        """
        Mostrar lista de plantillas disponibles para inspectores

        Returns:
            Template renderizado con las plantillas
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                flash('Debe iniciar sesión', 'error')
                return redirect(url_for('auth.login'))

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                flash('No tiene permisos para acceder a esta sección', 'error')
                return redirect(url_for('auth.login'))

            # Obtener plantillas activas agrupadas por tipo de establecimiento
            plantillas = PlantillaChecklist.query.filter_by(activo=True)\
                .join(TipoEstablecimiento)\
                .order_by(TipoEstablecimiento.nombre, PlantillaChecklist.tamano_local)\
                .all()

            # Agrupar plantillas por tipo de establecimiento
            plantillas_por_tipo = {}
            for plantilla in plantillas:
                tipo_nombre = plantilla.tipo_establecimiento.nombre
                if tipo_nombre not in plantillas_por_tipo:
                    plantillas_por_tipo[tipo_nombre] = []
                plantillas_por_tipo[tipo_nombre].append(plantilla)

            return render_template('inspector_plantillas.html',
                                 plantillas_por_tipo=plantillas_por_tipo,
                                 current_user=usuario)

        except Exception as e:
            print(f"Error al listar plantillas: {str(e)}")
            traceback.print_exc()
            flash('Error al cargar las plantillas', 'error')
            return redirect(url_for('inspeccion.dashboard_page'))

    @staticmethod
    def ver_plantilla(plantilla_id):
        """
        Ver detalles de una plantilla específica

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            Template renderizado con detalles de la plantilla
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                flash('Debe iniciar sesión', 'error')
                return redirect(url_for('auth.login'))

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                flash('No tiene permisos para acceder a esta sección', 'error')
                return redirect(url_for('auth.login'))

            # Obtener plantilla con sus items
            plantilla = PlantillaChecklist.query.get_or_404(plantilla_id)

            # Obtener items de la plantilla ordenados
            items_plantilla = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla_id, activo=True)\
                .join(ItemEvaluacionBase)\
                .join(ItemEvaluacionBase.categoria)\
                .order_by(ItemEvaluacionBase.categoria_id, ItemPlantillaChecklist.orden)\
                .all()

            # Agrupar items por categoría
            items_por_categoria = {}
            for item in items_plantilla:
                categoria_nombre = item.item_base.categoria.nombre
                if categoria_nombre not in items_por_categoria:
                    items_por_categoria[categoria_nombre] = []
                items_por_categoria[categoria_nombre].append(item)

            return render_template('inspector_plantilla_detalle.html',
                                 plantilla=plantilla,
                                 items_por_categoria=items_por_categoria,
                                 current_user=usuario)

        except Exception as e:
            print(f"Error al ver plantilla: {str(e)}")
            traceback.print_exc()
            flash('Error al cargar la plantilla', 'error')
            return redirect(url_for('plantillas.listar_plantillas'))

    @staticmethod
    def crear_establecimiento_desde_plantilla(plantilla_id):
        """
        Mostrar interfaz para gestionar items antes de crear establecimiento desde plantilla

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            Template renderizado con interfaz de gestión de items
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                flash('Debe iniciar sesión', 'error')
                return redirect(url_for('auth.login'))

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                flash('No tiene permisos para acceder a esta sección', 'error')
                return redirect(url_for('auth.login'))

            # Obtener plantilla con sus items
            plantilla = PlantillaChecklist.query.get_or_404(plantilla_id)

            # Obtener items de la plantilla ordenados por categoría
            items_plantilla = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla_id, activo=True)\
                .join(ItemEvaluacionBase)\
                .join(ItemEvaluacionBase.categoria)\
                .order_by(CategoriaEvaluacion.orden, ItemPlantillaChecklist.orden)\
                .all()

            # Agrupar items por categoría para mostrarlos organizados
            items_por_categoria = {}
            for item in items_plantilla:
                categoria_nombre = item.item_base.categoria.nombre
                if categoria_nombre not in items_por_categoria:
                    items_por_categoria[categoria_nombre] = []
                items_por_categoria[categoria_nombre].append(item)

            # Obtener tipos de establecimiento para el formulario final
            tipos_establecimiento = TipoEstablecimiento.query.filter_by(activo=True)\
                .order_by(TipoEstablecimiento.nombre).all()

            return render_template('inspector_gestionar_items_creacion.html',
                                 plantilla=plantilla,
                                 items_por_categoria=items_por_categoria,
                                 tipos_establecimiento=tipos_establecimiento,
                                 current_user=usuario)

        except Exception as e:
            print(f"Error al mostrar interfaz de gestión: {str(e)}")
            traceback.print_exc()
            flash('Error al cargar la interfaz de gestión', 'error')
            return redirect(url_for('plantillas.listar_plantillas'))

    @staticmethod
    def guardar_establecimiento_desde_plantilla():
        """
        Crear establecimiento y su checklist desde una plantilla principal y plantillas adicionales

        Request Form Data:
            - plantilla_id: ID de la plantilla principal
            - plantillas_adicionales: JSON string con IDs de plantillas adicionales
            - nombre: Nombre del establecimiento
            - tipo_establecimiento_id: ID del tipo de establecimiento
            - direccion: Dirección (opcional)
            - telefono: Teléfono (opcional)
            - correo: Correo electrónico (opcional)

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para esta operación'
                }), 403

            # Obtener datos del formulario
            plantilla_id = request.form.get('plantilla_id')
            plantillas_adicionales_json = request.form.get('plantillas_adicionales', '[]')
            nombre = request.form.get('nombre', '').strip()
            tipo_establecimiento_id = request.form.get('tipo_establecimiento_id')
            direccion = request.form.get('direccion', '').strip()
            telefono = request.form.get('telefono', '').strip()
            correo = request.form.get('correo', '').strip()

            # Validaciones
            if not plantilla_id or not nombre or not tipo_establecimiento_id:
                return jsonify({
                    'success': False,
                    'message': 'Datos incompletos. Nombre, tipo de establecimiento y plantilla principal son obligatorios.'
                }), 400

            # Verificar que la plantilla principal existe
            plantilla_principal = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla_principal or not plantilla_principal.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla principal no encontrada o inactiva'
                }), 404

            # Parsear plantillas adicionales
            try:
                plantillas_adicionales_ids = json.loads(plantillas_adicionales_json)
            except json.JSONDecodeError:
                plantillas_adicionales_ids = []

            # Verificar plantillas adicionales
            plantillas_adicionales = []
            for pid in plantillas_adicionales_ids:
                plantilla = PlantillaChecklist.query.get(pid)
                if plantilla and plantilla.activo:
                    plantillas_adicionales.append(plantilla)
                else:
                    return jsonify({
                        'success': False,
                        'message': f'Plantilla adicional con ID {pid} no encontrada o inactiva'
                    }), 404

            # Verificar que el tipo de establecimiento existe
            tipo_establecimiento = TipoEstablecimiento.query.get(tipo_establecimiento_id)
            if not tipo_establecimiento or not tipo_establecimiento.activo:
                return jsonify({
                    'success': False,
                    'message': 'Tipo de establecimiento no encontrado o inactivo'
                }), 404

            # Crear establecimiento
            establecimiento = Establecimiento(
                nombre=nombre,
                tipo_establecimiento_id=tipo_establecimiento_id,
                direccion=direccion if direccion else None,
                telefono=telefono if telefono else None,
                correo=correo if correo else None,
                activo=True
            )

            db.session.add(establecimiento)
            db.session.flush()  # Para obtener el ID

            total_items = 0

            # Crear items de evaluación desde la plantilla principal
            items_principal = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla_id, activo=True)\
                .all()

            for item_plantilla in items_principal:
                item_establecimiento = ItemEvaluacionEstablecimiento(
                    establecimiento_id=establecimiento.id,
                    item_base_id=item_plantilla.item_base_id,
                    descripcion_personalizada=item_plantilla.descripcion_personalizada,
                    factor_ajuste=item_plantilla.factor_ajuste,
                    activo=True
                )
                db.session.add(item_establecimiento)

            total_items += len(items_principal)

            # Crear items de evaluación desde plantillas adicionales
            for plantilla_adicional in plantillas_adicionales:
                items_adicionales = ItemPlantillaChecklist.query\
                    .filter_by(plantilla_id=plantilla_adicional.id, activo=True)\
                    .all()

                for item_plantilla in items_adicionales:
                    # Verificar que no se duplique el item (mismo item_base_id)
                    existing_item = ItemEvaluacionEstablecimiento.query\
                        .filter_by(
                            establecimiento_id=establecimiento.id,
                            item_base_id=item_plantilla.item_base_id
                        ).first()

                    if not existing_item:
                        item_establecimiento = ItemEvaluacionEstablecimiento(
                            establecimiento_id=establecimiento.id,
                            item_base_id=item_plantilla.item_base_id,
                            descripcion_personalizada=item_plantilla.descripcion_personalizada,
                            factor_ajuste=item_plantilla.factor_ajuste,
                            activo=True
                        )
                        db.session.add(item_establecimiento)
                        total_items += 1

            # Asignar inspector al establecimiento
            inspector_asignacion = InspectorEstablecimiento(
                inspector_id=usuario_id,
                establecimiento_id=establecimiento.id,
                fecha_asignacion=datetime.now().date(),
                es_principal=True,
                activo=True
            )
            db.session.add(inspector_asignacion)

            # Confirmar cambios
            db.session.commit()

            # Preparar mensaje con detalles
            plantillas_usadas = [plantilla_principal.nombre] + [p.nombre for p in plantillas_adicionales]
            mensaje = f'Establecimiento "{nombre}" creado exitosamente con {total_items} items de evaluación desde {len(plantillas_usadas)} plantillas: {", ".join(plantillas_usadas)}'

            return jsonify({
                'success': True,
                'message': mensaje,
                'establecimiento_id': establecimiento.id,
                'total_items': total_items,
                'plantillas_usadas': len(plantillas_usadas)
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al crear establecimiento: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al crear el establecimiento'
            }), 500

    @staticmethod
    def finalizar_creacion_establecimiento(plantilla_id):
        """
        Mostrar formulario final para crear establecimiento con items personalizados

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            Template con formulario final
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                flash('Debe iniciar sesión', 'error')
                return redirect(url_for('auth.login'))

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                flash('No tiene permisos para acceder a esta sección', 'error')
                return redirect(url_for('auth.login'))

            # Obtener plantilla
            plantilla = PlantillaChecklist.query.get_or_404(plantilla_id)

            # Obtener tipos de establecimiento
            tipos_establecimiento = TipoEstablecimiento.query.filter_by(activo=True)\
                .order_by(TipoEstablecimiento.nombre).all()

            return render_template('inspector_finalizar_creacion.html',
                                 plantilla=plantilla,
                                 tipos_establecimiento=tipos_establecimiento,
                                 current_user=usuario)

        except Exception as e:
            print(f"Error al mostrar formulario final: {str(e)}")
            traceback.print_exc()
            flash('Error al cargar el formulario final', 'error')
            return redirect(url_for('plantillas.listar_plantillas'))

    @staticmethod
    def guardar_establecimiento_con_items_personalizados():
        """
        Crear establecimiento con selección personalizada de items

        Request Form Data:
            - plantilla_id: ID de la plantilla principal
            - nombre: Nombre del establecimiento
            - tipo_establecimiento_id: ID del tipo de establecimiento
            - direccion: Dirección (opcional)
            - telefono: Teléfono (opcional)
            - correo: Correo electrónico (opcional)
            - items_seleccionados: JSON con IDs de items de plantilla seleccionados
            - items_adicionales: JSON con IDs de items base adicionales

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para esta operación'
                }), 403

            # Obtener datos del formulario
            plantilla_id = request.form.get('plantilla_id')
            nombre = request.form.get('nombre', '').strip()
            tipo_establecimiento_id = request.form.get('tipo_establecimiento_id')
            direccion = request.form.get('direccion', '').strip()
            telefono = request.form.get('telefono', '').strip()
            correo = request.form.get('correo', '').strip()
            items_seleccionados_json = request.form.get('items_seleccionados', '[]')
            items_adicionales_json = request.form.get('items_adicionales', '[]')

            # Validaciones
            if not plantilla_id or not nombre or not tipo_establecimiento_id:
                return jsonify({
                    'success': False,
                    'message': 'Datos incompletos. Nombre, tipo de establecimiento y plantilla son obligatorios.'
                }), 400

            # Parsear selección de items
            try:
                items_seleccionados_ids = json.loads(items_seleccionados_json)
                items_adicionales_ids = json.loads(items_adicionales_json)
            except json.JSONDecodeError:
                return jsonify({
                    'success': False,
                    'message': 'Error en el formato de los datos de items seleccionados'
                }), 400

            # Verificar que hay al menos un item seleccionado
            if not items_seleccionados_ids and not items_adicionales_ids:
                return jsonify({
                    'success': False,
                    'message': 'Debes seleccionar al menos un item para el establecimiento'
                }), 400

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla or not plantilla.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada o inactiva'
                }), 404

            # Verificar que el tipo de establecimiento existe
            tipo_establecimiento = TipoEstablecimiento.query.get(tipo_establecimiento_id)
            if not tipo_establecimiento or not tipo_establecimiento.activo:
                return jsonify({
                    'success': False,
                    'message': 'Tipo de establecimiento no encontrado o inactivo'
                }), 404

            # Verificar items de plantilla seleccionados
            items_plantilla_seleccionados = []
            if items_seleccionados_ids:
                items_plantilla_seleccionados = ItemPlantillaChecklist.query\
                    .filter(
                        ItemPlantillaChecklist.id.in_(items_seleccionados_ids),
                        ItemPlantillaChecklist.plantilla_id == plantilla_id,
                        ItemPlantillaChecklist.activo == True
                    ).all()

                if len(items_plantilla_seleccionados) != len(items_seleccionados_ids):
                    return jsonify({
                        'success': False,
                        'message': 'Algunos items de plantilla seleccionados no son válidos'
                    }), 400

            # Verificar items base adicionales
            items_base_adicionales = []
            if items_adicionales_ids:
                items_base_adicionales = ItemEvaluacionBase.query\
                    .filter(
                        ItemEvaluacionBase.id.in_(items_adicionales_ids),
                        ItemEvaluacionBase.activo == True
                    ).all()

                if len(items_base_adicionales) != len(items_adicionales_ids):
                    return jsonify({
                        'success': False,
                        'message': 'Algunos items adicionales no son válidos'
                    }), 400

            # Crear establecimiento
            establecimiento = Establecimiento(
                nombre=nombre,
                tipo_establecimiento_id=tipo_establecimiento_id,
                direccion=direccion if direccion else None,
                telefono=telefono if telefono else None,
                correo=correo if correo else None,
                activo=True
            )

            db.session.add(establecimiento)
            db.session.flush()  # Para obtener el ID

            total_items = 0

            # Crear items de evaluación desde items de plantilla seleccionados
            for item_plantilla in items_plantilla_seleccionados:
                item_establecimiento = ItemEvaluacionEstablecimiento(
                    establecimiento_id=establecimiento.id,
                    item_base_id=item_plantilla.item_base_id,
                    descripcion_personalizada=item_plantilla.descripcion_personalizada,
                    factor_ajuste=item_plantilla.factor_ajuste,
                    activo=True
                )
                db.session.add(item_establecimiento)
                total_items += 1

            # Crear items de evaluación desde items base adicionales
            for item_base in items_base_adicionales:
                # Verificar que no se duplique con items de plantilla
                existing_item = ItemEvaluacionEstablecimiento.query\
                    .filter_by(
                        establecimiento_id=establecimiento.id,
                        item_base_id=item_base.id
                    ).first()

                if not existing_item:
                    item_establecimiento = ItemEvaluacionEstablecimiento(
                        establecimiento_id=establecimiento.id,
                        item_base_id=item_base.id,
                        descripcion_personalizada=None,
                        factor_ajuste=1.0,
                        activo=True
                    )
                    db.session.add(item_establecimiento)
                    total_items += 1

            # Asignar inspector al establecimiento
            inspector_asignacion = InspectorEstablecimiento(
                inspector_id=usuario_id,
                establecimiento_id=establecimiento.id,
                fecha_asignacion=datetime.now().date(),
                es_principal=True,
                activo=True
            )
            db.session.add(inspector_asignacion)

            # Confirmar cambios
            db.session.commit()

            mensaje = f'Establecimiento "{nombre}" creado exitosamente con {total_items} items de evaluación personalizados'

            return jsonify({
                'success': True,
                'message': mensaje,
                'establecimiento_id': establecimiento.id,
                'total_items': total_items,
                'items_plantilla': len(items_plantilla_seleccionados),
                'items_adicionales': len(items_base_adicionales)
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al crear establecimiento personalizado: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al crear el establecimiento'
            }), 500

    @staticmethod
    def obtener_plantillas_json():
        """
        Obtener plantillas en formato JSON para AJAX

        Returns:
            JSON con lista de plantillas
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener plantillas activas
            plantillas = PlantillaChecklist.query.filter_by(activo=True)\
                .join(TipoEstablecimiento)\
                .order_by(TipoEstablecimiento.nombre, PlantillaChecklist.nombre)\
                .all()

            plantillas_data = []
            for plantilla in plantillas:
                # Contar items
                num_items = ItemPlantillaChecklist.query\
                    .filter_by(plantilla_id=plantilla.id, activo=True)\
                    .count()

                # Contar establecimientos que usan esta plantilla
                establecimientos_count = db.session.query(
                    Establecimiento.id.distinct()
                ).join(ItemEvaluacionEstablecimiento)\
                .join(ItemPlantillaChecklist,
                      ItemEvaluacionEstablecimiento.item_base_id == ItemPlantillaChecklist.item_base_id)\
                .filter(ItemPlantillaChecklist.plantilla_id == plantilla.id)\
                .count()

                plantillas_data.append({
                    'id': plantilla.id,
                    'nombre': plantilla.nombre,
                    'descripcion': plantilla.descripcion,
                    'tipo': plantilla.tipo_establecimiento.nombre,
                    'categoria': plantilla.tamano_local.title() if plantilla.tamano_local else 'Sin categoría',
                    'items_count': num_items,
                    'establecimientos_count': establecimientos_count,
                    'fecha_creacion': plantilla.created_at.isoformat() if plantilla.created_at else None
                })

            return jsonify(plantillas_data)

        except Exception as e:
            print(f"Error al obtener plantillas JSON: {str(e)}")
            return jsonify({
                'success': False,
                'message': 'Error al obtener plantillas'
            }), 500

    @staticmethod
    def crear_plantilla():
        """
        Crear nueva plantilla

        Request JSON Data:
            - nombre: Nombre de la plantilla
            - descripcion: Descripción (opcional)
            - tipo: Tipo de establecimiento
            - categoria: Categoría (opcional)

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para crear plantillas'
                }), 403

            # Obtener datos del JSON
            data = request.get_json()
            nombre = data.get('nombre', '').strip()
            descripcion = data.get('descripcion', '').strip()
            tipo = data.get('tipo')
            categoria = data.get('categoria', '').strip()

            # Validaciones
            if not nombre or not tipo:
                return jsonify({
                    'success': False,
                    'message': 'Nombre y tipo son obligatorios'
                }), 400

            # Verificar que el tipo de establecimiento existe
            tipo_establecimiento = TipoEstablecimiento.query.filter_by(nombre=tipo, activo=True).first()
            if not tipo_establecimiento:
                return jsonify({
                    'success': False,
                    'message': 'Tipo de establecimiento no válido'
                }), 400

            # Crear plantilla
            plantilla = PlantillaChecklist(
                nombre=nombre,
                descripcion=descripcion if descripcion else None,
                tipo_establecimiento_id=tipo_establecimiento.id,
                tamano_local=categoria.lower() if categoria else None,
                activo=True
            )

            db.session.add(plantilla)
            db.session.commit()

            return jsonify({
                'success': True,
                'message': f'Plantilla "{nombre}" creada exitosamente',
                'plantilla_id': plantilla.id
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al crear plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al crear la plantilla'
            }), 500

    @staticmethod
    def eliminar_plantilla(plantilla_id):
        """
        Eliminar plantilla

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para eliminar plantillas'
                }), 403

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Verificar que no esté siendo usada por establecimientos
            establecimientos_count = db.session.query(
                Establecimiento.id.distinct()
            ).join(ItemEvaluacionEstablecimiento)\
            .join(ItemPlantillaChecklist,
                  ItemEvaluacionEstablecimiento.item_base_id == ItemPlantillaChecklist.item_base_id)\
            .filter(ItemPlantillaChecklist.plantilla_id == plantilla_id)\
            .count()

            if establecimientos_count > 0:
                return jsonify({
                    'success': False,
                    'message': f'No se puede eliminar la plantilla porque está siendo usada por {establecimientos_count} establecimiento(s)'
                }), 409

            # Desactivar plantilla (no eliminar físicamente)
            plantilla.activo = False
            db.session.commit()

            return jsonify({
                'success': True,
                'message': f'Plantilla "{plantilla.nombre}" eliminada exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al eliminar plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al eliminar la plantilla'
            }), 500

    @staticmethod
    def obtener_plantilla(plantilla_id):
        """
        Obtener plantilla específica en formato JSON

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            JSON con datos de la plantilla
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener plantilla
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla or not plantilla.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Contar items
            num_items = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla.id, activo=True)\
                .count()

            # Contar establecimientos que usan esta plantilla
            establecimientos_count = db.session.query(
                Establecimiento.id.distinct()
            ).join(ItemEvaluacionEstablecimiento)\
            .join(ItemPlantillaChecklist,
                  ItemEvaluacionEstablecimiento.item_base_id == ItemPlantillaChecklist.item_base_id)\
            .filter(ItemPlantillaChecklist.plantilla_id == plantilla.id)\
            .count()

            plantilla_data = {
                'id': plantilla.id,
                'nombre': plantilla.nombre,
                'descripcion': plantilla.descripcion,
                'tipo': plantilla.tipo_establecimiento.nombre,
                'categoria': plantilla.tamano_local.title() if plantilla.tamano_local else 'Sin categoría',
                'items_count': num_items,
                'establecimientos_count': establecimientos_count,
                'fecha_creacion': plantilla.created_at.isoformat() if plantilla.created_at else None
            }

            return jsonify(plantilla_data)

        except Exception as e:
            print(f"Error al obtener plantilla: {str(e)}")
            return jsonify({
                'success': False,
                'message': 'Error al obtener plantilla'
            }), 500

    @staticmethod
    def editar_plantilla(plantilla_id):
        """
        Mostrar formulario para editar una plantilla

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            Template renderizado con formulario de edición
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                flash('Debe iniciar sesión', 'error')
                return redirect(url_for('auth.login'))

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                flash('No tiene permisos para editar plantillas', 'error')
                return redirect(url_for('plantillas.listar_plantillas'))

            # Obtener plantilla
            plantilla = PlantillaChecklist.query.get_or_404(plantilla_id)

            # Obtener tipos de establecimiento
            tipos_establecimiento = TipoEstablecimiento.query.filter_by(activo=True)\
                .order_by(TipoEstablecimiento.nombre).all()

            return render_template('admin_editar_plantilla.html',
                                 plantilla=plantilla,
                                 tipos_establecimiento=tipos_establecimiento,
                                 current_user=usuario)

        except Exception as e:
            print(f"Error al mostrar formulario de edición: {str(e)}")
            traceback.print_exc()
            flash('Error al cargar el formulario de edición', 'error')
            return redirect(url_for('plantillas.listar_plantillas'))

    @staticmethod
    def guardar_edicion_plantilla():
        """
        Guardar cambios en una plantilla

        Request JSON Data:
            - plantilla_id: ID de la plantilla
            - nombre: Nuevo nombre
            - descripcion: Nueva descripción

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para editar plantillas'
                }), 403

            # Obtener datos del JSON
            data = request.get_json()
            plantilla_id = data.get('plantilla_id')
            nombre = data.get('nombre', '').strip()
            descripcion = data.get('descripcion', '').strip()

            # Validaciones
            if not plantilla_id or not nombre:
                return jsonify({
                    'success': False,
                    'message': 'Datos incompletos. Nombre es obligatorio.'
                }), 400

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Actualizar plantilla
            plantilla.nombre = nombre
            plantilla.descripcion = descripcion if descripcion else None

            # Confirmar cambios
            db.session.commit()

            return jsonify({
                'success': True,
                'message': f'Plantilla "{nombre}" actualizada exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al editar plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al editar la plantilla'
            }), 500

    @staticmethod
    def obtener_items_plantilla(plantilla_id):
        """
        Obtener items de una plantilla específica en formato JSON

        Args:
            plantilla_id: ID de la plantilla

        Returns:
            JSON con lista de items de la plantilla
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla or not plantilla.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Obtener items de la plantilla ordenados
            items = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla_id, activo=True)\
                .join(ItemEvaluacionBase)\
                .join(CategoriaEvaluacion)\
                .order_by(CategoriaEvaluacion.orden, ItemPlantillaChecklist.orden)\
                .all()

            items_data = []
            for item in items:
                items_data.append({
                    'id': item.id,
                    'item_base_id': item.item_base_id,
                    'codigo': item.item_base.codigo,
                    'descripcion_base': item.item_base.descripcion,
                    'descripcion_personalizada': item.descripcion_personalizada,
                    'categoria': item.item_base.categoria.nombre,
                    'riesgo': item.riesgo,  # Usa la propiedad que considera el riesgo personalizado
                    'riesgo_base': item.item_base.riesgo,  # Incluye el riesgo base para referencia
                    'puntaje_minimo': item.puntaje_minimo,  # Usa la propiedad calculada
                    'puntaje_maximo': item.puntaje_maximo,  # Usa la propiedad calculada
                    'puntaje_minimo_personalizado': item.puntaje_minimo_personalizado,
                    'puntaje_maximo_personalizado': item.puntaje_maximo_personalizado,
                    'factor_ajuste': float(item.factor_ajuste) if item.factor_ajuste else 1.0,
                    'obligatorio': item.obligatorio,
                    'orden': item.orden
                })

            return jsonify({
                'success': True,
                'items': items_data
            })

        except Exception as e:
            print(f"Error al obtener items de plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error al obtener items de la plantilla'
            }), 500

    @staticmethod
    def agregar_item_plantilla(plantilla_id):
        """
        Agregar nuevo item a plantilla (desde item base existente o creando uno nuevo)

        Args:
            plantilla_id: ID de la plantilla

        Request JSON Data (para item base):
            - tipo: 'base'
            - item_base_id: ID del item base a agregar
            - descripcion_personalizada: Descripción personalizada (opcional)
            - puntaje_minimo: Puntaje mínimo personalizado (opcional)
            - puntaje_maximo: Puntaje máximo personalizado (opcional)
            - obligatorio: Si es obligatorio (opcional, default True)

        Request JSON Data (para item nuevo):
            - tipo: 'nuevo'
            - descripcion: Descripción del nuevo item
            - categoria_id: ID de la categoría
            - riesgo: Nivel de riesgo
            - puntaje_minimo: Puntaje mínimo base
            - puntaje_maximo: Puntaje máximo base
            - descripcion_personalizada: Descripción personalizada (opcional)
            - puntaje_minimo_personalizado: Puntaje mínimo personalizado (opcional)
            - puntaje_maximo_personalizado: Puntaje máximo personalizado (opcional)
            - obligatorio: Si es obligatorio (opcional, default True)

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para modificar plantillas'
                }), 403

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla or not plantilla.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Obtener datos del JSON
            data = request.get_json()
            tipo = data.get('tipo', 'base')

            item_base = None

            if tipo == 'base':
                # Usar item base existente
                item_base_id = data.get('item_base_id')
                if not item_base_id:
                    return jsonify({
                        'success': False,
                        'message': 'ID del item base es obligatorio'
                    }), 400

                item_base = ItemEvaluacionBase.query.get(item_base_id)
                if not item_base or not item_base.activo:
                    return jsonify({
                        'success': False,
                        'message': 'Item base no encontrado o inactivo'
                    }), 404

            elif tipo == 'nuevo':
                # Crear nuevo item base
                descripcion = data.get('descripcion', '').strip()
                categoria_id = data.get('categoria_id')
                riesgo = data.get('riesgo', '').strip()
                puntaje_minimo = data.get('puntaje_minimo', 0)
                puntaje_maximo = data.get('puntaje_maximo', 4)

                # Validaciones para item nuevo
                if not descripcion or not categoria_id or not riesgo:
                    return jsonify({
                        'success': False,
                        'message': 'Descripción, categoría y riesgo son obligatorios para items nuevos'
                    }), 400

                if len(descripcion) > 1000:
                    return jsonify({
                        'success': False,
                        'message': 'La descripción no puede tener más de 1000 caracteres'
                    }), 400

                if riesgo not in ['Menor', 'Mayor', 'Crítico']:
                    return jsonify({
                        'success': False,
                        'message': 'El riesgo debe ser Menor, Mayor o Crítico'
                    }), 400

                if not isinstance(puntaje_minimo, int) or not isinstance(puntaje_maximo, int):
                    return jsonify({
                        'success': False,
                        'message': 'Los puntajes deben ser números enteros'
                    }), 400

                if puntaje_minimo < 0 or puntaje_maximo < 0 or puntaje_minimo >= puntaje_maximo:
                    return jsonify({
                        'success': False,
                        'message': 'Los puntajes deben ser positivos y el mínimo debe ser menor que el máximo'
                    }), 400

                # Verificar que la categoría existe
                categoria = CategoriaEvaluacion.query.get(categoria_id)
                if not categoria or not categoria.activo:
                    return jsonify({
                        'success': False,
                        'message': 'Categoría no encontrada o inactiva'
                    }), 404

                # Generar código automáticamente
                # Obtener el último código para esta categoría
                ultimo_item = ItemEvaluacionBase.query\
                    .filter_by(categoria_id=categoria_id, activo=True)\
                    .order_by(ItemEvaluacionBase.orden.desc())\
                    .first()

                if ultimo_item and ultimo_item.codigo:
                    # Extraer el número del código (formato: X.Y)
                    try:
                        partes = ultimo_item.codigo.split('.')
                        if len(partes) == 2:
                            numero_actual = int(partes[1])
                            nuevo_numero = numero_actual + 1
                        else:
                            nuevo_numero = 1
                    except (ValueError, IndexError):
                        nuevo_numero = 1
                else:
                    nuevo_numero = 1

                codigo = f"{categoria_id}.{nuevo_numero}"

                # Verificar que el código generado no esté duplicado (por si acaso)
                existing_item = ItemEvaluacionBase.query.filter_by(codigo=codigo, activo=True).first()
                while existing_item:
                    nuevo_numero += 1
                    codigo = f"{categoria_id}.{nuevo_numero}"
                    existing_item = ItemEvaluacionBase.query.filter_by(codigo=codigo, activo=True).first()

                # Obtener el orden máximo para la categoría
                max_orden = db.session.query(db.func.max(ItemEvaluacionBase.orden))\
                    .filter_by(categoria_id=categoria_id, activo=True)\
                    .scalar() or 0

                # Crear el nuevo item base
                item_base = ItemEvaluacionBase(
                    categoria_id=categoria_id,
                    codigo=codigo,
                    descripcion=descripcion,
                    riesgo=riesgo,
                    puntaje_minimo=puntaje_minimo,
                    puntaje_maximo=puntaje_maximo,
                    orden=max_orden + 1,
                    activo=True
                )

                db.session.add(item_base)
                db.session.flush()  # Para obtener el ID

            else:
                return jsonify({
                    'success': False,
                    'message': 'Tipo de item no válido'
                }), 400

            # Verificar que no esté duplicado en la plantilla
            existing_item = ItemPlantillaChecklist.query\
                .filter_by(plantilla_id=plantilla_id, item_base_id=item_base.id, activo=True)\
                .first()

            if existing_item:
                return jsonify({
                    'success': False,
                    'message': 'Este item ya existe en la plantilla'
                }), 409

            # Obtener datos comunes
            descripcion_personalizada = (data.get('descripcion_personalizada') or '').strip() if data.get('descripcion_personalizada') is not None else ''
            puntaje_minimo_personalizado = data.get('puntaje_minimo')
            puntaje_maximo_personalizado = data.get('puntaje_maximo')
            obligatorio = data.get('obligatorio', True)

            # Validar puntajes personalizados si se proporcionan
            if puntaje_minimo_personalizado is not None and (puntaje_minimo_personalizado < 0 or puntaje_minimo_personalizado > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo personalizado debe estar entre 0 y 100'
                }), 400

            if puntaje_maximo_personalizado is not None and (puntaje_maximo_personalizado < 0 or puntaje_maximo_personalizado > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje máximo personalizado debe estar entre 0 y 100'
                }), 400

            if (puntaje_minimo_personalizado is not None and puntaje_maximo_personalizado is not None and
                puntaje_minimo_personalizado >= puntaje_maximo_personalizado):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo personalizado debe ser menor que el máximo'
                }), 400

            # Obtener el orden máximo actual
            max_orden = db.session.query(db.func.max(ItemPlantillaChecklist.orden))\
                .filter_by(plantilla_id=plantilla_id, activo=True)\
                .scalar() or 0

            # Crear nuevo item en la plantilla
            nuevo_item = ItemPlantillaChecklist(
                plantilla_id=plantilla_id,
                item_base_id=item_base.id,
                descripcion_personalizada=descripcion_personalizada if descripcion_personalizada else None,
                factor_ajuste=1.0,
                riesgo_personalizado=None,  # No se usa en la nueva estructura
                puntaje_minimo_personalizado=puntaje_minimo_personalizado,
                puntaje_maximo_personalizado=puntaje_maximo_personalizado,
                obligatorio=obligatorio,
                orden=max_orden + 1,
                activo=True
            )

            db.session.add(nuevo_item)
            db.session.commit()

            tipo_mensaje = "nuevo" if tipo == "nuevo" else "existente"
            return jsonify({
                'success': True,
                'message': f'Item {tipo_mensaje} "{item_base.descripcion}" agregado exitosamente',
                'item_id': nuevo_item.id
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al agregar item a plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al agregar el item'
            }), 500

    @staticmethod
    def editar_item_plantilla(item_id):
        """
        Editar item específico de plantilla

        Args:
            item_id: ID del item de plantilla

        Request JSON Data:
            - descripcion_personalizada: Descripción personalizada (opcional)
            - factor_ajuste: Factor de ajuste (opcional)
            - riesgo: Riesgo personalizado (opcional)
            - puntaje_minimo: Puntaje mínimo personalizado (opcional)
            - puntaje_maximo: Puntaje máximo personalizado (opcional)
            - obligatorio: Si es obligatorio (opcional)

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para modificar plantillas'
                }), 403

            # Verificar que el item existe
            item = ItemPlantillaChecklist.query.get(item_id)
            if not item or not item.activo:
                return jsonify({
                    'success': False,
                    'message': 'Item no encontrado'
                }), 404

            # Obtener datos del JSON
            data = request.get_json()
            descripcion_base = (data.get('descripcion_base') or '').strip()
            descripcion_personalizada = (data.get('descripcion_personalizada') or '').strip() if data.get('descripcion_personalizada') is not None else ''
            factor_ajuste = data.get('factor_ajuste', item.factor_ajuste)
            riesgo = (data.get('riesgo') or '').strip() if data.get('riesgo') else None
            puntaje_minimo = data.get('puntaje_minimo')
            puntaje_maximo = data.get('puntaje_maximo')
            obligatorio = data.get('obligatorio', item.obligatorio)

            # Validar descripción base
            if not descripcion_base:
                return jsonify({
                    'success': False,
                    'message': 'La descripción base del item es obligatoria'
                }), 400

            if len(descripcion_base) > 1000:
                return jsonify({
                    'success': False,
                    'message': 'La descripción base no puede tener más de 1000 caracteres'
                }), 400

            # Validar factor de ajuste
            if factor_ajuste < 0.1 or factor_ajuste > 5.0:
                return jsonify({
                    'success': False,
                    'message': 'El factor de ajuste debe estar entre 0.1 y 5.0'
                }), 400

            # Validar riesgo si se proporciona
            if riesgo and riesgo not in ['Menor', 'Mayor', 'Crítico']:
                return jsonify({
                    'success': False,
                    'message': 'El riesgo debe ser Menor, Mayor o Crítico'
                }), 400

            # Validar puntajes si se proporcionan
            if puntaje_minimo is not None and (puntaje_minimo < 0 or puntaje_minimo > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo debe estar entre 0 y 100'
                }), 400

            if puntaje_maximo is not None and (puntaje_maximo < 0 or puntaje_maximo > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje máximo debe estar entre 0 y 100'
                }), 400

            if puntaje_minimo is not None and puntaje_maximo is not None and puntaje_minimo >= puntaje_maximo:
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo debe ser menor que el puntaje máximo'
                }), 400

            # Validar riesgo si se proporciona
            if riesgo and riesgo not in ['Menor', 'Mayor', 'Crítico']:
                return jsonify({
                    'success': False,
                    'message': 'El riesgo debe ser Menor, Mayor o Crítico'
                }), 400

            # Validar puntajes si se proporcionan
            if puntaje_minimo is not None and (puntaje_minimo < 0 or puntaje_minimo > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo debe estar entre 0 y 100'
                }), 400

            if puntaje_maximo is not None and (puntaje_maximo < 0 or puntaje_maximo > 100):
                return jsonify({
                    'success': False,
                    'message': 'El puntaje máximo debe estar entre 0 y 100'
                }), 400

            if puntaje_minimo is not None and puntaje_maximo is not None and puntaje_minimo >= puntaje_maximo:
                return jsonify({
                    'success': False,
                    'message': 'El puntaje mínimo debe ser menor que el puntaje máximo'
                }), 400

            # Actualizar item base
            item.item_base.descripcion = descripcion_base

            # Actualizar item de plantilla
            item.descripcion_personalizada = descripcion_personalizada if descripcion_personalizada else None
            item.factor_ajuste = factor_ajuste
            item.riesgo_personalizado = riesgo if riesgo else None
            item.puntaje_minimo_personalizado = puntaje_minimo
            item.puntaje_maximo_personalizado = puntaje_maximo
            item.obligatorio = obligatorio

            db.session.commit()

            return jsonify({
                'success': True,
                'message': 'Item actualizado exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al editar item de plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al editar el item'
            }), 500

    @staticmethod
    def eliminar_item_plantilla(item_id):
        """
        Eliminar item de plantilla

        Args:
            item_id: ID del item de plantilla

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para modificar plantillas'
                }), 403

            # Verificar que el item existe
            item = ItemPlantillaChecklist.query.get(item_id)
            if not item or not item.activo:
                return jsonify({
                    'success': False,
                    'message': 'Item no encontrado'
                }), 404

            # Verificar que no esté siendo usado por establecimientos
            establecimientos_count = db.session.query(
                Establecimiento.id.distinct()
            ).join(ItemEvaluacionEstablecimiento)\
            .filter(ItemEvaluacionEstablecimiento.item_base_id == item.item_base_id)\
            .count()

            if establecimientos_count > 0:
                return jsonify({
                    'success': False,
                    'message': f'No se puede eliminar el item porque está siendo usado por {establecimientos_count} establecimiento(s)'
                }), 409

            # Desactivar item (no eliminar físicamente)
            item.activo = False
            db.session.commit()

            return jsonify({
                'success': True,
                'message': f'Item "{item.item_base.descripcion}" eliminado exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al eliminar item de plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al eliminar el item'
            }), 500

    @staticmethod
    def reordenar_items_plantilla(plantilla_id):
        """
        Reordenar items de plantilla

        Args:
            plantilla_id: ID de la plantilla

        Request JSON Data:
            - items: Array de objetos con {id: item_id, orden: nuevo_orden}

        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario or usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False,
                    'message': 'No tiene permisos para modificar plantillas'
                }), 403

            # Verificar que la plantilla existe
            plantilla = PlantillaChecklist.query.get(plantilla_id)
            if not plantilla or not plantilla.activo:
                return jsonify({
                    'success': False,
                    'message': 'Plantilla no encontrada'
                }), 404

            # Obtener datos del JSON
            data = request.get_json()
            items_data = data.get('items', [])

            if not items_data:
                return jsonify({
                    'success': False,
                    'message': 'No se proporcionaron items para reordenar'
                }), 400

            # Actualizar orden de cada item
            for item_data in items_data:
                item_id = item_data.get('id')
                nuevo_orden = item_data.get('orden')

                if item_id and nuevo_orden is not None:
                    item = ItemPlantillaChecklist.query.get(item_id)
                    if item and item.plantilla_id == plantilla_id and item.activo:
                        item.orden = nuevo_orden

            db.session.commit()

            return jsonify({
                'success': True,
                'message': 'Items reordenados exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            print(f"Error al reordenar items de plantilla: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error interno del servidor al reordenar los items'
            }), 500

    @staticmethod
    def buscar_items_base():
        """
        Buscar items base disponibles para agregar a plantillas

        Body Parameters (JSON):
            - query: Texto de búsqueda
            - exclude: Lista de IDs de items a excluir

        Returns:
            JSON con lista de items base
        """
        try:
            data = request.get_json()
            if not data:
                return jsonify({
                    'success': False,
                    'message': 'Datos JSON requeridos'
                }), 400

            query = data.get('query', '').strip()
            exclude_ids = data.get('exclude', [])

            if not query or len(query) < 2:
                return jsonify({
                    'success': False,
                    'message': 'La búsqueda debe tener al menos 2 caracteres'
                }), 400

            # Buscar items base que coincidan con la query
            items_query = ItemEvaluacionBase.query.filter(
                ItemEvaluacionBase.activo == True
            ).filter(
                db.or_(
                    ItemEvaluacionBase.descripcion.ilike(f'%{query}%'),
                    ItemEvaluacionBase.codigo.ilike(f'%{query}%'),
                    CategoriaEvaluacion.nombre.ilike(f'%{query}%')
                )
            )

            # Excluir items que ya están en la lista de exclusión
            if exclude_ids:
                items_query = items_query.filter(~ItemEvaluacionBase.id.in_(exclude_ids))

            # Unir con categoría y ordenar
            items = items_query.join(CategoriaEvaluacion)\
                .order_by(CategoriaEvaluacion.orden, ItemEvaluacionBase.orden)\
                .limit(20)\
                .all()

            items_data = []
            for item in items:
                items_data.append({
                    'id': item.id,
                    'codigo': item.codigo,
                    'descripcion': item.descripcion,
                    'categoria': item.categoria.nombre,
                    'riesgo': item.riesgo,
                    'puntaje_minimo': item.puntaje_minimo,
                    'puntaje_maximo': item.puntaje_maximo
                })

            return jsonify({
                'success': True,
                'items': items_data
            })

        except Exception as e:
            print(f"Error al buscar items base: {str(e)}")
            traceback.print_exc()
            return jsonify({
                'success': False,
                'message': 'Error al buscar items base'
            }), 500

    @staticmethod
    def obtener_categorias():
        """
        Obtener lista de categorías activas

        Returns:
            JSON con lista de categorías
        """
        try:
            categorias = CategoriaEvaluacion.query.filter_by(activo=True)\
                .order_by(CategoriaEvaluacion.orden)\
                .all()

            categorias_data = []
            for categoria in categorias:
                categorias_data.append({
                    'id': categoria.id,
                    'nombre': categoria.nombre,
                    'descripcion': categoria.descripcion
                })

            return jsonify({
                'success': True,
                'categorias': categorias_data
            })

        except Exception as e:
            print(f"Error al obtener categorías: {str(e)}")
            return jsonify({
                'success': False,
                'message': 'Error al obtener categorías'
            }), 500