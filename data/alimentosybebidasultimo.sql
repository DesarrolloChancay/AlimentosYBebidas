CREATE DATABASE  IF NOT EXISTS `alimentosybebidas` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `alimentosybebidas`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: alimentosybebidas
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auditoria_acciones`
--

DROP TABLE IF EXISTS auditoria_acciones;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE auditoria_acciones (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  accion varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  recurso varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  recurso_id int DEFAULT NULL,
  detalles json DEFAULT NULL,
  ip_origen varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Soporta IPv4 e IPv6',
  user_agent varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  exitoso tinyint(1) DEFAULT '1',
  mensaje_error text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_usuario_fecha (usuario_id,created_at),
  KEY idx_recurso_fecha (recurso,created_at),
  KEY idx_accion (accion),
  KEY idx_fecha (created_at),
  KEY idx_auditoria_usuario_accion (usuario_id,accion),
  KEY idx_auditoria_recurso_exitoso (recurso,exitoso),
  CONSTRAINT auditoria_acciones_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registro completo de todas las acciones realizadas en el sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auditoria_acciones`
--


--
-- Table structure for table `categorias_evaluacion`
--

DROP TABLE IF EXISTS categorias_evaluacion;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE categorias_evaluacion (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categorias_evaluacion`
--

INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (1,'Higiene y Bioseguridad - Cocinas','Evaluación de higiene y bioseguridad en áreas de cocina',1,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (2,'Equipamiento - Cocinas','Evaluación del equipamiento en cocinas',2,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (3,'Producción y Almacenamiento previo','Evaluación de procesos de producción y almacenamiento',3,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (4,'Preparación de alimentos','Evaluación de procesos de preparación de alimentos',4,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (5,'Gestión de residuos y plagas','Evaluación de manejo de residuos y control de plagas',5,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (6,'Vajillas y Utensilios','Evaluación de vajillas y utensilios de cocina',6,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (7,'Higiene general - Comedor','Evaluación de higiene en área de comedor',7,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (8,'Almacenes','Evaluación de áreas de almacenamiento',8,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (9,'Seguridad - Defensa Civil','Evaluación de medidas de seguridad',9,1);
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (10,'Administración','Evaluación de aspectos administrativos',10,1);

--
-- Table structure for table `configuracion_evaluacion`
--

DROP TABLE IF EXISTS configuracion_evaluacion;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_evaluacion (
  id int NOT NULL AUTO_INCREMENT,
  meta_semanal_default int NOT NULL DEFAULT '3',
  inicio_semana enum('lunes','domingo') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'lunes',
  zona_horaria varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'America/Lima',
  dias_recordatorio json DEFAULT NULL,
  hora_recordatorio time DEFAULT '09:00:00',
  notificaciones_email tinyint(1) DEFAULT '1',
  notificaciones_navegador tinyint(1) DEFAULT '1',
  alertas_dashboard tinyint(1) DEFAULT '1',
  retener_logs_dias int DEFAULT '90',
  backup_automatico enum('diario','semanal','mensual','manual') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'semanal',
  tiempo_sesion_minutos int DEFAULT '240',
  intentos_login_max int DEFAULT '5',
  fecha_creacion timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_evaluacion`
--

INSERT INTO configuracion_evaluacion (id, meta_semanal_default, inicio_semana, zona_horaria, dias_recordatorio, hora_recordatorio, notificaciones_email, notificaciones_navegador, alertas_dashboard, retener_logs_dias, backup_automatico, tiempo_sesion_minutos, intentos_login_max, fecha_creacion, fecha_actualizacion) VALUES (1,3,'lunes','America/Lima','[1, 3, 5]','09:00:00',1,1,1,90,'semanal',240,5,'2025-09-01 14:59:39','2025-09-01 14:59:39');

--
-- Table structure for table `configuracion_evaluaciones`
--

DROP TABLE IF EXISTS configuracion_evaluaciones;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_evaluaciones (
  id int NOT NULL AUTO_INCREMENT,
  clave varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  valor varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  modificable_por_inspector tinyint(1) DEFAULT '0',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY clave (clave)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_evaluaciones`
--

INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (1,'meta_semanal_default','3','Meta semanal por defecto para nuevos establecimientos',1,'2025-09-01 14:59:43','2025-10-16 20:21:32');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (6,'tiempo_sesion','240','Tiempo de sesión en minutos',0,'2025-09-01 15:59:44','2025-09-01 15:59:44');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (7,'intentos_login','5','Número máximo de intentos de login',0,'2025-09-01 15:59:44','2025-09-01 15:59:44');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (8,'dias_recordatorio','1,3,5','Días de la semana para recordatorios (1=Lunes, 7=Domingo)',0,'2025-10-07 17:22:05','2025-10-07 17:22:05');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (9,'hora_recordatorio','09:00','Hora para envío de recordatorios',0,'2025-10-07 17:22:05','2025-10-07 17:22:05');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (10,'zona_horaria','America/Lima','Zona horaria del sistema',0,'2025-10-07 17:22:05','2025-10-07 17:22:05');
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (11,'notificaciones_email','true','Activar notificaciones por email',0,'2025-10-07 17:22:05','2025-10-07 17:22:05');

--
-- Table structure for table `configuracion_sistema`
--

DROP TABLE IF EXISTS configuracion_sistema;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_sistema (
  id int NOT NULL AUTO_INCREMENT,
  modulo varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  configuracion json NOT NULL,
  version varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT NULL,
  created_at timestamp NULL DEFAULT NULL,
  updated_at timestamp NULL DEFAULT NULL,
  updated_by int DEFAULT NULL,
  PRIMARY KEY (id),
  KEY updated_by (updated_by),
  CONSTRAINT configuracion_sistema_ibfk_1 FOREIGN KEY (updated_by) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuracion_sistema`
--


--
-- Table structure for table `encargados_establecimientos`
--

DROP TABLE IF EXISTS encargados_establecimientos;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE encargados_establecimientos (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  establecimiento_id int NOT NULL,
  fecha_inicio date NOT NULL,
  fecha_fin date DEFAULT NULL,
  es_principal tinyint(1) DEFAULT '0',
  comentario varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  habilitado_por int DEFAULT NULL,
  fecha_habilitacion timestamp NULL DEFAULT NULL,
  observaciones_jefe text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY idx_encargado_establecimiento_fecha (establecimiento_id,fecha_inicio,fecha_fin),
  KEY idx_encargado_activo (activo),
  KEY idx_encargado_habilitado_por (habilitado_por),
  CONSTRAINT encargados_establecimientos_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT encargados_establecimientos_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT encargados_establecimientos_ibfk_3 FOREIGN KEY (habilitado_por) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `encargados_establecimientos`
--

INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (1,2,1,'2025-08-16',NULL,1,NULL,1,NULL,'2025-09-01 13:47:21','a','2025-08-19 16:30:01');
INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (2,3,2,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01');
INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (3,4,3,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01');
INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (4,5,4,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01');
INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (8,63,1,'2025-10-16',NULL,0,NULL,1,NULL,NULL,NULL,'2025-10-16 20:49:18');

--
-- Table structure for table `establecimientos`
--

DROP TABLE IF EXISTS establecimientos;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE establecimientos (
  id int NOT NULL AUTO_INCREMENT,
  tipo_establecimiento_id int DEFAULT NULL,
  nombre varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  direccion varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  telefono varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  correo varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY tipo_establecimiento_id (tipo_establecimiento_id),
  KEY idx_establecimientos_activo (activo),
  CONSTRAINT establecimientos_ibfk_1 FOREIGN KEY (tipo_establecimiento_id) REFERENCES tipos_establecimiento (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `establecimientos`
--

INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (1,1,'Déjà vu','Dirección Déjà vu','985478569',NULL,1,'2025-08-19 16:30:01');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (2,1,'Silvia','Dirección Silvia','123456789','silvia@chancay.com',1,'2025-08-19 16:30:01');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (3,1,'Náutica','Dirección Náutica','123456789','nautica@chancay.com',1,'2025-08-19 16:30:01');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (4,1,'Rincón del Norte','Dirección Rincón del Norte','123456789','rinconnorte@chancay.com',1,'2025-08-19 16:30:01');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (6,4,'El Buen Sabor','Av. Larco 123, Miraflores, Lima','954125748',NULL,1,'2025-09-16 22:22:19');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (7,1,'BRISA MARINAS','A.v 1 de mayo 1224','977568239','',1,'2025-10-02 22:55:34');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (9,1,'El Parque',NULL,NULL,NULL,1,'2025-10-07 17:53:39');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (10,1,'Establecimiento de Prueba','Dirección de prueba',NULL,NULL,1,'2025-10-07 20:48:31');
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (16,1,'Fast Food Express','','','',1,'2025-10-17 15:30:25');

--
-- Table structure for table `evaluaciones_reglamento`
--

DROP TABLE IF EXISTS evaluaciones_reglamento;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE evaluaciones_reglamento (
  id int NOT NULL AUTO_INCREMENT,
  reunion_id int NOT NULL,
  item_id int NOT NULL,
  cumple tinyint(1) NOT NULL,
  numero_infracciones int DEFAULT NULL,
  observacion text COLLATE utf8mb4_general_ci,
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY reunion_id (reunion_id),
  KEY item_id (item_id),
  CONSTRAINT evaluaciones_reglamento_ibfk_1 FOREIGN KEY (reunion_id) REFERENCES reuniones_reglamento (id),
  CONSTRAINT evaluaciones_reglamento_ibfk_2 FOREIGN KEY (item_id) REFERENCES items_reglamento_restaurante (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evaluaciones_reglamento`
--


--
-- Table structure for table `evidencias_inspeccion`
--

DROP TABLE IF EXISTS evidencias_inspeccion;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE evidencias_inspeccion (
  id int NOT NULL AUTO_INCREMENT,
  inspeccion_id int NOT NULL,
  item_detalle_id int DEFAULT NULL,
  filename varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  ruta_archivo varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  mime_type varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  tamano_bytes int DEFAULT NULL,
  uploaded_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY item_detalle_id (item_detalle_id),
  KEY idx_evidencias_inspeccion (inspeccion_id),
  CONSTRAINT evidencias_inspeccion_ibfk_1 FOREIGN KEY (inspeccion_id) REFERENCES inspecciones (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT evidencias_inspeccion_ibfk_2 FOREIGN KEY (item_detalle_id) REFERENCES inspeccion_detalles (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `evidencias_inspeccion`
--

INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (5,16,NULL,'evidencia_16_102855_193.avif','evidencias\\Déjà_vu\\2025-09-01\\evidencia_16_102855_193.avif',NULL,'image/avif',53822,'2025-09-01 15:28:55');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (6,17,NULL,'evidencia_17_144653_257.jpg','evidencias\\Déjà_vu\\2025-09-12\\evidencia_17_144653_257.jpg',NULL,'image/jpeg',7267,'2025-09-12 19:46:53');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (7,19,NULL,'evidencia_19_105118_562.avif','evidencias\\Déjà_vu\\2025-09-25\\evidencia_19_105118_562.avif',NULL,'image/avif',53822,'2025-09-25 15:51:19');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (8,20,NULL,'evidencia_20_121103_596.jpeg','static/evidencias/Déjà_vu/2025-09-25/evidencia_20_121103_596.jpeg',NULL,'image/jpeg',9687,'2025-09-25 17:11:04');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (11,25,NULL,'evidencia_25_124638_604.jpg','static/evidencias/Déjà_vu/2025-10-02/evidencia_25_124638_604.jpg',NULL,'image/jpeg',39289,'2025-10-02 17:46:39');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (12,25,NULL,'evidencia_25_124638_809.jpg','static/evidencias/Déjà_vu/2025-10-02/evidencia_25_124638_809.jpg',NULL,'image/jpg',39289,'2025-10-02 17:46:39');
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (15,43,NULL,'evidencia_43_162138_079.jpeg','static/evidencias/Silvia/2025-10-10/evidencia_43_162138_079.jpeg',NULL,'image/jpeg',9687,'2025-10-10 21:21:38');

--
-- Table structure for table `firmas_encargados_por_jefe`
--

DROP TABLE IF EXISTS firmas_encargados_por_jefe;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE firmas_encargados_por_jefe (
  id int NOT NULL AUTO_INCREMENT,
  jefe_id int NOT NULL,
  encargado_id int NOT NULL,
  establecimiento_id int NOT NULL,
  path_firma varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  fecha_firma timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activa tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY jefe_id (jefe_id),
  KEY encargado_id (encargado_id),
  KEY establecimiento_id (establecimiento_id),
  KEY idx_firma_activa (activa),
  KEY idx_firma_fecha (fecha_firma),
  CONSTRAINT firmas_encargados_por_jefe_ibfk_1 FOREIGN KEY (jefe_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT firmas_encargados_por_jefe_ibfk_2 FOREIGN KEY (encargado_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT firmas_encargados_por_jefe_ibfk_3 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firmas_encargados_por_jefe`
--

INSERT INTO firmas_encargados_por_jefe (id, jefe_id, encargado_id, establecimiento_id, path_firma, fecha_firma, activa, created_at) VALUES (8,7,2,1,'img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-01 10:54:53',1,'2025-09-01 17:59:42');
INSERT INTO firmas_encargados_por_jefe (id, jefe_id, encargado_id, establecimiento_id, path_firma, fecha_firma, activa, created_at) VALUES (9,7,3,2,'img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-02 17:33:22',1,'2025-10-02 17:33:22');
INSERT INTO firmas_encargados_por_jefe (id, jefe_id, encargado_id, establecimiento_id, path_firma, fecha_firma, activa, created_at) VALUES (10,7,63,1,'img/firmas/Déjà_vu/firma_63_20251016_155018.png','2025-10-16 20:50:18',1,'2025-10-16 20:50:18');

--
-- Table structure for table `historial_metas_semanales`
--

DROP TABLE IF EXISTS historial_metas_semanales;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE historial_metas_semanales (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  establecimiento_id int DEFAULT NULL,
  meta_anterior int NOT NULL,
  meta_nueva int NOT NULL,
  fecha_cambio timestamp NOT NULL,
  razon_cambio varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  tipo_cambio enum('global','individual') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY establecimiento_id (establecimiento_id),
  CONSTRAINT historial_metas_semanales_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
  CONSTRAINT historial_metas_semanales_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_metas_semanales`
--

INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (1,1,1,0,3,'2025-09-01 15:28:55','Migración inicial - Meta existente al momento de la primera inspección','individual','2025-10-15 17:02:00');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (2,1,2,0,3,'2025-10-03 23:28:30','Migración inicial - Meta existente al momento de la primera inspección','individual','2025-10-15 17:02:00');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (3,1,1,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (4,1,2,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (5,1,3,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (6,1,4,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (7,1,6,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (8,1,7,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (9,1,9,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');
INSERT INTO historial_metas_semanales (id, usuario_id, establecimiento_id, meta_anterior, meta_nueva, fecha_cambio, razon_cambio, tipo_cambio, created_at) VALUES (10,1,10,3,5,'2025-10-15 17:03:15','Prueba de cambio de meta semanal','global','2025-10-15 17:03:15');

--
-- Table structure for table `inspeccion_detalles`
--

DROP TABLE IF EXISTS inspeccion_detalles;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE inspeccion_detalles (
  id int NOT NULL AUTO_INCREMENT,
  inspeccion_id int NOT NULL,
  item_establecimiento_id int NOT NULL,
  rating int DEFAULT NULL,
  score decimal(5,2) DEFAULT NULL,
  observacion_item text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_inspeccion_item (inspeccion_id,item_establecimiento_id),
  KEY item_establecimiento_id (item_establecimiento_id),
  CONSTRAINT inspeccion_detalles_ibfk_1 FOREIGN KEY (inspeccion_id) REFERENCES inspecciones (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT inspeccion_detalles_ibfk_2 FOREIGN KEY (item_establecimiento_id) REFERENCES items_evaluacion_establecimiento (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2019 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspeccion_detalles`
--

INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (511,16,4,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (512,16,8,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (513,16,12,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (514,16,16,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (515,16,20,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (516,16,24,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (517,16,28,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (518,16,32,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (519,16,36,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (520,16,40,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (521,16,44,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (522,16,48,7,7.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (523,16,52,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (524,16,56,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (525,16,60,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (526,16,64,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (527,16,68,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (528,16,72,7,7.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (529,16,76,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (530,16,80,7,7.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (531,16,84,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (532,16,88,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (533,16,92,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (534,16,96,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (535,16,100,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (536,16,104,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (537,16,108,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (538,16,112,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (539,16,116,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (540,16,120,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (541,16,124,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (542,16,128,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (543,16,132,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (544,16,136,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (545,16,140,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (546,16,144,7,7.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (547,16,148,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (548,16,152,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (549,16,156,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (550,16,160,8,8.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (551,16,164,7,7.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (552,16,168,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (553,16,172,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (554,16,176,4,4.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (555,16,180,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (556,16,184,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (557,16,188,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (558,16,192,3,3.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (559,16,196,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (560,16,200,2,2.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (561,16,204,1,1.00,'','2025-09-01 15:28:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (562,17,4,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (563,17,8,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (564,17,12,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (565,17,16,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (566,17,20,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (567,17,24,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (568,17,28,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (569,17,32,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (570,17,36,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (571,17,40,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (572,17,44,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (573,17,48,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (574,17,52,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (575,17,56,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (576,17,60,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (577,17,64,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (578,17,68,7,7.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (579,17,72,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (580,17,76,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (581,17,80,7,7.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (582,17,84,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (583,17,88,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (584,17,92,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (585,17,96,7,7.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (586,17,100,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (587,17,104,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (588,17,108,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (589,17,112,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (590,17,116,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (591,17,120,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (592,17,124,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (593,17,128,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (594,17,132,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (595,17,136,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (596,17,140,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (597,17,144,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (598,17,148,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (599,17,152,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (600,17,156,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (601,17,160,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (602,17,164,8,8.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (603,17,168,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (604,17,172,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (605,17,176,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (606,17,180,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (607,17,184,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (608,17,188,3,3.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (609,17,192,4,4.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (610,17,196,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (611,17,200,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (612,17,204,2,2.00,'','2025-09-12 19:46:53');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (613,19,4,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (614,19,8,2,2.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (615,19,12,4,4.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (616,19,16,2,2.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (617,19,20,2,2.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (618,19,24,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (619,19,28,1,1.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (620,19,32,4,4.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (621,19,36,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (622,19,40,4,4.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (623,19,44,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (624,19,48,5,5.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (625,19,52,4,4.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (626,19,56,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (627,19,60,3,3.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (628,19,64,4,4.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (629,19,68,8,8.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (630,19,72,8,8.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (631,19,76,8,8.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (632,19,80,8,8.00,'','2025-09-25 15:51:18');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (633,19,84,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (634,19,88,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (635,19,92,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (636,19,96,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (637,19,100,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (638,19,104,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (639,19,108,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (640,19,112,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (641,19,116,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (642,19,120,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (643,19,124,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (644,19,128,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (645,19,132,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (646,19,136,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (647,19,140,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (648,19,144,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (649,19,148,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (650,19,152,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (651,19,156,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (652,19,160,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (653,19,164,8,8.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (654,19,168,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (655,19,172,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (656,19,176,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (657,19,180,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (658,19,184,1,1.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (659,19,188,4,4.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (660,19,192,3,3.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (661,19,196,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (662,19,200,2,2.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (663,19,204,1,1.00,'','2025-09-25 15:51:19');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (664,20,4,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (665,20,8,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (666,20,12,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (667,20,16,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (668,20,20,1,1.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (669,20,24,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (670,20,28,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (671,20,32,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (672,20,36,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (673,20,40,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (674,20,44,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (675,20,48,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (676,20,52,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (677,20,56,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (678,20,60,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (679,20,64,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (680,20,68,7,7.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (681,20,72,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (682,20,76,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (683,20,80,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (684,20,84,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (685,20,88,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (686,20,92,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (687,20,96,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (688,20,100,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (689,20,104,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (690,20,108,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (691,20,112,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (692,20,116,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (693,20,120,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (694,20,124,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (695,20,128,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (696,20,132,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (697,20,136,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (698,20,140,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (699,20,144,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (700,20,148,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (701,20,152,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (702,20,156,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (703,20,160,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (704,20,164,8,8.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (705,20,168,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (706,20,172,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (707,20,176,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (708,20,180,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (709,20,184,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (710,20,188,3,3.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (711,20,192,4,4.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (712,20,196,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (713,20,200,2,2.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (714,20,204,1,1.00,'','2025-09-25 17:11:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (919,25,4,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (920,25,8,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (921,25,12,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (922,25,16,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (923,25,20,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (924,25,24,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (925,25,28,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (926,25,32,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (927,25,36,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (928,25,40,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (929,25,44,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (930,25,48,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (931,25,52,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (932,25,56,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (933,25,60,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (934,25,64,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (935,25,68,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (936,25,72,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (937,25,76,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (938,25,80,7,7.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (939,25,84,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (940,25,88,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (941,25,92,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (942,25,96,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (943,25,100,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (944,25,104,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (945,25,108,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (946,25,112,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (947,25,116,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (948,25,120,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (949,25,124,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (950,25,128,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (951,25,132,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (952,25,136,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (953,25,140,7,7.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (954,25,144,7,7.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (955,25,148,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (956,25,152,7,7.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (957,25,156,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (958,25,160,7,7.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (959,25,164,8,8.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (960,25,168,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (961,25,172,4,4.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (962,25,176,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (963,25,180,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (964,25,184,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (965,25,188,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (966,25,192,3,3.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (967,25,196,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (968,25,200,2,2.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (969,25,204,1,1.00,'','2025-10-02 17:46:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1032,30,3,4,4.00,'','2025-10-03 23:28:30');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1033,30,7,2,2.00,'','2025-10-03 23:28:30');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1034,30,11,4,4.00,'','2025-10-04 15:24:02');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1035,30,15,2,2.00,'','2025-10-04 15:24:02');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1036,30,19,2,2.00,'','2025-10-04 15:24:02');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1037,30,23,3,3.00,'','2025-10-04 15:24:02');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1038,30,27,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1039,30,31,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1040,30,35,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1041,30,39,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1042,30,79,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1043,30,83,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1044,30,87,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1045,30,91,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1046,30,95,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1047,30,99,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1048,30,103,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1049,30,107,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1050,30,111,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1051,30,115,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1052,30,119,1,1.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1053,30,123,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1054,30,127,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1055,30,131,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1056,30,135,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1057,30,139,7,7.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1058,30,143,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1059,30,147,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1060,30,151,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1061,30,155,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1062,30,159,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1063,30,163,8,8.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1064,30,167,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1065,30,171,4,4.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1066,30,175,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1067,30,179,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1068,30,183,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1069,30,187,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1070,30,191,3,3.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1071,30,195,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1072,30,199,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1073,30,203,2,2.00,'','2025-10-04 15:39:52');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1074,30,43,4,4.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1075,30,47,7,7.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1076,30,51,4,4.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1077,30,55,3,3.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1078,30,59,4,4.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1079,30,63,4,4.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1080,30,67,8,8.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1081,30,71,7,7.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1082,30,75,8,8.00,'','2025-10-10 20:01:50');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1083,31,3,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1084,31,7,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1085,31,11,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1086,31,15,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1087,31,19,1,1.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1088,31,23,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1089,31,27,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1090,31,31,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1091,31,35,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1092,31,39,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1093,31,43,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1094,31,47,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1095,31,51,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1096,31,55,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1097,31,59,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1098,31,63,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1099,31,67,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1100,31,71,7,7.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1101,31,75,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1102,31,79,7,7.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1103,31,83,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1104,31,87,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1105,31,91,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1106,31,95,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1107,31,99,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1108,31,103,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1109,31,107,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1110,31,111,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1111,31,115,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1112,31,119,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1113,31,123,1,1.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1114,31,127,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1115,31,131,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1116,31,135,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1117,31,139,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1118,31,143,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1119,31,147,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1120,31,151,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1121,31,155,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1122,31,159,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1123,31,163,8,8.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1124,31,167,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1125,31,171,4,4.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1126,31,175,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1127,31,179,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1128,31,183,1,1.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1129,31,187,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1130,31,191,3,3.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1131,31,195,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1132,31,199,1,1.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1133,31,203,2,2.00,'','2025-10-10 20:03:40');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1134,32,3,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1135,32,7,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1136,32,11,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1137,32,15,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1138,32,19,1,1.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1139,32,23,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1140,32,27,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1141,32,31,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1142,32,35,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1143,32,39,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1144,32,43,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1145,32,47,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1146,32,51,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1147,32,55,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1148,32,59,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1149,32,63,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1150,32,67,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1151,32,71,7,7.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1152,32,75,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1153,32,79,7,7.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1154,32,83,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1155,32,87,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1156,32,91,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1157,32,95,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1158,32,99,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1159,32,103,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1160,32,107,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1161,32,111,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1162,32,115,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1163,32,119,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1164,32,123,1,1.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1165,32,127,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1166,32,131,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1167,32,135,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1168,32,139,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1169,32,143,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1170,32,147,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1171,32,151,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1172,32,155,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1173,32,159,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1174,32,163,8,8.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1175,32,167,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1176,32,171,4,4.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1177,32,175,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1178,32,179,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1179,32,183,1,1.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1180,32,187,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1181,32,191,3,3.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1182,32,195,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1183,32,199,1,1.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1184,32,203,2,2.00,'','2025-10-10 20:51:10');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1185,42,3,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1186,42,7,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1187,42,11,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1188,42,15,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1189,42,19,1,1.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1190,42,23,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1191,42,27,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1192,42,31,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1193,42,35,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1194,42,39,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1195,42,43,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1196,42,47,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1197,42,51,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1198,42,55,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1199,42,59,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1200,42,63,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1201,42,67,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1202,42,71,7,7.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1203,42,75,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1204,42,79,7,7.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1205,42,83,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1206,42,87,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1207,42,91,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1208,42,95,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1209,42,99,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1210,42,103,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1211,42,107,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1212,42,111,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1213,42,115,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1214,42,119,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1215,42,123,1,1.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1216,42,127,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1217,42,131,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1218,42,135,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1219,42,139,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1220,42,143,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1221,42,147,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1222,42,151,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1223,42,155,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1224,42,159,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1225,42,163,8,8.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1226,42,167,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1227,42,171,4,4.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1228,42,175,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1229,42,179,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1230,42,183,1,1.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1231,42,187,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1232,42,191,3,3.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1233,42,195,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1234,42,199,1,1.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1235,42,203,2,2.00,'','2025-10-10 21:14:23');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1236,43,3,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1237,43,7,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1238,43,11,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1239,43,15,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1240,43,19,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1241,43,23,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1242,43,27,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1243,43,31,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1244,43,35,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1245,43,39,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1246,43,43,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1247,43,47,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1248,43,51,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1249,43,55,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1250,43,59,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1251,43,63,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1252,43,67,7,7.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1253,43,71,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1254,43,75,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1255,43,79,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1256,43,83,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1257,43,87,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1258,43,91,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1259,43,95,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1260,43,99,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1261,43,103,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1262,43,107,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1263,43,111,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1264,43,115,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1265,43,119,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1266,43,123,1,1.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1267,43,127,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1268,43,131,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1269,43,135,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1270,43,139,7,7.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1271,43,143,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1272,43,147,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1273,43,151,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1274,43,155,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1275,43,159,7,7.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1276,43,163,8,8.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1277,43,167,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1278,43,171,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1279,43,175,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1280,43,179,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1281,43,183,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1282,43,187,3,3.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1283,43,191,4,4.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1284,43,195,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1285,43,199,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1286,43,203,2,2.00,'','2025-10-10 21:21:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1287,44,4,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1288,44,8,1,1.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1289,44,12,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1290,44,16,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1291,44,20,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1292,44,24,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1293,44,28,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1294,44,32,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1295,44,36,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1296,44,40,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1297,44,44,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1298,44,48,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1299,44,52,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1300,44,56,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1301,44,60,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1302,44,64,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1303,44,68,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1304,44,72,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1305,44,76,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1306,44,80,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1307,44,84,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1308,44,88,1,1.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1309,44,92,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1310,44,96,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1311,44,100,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1312,44,104,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1313,44,108,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1314,44,112,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1315,44,116,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1316,44,120,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1317,44,124,1,1.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1318,44,128,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1319,44,132,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1320,44,136,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1321,44,140,7,7.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1322,44,144,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1323,44,148,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1324,44,152,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1325,44,156,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1326,44,160,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1327,44,164,8,8.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1328,44,168,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1329,44,172,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1330,44,176,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1331,44,180,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1332,44,184,1,1.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1333,44,188,4,4.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1334,44,192,3,3.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1335,44,196,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1336,44,200,1,1.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1337,44,204,2,2.00,'','2025-10-10 21:25:39');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1338,45,4,1,1.00,'','2025-10-10 21:42:58');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1339,45,3,0,0.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1340,45,7,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1341,45,8,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1342,45,11,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1343,45,12,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1344,45,15,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1345,45,16,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1346,45,19,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1347,45,20,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1348,45,23,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1349,45,24,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1350,45,28,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1351,45,32,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1352,45,36,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1353,45,40,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1354,45,44,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1355,45,48,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1356,45,52,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1357,45,56,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1358,45,60,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1359,45,64,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1360,45,68,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1361,45,72,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1362,45,76,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1363,45,80,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1364,45,84,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1365,45,88,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1366,45,92,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1367,45,96,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1368,45,100,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1369,45,104,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1370,45,112,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1371,45,116,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1372,45,120,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1373,45,124,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1374,45,128,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1375,45,132,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1376,45,136,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1377,45,140,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1378,45,144,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1379,45,148,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1380,45,152,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1381,45,156,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1382,45,160,3,3.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1383,45,164,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1384,45,168,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1385,45,172,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1386,45,176,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1387,45,180,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1388,45,184,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1389,45,188,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1390,45,192,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1391,45,196,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1392,45,200,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1393,45,204,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1394,45,358,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1395,45,359,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1396,45,360,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1397,45,361,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1398,45,362,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1399,45,363,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1400,45,364,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1401,45,365,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1402,45,366,3,3.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1403,45,367,1,1.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1404,45,368,2,2.00,'','2025-10-10 21:50:08');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1405,46,4,0,0.00,'','2025-10-10 22:36:03');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1406,46,8,1,1.00,'','2025-10-10 22:36:03');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1407,46,12,0,0.00,'','2025-10-10 22:36:03');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1408,46,16,1,1.00,'','2025-10-10 22:36:03');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1409,46,20,1,1.00,'','2025-10-10 22:36:03');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1410,46,24,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1411,46,28,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1412,46,32,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1413,46,36,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1414,46,40,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1415,46,44,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1416,46,48,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1417,46,52,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1418,46,56,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1419,46,60,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1420,46,64,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1421,46,68,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1422,46,72,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1423,46,76,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1424,46,80,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1425,46,84,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1426,46,88,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1427,46,92,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1428,46,96,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1429,46,100,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1430,46,104,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1431,46,108,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1432,46,112,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1433,46,116,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1434,46,120,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1435,46,124,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1436,46,128,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1437,46,132,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1438,46,136,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1439,46,140,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1440,46,144,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1441,46,148,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1442,46,152,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1443,46,156,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1444,46,160,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1445,46,164,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1446,46,168,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1447,46,172,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1448,46,176,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1449,46,180,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1450,46,184,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1451,46,188,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1452,46,192,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1453,46,196,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1454,46,200,2,2.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1455,46,204,1,1.00,'','2025-10-10 22:36:04');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1456,47,4,4,4.00,'','2025-10-16 17:49:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1457,47,8,2,2.00,'','2025-10-16 17:49:38');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1458,47,3,0,0.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1459,47,7,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1460,47,11,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1461,47,15,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1462,47,19,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1463,47,23,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1464,47,27,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1465,47,31,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1466,47,35,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1467,47,39,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1468,47,43,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1469,47,47,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1470,47,51,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1471,47,55,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1472,47,59,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1473,47,63,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1474,47,67,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1475,47,71,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1476,47,75,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1477,47,79,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1478,47,83,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1479,47,87,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1480,47,91,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1481,47,95,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1482,47,99,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1483,47,103,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1484,47,107,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1485,47,111,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1486,47,115,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1487,47,119,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1488,47,123,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1489,47,127,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1490,47,131,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1491,47,135,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1492,47,139,3,3.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1493,47,143,3,3.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1494,47,147,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1495,47,151,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1496,47,155,3,3.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1497,47,159,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1498,47,163,3,3.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1499,47,167,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1500,47,171,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1501,47,175,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1502,47,179,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1503,47,183,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1504,47,187,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1505,47,191,3,3.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1506,47,195,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1507,47,199,2,2.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1508,47,203,1,1.00,'','2025-10-16 20:18:36');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1509,48,4,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1510,48,8,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1511,48,12,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1512,48,16,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1513,48,20,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1514,48,24,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1515,48,28,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1516,48,32,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1517,48,36,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1518,48,40,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1519,48,44,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1520,48,48,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1521,48,52,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1522,48,56,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1523,48,60,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1524,48,64,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1525,48,68,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1526,48,72,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1527,48,76,3,3.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1528,48,80,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1529,48,84,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1530,48,88,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1531,48,92,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1532,48,96,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1533,48,100,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1534,48,104,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1535,48,108,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1536,48,112,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1537,48,116,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1538,48,120,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1539,48,124,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1540,48,128,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1541,48,132,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1542,48,136,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1543,48,140,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1544,48,144,8,8.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1545,48,148,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1546,48,152,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1547,48,156,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1548,48,160,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1549,48,164,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1550,48,168,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1551,48,172,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1552,48,176,1,1.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1553,48,180,2,2.00,'','2025-10-16 20:55:59');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1554,48,184,1,1.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1555,48,188,2,2.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1556,48,192,1,1.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1557,48,196,2,2.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1558,48,200,1,1.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1559,48,204,2,2.00,'','2025-10-16 20:56:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1560,49,4,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1561,49,8,1,1.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1562,49,12,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1563,49,16,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1564,49,20,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1565,49,24,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1566,49,28,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1567,49,32,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1568,49,36,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1569,49,40,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1570,49,44,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1571,49,48,5,5.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1572,49,52,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1573,49,56,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1574,49,60,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1575,49,64,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1576,49,68,8,8.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1577,49,72,7,7.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1578,49,76,8,8.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1579,49,80,8,8.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1580,49,84,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1581,49,88,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1582,49,92,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1583,49,96,8,8.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1584,49,100,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1585,49,104,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1586,49,108,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1587,49,112,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1588,49,116,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1589,49,120,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1590,49,124,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1591,49,128,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1592,49,132,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1593,49,136,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1594,49,140,7,7.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1595,49,144,8,8.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1596,49,148,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1597,49,152,7,7.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1598,49,156,4,4.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1599,49,160,7,7.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1600,49,164,7,7.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1601,49,168,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1602,49,172,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1603,49,176,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1604,49,180,1,1.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1605,49,184,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1606,49,188,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1607,49,192,3,3.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1608,49,196,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1609,49,200,1,1.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1610,49,204,2,2.00,'','2025-10-20 15:38:55');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1611,50,4,4,4.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1612,50,8,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1613,50,12,4,4.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1614,50,16,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1615,50,20,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1616,50,24,4,4.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1617,50,28,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1618,50,32,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1619,50,36,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1620,50,40,4,4.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1621,50,44,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1622,50,48,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1623,50,52,4,4.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1624,50,56,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1625,50,60,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1626,50,64,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1627,50,68,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1628,50,72,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1629,50,76,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1630,50,80,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1631,50,84,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1632,50,88,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1633,50,92,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1634,50,96,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1635,50,100,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1636,50,104,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1637,50,108,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1638,50,112,1,1.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1639,50,116,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1640,50,120,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1641,50,124,1,1.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1642,50,128,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1643,50,132,1,1.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1644,50,136,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1645,50,140,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1646,50,144,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1647,50,148,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1648,50,152,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1649,50,156,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1650,50,160,7,7.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1651,50,164,8,8.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1652,50,168,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1653,50,172,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1654,50,176,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1655,50,180,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1656,50,184,1,1.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1657,50,188,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1658,50,192,3,3.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1659,50,196,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1660,50,200,1,1.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1661,50,204,2,2.00,'','2025-10-20 16:17:41');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1662,51,4,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1663,51,8,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1664,51,12,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1665,51,16,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1666,51,20,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1667,51,24,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1668,51,28,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1669,51,32,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1670,51,36,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1671,51,40,4,4.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1672,51,44,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1673,51,48,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1674,51,52,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1675,51,56,4,4.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1676,51,60,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1677,51,64,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1678,51,68,8,8.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1679,51,72,8,8.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1680,51,76,8,8.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1681,51,80,6,6.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1682,51,84,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1683,51,88,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1684,51,92,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1685,51,96,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1686,51,100,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1687,51,104,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1688,51,108,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1689,51,112,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1690,51,116,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1691,51,120,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1692,51,124,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1693,51,128,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1694,51,132,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1695,51,136,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1696,51,140,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1697,51,144,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1698,51,148,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1699,51,152,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1700,51,156,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1701,51,160,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1702,51,164,7,7.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1703,51,168,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1704,51,172,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1705,51,176,4,4.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1706,51,180,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1707,51,184,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1708,51,188,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1709,51,192,3,3.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1710,51,196,1,1.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1711,51,200,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1712,51,204,2,2.00,'','2025-10-20 16:56:21');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1713,52,4,4,4.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1714,52,8,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1715,52,12,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1716,52,16,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1717,52,20,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1718,52,24,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1719,52,28,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1720,52,32,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1721,52,36,4,4.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1722,52,40,4,4.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1723,52,44,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1724,52,48,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1725,52,52,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1726,52,56,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1727,52,60,4,4.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1728,52,64,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1729,52,68,8,8.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1730,52,72,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1731,52,76,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1732,52,80,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1733,52,84,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1734,52,88,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1735,52,92,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1736,52,96,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1737,52,100,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1738,52,104,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1739,52,108,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1740,52,112,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1741,52,116,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1742,52,120,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1743,52,124,1,1.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1744,52,128,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1745,52,132,1,1.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1746,52,136,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1747,52,140,6,6.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1748,52,144,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1749,52,148,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1750,52,152,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1751,52,156,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1752,52,160,7,7.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1753,52,164,6,6.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1754,52,168,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1755,52,172,4,4.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1756,52,176,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1757,52,180,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1758,52,184,1,1.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1759,52,188,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1760,52,192,3,3.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1761,52,196,1,1.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1762,52,200,2,2.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1763,52,204,1,1.00,'','2025-10-20 17:15:28');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1764,53,4,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1765,53,8,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1766,53,12,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1767,53,16,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1768,53,20,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1769,53,24,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1770,53,28,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1771,53,32,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1772,53,36,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1773,53,40,4,4.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1774,53,44,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1775,53,48,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1776,53,52,4,4.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1777,53,56,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1778,53,60,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1779,53,64,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1780,53,68,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1781,53,72,8,8.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1782,53,76,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1783,53,80,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1784,53,84,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1785,53,88,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1786,53,92,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1787,53,96,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1788,53,100,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1789,53,104,4,4.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1790,53,108,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1791,53,112,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1792,53,116,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1793,53,120,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1794,53,124,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1795,53,128,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1796,53,132,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1797,53,136,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1798,53,140,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1799,53,144,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1800,53,148,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1801,53,152,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1802,53,156,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1803,53,160,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1804,53,164,7,7.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1805,53,168,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1806,53,172,4,4.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1807,53,176,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1808,53,180,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1809,53,184,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1810,53,188,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1811,53,192,3,3.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1812,53,196,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1813,53,200,1,1.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1814,53,204,2,2.00,'','2025-10-20 17:31:07');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1815,54,3,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1816,54,7,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1817,54,11,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1818,54,15,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1819,54,19,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1820,54,23,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1821,54,27,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1822,54,31,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1823,54,35,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1824,54,39,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1825,54,43,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1826,54,47,7,7.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1827,54,51,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1828,54,55,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1829,54,59,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1830,54,63,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1831,54,67,7,7.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1832,54,71,8,8.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1833,54,75,7,7.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1834,54,79,8,8.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1835,54,83,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1836,54,87,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1837,54,91,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1838,54,95,6,6.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1839,54,99,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1840,54,103,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1841,54,107,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1842,54,111,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1843,54,115,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1844,54,119,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1845,54,123,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1846,54,127,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1847,54,131,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1848,54,135,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1849,54,139,6,6.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1850,54,143,7,7.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1851,54,147,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1852,54,151,7,7.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1853,54,155,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1854,54,159,6,6.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1855,54,163,6,6.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1856,54,167,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1857,54,171,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1858,54,175,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1859,54,179,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1860,54,183,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1861,54,187,4,4.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1862,54,191,3,3.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1863,54,195,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1864,54,199,1,1.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1865,54,203,2,2.00,'','2025-10-20 17:50:15');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1866,55,3,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1867,55,7,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1868,55,11,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1869,55,15,1,1.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1870,55,19,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1871,55,23,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1872,55,27,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1873,55,31,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1874,55,35,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1875,55,39,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1876,55,43,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1877,55,47,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1878,55,51,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1879,55,55,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1880,55,59,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1881,55,63,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1882,55,67,8,8.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1883,55,71,6,6.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1884,55,75,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1885,55,79,6,6.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1886,55,83,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1887,55,87,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1888,55,91,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1889,55,95,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1890,55,99,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1891,55,103,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1892,55,107,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1893,55,111,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1894,55,115,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1895,55,119,1,1.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1896,55,123,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1897,55,127,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1898,55,131,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1899,55,135,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1900,55,139,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1901,55,143,6,6.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1902,55,147,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1903,55,151,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1904,55,155,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1905,55,159,7,7.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1906,55,163,8,8.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1907,55,167,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1908,55,171,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1909,55,175,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1910,55,179,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1911,55,183,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1912,55,187,3,3.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1913,55,191,4,4.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1914,55,195,1,1.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1915,55,199,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1916,55,203,2,2.00,'','2025-10-20 19:47:35');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1917,56,4,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1918,56,8,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1919,56,12,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1920,56,16,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1921,56,20,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1922,56,24,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1923,56,28,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1924,56,32,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1925,56,36,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1926,56,40,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1927,56,44,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1928,56,48,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1929,56,52,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1930,56,56,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1931,56,60,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1932,56,64,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1933,56,68,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1934,56,72,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1935,56,76,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1936,56,80,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1937,56,84,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1938,56,88,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1939,56,92,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1940,56,96,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1941,56,100,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1942,56,104,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1943,56,108,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1944,56,112,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1945,56,116,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1946,56,120,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1947,56,124,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1948,56,128,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1949,56,132,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1950,56,136,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1951,56,140,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1952,56,144,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1953,56,148,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1954,56,152,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1955,56,156,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1956,56,160,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1957,56,164,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1958,56,168,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1959,56,172,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1960,56,176,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1961,56,180,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1962,56,184,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1963,56,188,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1964,56,192,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1965,56,196,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1966,56,200,2,2.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1967,56,204,1,1.00,'','2025-10-20 21:23:06');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1968,57,3,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1969,57,7,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1970,57,11,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1971,57,15,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1972,57,19,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1973,57,23,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1974,57,27,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1975,57,31,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1976,57,35,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1977,57,39,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1978,57,43,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1979,57,47,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1980,57,51,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1981,57,55,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1982,57,59,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1983,57,63,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1984,57,67,7,7.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1985,57,71,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1986,57,75,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1987,57,79,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1988,57,83,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1989,57,87,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1990,57,91,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1991,57,95,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1992,57,99,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1993,57,103,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1994,57,107,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1995,57,111,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1996,57,115,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1997,57,119,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1998,57,123,1,1.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (1999,57,127,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2000,57,131,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2001,57,135,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2002,57,139,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2003,57,143,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2004,57,147,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2005,57,151,7,7.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2006,57,155,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2007,57,159,8,8.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2008,57,163,7,7.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2009,57,167,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2010,57,171,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2011,57,175,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2012,57,179,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2013,57,183,1,1.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2014,57,187,3,3.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2015,57,191,4,4.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2016,57,195,2,2.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2017,57,199,1,1.00,'','2025-11-03 20:26:00');
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (2018,57,203,2,2.00,'','2025-11-03 20:26:00');

--
-- Table structure for table `inspecciones`
--

DROP TABLE IF EXISTS inspecciones;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE inspecciones (
  id int NOT NULL AUTO_INCREMENT,
  establecimiento_id int NOT NULL,
  inspector_id int NOT NULL,
  encargado_id int DEFAULT NULL,
  fecha date NOT NULL,
  hora_inicio time DEFAULT NULL,
  hora_fin time DEFAULT NULL,
  observaciones text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  puntaje_total decimal(6,2) DEFAULT NULL,
  puntaje_maximo_posible decimal(6,2) DEFAULT NULL,
  porcentaje_cumplimiento decimal(5,2) DEFAULT NULL,
  puntos_criticos_perdidos int DEFAULT NULL,
  estado enum('pendiente','en_proceso','completada') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'pendiente',
  firma_inspector varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  firma_encargado varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  fecha_firma_inspector timestamp NULL DEFAULT NULL,
  fecha_firma_encargado timestamp NULL DEFAULT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_inspecciones_fecha (fecha),
  KEY idx_inspecciones_establecimiento_fecha (establecimiento_id,fecha),
  KEY idx_inspecciones_estado (estado),
  KEY idx_inspecciones_inspector (inspector_id),
  KEY idx_inspecciones_encargado (encargado_id),
  CONSTRAINT inspecciones_ibfk_1 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT inspecciones_ibfk_2 FOREIGN KEY (inspector_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT inspecciones_ibfk_3 FOREIGN KEY (encargado_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspecciones`
--

INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (16,1,1,2,'2025-09-01',NULL,'10:28:55','Mejorar la limpieza de pisos',208.00,220.00,94.55,5,'completada','/static/img/firmas/firma_inspector_16_1_20250901_102855_d27924f4.avif','/static/img/firmas/firma_encargado_16_2_20250901_102855_ac82360e.jpeg','2025-09-01 10:28:55','2025-09-01 10:28:55','2025-09-01 15:28:55','2025-09-01 15:28:55');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (17,1,1,2,'2025-09-12',NULL,'14:46:53','Todo está correcto',208.00,220.00,94.55,3,'completada','/static/img/firmas/firma_inspector_17_1_20250912_144653_6d75c00f.jpeg','/static/img/firmas/firma_encargado_17_2_20250912_144653_3e3fa9b1.avif','2025-09-12 14:46:53','2025-09-12 14:46:53','2025-09-12 19:46:53','2025-09-12 19:46:53');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (19,1,1,2,'2025-09-25',NULL,'10:51:18','Todo se encontró limpio',200.00,220.00,90.91,3,'completada','/static/img/firmas/firma_inspector_19_1_20250925_105118_cd5ed2d8.jpeg','/static/img/firmas/firma_encargado_19_2_20250925_105118_98d94faf.jpeg','2025-09-25 10:51:18','2025-09-25 10:51:18','2025-09-25 15:51:18','2025-09-25 15:51:19');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (20,1,1,2,'2025-09-25',NULL,'12:11:04','Todo está correcto',202.00,220.00,91.82,1,'completada','/static/img/firmas/firma_inspector_20_1_20250925_121103_e9861281.jpeg','/static/img/firmas/firma_encargado_20_2_20250925_121103_8c4a9334.jpeg','2025-09-25 12:11:04','2025-09-25 12:11:04','2025-09-25 17:11:04','2025-09-25 17:11:04');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (25,1,1,2,'2025-10-02',NULL,'12:46:39','Falta higiene ',199.00,220.00,90.45,5,'completada','/static/img/firmas/firma_inspector_1_20251002_115150.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-02 12:46:39','2025-10-02 12:46:39','2025-10-02 17:46:39','2025-10-02 17:46:39');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (30,2,1,3,'2025-10-03','18:28:30','16:15:56','',203.00,220.00,92.27,3,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-03 18:28:30','2025-10-10 16:15:56','2025-10-03 23:28:30','2025-10-10 21:15:56');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (31,2,1,3,'2025-10-10','15:03:40','16:17:18','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 15:03:40','2025-10-10 16:17:18','2025-10-10 20:03:40','2025-10-10 21:17:18');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (32,2,1,3,'2025-10-10','15:51:10','16:16:31','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 15:51:10','2025-10-10 16:16:31','2025-10-10 20:51:10','2025-10-10 21:16:31');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (42,2,1,3,'2025-10-10',NULL,'16:14:23','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:14:23','2025-10-10 16:14:23','2025-10-10 21:14:23','2025-10-10 21:14:23');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (43,2,1,3,'2025-10-10',NULL,'16:21:38','Observados',203.00,220.00,92.27,3,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:21:38','2025-10-10 16:21:38','2025-10-10 21:21:38','2025-10-10 21:21:38');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (44,1,1,2,'2025-10-10',NULL,'16:25:39','',196.00,220.00,89.09,1,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:25:39','2025-10-10 16:25:39','2025-10-10 21:25:39','2025-10-10 21:25:39');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (45,1,13,2,'2025-10-10','16:42:58','16:50:08','',101.00,270.00,37.41,68,'completada','/static/img/firmas/firma_inspector_13_20251007_094518.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:42:58','2025-10-10 16:42:58','2025-10-10 21:42:58','2025-10-10 21:50:08');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (46,1,13,2,'2025-10-10',NULL,'17:36:03','',56.00,220.00,25.45,75,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 17:36:03','2025-10-10 17:36:03','2025-10-10 22:36:03','2025-10-10 22:36:04');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (47,1,13,2,'2025-10-16','12:49:38','15:18:36','',92.00,226.00,40.71,66,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-16 15:18:36','2025-10-16 12:49:38','2025-10-16 17:49:38','2025-10-16 20:18:36');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (48,1,13,2,'2025-10-16',NULL,'15:55:59','',87.00,220.00,39.55,64,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-16 15:55:59','2025-10-16 15:55:59','2025-10-16 20:55:59','2025-10-16 20:56:00');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (49,1,1,2,'2025-10-20',NULL,'10:38:55','',194.00,220.00,88.18,8,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 10:38:55','2025-10-20 10:38:55','2025-10-20 15:38:55','2025-10-20 15:38:55');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (50,1,13,2,'2025-10-20','11:17:41','11:21:11','',183.00,220.00,83.18,10,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 11:21:11','2025-10-20 11:21:11','2025-10-20 16:17:41','2025-10-20 16:21:11');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (51,1,13,2,'2025-10-20',NULL,'11:56:21','',180.00,220.00,81.82,9,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 11:56:21','2025-10-20 11:56:21','2025-10-20 16:56:21','2025-10-20 16:56:21');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (52,1,13,2,'2025-10-20',NULL,'12:15:28','',180.00,220.00,81.82,12,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 12:15:28','2025-10-20 12:15:28','2025-10-20 17:15:28','2025-10-20 17:15:28');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (53,1,13,2,'2025-10-20',NULL,'12:31:07','',176.00,220.00,80.00,10,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 12:31:07','2025-10-20 12:31:07','2025-10-20 17:31:07','2025-10-20 17:31:07');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (54,2,13,3,'2025-10-20',NULL,'12:50:15','',186.00,220.00,84.55,13,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 12:50:15','2025-10-20 12:50:15','2025-10-20 17:50:15','2025-10-20 17:50:15');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (55,2,1,3,'2025-10-20',NULL,'14:47:35','',192.00,220.00,87.27,12,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 14:47:35','2025-10-20 14:47:35','2025-10-20 19:47:35','2025-10-20 19:47:35');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (56,1,13,2,'2025-10-20',NULL,'16:23:06','',74.00,220.00,33.64,71,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-20 16:23:06','2025-10-20 16:23:06','2025-10-20 21:23:06','2025-10-20 21:23:06');
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (57,2,1,3,'2025-11-03',NULL,'15:26:00','',187.00,220.00,85.00,7,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-11-03 15:26:00','2025-11-03 15:26:00','2025-11-03 20:26:00','2025-11-03 20:26:00');

--
-- Table structure for table `inspector_establecimientos`
--

DROP TABLE IF EXISTS inspector_establecimientos;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE inspector_establecimientos (
  id int NOT NULL AUTO_INCREMENT,
  inspector_id int NOT NULL,
  establecimiento_id int NOT NULL,
  fecha_asignacion date NOT NULL,
  fecha_fin_asignacion date DEFAULT NULL,
  es_principal tinyint(1) DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY establecimiento_id (establecimiento_id),
  KEY idx_inspector_establecimiento (inspector_id,establecimiento_id),
  KEY idx_inspector_activo (activo),
  CONSTRAINT inspector_establecimientos_ibfk_1 FOREIGN KEY (inspector_id) REFERENCES usuarios (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT inspector_establecimientos_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspector_establecimientos`
--

INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (1,1,1,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01');
INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (2,1,2,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01');
INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (3,1,3,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01');
INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (4,1,4,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01');
INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (5,6,9,'2025-10-07',NULL,1,1,'2025-10-07 17:53:39');

--
-- Table structure for table `items_evaluacion_base`
--

DROP TABLE IF EXISTS items_evaluacion_base;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE items_evaluacion_base (
  id int NOT NULL AUTO_INCREMENT,
  categoria_id int NOT NULL,
  codigo varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  riesgo enum('Menor','Mayor','Crítico') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Menor',
  puntaje_minimo int NOT NULL,
  puntaje_maximo int NOT NULL,
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_categoria_codigo (categoria_id,codigo),
  CONSTRAINT items_evaluacion_base_ibfk_1 FOREIGN KEY (categoria_id) REFERENCES categorias_evaluacion (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_base`
--

INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (1,1,'1.1','Pisos y paredes sin suciedad visible ni humedad','Mayor',1,4,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (2,1,'1.2','Lavaderos libres de residuos','Menor',1,2,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (3,1,'1.3','Campana extractora limpia y operativa','Mayor',1,4,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (4,1,'1.4','Iluminación adecuada','Menor',1,2,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (5,1,'1.5','Gel antibacterial / Jabón líquido','Menor',1,2,5,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (6,1,'1.6','Personal de cocina con uniforme completo, limpio y buena higiene personal','Mayor',1,4,6,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (7,1,'1.7','Presencia de personas ajenas','Menor',1,2,7,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (8,1,'1.8','Insumos de limpieza alejados de alimentos y hornillas','Mayor',1,4,8,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (9,2,'2.1','Equipos completos, operativos y en buen estado','Mayor',1,4,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (10,2,'2.2','Limpieza y conservación de equipos','Mayor',1,4,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (11,2,'2.3','Constancia de mantenimiento de sus equipos cada 6 meses','Mayor',1,4,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (12,3,'3.1','Mise en place de carnes, pescados y mariscos','Crítico',1,8,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (13,3,'3.2','Mise en place de vegetales','Mayor',1,4,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (14,3,'3.3','Mise en place de complementos','Mayor',1,4,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (15,3,'3.4','Mise en place de salsas','Mayor',1,4,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (16,4,'4.1','Aspecto limpio del aceite','Mayor',1,4,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (17,4,'4.2','Separación de alimentos crudos y cocidos','Crítico',1,8,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (18,4,'4.3','Descongelación adecuada','Crítico',1,8,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (19,4,'4.4','Insumos en buen estado','Crítico',1,8,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (20,4,'4.5','Rotulado de productos','Crítico',1,8,5,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (21,4,'4.6','Verificación del agua potable (bidón y filtros de agua)','Mayor',1,4,6,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (22,5,'5.1','Basureros adecuados','Menor',1,2,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (23,5,'5.2','Eliminación diaria de basura en el lugar adecuado','Mayor',1,4,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (24,5,'5.3','Ausencia de insectos y cualquier animal','Crítico',1,8,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (25,5,'5.4','Bitácoras de limpieza y gestión de plagas','Mayor',1,4,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (26,6,'6.1','Buen estado de conservación','Mayor',1,4,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (27,6,'6.2','Vajillas y Utensilios limpios','Mayor',1,4,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (28,6,'6.3','Secado adecuado','Menor',1,2,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (29,6,'6.4','Tablas de picar separadas por color, en buen estado y limpias (se recomienda acero)','Mayor',1,4,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (30,7,'7.1','Pisos limpios','Menor',1,2,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (31,7,'7.2','Mesas y manteles limpios','Menor',1,2,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (32,7,'7.3','Personal con uniforme completo y limpio y buena higiene personal','Mayor',1,4,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (33,7,'7.4','Contar con implementos de atención','Menor',1,2,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (34,8,'8.1','Ordenado y limpio','Mayor',1,4,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (35,8,'8.2','Enlatados en buen estado y vigentes','Crítico',1,8,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (36,8,'8.3','Control de fechas de vencimiento de todos los productos','Crítico',1,8,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (37,8,'8.4','Ausencia de sustancias químicas','Mayor',1,4,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (38,9,'9.1','Extintores operativos y vigentes (plateado y rojo) con señalización, tarjeta de inspección y certificado','Crítico',1,8,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (39,9,'9.2','Botiquín de primeros auxilios completo con señalización','Mayor',1,4,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (40,9,'9.3','Balones de Gas: con seguridad y señalización','Crítico',1,8,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (41,9,'9.4','Sistema contra incendios operativo','Crítico',1,8,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (42,9,'9.5','Otras señalizaciones de salida, entrada, aforo, horario de atención, zona segura','Mayor',1,4,5,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (43,9,'9.6','Pisos antideslizantes en las cocinas y cintas en las escaleras y rampas','Mayor',1,4,6,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (44,9,'9.7','Luces de emergencia operativas con señalética y con certificado','Mayor',1,4,7,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (45,10,'10.1','POS operativo','Menor',1,2,1,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (46,10,'10.2','Caja chica disponible','Menor',1,2,2,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (47,10,'10.3','Facturas y boletas vigentes','Mayor',1,4,3,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (48,10,'10.4','Libro de reclamaciones','Mayor',1,4,4,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (49,10,'10.5','Cartas en buen estado','Menor',1,2,5,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (50,10,'10.6','Stock de bebidas','Menor',1,2,6,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (51,10,'10.7','Stock de envases y sachet','Menor',1,2,7,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (55,1,'1.9','Paredes con suciedad visible','Mayor',0,4,9,1,'2025-10-10 19:29:48');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (56,10,'10.8','Letreros en buen estado','Menor',0,2,8,1,'2025-10-10 22:06:59');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (57,1,'HIG-01','Vasos limpios','Mayor',1,4,999,1,'2025-10-17 15:52:54');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (58,1,'HIG-02','Vasos limpios','Mayor',1,4,999,1,'2025-10-17 15:54:09');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (59,1,'HIG-03','Vasos Limpios','Mayor',1,4,999,1,'2025-10-17 15:54:33');
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (60,1,'1.10','Vasos Limpios','Mayor',1,4,999,1,'2025-10-17 16:21:02');

--
-- Table structure for table `items_evaluacion_establecimiento`
--

DROP TABLE IF EXISTS items_evaluacion_establecimiento;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE items_evaluacion_establecimiento (
  id int NOT NULL AUTO_INCREMENT,
  establecimiento_id int NOT NULL,
  item_base_id int NOT NULL,
  descripcion_personalizada text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  factor_ajuste decimal(3,2) DEFAULT '1.00',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_establecimiento_item (establecimiento_id,item_base_id),
  KEY item_base_id (item_base_id),
  CONSTRAINT items_evaluacion_establecimiento_ibfk_1 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT items_evaluacion_establecimiento_ibfk_2 FOREIGN KEY (item_base_id) REFERENCES items_evaluacion_base (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=693 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_establecimiento`
--

INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (1,4,1,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (2,3,1,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (3,2,1,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (4,1,1,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (5,4,2,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (6,3,2,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (7,2,2,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (8,1,2,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (9,4,3,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (10,3,3,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (11,2,3,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (12,1,3,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (13,4,4,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (14,3,4,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (15,2,4,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (16,1,4,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (17,4,5,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (18,3,5,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (19,2,5,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (20,1,5,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (21,4,6,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (22,3,6,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (23,2,6,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (24,1,6,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (25,4,7,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (26,3,7,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (27,2,7,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (28,1,7,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (29,4,8,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (30,3,8,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (31,2,8,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (32,1,8,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (33,4,9,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (34,3,9,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (35,2,9,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (36,1,9,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (37,4,10,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (38,3,10,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (39,2,10,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (40,1,10,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (41,4,11,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (42,3,11,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (43,2,11,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (44,1,11,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (45,4,12,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (46,3,12,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (47,2,12,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (48,1,12,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (49,4,13,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (50,3,13,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (51,2,13,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (52,1,13,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (53,4,14,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (54,3,14,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (55,2,14,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (56,1,14,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (57,4,15,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (58,3,15,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (59,2,15,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (60,1,15,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (61,4,16,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (62,3,16,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (63,2,16,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (64,1,16,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (65,4,17,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (66,3,17,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (67,2,17,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (68,1,17,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (69,4,18,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (70,3,18,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (71,2,18,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (72,1,18,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (73,4,19,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (74,3,19,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (75,2,19,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (76,1,19,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (77,4,20,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (78,3,20,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (79,2,20,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (80,1,20,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (81,4,21,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (82,3,21,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (83,2,21,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (84,1,21,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (85,4,22,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (86,3,22,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (87,2,22,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (88,1,22,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (89,4,23,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (90,3,23,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (91,2,23,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (92,1,23,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (93,4,24,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (94,3,24,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (95,2,24,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (96,1,24,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (97,4,25,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (98,3,25,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (99,2,25,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (100,1,25,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (101,4,26,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (102,3,26,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (103,2,26,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (104,1,26,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (105,4,27,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (106,3,27,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (107,2,27,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (108,1,27,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (109,4,28,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (110,3,28,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (111,2,28,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (112,1,28,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (113,4,29,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (114,3,29,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (115,2,29,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (116,1,29,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (117,4,30,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (118,3,30,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (119,2,30,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (120,1,30,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (121,4,31,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (122,3,31,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (123,2,31,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (124,1,31,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (125,4,32,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (126,3,32,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (127,2,32,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (128,1,32,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (129,4,33,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (130,3,33,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (131,2,33,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (132,1,33,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (133,4,34,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (134,3,34,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (135,2,34,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (136,1,34,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (137,4,35,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (138,3,35,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (139,2,35,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (140,1,35,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (141,4,36,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (142,3,36,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (143,2,36,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (144,1,36,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (145,4,37,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (146,3,37,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (147,2,37,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (148,1,37,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (149,4,38,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (150,3,38,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (151,2,38,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (152,1,38,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (153,4,39,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (154,3,39,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (155,2,39,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (156,1,39,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (157,4,40,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (158,3,40,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (159,2,40,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (160,1,40,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (161,4,41,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (162,3,41,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (163,2,41,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (164,1,41,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (165,4,42,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (166,3,42,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (167,2,42,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (168,1,42,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (169,4,43,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (170,3,43,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (171,2,43,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (172,1,43,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (173,4,44,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (174,3,44,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (175,2,44,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (176,1,44,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (177,4,45,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (178,3,45,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (179,2,45,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (180,1,45,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (181,4,46,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (182,3,46,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (183,2,46,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (184,1,46,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (185,4,47,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (186,3,47,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (187,2,47,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (188,1,47,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (189,4,48,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (190,3,48,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (191,2,48,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (192,1,48,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (193,4,49,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (194,3,49,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (195,2,49,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (196,1,49,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (197,4,50,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (198,3,50,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (199,2,50,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (200,1,50,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (201,4,51,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (202,3,51,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (203,2,51,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (204,1,51,NULL,1.00,1,'2025-08-19 16:30:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (307,6,1,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (308,6,2,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (309,6,3,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (310,6,4,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (311,6,5,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (312,6,6,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (313,6,7,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (314,6,8,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (315,6,9,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (316,6,10,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (317,6,11,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (318,6,12,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (319,6,13,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (320,6,14,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (321,6,15,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (322,6,16,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (323,6,17,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (324,6,18,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (325,6,19,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (326,6,20,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (327,6,21,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (328,6,22,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (329,6,23,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (330,6,24,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (331,6,25,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (332,6,26,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (333,6,27,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (334,6,28,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (335,6,29,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (336,6,30,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (337,6,31,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (338,6,32,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (339,6,33,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (340,6,34,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (341,6,35,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (342,6,36,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (343,6,37,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (344,6,38,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (345,6,39,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (346,6,40,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (347,6,41,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (348,6,42,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (349,6,43,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (350,6,44,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (351,6,45,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (352,6,46,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (353,6,47,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (354,6,48,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (355,6,49,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (356,6,50,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (357,6,51,NULL,1.00,1,'2025-09-16 22:22:19');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (358,7,1,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (359,7,2,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (360,7,3,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (361,7,4,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (362,7,5,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (363,7,6,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (364,7,7,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (365,7,8,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (366,7,9,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (367,7,10,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (368,7,11,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (369,7,12,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (370,7,13,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (371,7,14,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (372,7,15,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (373,7,16,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (374,7,17,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (375,7,18,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (376,7,19,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (377,7,20,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (378,7,21,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (379,7,22,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (380,7,23,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (381,7,24,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (382,7,25,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (383,7,26,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (384,7,27,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (385,7,28,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (386,7,29,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (387,7,30,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (388,7,31,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (389,7,32,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (390,7,33,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (391,7,34,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (392,7,35,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (393,7,36,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (394,7,37,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (395,7,38,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (396,7,39,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (397,7,40,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (398,7,41,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (399,7,42,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (400,7,43,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (401,7,44,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (402,7,45,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (403,7,46,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (404,7,47,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (405,7,48,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (406,7,49,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (407,7,50,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (408,7,51,NULL,1.00,1,'2025-10-02 22:55:34');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (460,9,1,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (461,9,2,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (462,9,3,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (463,9,4,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (464,9,5,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (465,9,6,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (466,9,7,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (467,9,8,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (468,9,9,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (469,9,10,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (470,9,11,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (471,9,12,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (472,9,13,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (473,9,14,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (474,9,15,NULL,1.00,1,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (475,9,30,NULL,1.00,0,'2025-10-07 17:53:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (476,10,1,NULL,1.00,1,'2025-10-07 21:15:18');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (478,10,2,NULL,1.00,1,'2025-10-07 21:16:02');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (481,10,3,NULL,1.00,1,'2025-10-07 21:16:55');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (482,10,20,NULL,1.00,1,'2025-10-07 21:17:16');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (488,10,4,NULL,1.00,1,'2025-10-07 21:23:38');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (489,10,32,NULL,1.00,1,'2025-10-07 21:24:01');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (490,10,5,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (491,10,6,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (492,10,7,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (493,10,8,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (494,10,9,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (495,10,10,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (496,10,11,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (497,10,12,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (498,10,13,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (499,10,14,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (500,10,15,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (501,10,16,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (502,10,17,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (503,10,18,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (504,10,19,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (505,10,21,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (506,10,22,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (507,10,23,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (508,10,24,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (509,10,25,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (510,10,26,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (511,10,27,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (512,10,28,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (513,10,29,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (514,10,30,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (515,10,31,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (516,10,33,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (517,10,34,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (518,10,35,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (519,10,36,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (520,10,37,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (521,10,38,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (522,10,39,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (523,10,40,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (524,10,41,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (525,10,42,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (526,10,43,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (527,10,44,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (528,10,45,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (529,10,46,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (530,10,47,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (531,10,48,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (532,10,49,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (533,10,50,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (534,10,51,NULL,1.00,1,'2025-10-07 21:38:39');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (637,16,1,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (638,16,2,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (639,16,3,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (640,16,4,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (641,16,5,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (642,16,6,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (643,16,7,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (644,16,8,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (645,16,9,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (646,16,10,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (647,16,11,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (648,16,12,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (649,16,13,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (650,16,14,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (651,16,15,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (652,16,16,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (653,16,17,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (654,16,18,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (655,16,19,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (656,16,20,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (657,16,21,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (658,16,22,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (659,16,23,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (660,16,24,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (661,16,25,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (662,16,26,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (663,16,27,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (664,16,28,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (665,16,29,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (666,16,30,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (667,16,31,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (668,16,32,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (669,16,33,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (670,16,34,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (671,16,35,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (672,16,36,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (673,16,37,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (674,16,38,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (675,16,39,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (676,16,40,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (677,16,41,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (678,16,42,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (679,16,43,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (680,16,44,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (681,16,45,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (682,16,46,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (683,16,47,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (684,16,48,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (685,16,49,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (686,16,50,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (687,16,51,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (688,16,55,NULL,1.00,1,'2025-10-17 15:31:17');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (689,16,57,NULL,1.00,0,'2025-10-17 15:52:54');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (690,16,58,NULL,1.00,0,'2025-10-17 15:54:09');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (691,16,59,NULL,1.00,0,'2025-10-17 15:54:33');
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (692,16,60,NULL,1.00,1,'2025-10-17 16:21:02');

--
-- Table structure for table `items_plantilla_checklist`
--

DROP TABLE IF EXISTS items_plantilla_checklist;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE items_plantilla_checklist (
  id int NOT NULL AUTO_INCREMENT,
  plantilla_id int NOT NULL,
  item_base_id int NOT NULL,
  descripcion_personalizada text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  factor_ajuste decimal(3,2) DEFAULT '1.00',
  obligatorio tinyint(1) DEFAULT '1',
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  riesgo_personalizado varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  puntaje_minimo_personalizado int DEFAULT NULL,
  puntaje_maximo_personalizado int DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY unique_item_plantilla (plantilla_id,item_base_id),
  KEY item_base_id (item_base_id),
  CONSTRAINT items_plantilla_checklist_ibfk_1 FOREIGN KEY (plantilla_id) REFERENCES plantillas_checklist (id) ON DELETE CASCADE,
  CONSTRAINT items_plantilla_checklist_ibfk_2 FOREIGN KEY (item_base_id) REFERENCES items_evaluacion_base (id)
) ENGINE=InnoDB AUTO_INCREMENT=774 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_plantilla_checklist`
--

INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (1,1,1,NULL,1.00,1,0,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (2,1,2,NULL,1.00,1,1,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (3,1,3,NULL,1.00,1,2,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (4,1,4,NULL,1.00,1,3,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (5,1,5,NULL,1.00,1,4,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (6,1,6,NULL,1.00,1,5,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (7,1,7,NULL,1.00,1,6,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (8,1,8,NULL,1.00,1,7,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (9,1,9,NULL,1.00,1,8,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (10,1,10,NULL,1.00,1,9,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (11,1,11,NULL,1.00,1,10,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (12,1,12,NULL,1.00,1,11,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (13,1,13,NULL,1.00,1,12,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (14,1,14,NULL,1.00,1,13,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (15,1,15,NULL,1.00,1,14,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (16,2,1,NULL,1.00,1,0,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (17,2,2,NULL,1.00,1,1,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (18,2,3,NULL,1.00,1,2,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (19,2,4,NULL,1.00,1,3,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (20,2,5,NULL,1.00,1,4,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (21,2,6,NULL,1.00,1,5,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (22,2,7,NULL,1.00,1,6,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (23,2,8,NULL,1.00,1,7,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (24,2,9,NULL,1.00,1,8,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (25,2,10,NULL,1.00,1,9,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (26,2,11,NULL,1.00,1,10,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (27,2,12,NULL,1.00,1,11,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (28,2,13,NULL,1.00,1,12,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (29,2,14,NULL,1.00,1,13,1,'2025-10-07 09:59:45',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (30,2,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (31,2,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (32,2,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (33,2,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (34,2,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (35,2,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (36,2,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (37,2,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (38,2,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (39,2,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (40,2,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (41,3,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (42,3,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (43,3,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (44,3,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (45,3,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (46,3,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (47,3,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (48,3,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (49,3,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (50,3,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (51,3,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (52,3,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (53,3,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (54,3,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (55,3,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (56,3,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (57,3,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (58,3,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (59,3,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (60,3,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (61,3,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (62,3,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (63,3,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (64,3,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (65,3,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (66,3,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (67,3,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (68,3,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (69,3,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (70,3,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (71,3,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (72,3,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (73,3,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (74,3,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (75,3,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (76,3,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (77,3,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (78,3,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (79,3,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (80,3,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (81,3,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (82,3,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (83,3,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (84,3,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (85,3,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (86,3,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (87,3,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (88,3,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (89,3,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (90,3,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (91,3,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (92,4,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (93,4,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (94,4,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (95,4,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (96,4,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (97,4,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (98,4,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (99,4,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (100,4,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (101,4,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (102,4,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (103,4,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (104,4,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (105,4,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (106,4,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (107,4,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (108,4,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (109,4,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (110,4,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (111,4,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (112,4,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (113,4,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (114,4,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (115,4,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (116,4,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (117,5,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (118,5,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (119,5,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (120,5,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (121,5,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (122,5,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (123,5,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (124,5,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (125,5,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (126,5,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (127,5,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (128,5,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (129,5,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (130,5,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (131,5,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (132,5,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (133,5,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (134,5,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (135,5,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (136,5,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (137,5,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (138,5,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (139,5,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (140,5,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (141,5,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (142,5,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (143,5,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (144,5,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (145,5,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (146,5,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (147,5,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (148,5,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (149,5,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (150,5,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (151,5,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (152,5,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (153,5,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (154,5,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (155,5,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (156,5,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (157,5,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (158,5,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (159,5,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (160,5,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (161,5,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (162,5,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (163,5,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (164,5,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (165,5,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (166,5,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (167,5,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (168,6,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (169,6,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (170,6,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (171,6,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (172,6,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (173,6,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (174,6,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (175,6,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (176,6,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (177,6,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (178,6,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (179,6,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (180,6,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (181,6,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (182,6,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (183,6,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (184,6,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (185,6,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (186,6,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (187,6,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (188,6,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (189,6,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (190,6,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (191,6,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (192,6,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (193,7,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (194,7,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (195,7,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (196,7,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (197,7,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (198,7,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (199,7,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (200,7,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (201,7,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (202,7,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (203,7,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (204,7,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (205,7,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (206,7,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (207,7,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (208,8,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (209,8,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (210,8,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (211,8,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (212,8,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (213,8,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (214,8,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (215,8,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (216,8,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (217,8,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (218,8,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (219,8,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (220,8,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (221,8,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (222,8,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (223,8,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (224,8,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (225,8,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (226,8,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (227,8,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (228,8,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (229,8,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (230,8,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (231,8,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (232,8,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (233,9,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (234,9,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (235,9,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (236,9,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (237,9,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (238,9,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (239,9,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (240,9,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (241,9,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (242,9,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (243,9,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (244,9,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (245,9,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (246,9,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (247,9,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (248,9,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (249,9,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (250,9,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (251,9,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (252,9,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (253,9,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (254,9,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (255,9,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (256,9,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (257,9,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (258,9,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (259,9,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (260,9,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (261,9,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (262,9,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (263,9,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (264,9,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (265,9,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (266,9,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (267,9,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (268,9,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (269,9,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (270,9,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (271,9,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (272,9,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (273,9,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (274,9,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (275,9,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (276,9,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (277,9,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (278,9,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (279,9,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (280,9,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (281,9,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (282,9,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (283,9,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (284,10,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (285,10,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (286,10,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (287,10,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (288,10,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (289,10,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (290,10,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (291,10,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (292,10,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (293,10,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (294,10,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (295,10,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (296,10,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (297,10,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (298,10,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (299,10,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (300,10,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (301,10,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (302,10,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (303,10,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (304,10,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (305,10,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (306,10,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (307,10,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (308,10,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (309,11,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (310,11,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (311,11,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (312,11,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (313,11,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (314,11,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (315,11,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (316,11,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (317,11,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (318,11,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (319,11,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (320,11,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (321,11,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (322,11,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (323,11,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (324,11,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (325,11,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (326,11,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (327,11,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (328,11,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (329,11,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (330,11,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (331,11,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (332,11,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (333,11,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (334,11,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (335,11,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (336,11,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (337,11,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (338,11,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (339,11,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (340,11,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (341,11,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (342,11,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (343,11,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (344,11,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (345,11,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (346,11,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (347,11,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (348,11,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (349,11,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (350,11,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (351,11,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (352,11,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (353,11,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (354,11,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (355,11,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (356,11,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (357,11,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (358,11,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (359,11,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (360,12,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (361,12,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (362,12,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (363,12,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (364,12,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (365,12,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (366,12,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (367,12,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (368,12,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (369,12,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (370,12,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (371,12,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (372,12,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (373,12,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (374,12,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (375,12,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (376,12,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (377,12,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (378,12,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (379,12,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (380,12,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (381,12,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (382,12,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (383,12,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (384,12,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (385,13,1,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (386,13,2,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (387,13,3,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (388,13,4,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (389,13,5,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (390,13,6,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (391,13,7,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (392,13,8,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (393,13,9,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (394,13,10,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (395,13,11,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (396,13,12,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (397,13,13,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (398,13,14,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (399,13,15,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (400,14,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (401,14,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (402,14,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (403,14,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (404,14,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (405,14,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (406,14,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (407,14,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (408,14,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (409,14,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (410,14,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (411,14,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (412,14,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (413,14,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (414,14,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (415,14,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (416,14,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (417,14,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (418,14,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (419,14,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (420,14,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (421,14,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (422,14,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (423,14,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (424,14,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (425,15,1,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (426,15,2,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (427,15,3,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (428,15,4,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (429,15,5,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (430,15,6,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (431,15,7,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (432,15,8,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (433,15,9,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (434,15,10,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (435,15,11,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (436,15,12,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (437,15,13,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (438,15,14,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (439,15,15,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (440,15,16,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (441,15,17,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (442,15,18,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (443,15,19,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (444,15,20,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (445,15,21,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (446,15,22,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (447,15,23,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (448,15,24,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (449,15,25,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (450,15,26,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (451,15,27,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (452,15,28,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (453,15,29,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (454,15,30,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (455,15,31,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (456,15,32,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (457,15,33,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (458,15,34,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (459,15,35,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (460,15,36,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (461,15,37,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (462,15,38,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (463,15,39,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (464,15,40,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (465,15,41,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (466,15,42,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (467,15,43,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (468,15,44,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (469,15,45,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (470,15,46,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (471,15,47,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (472,15,48,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (473,15,49,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (474,15,50,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (475,15,51,NULL,1.00,1,51,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (476,16,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (477,16,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (478,16,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (479,16,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (480,16,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (481,16,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (482,16,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (483,16,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (484,16,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (485,16,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (486,16,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (487,16,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (488,16,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (489,16,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (490,16,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (491,16,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (492,16,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (493,16,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (494,16,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (495,16,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (496,16,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (497,16,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (498,16,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (499,16,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (500,16,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (501,17,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (502,17,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (503,17,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (504,17,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (505,17,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (506,17,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (507,17,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (508,17,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (509,17,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (510,17,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (511,17,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (512,17,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (513,17,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (514,17,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (515,17,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (516,17,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (517,17,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (518,17,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (519,17,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (520,17,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (521,17,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (522,17,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (523,17,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (524,17,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (525,17,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (526,17,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (527,17,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (528,17,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (529,17,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (530,17,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (531,17,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (532,17,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (533,17,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (534,17,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (535,17,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (536,17,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (537,17,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (538,17,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (539,17,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (540,17,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (541,17,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (542,17,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (543,17,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (544,17,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (545,17,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (546,17,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (547,17,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (548,17,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (549,17,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (550,17,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (551,17,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (552,18,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (553,18,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (554,18,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (555,18,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (556,18,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (557,18,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (558,18,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (559,18,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (560,18,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (561,18,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (562,18,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (563,18,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (564,18,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (565,18,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (566,18,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (567,18,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (568,18,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (569,18,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (570,18,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (571,18,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (572,18,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (573,18,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (574,18,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (575,18,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (576,18,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (577,19,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (578,19,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (579,19,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (580,19,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (581,19,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (582,19,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (583,19,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (584,19,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (585,19,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (586,19,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (587,19,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (588,19,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (589,19,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (590,19,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (591,19,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (592,20,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (593,20,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (594,20,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (595,20,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (596,20,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (597,20,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (598,20,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (599,20,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (600,20,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (601,20,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (602,20,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (603,20,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (604,20,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (605,20,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (606,20,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (607,20,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (608,20,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (609,20,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (610,20,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (611,20,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (612,20,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (613,20,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (614,20,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (615,20,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (616,20,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (617,21,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (618,21,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (619,21,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (620,21,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (621,21,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (622,21,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (623,21,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (624,21,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (625,21,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (626,21,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (627,21,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (628,21,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (629,21,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (630,21,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (631,21,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (632,21,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (633,21,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (634,21,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (635,21,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (636,21,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (637,21,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (638,21,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (639,21,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (640,21,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (641,21,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (642,21,26,NULL,1.00,1,25,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (643,21,27,NULL,1.00,1,26,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (644,21,28,NULL,1.00,1,27,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (645,21,29,NULL,1.00,1,28,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (646,21,30,NULL,1.00,1,29,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (647,21,31,NULL,1.00,1,30,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (648,21,32,NULL,1.00,1,31,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (649,21,33,NULL,1.00,1,32,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (650,21,34,NULL,1.00,1,33,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (651,21,35,NULL,1.00,1,34,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (652,21,36,NULL,1.00,1,35,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (653,21,37,NULL,1.00,1,36,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (654,21,38,NULL,1.00,1,37,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (655,21,39,NULL,1.00,1,38,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (656,21,40,NULL,1.00,1,39,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (657,21,41,NULL,1.00,1,40,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (658,21,42,NULL,1.00,1,41,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (659,21,43,NULL,1.00,1,42,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (660,21,44,NULL,1.00,1,43,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (661,21,45,NULL,1.00,1,44,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (662,21,46,NULL,1.00,1,45,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (663,21,47,NULL,1.00,1,46,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (664,21,48,NULL,1.00,1,47,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (665,21,49,NULL,1.00,1,48,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (666,21,50,NULL,1.00,1,49,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (667,21,51,NULL,1.00,1,50,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (668,22,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (669,22,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (670,22,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (671,22,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (672,22,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (673,22,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (674,22,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (675,22,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (676,22,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (677,22,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (678,22,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (679,22,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (680,22,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (681,22,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (682,22,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (683,22,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (684,22,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (685,22,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (686,22,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (687,22,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (688,22,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (689,22,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (690,22,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (691,22,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (692,22,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (693,23,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (694,23,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (695,23,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (696,23,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (697,23,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (698,23,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (699,23,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (700,23,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (701,23,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (702,23,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (703,23,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (704,23,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (705,23,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (706,23,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (707,23,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (708,23,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (709,23,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (710,23,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (711,23,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (712,23,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (713,23,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (714,23,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (715,23,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (716,23,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (717,23,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (718,23,26,NULL,1.00,1,25,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (719,23,27,NULL,1.00,1,26,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (720,23,28,NULL,1.00,1,27,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (721,23,29,NULL,1.00,1,28,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (722,23,30,NULL,1.00,1,29,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (723,23,31,NULL,1.00,1,30,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (724,23,32,NULL,1.00,1,31,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (725,23,33,NULL,1.00,1,32,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (726,23,34,NULL,1.00,1,33,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (727,23,35,NULL,1.00,1,34,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (728,23,36,NULL,1.00,1,35,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (729,23,37,NULL,1.00,1,36,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (730,23,38,NULL,1.00,1,37,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (731,23,39,NULL,1.00,1,38,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (732,23,40,NULL,1.00,1,39,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (733,23,41,NULL,1.00,1,40,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (734,23,42,NULL,1.00,1,41,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (735,23,43,NULL,1.00,1,42,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (736,23,44,NULL,1.00,1,43,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (737,23,45,NULL,1.00,1,44,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (738,23,46,NULL,1.00,1,45,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (739,23,47,NULL,1.00,1,46,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (740,23,48,NULL,1.00,1,47,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (741,23,49,NULL,1.00,1,48,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (742,23,50,NULL,1.00,1,49,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (743,23,51,NULL,1.00,1,50,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (744,24,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (745,24,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (746,24,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (747,24,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (748,24,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (749,24,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (750,24,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (751,24,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (752,24,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (753,24,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (754,24,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (755,24,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (756,24,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (757,24,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (758,24,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (759,24,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (760,24,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (761,24,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (762,24,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (763,24,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (764,24,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (765,24,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (766,24,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (767,24,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (768,24,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (771,3,55,NULL,1.00,1,51,1,'2025-10-10 19:29:48',NULL,1,4);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (772,1,30,NULL,1.00,1,15,1,'2025-10-10 22:05:00',NULL,NULL,NULL);
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (773,1,56,NULL,1.00,1,16,1,'2025-10-10 22:06:59',NULL,0,2);

--
-- Table structure for table `items_reglamento_restaurante`
--

DROP TABLE IF EXISTS items_reglamento_restaurante;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE items_reglamento_restaurante (
  id int NOT NULL AUTO_INCREMENT,
  codigo varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci NOT NULL,
  categoria varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  riesgo varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  puntaje int NOT NULL,
  orden int DEFAULT NULL,
  activo tinyint(1) DEFAULT NULL,
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY codigo (codigo)
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_reglamento_restaurante`
--

INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (88,'A-01','Obtener una calificacion Regular x checklist','Checklist (3 veces por semana)','Mayor',3,1,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (89,'A-02','Obtener una calificacion Mala x checklist','Checklist (3 veces por semana)','Crítico',5,2,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (90,'A-03','Incumplir 2 veces seguidas o alternadas en una misma semana el mismo item del check list','Checklist (3 veces por semana)','Mayor',3,3,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (91,'A-04','Incumplir las observaciones inopinadas (por el personal encargado)','Checklist (3 veces por semana)','Menor',1,4,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (92,'A-05','Obtener un porcentaje menor al 85% en las evaluaciones de satisfaccion del cliente.','Satisfacción al cliente - Encuestas','Menor',1,5,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (93,'A-06','Obtener un % menor al 90% en las recomendaciones de los clientes, segun las encuestas.','Satisfacción al cliente - Encuestas','Menor',1,6,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (94,'A-07','Si se acumulan 10 comentarios negativos en las encuestas de lunes a viernes.','Satisfacción al cliente - Encuestas','Menor',1,7,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (95,'A-08','Si se acumulan 15 comentarios negativos en las encuestas de sabado y domingo.','Satisfacción al cliente - Encuestas','Menor',1,8,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (96,'A-09','No entregar el libro de reclamaciones, cuando sea requerido por los clientes','Satisfacción al cliente - Encuestas','Mayor',3,9,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (97,'A-10','Quejas graves de clientes ya sean en las encuestas o directamente (puede implicar o no libro de reclamaciones).','Satisfacción al cliente - Encuestas','Crítico',5,10,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (98,'A-11','Realizar publicidad engañosa sea por no respetar los precios establecidos en las cartas y/o no cumplir con las promociones y/o cortesias ofrecidas.','Satisfacción al cliente - Encuestas','Mayor',3,11,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (99,'A-12','El tiempo de espera de un pedido de comida durar como máximo de 20 minutos y llegar a las 20 demoras se le para la venta.','Satisfacción al cliente - Encuestas','Mayor',3,12,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (100,'A-13','Permitir que sus trabajadores fijos laboren sin contar con el respectivo carnet de sanidad.','Incumplimientos Laborales','Menor',1,13,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (101,'A-14','Contratar trabajadores menores de edad y/o personal extranjero que no cuente con la documentacion correspondiente para trabajar en el pais.','Incumplimientos Laborales','Mayor',3,14,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (102,'A-15','Prohibido contratar personal que este en lista roja','Incumplimientos Laborales','Mayor',3,15,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (103,'A-16','Contratar al personal de los demas concesionarios y/o del castillo mientras los mismos se encuentren laborando en dichas otras entidades y/o antes que se cumplan los 3 meses desde que culmino su relacion laboral con su anterior empleador o previa coordinacion con el concesionario anterior.','Incumplimientos Laborales','Menor',1,16,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (104,'A-17','No tener el personal en planilla y con contratos.','Incumplimientos Laborales','Menor',1,17,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (105,'A-18','Incumplimiento de los acuerdos adoptados en las reuniones semanales.','Otros incumplimientos','Mayor',3,18,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (106,'A-19','No cumplir con la programacion semanal del personal acordado en reunion. De lunes a viernes. De sabado o de Domingo o feriado','Otros incumplimientos','Menor',1,19,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (107,'A-20','Realizar sus operaciones sin contar con el certificado de fumigacion vigente.','Otros incumplimientos','Menor',1,20,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (108,'A-21','No preparar el chancho al palo con los parametros de seguridad establecidos. (segun compromiso firmado)','Otros incumplimientos','Mayor',3,21,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (109,'A-22','Ingreso de mercaderia en horarios no establecido. (6:00-10:00 y de 5:00-7:00)','Otros incumplimientos','Menor',1,22,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (110,'A-23','Depositar desperdicios o basura en espacios no permitidos y dejar el espacio sucio. (en el deposito del castillo, mas no en los tachos dentro del castillo).','Otros incumplimientos','Menor',1,23,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (111,'A-24','Anular cupos o tickets sin la autorizacion o sin previa autorizacion del Castillo.','Otros incumplimientos','Mayor',3,24,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (112,'A-25','Usar tickets o comandas distintas a las aprobadas.','Otros incumplimientos','Mayor',3,25,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (113,'A-26','Inasistencia injustificada de los dueños de los restaurantes o establecimientos concesionados a las reuniones semanales, reuniones extraordinarias y/o capacitaciones programadas.','Otros incumplimientos','Menor',1,26,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (114,'A-27','No respetar el monto acordado para los descuentos a los turistas.','Otros incumplimientos','Mayor',3,27,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (115,'A-28','Falta de respeto entre concesionarios y/o personal.','Otros incumplimientos','Crítico',5,28,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (116,'A-29','Tomar objetos ajenos del restaurante que no le pertenecen.','Otros incumplimientos','Menor',1,29,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (117,'A-30','Adulterar las fechas de rotulado','Otros incumplimientos','Crítico',5,30,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (118,'A-31','No cumplir con el pago de impuestos (fecha de pagos entre el dia 25 al 30 de cada mes). Enviar los documentos de SUNAT.','Incumplimiento en pagos','Menor',1,31,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (119,'A-32','No cumplir con el pago a sus proveedores o personal que pueda generar mala reputacion al Castillo.','Incumplimiento en pagos','Crítico',5,32,1,'2025-11-03 21:09:23');
INSERT INTO items_reglamento_restaurante (id, codigo, descripcion, categoria, riesgo, puntaje, orden, activo, created_at) VALUES (120,'A-33','No cumplir con el pago del alquiler segun las fechas establecidas. (50% hasta e dia 7 y el 50% restante hasta el dia 15)','Incumplimiento en pagos','Crítico',5,33,1,'2025-11-03 21:09:23');

--
-- Table structure for table `jefes_establecimientos`
--

DROP TABLE IF EXISTS jefes_establecimientos;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE jefes_establecimientos (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  establecimiento_id int NOT NULL,
  fecha_inicio date NOT NULL,
  fecha_fin date DEFAULT NULL,
  es_principal tinyint(1) DEFAULT '1',
  comentario varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY establecimiento_id (establecimiento_id),
  KEY idx_jefe_establecimiento_fecha (establecimiento_id,fecha_inicio,fecha_fin),
  KEY idx_jefe_activo (activo),
  CONSTRAINT jefes_establecimientos_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT jefes_establecimientos_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jefes_establecimientos`
--

INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (1,7,1,'2025-08-28',NULL,1,'Jefe principal del establecimiento Déjà vu',1,'2025-08-28 16:30:01');
INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (2,8,2,'2025-08-28',NULL,1,'Jefe principal del establecimiento Silvia',1,'2025-08-28 16:30:01');
INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (3,9,3,'2025-08-28',NULL,1,'Jefe principal del establecimiento Náutica',1,'2025-08-28 16:30:01');
INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (27,61,4,'2025-10-10','2026-10-31',1,'',1,'2025-10-10 22:26:19');
INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (28,62,10,'2025-10-16',NULL,1,'',1,'2025-10-16 14:49:58');

--
-- Table structure for table `permisos_roles`
--

DROP TABLE IF EXISTS permisos_roles;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE permisos_roles (
  id int NOT NULL AUTO_INCREMENT,
  rol_id int NOT NULL,
  recurso varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'usuarios, establecimientos, inspecciones, etc.',
  accion varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'crear, editar, eliminar, ver, etc.',
  condicion json DEFAULT NULL COMMENT 'Condiciones adicionales',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rol_recurso_accion (rol_id,recurso,accion),
  KEY idx_rol_recurso (rol_id,recurso),
  KEY idx_recurso_accion (recurso,accion),
  CONSTRAINT permisos_roles_ibfk_1 FOREIGN KEY (rol_id) REFERENCES roles (id) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Permisos granulares asignados a roles del sistema';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permisos_roles`
--

INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (1,1,'inspecciones','crear',NULL,1,'2025-09-01 15:59:50');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (2,1,'inspecciones','editar','{\"propias\": true}',1,'2025-09-01 15:59:51');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (3,1,'inspecciones','ver',NULL,1,'2025-09-01 15:59:51');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (4,1,'configuracion','editar','{\"solo_meta_semanal\": true}',1,'2025-09-01 15:59:52');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (5,1,'configuracion','ver',NULL,1,'2025-09-01 15:59:53');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (6,1,'establecimientos','ver',NULL,1,'2025-09-01 15:59:54');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (7,2,'inspecciones','ver','{\"propias\": true}',1,'2025-09-01 15:59:56');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (9,2,'inspecciones','firmar','{\"propias\": true}',1,'2025-09-01 15:59:58');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (10,2,'establecimientos','ver','{\"propios\": true}',1,'2025-09-01 16:00:00');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (11,3,'*','*',NULL,1,'2025-09-01 16:00:00');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (12,4,'establecimientos','ver','{\"propios\": true}',1,'2025-09-01 16:00:03');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (13,4,'establecimientos','editar','{\"propios\": true}',1,'2025-09-01 16:00:04');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (14,4,'encargados','gestionar','{\"establecimiento_propio\": true}',1,'2025-09-01 16:00:05');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (15,4,'inspecciones','ver','{\"establecimiento_propio\": true}',1,'2025-09-01 16:00:06');
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (16,4,'firmas','cargar',NULL,1,'2025-09-01 16:00:07');

--
-- Table structure for table `permisos_usuarios`
--

DROP TABLE IF EXISTS permisos_usuarios;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE permisos_usuarios (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  recurso varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  accion varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  permitido tinyint(1) NOT NULL COMMENT 'True permite, False deniega',
  condicion json DEFAULT NULL,
  razon varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Razón para el permiso/denegación específica',
  otorgado_por int DEFAULT NULL,
  fecha_vencimiento timestamp NULL DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuario_recurso_accion (usuario_id,recurso,accion),
  KEY otorgado_por (otorgado_por),
  KEY idx_usuario_recurso (usuario_id,recurso),
  KEY idx_vencimiento (fecha_vencimiento),
  CONSTRAINT permisos_usuarios_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT permisos_usuarios_ibfk_2 FOREIGN KEY (otorgado_por) REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Permisos específicos por usuario que sobrescriben los del rol';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `permisos_usuarios`
--


--
-- Table structure for table `plan_semanal`
--

DROP TABLE IF EXISTS plan_semanal;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE plan_semanal (
  id int NOT NULL AUTO_INCREMENT,
  establecimiento_id int NOT NULL,
  semana int NOT NULL,
  ano int NOT NULL,
  evaluaciones_meta int DEFAULT '3',
  evaluaciones_realizadas int DEFAULT '0',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY establecimiento_id (establecimiento_id,semana,ano),
  CONSTRAINT plan_semanal_ibfk_1 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=116 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plan_semanal`
--

INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (1,1,36,2025,3,1,'2025-09-01 19:34:33');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (2,2,36,2025,3,0,'2025-09-01 19:34:33');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (3,3,36,2025,3,0,'2025-09-01 19:34:33');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (4,4,36,2025,3,0,'2025-09-01 19:34:33');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (5,1,37,2025,3,1,'2025-09-09 16:45:14');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (6,2,37,2025,3,0,'2025-09-09 16:45:14');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (7,3,37,2025,3,0,'2025-09-09 16:45:14');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (8,4,37,2025,3,0,'2025-09-09 16:45:14');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (9,1,38,2025,3,0,'2025-09-16 16:18:08');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (10,2,38,2025,3,0,'2025-09-16 16:18:08');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (11,3,38,2025,3,0,'2025-09-16 16:18:08');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (12,4,38,2025,3,0,'2025-09-16 16:18:08');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (14,6,38,2025,3,0,'2025-09-16 22:22:19');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (15,1,39,2025,4,2,'2025-09-24 20:26:17');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (16,2,39,2025,4,0,'2025-09-24 20:26:17');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (17,3,39,2025,4,0,'2025-09-24 20:26:17');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (18,4,39,2025,3,0,'2025-09-24 20:26:17');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (20,6,39,2025,3,0,'2025-09-24 20:26:17');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (21,1,40,2025,2,1,'2025-10-01 15:00:56');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (22,2,40,2025,2,1,'2025-10-01 15:00:56');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (23,3,40,2025,2,0,'2025-10-01 15:00:56');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (24,4,40,2025,3,0,'2025-10-01 15:00:56');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (26,6,40,2025,3,0,'2025-10-01 15:00:56');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (27,7,40,2025,3,0,'2025-10-02 22:55:34');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (28,1,40,2024,3,0,'2025-10-03 22:13:31');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (30,1,41,2025,3,3,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (31,2,41,2025,3,4,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (32,3,41,2025,3,0,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (33,4,41,2025,3,0,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (34,6,41,2025,3,0,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (35,7,41,2025,3,0,'2025-10-07 14:42:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (36,9,41,2025,3,0,'2025-10-07 17:53:42');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (37,10,41,2025,3,0,'2025-10-07 20:48:54');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (40,1,42,2025,3,2,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (41,2,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (42,3,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (43,4,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (44,6,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (45,7,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (46,9,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (47,10,42,2025,3,0,'2025-10-15 16:57:38');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (49,1,43,2025,6,6,'2025-10-15 17:11:05');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (50,2,43,2025,6,2,'2025-10-15 17:11:05');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (51,3,43,2025,6,0,'2025-10-15 17:11:05');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (52,6,37,2025,5,0,'2025-10-15 17:17:04');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (53,7,37,2025,5,0,'2025-10-15 17:17:04');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (54,9,37,2025,5,0,'2025-10-15 17:17:04');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (55,10,37,2025,5,0,'2025-10-15 17:17:04');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (56,1,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (57,2,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (58,3,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (59,4,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (60,6,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (61,7,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (62,9,35,2025,4,0,'2025-10-15 17:40:46');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (63,10,35,2025,4,0,'2025-10-15 17:40:47');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (64,9,40,2025,4,0,'2025-10-15 17:40:49');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (65,10,40,2025,4,0,'2025-10-15 17:40:49');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (66,1,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (67,2,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (68,3,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (69,4,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (70,6,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (71,7,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (72,9,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (73,10,34,2025,4,0,'2025-10-15 17:40:53');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (74,7,39,2025,3,0,'2025-10-16 20:27:11');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (75,9,39,2025,3,0,'2025-10-16 20:27:11');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (76,10,39,2025,3,0,'2025-10-16 20:27:11');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (77,7,38,2025,3,0,'2025-10-16 20:27:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (78,9,38,2025,3,0,'2025-10-16 20:27:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (79,10,38,2025,3,0,'2025-10-16 20:27:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (80,6,36,2025,3,0,'2025-10-16 20:27:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (81,7,36,2025,3,0,'2025-10-16 20:27:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (82,9,36,2025,3,0,'2025-10-16 20:27:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (83,10,36,2025,3,0,'2025-10-16 20:27:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (87,16,42,2025,3,0,'2025-10-17 15:30:25');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (88,4,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (89,6,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (90,7,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (91,9,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (92,10,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (93,16,43,2025,3,0,'2025-10-20 14:52:24');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (94,16,35,2025,3,0,'2025-10-20 20:24:27');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (95,16,38,2025,3,0,'2025-10-20 20:25:09');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (96,16,41,2025,3,0,'2025-10-20 21:02:13');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (97,16,40,2025,3,0,'2025-10-20 21:02:15');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (98,1,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (99,2,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (100,3,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (101,4,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (102,6,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (103,7,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (104,9,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (105,10,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (106,16,44,2025,3,0,'2025-10-31 20:30:01');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (107,1,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (108,2,45,2025,3,1,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (109,3,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (110,4,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (111,6,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (112,7,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (113,9,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (114,10,45,2025,3,0,'2025-11-03 17:16:12');
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (115,16,45,2025,3,0,'2025-11-03 17:16:12');

--
-- Table structure for table `plantillas_checklist`
--

DROP TABLE IF EXISTS plantillas_checklist;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE plantillas_checklist (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  tipo_establecimiento_id int DEFAULT NULL,
  tamano_local enum('pequeno','mediano','grande') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'mediano',
  tipo_restaurante varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY unique_plantilla (nombre,tipo_establecimiento_id,tamano_local),
  KEY tipo_establecimiento_id (tipo_establecimiento_id),
  CONSTRAINT plantillas_checklist_ibfk_1 FOREIGN KEY (tipo_establecimiento_id) REFERENCES tipos_establecimiento (id)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plantillas_checklist`
--

INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (1,'Restaurante - Checklist Básico Pequeño','Plantilla básica para locales pequeños',1,'pequeno',NULL,1,'2025-10-07 09:59:45','2025-10-07 09:59:45');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (2,'Restaurante - Checklist Estándar Mediano','Plantilla estándar para locales medianos',1,'mediano',NULL,1,'2025-10-07 09:59:45','2025-10-07 09:59:45');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (3,'Restaurante - Checklist Completo Principal','Plantilla completa para locales grandes',1,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-10 18:25:16');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (4,'Restaurante - Checklist Restaurante Casual','Para restaurantes de comida casual',1,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (5,'Restaurante - Checklist Restaurante Fino','Para restaurantes de alta cocina',1,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (6,'Restaurante - Checklist Bar Estándar','Para bares y pubs',1,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (7,'Cafetería - Checklist Básico Pequeño','Plantilla básica para locales pequeños',2,'pequeno',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (8,'Cafetería - Checklist Estándar Mediano','Plantilla estándar para locales medianos',2,'mediano',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (9,'Cafetería - Checklist Completo Grande','Plantilla completa para locales grandes',2,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (10,'Cafetería - Checklist Restaurante Casual','Para restaurantes de comida casual',2,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (11,'Cafetería - Checklist Restaurante Fino','Para restaurantes de alta cocina',2,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (12,'Cafetería - Checklist Bar Estándar','Para bares y pubs',2,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (13,'Bar - Checklist Básico Pequeño','Plantilla básica para locales pequeños',3,'pequeno',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (14,'Bar - Checklist Estándar Mediano','Plantilla estándar para locales medianos',3,'mediano',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (15,'Bar - Checklist Completo Grande','Plantilla completa para locales grandes',3,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (16,'Bar - Checklist Restaurante Casual','Para restaurantes de comida casual',3,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (17,'Bar - Checklist Restaurante Fino','Para restaurantes de alta cocina',3,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (18,'Bar - Checklist Bar Estándar','Para bares y pubs',3,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (19,'Food Court - Checklist Básico Pequeño','Plantilla básica para locales pequeños',4,'pequeno',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (20,'Food Court - Checklist Estándar Mediano','Plantilla estándar para locales medianos',4,'mediano',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (21,'Food Court - Checklist Completo Grande','Plantilla completa para locales grandes',4,'grande',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (22,'Food Court - Checklist Restaurante Casual','Para restaurantes de comida casual',4,'mediano','casual',1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (23,'Food Court - Checklist Restaurante Fino','Para restaurantes de alta cocina',4,'grande','fino',1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (24,'Food Court - Checklist Bar Estándar','Para bares y pubs',4,'mediano','bar',1,'2025-10-07 09:59:47','2025-10-07 09:59:47');

--
-- Table structure for table `reuniones_reglamento`
--

DROP TABLE IF EXISTS reuniones_reglamento;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE reuniones_reglamento (
  id int NOT NULL AUTO_INCREMENT,
  establecimiento_id int NOT NULL,
  semana int NOT NULL,
  ano int NOT NULL,
  fecha_reunion date NOT NULL,
  fecha_inicio_semana date NOT NULL,
  fecha_fin_semana date NOT NULL,
  total_inspecciones int DEFAULT NULL,
  total_infracciones int DEFAULT NULL,
  total_platos_sancion int DEFAULT NULL,
  observaciones text COLLATE utf8mb4_general_ci,
  estado varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  created_at timestamp NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY establecimiento_id (establecimiento_id),
  CONSTRAINT reuniones_reglamento_ibfk_1 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reuniones_reglamento`
--

INSERT INTO reuniones_reglamento (id, establecimiento_id, semana, ano, fecha_reunion, fecha_inicio_semana, fecha_fin_semana, total_inspecciones, total_infracciones, total_platos_sancion, observaciones, estado, created_at) VALUES (1,2,44,2025,'2025-11-03','2025-10-27','2025-11-02',0,0,0,NULL,'pendiente','2025-11-03 20:33:47');

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS roles;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE roles (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  permisos json DEFAULT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

INSERT INTO roles (id, nombre, descripcion, permisos, created_at) VALUES (1,'Inspector','Puede crear jefes de establecimiento y gestionar inspecciones','{\"informes\": {\"ver_todos\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"ver_todos\": true}}','2025-08-19 16:30:01');
INSERT INTO roles (id, nombre, descripcion, permisos, created_at) VALUES (2,'Encargado','Acceso limitado para realizar inspecciones','{\"informes\": {\"ver_propios\": true}, \"inspecciones\": {\"firmar\": true, \"ver_propias\": true}}','2025-08-19 16:30:01');
INSERT INTO roles (id, nombre, descripcion, permisos, created_at) VALUES (3,'Administrador','Acceso completo al sistema','{\"informes\": {\"ver_todos\": true}, \"usuarios\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"cambiar_roles\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"ver_todos\": true}, \"establecimientos\": {\"crear\": true, \"editar\": true, \"eliminar\": true}}','2025-08-19 16:30:01');
INSERT INTO roles (id, nombre, descripcion, permisos, created_at) VALUES (4,'Jefe de Establecimiento','Puede crear encargados y gestionar su establecimiento','{\"firmas\": {\"validar\": true, \"cargar_encargados\": true}, \"encargados\": {\"habilitar\": true, \"deshabilitar\": true, \"cargar_firmas\": true, \"ver_todos_establecimiento\": true}, \"inspecciones\": {\"supervisar\": true, \"ver_establecimiento\": true}, \"establecimientos\": {\"ver_propio\": true, \"editar_propio\": true, \"gestionar_encargados\": true}}','2025-08-28 16:30:01');

--
-- Table structure for table `tipos_establecimiento`
--

DROP TABLE IF EXISTS tipos_establecimiento;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE tipos_establecimiento (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tipos_establecimiento`
--

INSERT INTO tipos_establecimiento (id, nombre, descripcion, activo, created_at) VALUES (1,'Restaurante','Establecimiento de servicio de alimentos y bebidas',1,'2025-08-19 16:30:01');
INSERT INTO tipos_establecimiento (id, nombre, descripcion, activo, created_at) VALUES (2,'Cafetería','Establecimiento especializado en café y aperitivos',1,'2025-08-19 16:30:01');
INSERT INTO tipos_establecimiento (id, nombre, descripcion, activo, created_at) VALUES (3,'Bar','Establecimiento especializado en bebidas',1,'2025-08-19 16:30:01');
INSERT INTO tipos_establecimiento (id, nombre, descripcion, activo, created_at) VALUES (4,'Food Court','Área común de diversos establecimientos de comida',1,'2025-08-19 16:30:01');

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS usuarios;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE usuarios (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  apellido varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  correo varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  contrasena varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  rol_id int NOT NULL,
  activo tinyint(1) NOT NULL DEFAULT '1',
  en_linea tinyint(1) NOT NULL DEFAULT '0',
  ultimo_acceso timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  telefono varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  dni varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  ruta_firma varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  fecha_creacion timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  cambiar_contrasena tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY correo (correo),
  KEY idx_usuarios_correo (correo),
  KEY idx_usuarios_dni (dni),
  KEY idx_usuarios_rol (rol_id),
  CONSTRAINT usuarios_ibfk_1 FOREIGN KEY (rol_id) REFERENCES roles (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (1,'Jesus','Isique','desarrollo@castillodechancay.com','$2b$12$C58u.bPb.cR45jpC9QxLf.i05oucxUGq/XABKPCL2X.N5jOVkd7Sq',1,1,1,'2025-11-03 20:33:42','987654321','45678912','img/firmas/firma_inspector_1_20251002_124757.jpg','2025-08-19 16:30:01','2025-08-19 16:30:01','2025-11-03 20:33:42',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (2,'Jhon','Doe','jhondoe@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',2,1,0,'2025-10-20 21:18:02','987654322','12345678',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-20 21:24:46',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (3,'María','García','maria.garcia@example.com','$2b$12$LfnXh.QTjJW1rjw16I1Nse2wLZRGQw6ZVXegdPAoLhxeW12yDymTu',2,1,0,'2025-11-03 20:24:46','987654323','87654321',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-11-03 21:44:22',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (4,'Carlos','López','carlos.lopez@example.com','$2b$12$G6AjqJNIRp5CaNwOH3ZN9OhLqMOPSXdhzFR.bIawHhI8UqohZH40m',2,1,0,'2025-08-19 16:30:01','987654324','45678913',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-08-19 16:30:01',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (5,'Ana','Martínez','ana.martinez@example.com','$2b$12$4rxq9BvEThorOft1eMRSQe.DDpK3gIFX/rXZ/feJZ/hgXiz6PnrC.',2,1,0,'2025-08-19 16:30:01','987654325','78912345',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-08-19 16:30:01',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (6,'Admin','Sistema','estadistica@castillodechancay.com','$2b$12$jeZG0C.IXQsL/zmrvCS/4OBnfPIHDdDQs2KrdqUWVUqPnXPdTeyte',3,1,0,'2025-10-16 15:38:12','987654326','11111111',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-16 16:09:31',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (7,'Roberto','Fernández','jefe.dejavu@chancay.com','$2b$12$MFbKMeEyu0VPqAkjeDSF0uOWNyH58XqeQrKdJqXUWP1eQIOLevs.6',4,1,0,'2025-10-20 20:19:11','987654327','55555555',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-10-20 20:19:16',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (8,'Patricia','Morales','jefe.silvia@chancay.com','$2b$12$EjtmpMwAROy73Df9CYRdyejducZpGhhPgpbvVyLTES6IIqLOUmy9y',4,1,0,'2025-08-28 16:30:01','987654328','66666666',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-08-28 16:30:01',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (9,'Miguel','Herrera','jefe.nautica@chancay.com','$2b$12$w6a5mjIqjy7Nzi8lLYFSfeuu7ArtK2Xdv/EJ9zZytM3tgd3LUY/my',4,1,0,'2025-08-28 16:30:01','987654329','77777777',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-08-28 16:30:01',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (10,'Jhon2','Doe2','encargado.dejavu@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',2,1,0,'2025-10-02 15:22:41','978541259','84524685',NULL,'2025-09-12 16:35:12','2025-09-12 16:35:12','2025-10-20 16:04:36',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (13,'Janet',NULL,'alimentoybebidas@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',1,1,1,'2025-10-20 21:16:31','985236985','74589635','img/firmas/firma_inspector_13_20251010_172854.jpg','2025-10-02 17:14:46','2025-10-02 17:14:46','2025-10-20 21:16:31',0);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (61,'Luz','Serrato','luz@gmail.com','$2b$12$NXwtnE32at7CfCgD1o11UeXwY9lql7xlj8k1nGqoDR3maRl7Sj5Fi',4,1,0,'2025-10-10 22:26:19','982841347','72487591',NULL,'2025-10-10 22:26:19','2025-10-10 22:26:19','2025-10-16 14:48:53',1);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (62,'Yisus','Isique','yisus@gmail.com','$2b$12$hrfLuxci7QAlz994HtTN9eYfPrw1yO4Sd7jOAsM5mpkApkNaudU2m',4,1,0,'2025-10-16 14:49:58','985423669','75421369',NULL,'2025-10-16 14:49:58','2025-10-16 14:49:58','2025-10-16 15:10:49',1);
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (63,'Jordan','Buleje','m48669746@gmail.com','$2b$12$EV100jlFdUwZgbCoPwidT.MWZdAmVV7Nj.brxXS2gqGAGoqzBF5um',2,1,0,'2025-10-16 20:49:18','99999999','14235689',NULL,'2025-10-16 20:49:18','2025-10-16 20:49:18','2025-10-16 20:49:18',1);

--
-- Temporary view structure for view `vista_jerarquia_establecimiento`
--

DROP TABLE IF EXISTS vista_jerarquia_establecimiento;
/*!50001 DROP VIEW IF EXISTS vista_jerarquia_establecimiento*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vista_jerarquia_establecimiento` AS SELECT 
 1 AS establecimiento_id,
 1 AS establecimiento_nombre,
 1 AS jefe_id,
 1 AS jefe_nombre,
 1 AS jefe_apellido,
 1 AS jefe_correo,
 1 AS jefe_fecha_inicio,
 1 AS jefe_activo,
 1 AS encargado_id,
 1 AS encargado_nombre,
 1 AS encargado_apellido,
 1 AS encargado_correo,
 1 AS encargado_fecha_inicio,
 1 AS encargado_activo,
 1 AS encargado_habilitado_por_jefe_id,
 1 AS encargado_fecha_habilitacion,
 1 AS total_firmas_activas*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'alimentosybebidas'
--

--
-- Dumping routines for database 'alimentosybebidas'
--

--
-- Final view structure for view `vista_jerarquia_establecimiento`
--

/*!50001 DROP VIEW IF EXISTS vista_jerarquia_establecimiento*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=root@localhost SQL SECURITY DEFINER */
/*!50001 VIEW vista_jerarquia_establecimiento AS select e.id AS establecimiento_id,e.nombre AS establecimiento_nombre,uj.id AS jefe_id,uj.nombre AS jefe_nombre,uj.apellido AS jefe_apellido,uj.correo AS jefe_correo,je.fecha_inicio AS jefe_fecha_inicio,je.activo AS jefe_activo,ue.id AS encargado_id,ue.nombre AS encargado_nombre,ue.apellido AS encargado_apellido,ue.correo AS encargado_correo,ee.fecha_inicio AS encargado_fecha_inicio,ee.activo AS encargado_activo,ee.habilitado_por AS encargado_habilitado_por_jefe_id,ee.fecha_habilitacion AS encargado_fecha_habilitacion,(select count(0) from firmas_encargados_por_jefe f where ((f.establecimiento_id = e.id) and (f.activa = 1))) AS total_firmas_activas from ((((establecimientos e left join jefes_establecimientos je on(((e.id = je.establecimiento_id) and (je.activo = 1)))) left join usuarios uj on((je.usuario_id = uj.id))) left join encargados_establecimientos ee on(((e.id = ee.establecimiento_id) and (ee.activo = 1)))) left join usuarios ue on((ee.usuario_id = ue.id))) where (e.activo = 1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
