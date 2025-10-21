"""
Controlador para funcionalidades del Inspector
"""
from flask import render_template, request, jsonify, session
from werkzeug.utils import secure_filename
from app.models.Usuario_models import Usuario, Rol, TipoEstablecimiento
from app.models.Inspecciones_models import (
    Establecimiento, JefeEstablecimiento
)
from app.extensions import db
from sqlalchemy import and_
import os
from datetime import datetime
from app.utils.auth_utils import generar_contrasena_temporal


class InspectorController:
    """
    Controlador para gestionar las funcionalidades del Inspector
    """

    @staticmethod
    def ver_perfil():
        """
        Mostrar la página de perfil del inspector donde puede gestionar su firma
        
        Returns:
            Template renderizado con los datos del usuario
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            # Renderizar template
            return render_template('inspector_perfil.html', 
                                 usuario=usuario,
                                 current_user=usuario)

        except Exception as e:
            import traceback
            return jsonify({'success': False, 'message': f'Error al cargar el perfil: {str(e)}'}), 500

    @staticmethod
    def guardar_firma():
        """
        Guardar o actualizar la firma del inspector
        
        Request:
            - firma (file): Imagen de la firma
        
        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            # Verificar que es inspector o admin
            if usuario.rol.nombre not in ['Inspector', 'Administrador']:
                return jsonify({
                    'success': False, 
                    'message': 'Solo inspectores y administradores pueden usar esta función'
                }), 403

            # Verificar que se envió el archivo
            if 'firma' not in request.files:
                return jsonify({'success': False, 'message': 'No se envió ningún archivo'}), 400

            file = request.files['firma']
            if file.filename == '':
                return jsonify({'success': False, 'message': 'No se seleccionó ningún archivo'}), 400

            # Validar extensión
            allowed_extensions = {'png', 'jpg', 'jpeg'}
            if '.' not in file.filename or file.filename.rsplit('.', 1)[1].lower() not in allowed_extensions:
                return jsonify({
                    'success': False, 
                    'message': 'Formato no válido. Use PNG, JPG o JPEG'
                }), 400

            # Generar nombre seguro para el archivo
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = secure_filename(file.filename)
            ext = filename.rsplit('.', 1)[1].lower()
            nuevo_nombre = f"firma_inspector_{usuario.id}_{timestamp}.{ext}"

            # Ruta de guardado
            upload_folder = os.path.join('app', 'static', 'img', 'firmas')
            os.makedirs(upload_folder, exist_ok=True)
            
            filepath = os.path.join(upload_folder, nuevo_nombre)
            
            # Eliminar firma anterior si existe
            if usuario.ruta_firma:
                old_path = os.path.join('app', 'static', usuario.ruta_firma)
                if os.path.exists(old_path):
                    try:
                        os.remove(old_path)
                    except Exception as e:
                        import logging
                        logging.warning(f"No se pudo eliminar firma anterior: {str(e)}")

            # Guardar archivo
            file.save(filepath)

            # Actualizar base de datos
            usuario.ruta_firma = f"img/firmas/{nuevo_nombre}"
            db.session.commit()

            return jsonify({
                'success': True,
                'message': 'Firma guardada exitosamente',
                'ruta_firma': usuario.ruta_firma
            })

        except Exception as e:
            db.session.rollback()
            return jsonify({
                'success': False,
                'message': 'Error al guardar la firma'
            }), 500

    @staticmethod
    def obtener_firma():
        """
        Obtener la firma actual del inspector
        
        Returns:
            JSON con los datos de la firma
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener usuario
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            if usuario.ruta_firma:
                return jsonify({
                    'success': True,
                    'ruta_firma': usuario.ruta_firma,
                    'usuario_nombre': f"{usuario.nombre} {usuario.apellido}"
                })
            else:
                return jsonify({
                    'success': False,
                    'message': 'No tiene firma registrada'
                })

        except Exception as e:
            return jsonify({
                'success': False,
                'message': 'Error al obtener la firma'
            }), 500

    @staticmethod
    def gestionar_jefes_establecimiento():
        """
        Vista para que inspectores gestionen jefes de establecimiento
        
        Returns:
            Template renderizado con la lista de jefes
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener jefes con información de establecimiento
            jefes = db.session.query(
                JefeEstablecimiento.id,
                JefeEstablecimiento.fecha_inicio,
                JefeEstablecimiento.fecha_fin,
                JefeEstablecimiento.activo,
                Usuario.id.label('usuario_id'),
                Usuario.nombre,
                Usuario.apellido,
                Usuario.correo,
                Usuario.telefono,
                Usuario.dni,
                Establecimiento.id.label('establecimiento_id'),
                Establecimiento.nombre.label('establecimiento_nombre'),
                Establecimiento.direccion.label('establecimiento_direccion')
            ).join(Usuario, JefeEstablecimiento.usuario_id == Usuario.id
            ).join(Establecimiento, JefeEstablecimiento.establecimiento_id == Establecimiento.id
            ).order_by(JefeEstablecimiento.fecha_inicio.desc()).all()

            # Obtener SOLO establecimientos disponibles (sin jefe asignado) para el modal de creación
            # Primero obtener IDs de establecimientos que ya tienen jefe activo
            establecimientos_con_jefe = db.session.query(JefeEstablecimiento.establecimiento_id.distinct()).filter(
                JefeEstablecimiento.activo == True
            ).subquery()

            # Luego obtener establecimientos sin jefe asignado
            establecimientos_disponibles = db.session.query(
                Establecimiento.id,
                Establecimiento.nombre,
                Establecimiento.direccion
            ).filter(
                Establecimiento.activo == True
            ).filter(
                ~Establecimiento.id.in_(establecimientos_con_jefe)
            ).order_by(Establecimiento.nombre).all()

            return render_template('admin/jefes_establecimiento.html', 
                                 jefes=jefes,
                                 establecimientos=establecimientos_disponibles)

        except Exception as e:
            import traceback
            return jsonify({'success': False, 'message': f'Error al cargar jefes: {str(e)}'}), 500

    @staticmethod
    def crear_jefe_establecimiento():
        """
        Vista para que inspectores creen un nuevo jefe de establecimiento
        
        Returns:
            Template renderizado con el formulario
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener todos los establecimientos activos para el modal de creación
            establecimientos_disponibles = db.session.query(
                Establecimiento.id,
                Establecimiento.nombre,
                Establecimiento.direccion
            ).filter(
                Establecimiento.activo == True
            ).order_by(Establecimiento.nombre).all()

            return render_template('inspector_crear_jefe_establecimiento.html',
                                 establecimientos=establecimientos_disponibles)

        except Exception as e:
            import traceback
            print(f"Error en crear_jefe_establecimiento: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': f'Error al cargar formulario: {str(e)}'}), 500

    @staticmethod
    def api_crear_jefe_establecimiento():
        """
        API para que inspectores creen un jefe de establecimiento
        
        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            data = request.get_json()

            # Validar datos requeridos
            required_fields = ['nombre', 'apellido', 'correo', 'dni', 'establecimiento_id', 'fecha_inicio']
            for field in required_fields:
                if not data.get(field):
                    return jsonify({'success': False, 'message': f'El campo {field} es requerido'}), 400

            # Verificar que el correo no exista
            if Usuario.query.filter_by(correo=data['correo']).first():
                return jsonify({'success': False, 'message': 'Ya existe un usuario con este correo electrónico'}), 400

            # Verificar que el DNI no exista
            if Usuario.query.filter_by(dni=data['dni']).first():
                return jsonify({'success': False, 'message': 'Ya existe un usuario con este DNI'}), 400

            # Verificar que el establecimiento no tenga jefe asignado
            jefe_existente = JefeEstablecimiento.query.filter_by(
                establecimiento_id=data['establecimiento_id'],
                activo=True
            ).first()
            if jefe_existente:
                return jsonify({'success': False, 'message': 'Este establecimiento ya tiene un jefe asignado'}), 400

            # Obtener rol de Jefe de Establecimiento
            rol_jefe = Rol.query.filter_by(nombre='Jefe de Establecimiento').first()
            if not rol_jefe:
                return jsonify({'success': False, 'message': 'Rol de Jefe de Establecimiento no encontrado'}), 500

            # Generar contraseña temporal robusta
            contrasena_temporal = generar_contrasena_temporal()

            # Crear usuario
            nuevo_usuario = Usuario(
                nombre=data['nombre'],
                apellido=data['apellido'],
                correo=data['correo'],
                telefono=data.get('telefono'),
                dni=data['dni'],
                rol_id=rol_jefe.id,
                activo=True,
                cambiar_contrasena=True  # Marcar que debe cambiar contraseña
            )
            nuevo_usuario.set_password(contrasena_temporal)  # Contraseña temporal generada

            db.session.add(nuevo_usuario)
            db.session.flush()  # Para obtener el ID del usuario

            # Crear asignación de jefe
            nuevo_jefe = JefeEstablecimiento(
                usuario_id=nuevo_usuario.id,
                establecimiento_id=data['establecimiento_id'],
                fecha_inicio=datetime.strptime(data['fecha_inicio'], '%Y-%m-%d').date(),
                fecha_fin=datetime.strptime(data['fecha_fin'], '%Y-%m-%d').date() if data.get('fecha_fin') else None,
                comentario=data.get('comentario'),
                activo=True
            )

            db.session.add(nuevo_jefe)
            db.session.commit()

            return jsonify({
                'success': True,
                'message': f'Jefe de establecimiento creado exitosamente. Usuario: {data["correo"]}, Contraseña temporal: {contrasena_temporal}',
                'usuario_id': nuevo_usuario.id,
                'jefe_id': nuevo_jefe.id,
                'correo': data['correo'],
                'contrasena_temporal': contrasena_temporal
            })

        except Exception as e:
            db.session.rollback()
            import traceback
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def obtener_establecimientos_disponibles():
        """
        Obtener establecimientos disponibles para asignar jefe (sin jefe asignado activo)
        
        Returns:
            JSON con lista de establecimientos disponibles
        """
        try:
            from app.models.Inspecciones_models import Establecimiento, JefeEstablecimiento
            from app.models.Usuario_models import TipoEstablecimiento

            # Establecimientos sin jefe asignado activo
            establecimientos = db.session.query(
                Establecimiento.id,
                Establecimiento.nombre,
                Establecimiento.direccion,
                TipoEstablecimiento.nombre.label('tipo_establecimiento')
            ).outerjoin(JefeEstablecimiento, and_(
                JefeEstablecimiento.establecimiento_id == Establecimiento.id,
                JefeEstablecimiento.activo == True
            )).outerjoin(TipoEstablecimiento, 
                TipoEstablecimiento.id == Establecimiento.tipo_establecimiento_id
            ).filter(
                Establecimiento.activo == True,
                JefeEstablecimiento.id.is_(None)
            ).order_by(Establecimiento.nombre).all()

            establecimientos_data = []
            for est in establecimientos:
                establecimientos_data.append({
                    'id': est.id,
                    'nombre': est.nombre,
                    'direccion': est.direccion or '',
                    'tipo_establecimiento': est.tipo_establecimiento or 'Sin tipo'
                })

            return jsonify({'establecimientos': establecimientos_data})

        except Exception as e:
            return jsonify({'error': f'Error obteniendo establecimientos disponibles: {str(e)}'}), 500

    @staticmethod
    def restablecer_contrasena_jefe(jefe_id):
        """
        Restablecer la contraseña de un jefe de establecimiento
        
        Args:
            jefe_id: ID del jefe de establecimiento
            
        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener el jefe de establecimiento
            jefe = JefeEstablecimiento.query.get(jefe_id)
            if not jefe:
                return jsonify({'success': False, 'message': 'Jefe de establecimiento no encontrado'}), 404

            # Verificar que el jefe esté activo
            if not jefe.activo:
                return jsonify({'success': False, 'message': 'Este jefe de establecimiento no está activo'}), 400

            # Obtener el usuario
            usuario = Usuario.query.get(jefe.usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            # Generar nueva contraseña temporal
            nueva_contrasena = generar_contrasena_temporal()
            
            # Actualizar contraseña del usuario
            usuario.set_password(nueva_contrasena)
            usuario.cambiar_contrasena = True  # Forzar cambio de contraseña
            usuario.updated_at = datetime.utcnow()
            
            db.session.commit()

            return jsonify({
                'success': True,
                'message': 'Contraseña restablecida exitosamente',
                'correo': usuario.correo,
                'contrasena_temporal': nueva_contrasena
            })

        except Exception as e:
            db.session.rollback()
            import traceback
            print(f"Error en restablecer_contrasena_jefe: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def obtener_detalles_jefe(jefe_id):
        """
        Obtener detalles completos de un jefe de establecimiento
        
        Args:
            jefe_id: ID del jefe de establecimiento
            
        Returns:
            JSON con detalles del jefe
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener el jefe con toda su información relacionada
            jefe_info = db.session.query(
                JefeEstablecimiento.id,
                JefeEstablecimiento.fecha_inicio,
                JefeEstablecimiento.fecha_fin,
                JefeEstablecimiento.activo,
                JefeEstablecimiento.comentario,
                Usuario.id.label('usuario_id'),
                Usuario.nombre,
                Usuario.apellido,
                Usuario.correo,
                Usuario.telefono,
                Usuario.dni,
                Usuario.fecha_creacion.label('usuario_fecha_creacion'),
                Usuario.updated_at.label('usuario_fecha_actualizacion'),
                Usuario.activo.label('usuario_activo'),
                Usuario.cambiar_contrasena,
                Establecimiento.id.label('establecimiento_id'),
                Establecimiento.nombre.label('establecimiento_nombre'),
                Establecimiento.direccion.label('establecimiento_direccion'),
                Establecimiento.telefono.label('establecimiento_telefono'),
                TipoEstablecimiento.nombre.label('tipo_establecimiento')
            ).join(Usuario, JefeEstablecimiento.usuario_id == Usuario.id
            ).join(Establecimiento, JefeEstablecimiento.establecimiento_id == Establecimiento.id
            ).outerjoin(TipoEstablecimiento, Establecimiento.tipo_establecimiento_id == TipoEstablecimiento.id
            ).filter(JefeEstablecimiento.id == jefe_id
            ).first()

            if not jefe_info:
                return jsonify({'success': False, 'message': 'Jefe de establecimiento no encontrado'}), 404

            # Obtener estadísticas adicionales
            from app.models.Inspecciones_models import Inspeccion, EncargadoEstablecimiento

            # Número de inspecciones realizadas por encargados bajo este jefe
            # Primero obtener los IDs de los encargados del establecimiento del jefe
            encargados_ids = db.session.query(EncargadoEstablecimiento.usuario_id).filter(
                EncargadoEstablecimiento.establecimiento_id == jefe_info.establecimiento_id,
                EncargadoEstablecimiento.activo == True
            ).subquery()

            total_inspecciones = db.session.query(Inspeccion).filter(
                Inspeccion.encargado_id.in_(encargados_ids)
            ).count()

            # Número de encargados activos bajo este jefe
            total_encargados = db.session.query(EncargadoEstablecimiento).filter(
                EncargadoEstablecimiento.establecimiento_id == jefe_info.establecimiento_id,
                EncargadoEstablecimiento.activo == True
            ).count()

            # Última inspección
            ultima_inspeccion = db.session.query(Inspeccion).filter(
                Inspeccion.encargado_id.in_(encargados_ids)
            ).order_by(Inspeccion.fecha.desc()).first()

            return jsonify({
                'success': True,
                'jefe': {
                    'id': jefe_info.id,
                    'fecha_inicio': jefe_info.fecha_inicio.isoformat() if jefe_info.fecha_inicio else None,
                    'fecha_fin': jefe_info.fecha_fin.isoformat() if jefe_info.fecha_fin else None,
                    'activo': jefe_info.activo,
                    'comentario': jefe_info.comentario,
                    'usuario': {
                        'id': jefe_info.usuario_id,
                        'nombre': jefe_info.nombre,
                        'apellido': jefe_info.apellido,
                        'correo': jefe_info.correo,
                        'telefono': jefe_info.telefono,
                        'dni': jefe_info.dni,
                        'fecha_creacion': jefe_info.usuario_fecha_creacion.isoformat() if jefe_info.usuario_fecha_creacion else None,
                        'fecha_actualizacion': jefe_info.usuario_fecha_actualizacion.isoformat() if jefe_info.usuario_fecha_actualizacion else None,
                        'activo': jefe_info.usuario_activo,
                        'cambiar_contrasena': jefe_info.cambiar_contrasena
                    },
                    'establecimiento': {
                        'id': jefe_info.establecimiento_id,
                        'nombre': jefe_info.establecimiento_nombre,
                        'direccion': jefe_info.establecimiento_direccion,
                        'telefono': jefe_info.establecimiento_telefono,
                        'tipo_establecimiento': jefe_info.tipo_establecimiento
                    },
                    'estadisticas': {
                        'total_inspecciones': total_inspecciones,
                        'total_encargados': total_encargados,
                        'ultima_inspeccion': ultima_inspeccion.fecha.isoformat() if ultima_inspeccion else None
                    }
                }
            })

        except Exception as e:
            import traceback
            print(f"Error en obtener_detalles_jefe: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def obtener_jefe_para_editar(jefe_id):
        """
        Obtener datos de un jefe de establecimiento para editar
        
        Args:
            jefe_id: ID del jefe de establecimiento
            
        Returns:
            JSON con datos del jefe para editar
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener el jefe con toda su información relacionada
            jefe_info = db.session.query(
                JefeEstablecimiento.id,
                JefeEstablecimiento.fecha_inicio,
                JefeEstablecimiento.fecha_fin,
                JefeEstablecimiento.activo,
                JefeEstablecimiento.comentario,
                Usuario.id.label('usuario_id'),
                Usuario.nombre,
                Usuario.apellido,
                Usuario.correo,
                Usuario.telefono,
                Usuario.dni,
                Usuario.activo.label('usuario_activo'),
                Establecimiento.id.label('establecimiento_id'),
                Establecimiento.nombre.label('establecimiento_nombre'),
                Establecimiento.direccion.label('establecimiento_direccion')
            ).join(Usuario, JefeEstablecimiento.usuario_id == Usuario.id
            ).join(Establecimiento, JefeEstablecimiento.establecimiento_id == Establecimiento.id
            ).filter(JefeEstablecimiento.id == jefe_id
            ).first()

            if not jefe_info:
                return jsonify({'success': False, 'message': 'Jefe de establecimiento no encontrado'}), 404

            # Obtener todos los establecimientos activos que NO tienen jefe asignado
            # Más el establecimiento actual del jefe que se está editando
            establecimientos_con_jefe = db.session.query(JefeEstablecimiento.establecimiento_id).filter(
                JefeEstablecimiento.activo == True
            ).subquery()

            establecimientos = db.session.query(
                Establecimiento.id,
                Establecimiento.nombre,
                Establecimiento.direccion
            ).filter(
                Establecimiento.activo == True,
                ~Establecimiento.id.in_(establecimientos_con_jefe) | (Establecimiento.id == jefe_info.establecimiento_id)
            ).order_by(Establecimiento.nombre).all()

            establecimientos_data = []
            for est in establecimientos:
                establecimientos_data.append({
                    'id': est.id,
                    'nombre': est.nombre,
                    'direccion': est.direccion or '',
                    'selected': est.id == jefe_info.establecimiento_id
                })

            return jsonify({
                'success': True,
                'jefe': {
                    'id': jefe_info.id,
                    'fecha_inicio': jefe_info.fecha_inicio.isoformat() if jefe_info.fecha_inicio else None,
                    'fecha_fin': jefe_info.fecha_fin.isoformat() if jefe_info.fecha_fin else None,
                    'activo': jefe_info.activo,
                    'comentario': jefe_info.comentario,
                    'usuario': {
                        'id': jefe_info.usuario_id,
                        'nombre': jefe_info.nombre,
                        'apellido': jefe_info.apellido,
                        'correo': jefe_info.correo,
                        'telefono': jefe_info.telefono,
                        'dni': jefe_info.dni,
                        'activo': jefe_info.usuario_activo
                    },
                    'establecimiento': {
                        'id': jefe_info.establecimiento_id,
                        'nombre': jefe_info.establecimiento_nombre,
                        'direccion': jefe_info.establecimiento_direccion
                    }
                },
                'establecimientos': establecimientos_data
            })

        except Exception as e:
            import traceback
            print(f"Error en obtener_jefe_para_editar: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def actualizar_jefe_establecimiento(jefe_id):
        """
        Actualizar datos de un jefe de establecimiento
        
        Args:
            jefe_id: ID del jefe de establecimiento
            
        Returns:
            JSON con resultado de la actualización
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            data = request.get_json()

            # Obtener el jefe actual
            jefe = JefeEstablecimiento.query.get(jefe_id)
            if not jefe:
                return jsonify({'success': False, 'message': 'Jefe de establecimiento no encontrado'}), 404

            # Obtener el usuario
            usuario = Usuario.query.get(jefe.usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            # Validar datos requeridos
            required_fields = ['nombre', 'apellido', 'correo', 'dni', 'establecimiento_id', 'fecha_inicio']
            for field in required_fields:
                if not data.get(field):
                    return jsonify({'success': False, 'message': f'El campo {field} es requerido'}), 400

            # Verificar que el correo no exista en otro usuario
            usuario_existente = Usuario.query.filter(
                Usuario.correo == data['correo'],
                Usuario.id != usuario.id
            ).first()
            if usuario_existente:
                return jsonify({'success': False, 'message': 'Ya existe otro usuario con este correo electrónico'}), 400

            # Verificar que el DNI no exista en otro usuario
            usuario_dni_existente = Usuario.query.filter(
                Usuario.dni == data['dni'],
                Usuario.id != usuario.id
            ).first()
            if usuario_dni_existente:
                return jsonify({'success': False, 'message': 'Ya existe otro usuario con este DNI'}), 400

            # Verificar que el establecimiento no tenga otro jefe asignado (si cambió)
            if data['establecimiento_id'] != jefe.establecimiento_id:
                jefe_existente = JefeEstablecimiento.query.filter_by(
                    establecimiento_id=data['establecimiento_id'],
                    activo=True
                ).first()
                if jefe_existente and jefe_existente.id != jefe.id:
                    return jsonify({'success': False, 'message': 'Este establecimiento ya tiene un jefe asignado'}), 400

            # Validar formato de email
            import re
            email_regex = r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
            if not re.match(email_regex, data['correo']):
                return jsonify({'success': False, 'message': 'El formato del correo electrónico no es válido'}), 400

            # Validar DNI
            if not re.match(r'^\d{8}$', data['dni']):
                return jsonify({'success': False, 'message': 'El DNI debe tener exactamente 8 dígitos'}), 400

            # Actualizar datos del usuario
            usuario.nombre = data['nombre']
            usuario.apellido = data['apellido']
            usuario.correo = data['correo']
            usuario.telefono = data.get('telefono')
            usuario.dni = data['dni']
            usuario.updated_at = datetime.utcnow()

            # Actualizar datos del jefe
            jefe.establecimiento_id = data['establecimiento_id']
            jefe.fecha_inicio = datetime.strptime(data['fecha_inicio'], '%Y-%m-%d').date()
            jefe.fecha_fin = datetime.strptime(data['fecha_fin'], '%Y-%m-%d').date() if data.get('fecha_fin') else None
            jefe.comentario = data.get('comentario')
            jefe.activo = data.get('activo', True)

            db.session.commit()

            return jsonify({
                'success': True,
                'message': 'Jefe de establecimiento actualizado exitosamente'
            })

        except Exception as e:
            db.session.rollback()
            import traceback
            print(f"Error en actualizar_jefe_establecimiento: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def toggle_jefe_establecimiento(jefe_id):
        """
        Activar o desactivar un jefe de establecimiento
        
        Args:
            jefe_id: ID del jefe de establecimiento
            
        Returns:
            JSON con resultado de la operación
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener el jefe de establecimiento
            jefe = JefeEstablecimiento.query.get(jefe_id)
            if not jefe:
                return jsonify({'success': False, 'message': 'Jefe de establecimiento no encontrado'}), 404

            # Obtener el usuario asociado
            usuario = Usuario.query.get(jefe.usuario_id)
            if not usuario:
                return jsonify({'success': False, 'message': 'Usuario no encontrado'}), 404

            # Toggle del estado
            nuevo_estado = not jefe.activo
            jefe.activo = nuevo_estado
            
            if nuevo_estado:
                # Si se está activando, quitar la fecha de fin
                jefe.fecha_fin = None
            else:
                # Si se está desactivando, establecer fecha de fin como hoy
                jefe.fecha_fin = datetime.utcnow().date()

            # También cambiar el estado del usuario
            usuario.activo = nuevo_estado
            usuario.updated_at = datetime.utcnow()

            db.session.commit()

            mensaje = 'Jefe de establecimiento activado exitosamente' if nuevo_estado else 'Jefe de establecimiento desactivado exitosamente'

            return jsonify({
                'success': True,
                'message': mensaje,
                'nuevo_estado': nuevo_estado
            })

        except Exception as e:
            db.session.rollback()
            import traceback
            print(f"Error en toggle_jefe_establecimiento: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def obtener_lista_jefes():
        """
        Obtener lista de jefes de establecimiento para actualizar tabla
        
        Returns:
            JSON con lista de jefes
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Obtener todos los jefes con su información relacionada
            jefes_query = db.session.query(
                JefeEstablecimiento.id,
                JefeEstablecimiento.fecha_inicio,
                JefeEstablecimiento.fecha_fin,
                JefeEstablecimiento.activo,
                Usuario.nombre,
                Usuario.apellido,
                Usuario.correo,
                Usuario.telefono,
                Establecimiento.nombre.label('establecimiento_nombre'),
                Establecimiento.direccion.label('establecimiento_direccion')
            ).join(Usuario, JefeEstablecimiento.usuario_id == Usuario.id
            ).join(Establecimiento, JefeEstablecimiento.establecimiento_id == Establecimiento.id
            ).order_by(JefeEstablecimiento.fecha_inicio.desc()).all()

            jefes_data = []
            for jefe in jefes_query:
                jefes_data.append({
                    'id': jefe.id,
                    'nombre': jefe.nombre,
                    'apellido': jefe.apellido,
                    'correo': jefe.correo,
                    'telefono': jefe.telefono,
                    'establecimiento_nombre': jefe.establecimiento_nombre,
                    'establecimiento_direccion': jefe.establecimiento_direccion,
                    'fecha_inicio': jefe.fecha_inicio.strftime('%d/%m/%Y') if jefe.fecha_inicio else '',
                    'fecha_fin': jefe.fecha_fin.strftime('%d/%m/%Y') if jefe.fecha_fin else None,
                    'activo': jefe.activo
                })

            return jsonify({
                'success': True,
                'jefes': jefes_data
            })

        except Exception as e:
            import traceback
            print(f"Error en obtener_lista_jefes: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500

    @staticmethod
    def obtener_estadisticas_jefes():
        """
        Obtener estadísticas de jefes de establecimiento
        
        Returns:
            JSON con estadísticas
        """
        try:
            usuario_id = session.get('user_id')
            if not usuario_id:
                return jsonify({'success': False, 'message': 'No autenticado'}), 401

            # Contar jefes activos
            total_jefes_activos = db.session.query(JefeEstablecimiento).filter(
                JefeEstablecimiento.activo == True
            ).count()

            # Contar establecimientos con jefe asignado
            total_establecimientos_con_jefe = db.session.query(JefeEstablecimiento).filter(
                JefeEstablecimiento.activo == True
            ).count()

            return jsonify({
                'success': True,
                'estadisticas': {
                    'jefes_activos': total_jefes_activos,
                    'establecimientos': total_establecimientos_con_jefe,
                    'asignaciones': '100%'  # Siempre 100% ya que cada jefe tiene un establecimiento
                }
            })

        except Exception as e:
            import traceback
            print(f"Error en obtener_estadisticas_jefes: {str(e)}")
            print(traceback.format_exc())
            return jsonify({'success': False, 'message': 'Error interno del servidor'}), 500
