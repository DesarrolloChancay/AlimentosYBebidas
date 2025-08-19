from flask import jsonify, session
from app.models.Usuario_models import Usuario
from app.utils.auth_utils import check_password, hash_password
from datetime import datetime, timedelta
import json

class AuthController:

    @staticmethod
    def login(correo, contrasena):
        try:
            from app.extensions import db
            
            usuario = Usuario.query.filter_by(correo=correo, activo=True).first()
            
            if not usuario:
                return jsonify({
                    'success': False,
                    'error': 'Credenciales inválidas'
                }), 401

            if not usuario.check_password(contrasena):
                return jsonify({
                    'success': False,
                    'error': 'Credenciales inválidas'
                }), 401

            # Verificar si el usuario ya está en línea
            if usuario.en_linea:
                return jsonify({
                    'success': False,
                    'error': 'Ya existe una sesión activa para este usuario. Use "Forzar Ingreso" si desea cerrar la sesión anterior.',
                    'codigo': 'SESION_DUPLICADA'
                }), 403
                
            # Marcar usuario como en línea
            usuario.en_linea = True
            usuario.ultimo_acceso = datetime.utcnow()
            db.session.commit()
            
            # Crear sesión de Flask
            session['user_id'] = usuario.id
            session['user_role'] = usuario.rol.nombre
            session['user_name'] = f"{usuario.nombre} {usuario.apellido if usuario.apellido else ''}"
            session['login_time'] = datetime.utcnow().isoformat()
            session['last_activity'] = datetime.utcnow().isoformat()
            
            return jsonify({
                'success': True,
                'user': {
                    'id': usuario.id,
                    'nombre': usuario.nombre,
                    'apellido': usuario.apellido,
                    'correo': usuario.correo,
                    'rol': usuario.rol.nombre
                }
            })
                
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'Error interno del servidor: {str(e)}'
            }), 500

    @staticmethod
    def login_forzado(correo, contrasena):
        """Login que permite forzar una nueva sesión cerrando la anterior"""
        try:
            from app.extensions import db
            
            usuario = Usuario.query.filter_by(correo=correo, activo=True).first()
            
            if not usuario:
                return jsonify({
                    'success': False,
                    'error': 'Credenciales inválidas'
                }), 401

            if not usuario.check_password(contrasena):
                return jsonify({
                    'success': False,
                    'error': 'Credenciales inválidas'
                }), 401
                
            # Forzar cierre de sesión anterior (marcar como desconectado)
            usuario.en_linea = True
            usuario.ultimo_acceso = datetime.utcnow()
            db.session.commit()
            
            # Crear nueva sesión de Flask
            session['user_id'] = usuario.id
            session['user_role'] = usuario.rol.nombre
            session['user_name'] = f"{usuario.nombre} {usuario.apellido if usuario.apellido else ''}"
            session['login_time'] = datetime.utcnow().isoformat()
            session['last_activity'] = datetime.utcnow().isoformat()
            
            return jsonify({
                'success': True,
                'mensaje': 'Sesión anterior cerrada, nueva sesión iniciada',
                'user': {
                    'id': usuario.id,
                    'nombre': usuario.nombre,
                    'apellido': usuario.apellido,
                    'correo': usuario.correo,
                    'rol': usuario.rol.nombre
                }
            })
                
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'Error interno del servidor: {str(e)}'
            }), 500

    @staticmethod
    def verificar_sesion_unica():
        """Verifica si la sesión actual es única y válida"""
        try:
            from app.extensions import db
            
            user_id = session.get('user_id')
            
            if not user_id:
                return jsonify({
                    'valida': False,
                    'error': 'No hay sesión activa'
                }), 401
            
            # Verificar si el usuario sigue marcado como en línea
            usuario = Usuario.query.get(user_id)
            if not usuario or not usuario.en_linea:
                session.clear()
                return jsonify({
                    'valida': False,
                    'error': 'Sesión no válida'
                }), 401
                
            # Actualizar último acceso
            usuario.ultimo_acceso = datetime.utcnow()
            session['last_activity'] = datetime.utcnow().isoformat()
            db.session.commit()
            
            return jsonify({
                'valida': True,
                'usuario_id': user_id
            })
            
        except Exception as e:
            return jsonify({
                'valida': False,
                'error': str(e)
            }), 500

    @staticmethod
    def logout():
        try:
            from app.extensions import db
            
            user_id = session.get('user_id')
            
            # Marcar usuario como desconectado en base de datos
            if user_id:
                usuario = Usuario.query.get(user_id)
                if usuario:
                    usuario.en_linea = False
                    db.session.commit()
            
            # Limpiar sesión de Flask
            session.clear()
            
            return jsonify({
                'success': True,
                'mensaje': 'Sesión cerrada exitosamente'
            })
            
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500

    @staticmethod
    def verificar_timeout_sesion():
        """Verifica si la sesión ha expirado por inactividad (10 minutos)"""
        try:
            from app.extensions import db
            
            user_id = session.get('user_id')
            last_activity = session.get('last_activity')
            
            if not user_id or not last_activity:
                return jsonify({
                    'valida': False,
                    'timeout': True,
                    'mensaje': 'No hay sesión activa'
                }), 401
            
            # Verificar timeout (10 minutos = 600 segundos)
            ultimo_acceso = datetime.fromisoformat(last_activity)
            tiempo_transcurrido = (datetime.utcnow() - ultimo_acceso).total_seconds()
            
            if tiempo_transcurrido > 600:  # 10 minutos
                # Sesión expirada, limpiar
                usuario = Usuario.query.get(user_id)
                if usuario:
                    usuario.en_linea = False
                    db.session.commit()
                session.clear()
                
                return jsonify({
                    'valida': False,
                    'timeout': True,
                    'mensaje': 'Sesión expirada por inactividad'
                }), 401
            
            # Sesión válida, actualizar último acceso
            usuario = Usuario.query.get(user_id)
            if usuario:
                usuario.ultimo_acceso = datetime.utcnow()
                db.session.commit()
            session['last_activity'] = datetime.utcnow().isoformat()
            
            return jsonify({
                'valida': True,
                'timeout': False,
                'tiempo_restante': int(600 - tiempo_transcurrido)
            })
            
        except Exception as e:
            return jsonify({
                'valida': False,
                'error': str(e)
            }), 500

    @staticmethod
    def forzar_cierre_sesion(user_id):
        """Fuerza el cierre de sesión de un usuario específico"""
        try:
            from app.extensions import db
            
            usuario = Usuario.query.get(user_id)
            if usuario and usuario.en_linea:
                usuario.en_linea = False
                db.session.commit()
                
                return jsonify({
                    'success': True,
                    'mensaje': f'Sesión del usuario {user_id} cerrada forzadamente'
                })
            else:
                return jsonify({
                    'success': False,
                    'mensaje': f'No hay sesión activa para el usuario {user_id}'
                })
                
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500

    @staticmethod
    def listar_sesiones_activas():
        """Lista todas las sesiones activas (solo para admin)"""
        try:
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({
                    'success': False,
                    'error': 'No autorizado'
                }), 403
            
            # Obtener usuarios que están en línea
            usuarios_en_linea = Usuario.query.filter_by(en_linea=True).all()
            
            sesiones = []
            for usuario in usuarios_en_linea:
                sesiones.append({
                    'user_id': usuario.id,
                    'usuario': f"{usuario.nombre} {usuario.apellido or ''}",
                    'correo': usuario.correo,
                    'rol': usuario.rol.nombre,
                    'ultimo_acceso': usuario.ultimo_acceso.isoformat() if usuario.ultimo_acceso else None
                })
            
            return jsonify({
                'success': True,
                'sesiones': sesiones,
                'total': len(sesiones)
            })
            
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 500

    @staticmethod
    def limpiar_sesiones_expiradas():
        """Limpia automáticamente las sesiones que han expirado"""
        try:
            from app.extensions import db
            
            # Calcular tiempo límite (10 minutos atrás)
            tiempo_limite = datetime.utcnow() - timedelta(minutes=10)
            
            # Buscar usuarios que siguen marcados como en línea pero con último acceso > 10 minutos
            usuarios_expirados = Usuario.query.filter(
                Usuario.en_linea == True,
                Usuario.ultimo_acceso < tiempo_limite
            ).all()
            
            count_limpiados = 0
            for usuario in usuarios_expirados:
                usuario.en_linea = False
                count_limpiados += 1
            
            if count_limpiados > 0:
                db.session.commit()
            
            return {
                'success': True,
                'sesiones_limpiadas': count_limpiados
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }

    @staticmethod
    def crear_usuario(nombre, apellido, dni, correo, contrasena, rol_id, telefono=None):
        """Crear un nuevo usuario con contraseña hasheada"""
        try:
            from app.extensions import db
            
            # Verificar que no exista el usuario
            usuario_existente = Usuario.query.filter_by(correo=correo).first()
            if usuario_existente:
                return jsonify({
                    'success': False,
                    'error': 'Ya existe un usuario con este correo'
                }), 400
            
            # Crear el usuario usando el método del modelo
            nuevo_usuario = Usuario(
                nombre=nombre,
                apellido=apellido,
                dni=dni,
                correo=correo,
                rol_id=rol_id,
                telefono=telefono,
                activo=True
            )
            
            # Usar el método del modelo para hashear la contraseña
            nuevo_usuario.set_password(contrasena)
            
            db.session.add(nuevo_usuario)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'mensaje': 'Usuario creado exitosamente',
                'usuario_id': nuevo_usuario.id
            }), 201
            
        except Exception as e:
            from app.extensions import db
            db.session.rollback()
            return jsonify({
                'success': False,
                'error': f'Error al crear usuario: {str(e)}'
            }), 500

    @staticmethod
    def cambiar_contrasena(usuario_id, contrasena_actual, contrasena_nueva):
        """Cambiar contraseña de un usuario"""
        try:
            from app.extensions import db
            
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({
                    'success': False,
                    'error': 'Usuario no encontrado'
                }), 404
            
            # Verificar contraseña actual usando el método del modelo
            if not usuario.check_password(contrasena_actual):
                return jsonify({
                    'success': False,
                    'error': 'Contraseña actual incorrecta'
                }), 400
            
            # Usar el método del modelo para hashear la nueva contraseña
            usuario.set_password(contrasena_nueva)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'mensaje': 'Contraseña actualizada exitosamente'
            })
            
        except Exception as e:
            from app.extensions import db
            db.session.rollback()
            return jsonify({
                'success': False,
                'error': f'Error al cambiar contraseña: {str(e)}'
            }), 500

    @staticmethod
    def resetear_contrasena_admin(usuario_id, nueva_contrasena):
        """Resetear contraseña de un usuario (solo admin)"""
        try:
            from app.extensions import db
            
            # Verificar que es admin
            if session.get('user_role') != 'Admin':
                return jsonify({
                    'success': False,
                    'error': 'No autorizado'
                }), 403
            
            usuario = Usuario.query.get(usuario_id)
            if not usuario:
                return jsonify({
                    'success': False,
                    'error': 'Usuario no encontrado'
                }), 404
            
            # Usar el método del modelo para hashear la nueva contraseña
            usuario.set_password(nueva_contrasena)
            db.session.commit()
            
            return jsonify({
                'success': True,
                'mensaje': 'Contraseña reseteada exitosamente'
            })
            
        except Exception as e:
            from app.extensions import db
            db.session.rollback()
            return jsonify({
                'success': False,
                'error': f'Error al resetear contraseña: {str(e)}'
            }), 500
