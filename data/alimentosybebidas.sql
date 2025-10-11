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
  accion varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  recurso varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  recurso_id int DEFAULT NULL,
  detalles json DEFAULT NULL,
  ip_origen varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Soporta IPv4 e IPv6',
  user_agent varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  exitoso tinyint(1) DEFAULT '1',
  mensaje_error text COLLATE utf8mb4_unicode_ci,
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

/*!40000 ALTER TABLE auditoria_acciones DISABLE KEYS */;
/*!40000 ALTER TABLE auditoria_acciones ENABLE KEYS */;

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

/*!40000 ALTER TABLE categorias_evaluacion DISABLE KEYS */;
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES (1,'Higiene y Bioseguridad - Cocinas','Evaluación de higiene y bioseguridad en áreas de cocina',1,1),(2,'Equipamiento - Cocinas','Evaluación del equipamiento en cocinas',2,1),(3,'Producción y Almacenamiento previo','Evaluación de procesos de producción y almacenamiento',3,1),(4,'Preparación de alimentos','Evaluación de procesos de preparación de alimentos',4,1),(5,'Gestión de residuos y plagas','Evaluación de manejo de residuos y control de plagas',5,1),(6,'Vajillas y Utensilios','Evaluación de vajillas y utensilios de cocina',6,1),(7,'Higiene general - Comedor','Evaluación de higiene en área de comedor',7,1),(8,'Almacenes','Evaluación de áreas de almacenamiento',8,1),(9,'Seguridad - Defensa Civil','Evaluación de medidas de seguridad',9,1),(10,'Administración','Evaluación de aspectos administrativos',10,1);
/*!40000 ALTER TABLE categorias_evaluacion ENABLE KEYS */;

--
-- Table structure for table `configuracion_evaluacion`
--

DROP TABLE IF EXISTS configuracion_evaluacion;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_evaluacion (
  id int NOT NULL AUTO_INCREMENT,
  meta_semanal_default int NOT NULL DEFAULT '3',
  inicio_semana enum('lunes','domingo') COLLATE utf8mb4_general_ci DEFAULT 'lunes',
  zona_horaria varchar(50) COLLATE utf8mb4_general_ci DEFAULT 'America/Lima',
  dias_recordatorio json DEFAULT NULL,
  hora_recordatorio time DEFAULT '09:00:00',
  notificaciones_email tinyint(1) DEFAULT '1',
  notificaciones_navegador tinyint(1) DEFAULT '1',
  alertas_dashboard tinyint(1) DEFAULT '1',
  retener_logs_dias int DEFAULT '90',
  backup_automatico enum('diario','semanal','mensual','manual') COLLATE utf8mb4_general_ci DEFAULT 'semanal',
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

/*!40000 ALTER TABLE configuracion_evaluacion DISABLE KEYS */;
INSERT INTO configuracion_evaluacion (id, meta_semanal_default, inicio_semana, zona_horaria, dias_recordatorio, hora_recordatorio, notificaciones_email, notificaciones_navegador, alertas_dashboard, retener_logs_dias, backup_automatico, tiempo_sesion_minutos, intentos_login_max, fecha_creacion, fecha_actualizacion) VALUES (1,3,'lunes','America/Lima','[1, 3, 5]','09:00:00',1,1,1,90,'semanal',240,5,'2025-09-01 14:59:39','2025-09-01 14:59:39');
/*!40000 ALTER TABLE configuracion_evaluacion ENABLE KEYS */;

--
-- Table structure for table `configuracion_evaluaciones`
--

DROP TABLE IF EXISTS configuracion_evaluaciones;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_evaluaciones (
  id int NOT NULL AUTO_INCREMENT,
  clave varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  valor varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci,
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

/*!40000 ALTER TABLE configuracion_evaluaciones DISABLE KEYS */;
INSERT INTO configuracion_evaluaciones (id, clave, valor, descripcion, modificable_por_inspector, created_at, updated_at) VALUES (1,'meta_semanal_default','3','Meta semanal por defecto para nuevos establecimientos',1,'2025-09-01 14:59:43','2025-10-10 22:19:11'),(6,'tiempo_sesion','240','Tiempo de sesión en minutos',0,'2025-09-01 15:59:44','2025-09-01 15:59:44'),(7,'intentos_login','5','Número máximo de intentos de login',0,'2025-09-01 15:59:44','2025-09-01 15:59:44'),(8,'dias_recordatorio','1,3,5','Días de la semana para recordatorios (1=Lunes, 7=Domingo)',0,'2025-10-07 17:22:05','2025-10-07 17:22:05'),(9,'hora_recordatorio','09:00','Hora para envío de recordatorios',0,'2025-10-07 17:22:05','2025-10-07 17:22:05'),(10,'zona_horaria','America/Lima','Zona horaria del sistema',0,'2025-10-07 17:22:05','2025-10-07 17:22:05'),(11,'notificaciones_email','true','Activar notificaciones por email',0,'2025-10-07 17:22:05','2025-10-07 17:22:05');
/*!40000 ALTER TABLE configuracion_evaluaciones ENABLE KEYS */;

--
-- Table structure for table `configuracion_sistema`
--

DROP TABLE IF EXISTS configuracion_sistema;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE configuracion_sistema (
  id int NOT NULL AUTO_INCREMENT,
  modulo varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  configuracion json NOT NULL,
  version varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
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

/*!40000 ALTER TABLE configuracion_sistema DISABLE KEYS */;
/*!40000 ALTER TABLE configuracion_sistema ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `encargados_establecimientos`
--

/*!40000 ALTER TABLE encargados_establecimientos DISABLE KEYS */;
INSERT INTO encargados_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, habilitado_por, fecha_habilitacion, observaciones_jefe, created_at) VALUES (1,2,1,'2025-08-16',NULL,1,NULL,1,NULL,'2025-09-01 13:47:21','a','2025-08-19 16:30:01'),(2,3,2,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01'),(3,4,3,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01'),(4,5,4,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 16:30:01');
/*!40000 ALTER TABLE encargados_establecimientos ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `establecimientos`
--

/*!40000 ALTER TABLE establecimientos DISABLE KEYS */;
INSERT INTO establecimientos (id, tipo_establecimiento_id, nombre, direccion, telefono, correo, activo, created_at) VALUES (1,1,'Déjà vu','Dirección Déjà vu','985478569',NULL,1,'2025-08-19 16:30:01'),(2,1,'Silvia','Dirección Silvia','123456789','silvia@chancay.com',1,'2025-08-19 16:30:01'),(3,1,'Náutica','Dirección Náutica','123456789','nautica@chancay.com',1,'2025-08-19 16:30:01'),(4,1,'Rincón del Norte','Dirección Rincón del Norte','123456789','rinconnorte@chancay.com',1,'2025-08-19 16:30:01'),(6,4,'El Buen Sabor','Av. Larco 123, Miraflores, Lima','954125748',NULL,1,'2025-09-16 22:22:19'),(7,1,'BRISA MARINAS','A.v 1 de mayo 1224','977568239','',1,'2025-10-02 22:55:34'),(9,1,'El Parque',NULL,NULL,NULL,1,'2025-10-07 17:53:39'),(10,1,'Establecimiento de Prueba','Dirección de prueba',NULL,NULL,1,'2025-10-07 20:48:31');
/*!40000 ALTER TABLE establecimientos ENABLE KEYS */;

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

/*!40000 ALTER TABLE evidencias_inspeccion DISABLE KEYS */;
INSERT INTO evidencias_inspeccion (id, inspeccion_id, item_detalle_id, filename, ruta_archivo, descripcion, mime_type, tamano_bytes, uploaded_at) VALUES (5,16,NULL,'evidencia_16_102855_193.avif','evidencias\\Déjà_vu\\2025-09-01\\evidencia_16_102855_193.avif',NULL,'image/avif',53822,'2025-09-01 15:28:55'),(6,17,NULL,'evidencia_17_144653_257.jpg','evidencias\\Déjà_vu\\2025-09-12\\evidencia_17_144653_257.jpg',NULL,'image/jpeg',7267,'2025-09-12 19:46:53'),(7,19,NULL,'evidencia_19_105118_562.avif','evidencias\\Déjà_vu\\2025-09-25\\evidencia_19_105118_562.avif',NULL,'image/avif',53822,'2025-09-25 15:51:19'),(8,20,NULL,'evidencia_20_121103_596.jpeg','static/evidencias/Déjà_vu/2025-09-25/evidencia_20_121103_596.jpeg',NULL,'image/jpeg',9687,'2025-09-25 17:11:04'),(11,25,NULL,'evidencia_25_124638_604.jpg','static/evidencias/Déjà_vu/2025-10-02/evidencia_25_124638_604.jpg',NULL,'image/jpeg',39289,'2025-10-02 17:46:39'),(12,25,NULL,'evidencia_25_124638_809.jpg','static/evidencias/Déjà_vu/2025-10-02/evidencia_25_124638_809.jpg',NULL,'image/jpg',39289,'2025-10-02 17:46:39'),(15,43,NULL,'evidencia_43_162138_079.jpeg','static/evidencias/Silvia/2025-10-10/evidencia_43_162138_079.jpeg',NULL,'image/jpeg',9687,'2025-10-10 21:21:38');
/*!40000 ALTER TABLE evidencias_inspeccion ENABLE KEYS */;

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
  path_firma varchar(250) COLLATE utf8mb4_general_ci DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firmas_encargados_por_jefe`
--

/*!40000 ALTER TABLE firmas_encargados_por_jefe DISABLE KEYS */;
INSERT INTO firmas_encargados_por_jefe (id, jefe_id, encargado_id, establecimiento_id, path_firma, fecha_firma, activa, created_at) VALUES (8,7,2,1,'img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-01 10:54:53',1,'2025-09-01 17:59:42'),(9,7,3,2,'img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-02 17:33:22',1,'2025-10-02 17:33:22');
/*!40000 ALTER TABLE firmas_encargados_por_jefe ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=1456 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspeccion_detalles`
--

/*!40000 ALTER TABLE inspeccion_detalles DISABLE KEYS */;
INSERT INTO inspeccion_detalles (id, inspeccion_id, item_establecimiento_id, rating, score, observacion_item, created_at) VALUES (511,16,4,4,4.00,'','2025-09-01 15:28:55'),(512,16,8,2,2.00,'','2025-09-01 15:28:55'),(513,16,12,3,3.00,'','2025-09-01 15:28:55'),(514,16,16,2,2.00,'','2025-09-01 15:28:55'),(515,16,20,2,2.00,'','2025-09-01 15:28:55'),(516,16,24,4,4.00,'','2025-09-01 15:28:55'),(517,16,28,2,2.00,'','2025-09-01 15:28:55'),(518,16,32,4,4.00,'','2025-09-01 15:28:55'),(519,16,36,4,4.00,'','2025-09-01 15:28:55'),(520,16,40,3,3.00,'','2025-09-01 15:28:55'),(521,16,44,4,4.00,'','2025-09-01 15:28:55'),(522,16,48,7,7.00,'','2025-09-01 15:28:55'),(523,16,52,4,4.00,'','2025-09-01 15:28:55'),(524,16,56,4,4.00,'','2025-09-01 15:28:55'),(525,16,60,4,4.00,'','2025-09-01 15:28:55'),(526,16,64,4,4.00,'','2025-09-01 15:28:55'),(527,16,68,8,8.00,'','2025-09-01 15:28:55'),(528,16,72,7,7.00,'','2025-09-01 15:28:55'),(529,16,76,8,8.00,'','2025-09-01 15:28:55'),(530,16,80,7,7.00,'','2025-09-01 15:28:55'),(531,16,84,4,4.00,'','2025-09-01 15:28:55'),(532,16,88,2,2.00,'','2025-09-01 15:28:55'),(533,16,92,4,4.00,'','2025-09-01 15:28:55'),(534,16,96,8,8.00,'','2025-09-01 15:28:55'),(535,16,100,4,4.00,'','2025-09-01 15:28:55'),(536,16,104,4,4.00,'','2025-09-01 15:28:55'),(537,16,108,4,4.00,'','2025-09-01 15:28:55'),(538,16,112,2,2.00,'','2025-09-01 15:28:55'),(539,16,116,3,3.00,'','2025-09-01 15:28:55'),(540,16,120,2,2.00,'','2025-09-01 15:28:55'),(541,16,124,2,2.00,'','2025-09-01 15:28:55'),(542,16,128,3,3.00,'','2025-09-01 15:28:55'),(543,16,132,2,2.00,'','2025-09-01 15:28:55'),(544,16,136,4,4.00,'','2025-09-01 15:28:55'),(545,16,140,8,8.00,'','2025-09-01 15:28:55'),(546,16,144,7,7.00,'','2025-09-01 15:28:55'),(547,16,148,4,4.00,'','2025-09-01 15:28:55'),(548,16,152,8,8.00,'','2025-09-01 15:28:55'),(549,16,156,4,4.00,'','2025-09-01 15:28:55'),(550,16,160,8,8.00,'','2025-09-01 15:28:55'),(551,16,164,7,7.00,'','2025-09-01 15:28:55'),(552,16,168,4,4.00,'','2025-09-01 15:28:55'),(553,16,172,4,4.00,'','2025-09-01 15:28:55'),(554,16,176,4,4.00,'','2025-09-01 15:28:55'),(555,16,180,2,2.00,'','2025-09-01 15:28:55'),(556,16,184,2,2.00,'','2025-09-01 15:28:55'),(557,16,188,3,3.00,'','2025-09-01 15:28:55'),(558,16,192,3,3.00,'','2025-09-01 15:28:55'),(559,16,196,2,2.00,'','2025-09-01 15:28:55'),(560,16,200,2,2.00,'','2025-09-01 15:28:55'),(561,16,204,1,1.00,'','2025-09-01 15:28:55'),(562,17,4,3,3.00,'','2025-09-12 19:46:53'),(563,17,8,2,2.00,'','2025-09-12 19:46:53'),(564,17,12,2,2.00,'','2025-09-12 19:46:53'),(565,17,16,2,2.00,'','2025-09-12 19:46:53'),(566,17,20,2,2.00,'','2025-09-12 19:46:53'),(567,17,24,3,3.00,'','2025-09-12 19:46:53'),(568,17,28,2,2.00,'','2025-09-12 19:46:53'),(569,17,32,3,3.00,'','2025-09-12 19:46:53'),(570,17,36,4,4.00,'','2025-09-12 19:46:53'),(571,17,40,3,3.00,'','2025-09-12 19:46:53'),(572,17,44,4,4.00,'','2025-09-12 19:46:53'),(573,17,48,8,8.00,'','2025-09-12 19:46:53'),(574,17,52,4,4.00,'','2025-09-12 19:46:53'),(575,17,56,3,3.00,'','2025-09-12 19:46:53'),(576,17,60,4,4.00,'','2025-09-12 19:46:53'),(577,17,64,4,4.00,'','2025-09-12 19:46:53'),(578,17,68,7,7.00,'','2025-09-12 19:46:53'),(579,17,72,8,8.00,'','2025-09-12 19:46:53'),(580,17,76,8,8.00,'','2025-09-12 19:46:53'),(581,17,80,7,7.00,'','2025-09-12 19:46:53'),(582,17,84,4,4.00,'','2025-09-12 19:46:53'),(583,17,88,2,2.00,'','2025-09-12 19:46:53'),(584,17,92,4,4.00,'','2025-09-12 19:46:53'),(585,17,96,7,7.00,'','2025-09-12 19:46:53'),(586,17,100,4,4.00,'','2025-09-12 19:46:53'),(587,17,104,4,4.00,'','2025-09-12 19:46:53'),(588,17,108,4,4.00,'','2025-09-12 19:46:53'),(589,17,112,2,2.00,'','2025-09-12 19:46:53'),(590,17,116,4,4.00,'','2025-09-12 19:46:53'),(591,17,120,2,2.00,'','2025-09-12 19:46:53'),(592,17,124,2,2.00,'','2025-09-12 19:46:53'),(593,17,128,4,4.00,'','2025-09-12 19:46:53'),(594,17,132,2,2.00,'','2025-09-12 19:46:53'),(595,17,136,4,4.00,'','2025-09-12 19:46:53'),(596,17,140,8,8.00,'','2025-09-12 19:46:53'),(597,17,144,8,8.00,'','2025-09-12 19:46:53'),(598,17,148,4,4.00,'','2025-09-12 19:46:53'),(599,17,152,8,8.00,'','2025-09-12 19:46:53'),(600,17,156,4,4.00,'','2025-09-12 19:46:53'),(601,17,160,8,8.00,'','2025-09-12 19:46:53'),(602,17,164,8,8.00,'','2025-09-12 19:46:53'),(603,17,168,4,4.00,'','2025-09-12 19:46:53'),(604,17,172,4,4.00,'','2025-09-12 19:46:53'),(605,17,176,3,3.00,'','2025-09-12 19:46:53'),(606,17,180,2,2.00,'','2025-09-12 19:46:53'),(607,17,184,2,2.00,'','2025-09-12 19:46:53'),(608,17,188,3,3.00,'','2025-09-12 19:46:53'),(609,17,192,4,4.00,'','2025-09-12 19:46:53'),(610,17,196,2,2.00,'','2025-09-12 19:46:53'),(611,17,200,2,2.00,'','2025-09-12 19:46:53'),(612,17,204,2,2.00,'','2025-09-12 19:46:53'),(613,19,4,3,3.00,'','2025-09-25 15:51:18'),(614,19,8,2,2.00,'','2025-09-25 15:51:18'),(615,19,12,4,4.00,'','2025-09-25 15:51:18'),(616,19,16,2,2.00,'','2025-09-25 15:51:18'),(617,19,20,2,2.00,'','2025-09-25 15:51:18'),(618,19,24,3,3.00,'','2025-09-25 15:51:18'),(619,19,28,1,1.00,'','2025-09-25 15:51:18'),(620,19,32,4,4.00,'','2025-09-25 15:51:18'),(621,19,36,3,3.00,'','2025-09-25 15:51:18'),(622,19,40,4,4.00,'','2025-09-25 15:51:18'),(623,19,44,3,3.00,'','2025-09-25 15:51:18'),(624,19,48,5,5.00,'','2025-09-25 15:51:18'),(625,19,52,4,4.00,'','2025-09-25 15:51:18'),(626,19,56,3,3.00,'','2025-09-25 15:51:18'),(627,19,60,3,3.00,'','2025-09-25 15:51:18'),(628,19,64,4,4.00,'','2025-09-25 15:51:18'),(629,19,68,8,8.00,'','2025-09-25 15:51:18'),(630,19,72,8,8.00,'','2025-09-25 15:51:18'),(631,19,76,8,8.00,'','2025-09-25 15:51:18'),(632,19,80,8,8.00,'','2025-09-25 15:51:18'),(633,19,84,4,4.00,'','2025-09-25 15:51:19'),(634,19,88,2,2.00,'','2025-09-25 15:51:19'),(635,19,92,3,3.00,'','2025-09-25 15:51:19'),(636,19,96,8,8.00,'','2025-09-25 15:51:19'),(637,19,100,4,4.00,'','2025-09-25 15:51:19'),(638,19,104,3,3.00,'','2025-09-25 15:51:19'),(639,19,108,4,4.00,'','2025-09-25 15:51:19'),(640,19,112,2,2.00,'','2025-09-25 15:51:19'),(641,19,116,3,3.00,'','2025-09-25 15:51:19'),(642,19,120,2,2.00,'','2025-09-25 15:51:19'),(643,19,124,2,2.00,'','2025-09-25 15:51:19'),(644,19,128,4,4.00,'','2025-09-25 15:51:19'),(645,19,132,2,2.00,'','2025-09-25 15:51:19'),(646,19,136,4,4.00,'','2025-09-25 15:51:19'),(647,19,140,8,8.00,'','2025-09-25 15:51:19'),(648,19,144,8,8.00,'','2025-09-25 15:51:19'),(649,19,148,3,3.00,'','2025-09-25 15:51:19'),(650,19,152,8,8.00,'','2025-09-25 15:51:19'),(651,19,156,3,3.00,'','2025-09-25 15:51:19'),(652,19,160,8,8.00,'','2025-09-25 15:51:19'),(653,19,164,8,8.00,'','2025-09-25 15:51:19'),(654,19,168,4,4.00,'','2025-09-25 15:51:19'),(655,19,172,3,3.00,'','2025-09-25 15:51:19'),(656,19,176,3,3.00,'','2025-09-25 15:51:19'),(657,19,180,2,2.00,'','2025-09-25 15:51:19'),(658,19,184,1,1.00,'','2025-09-25 15:51:19'),(659,19,188,4,4.00,'','2025-09-25 15:51:19'),(660,19,192,3,3.00,'','2025-09-25 15:51:19'),(661,19,196,2,2.00,'','2025-09-25 15:51:19'),(662,19,200,2,2.00,'','2025-09-25 15:51:19'),(663,19,204,1,1.00,'','2025-09-25 15:51:19'),(664,20,4,4,4.00,'','2025-09-25 17:11:04'),(665,20,8,2,2.00,'','2025-09-25 17:11:04'),(666,20,12,3,3.00,'','2025-09-25 17:11:04'),(667,20,16,2,2.00,'','2025-09-25 17:11:04'),(668,20,20,1,1.00,'','2025-09-25 17:11:04'),(669,20,24,4,4.00,'','2025-09-25 17:11:04'),(670,20,28,2,2.00,'','2025-09-25 17:11:04'),(671,20,32,3,3.00,'','2025-09-25 17:11:04'),(672,20,36,4,4.00,'','2025-09-25 17:11:04'),(673,20,40,3,3.00,'','2025-09-25 17:11:04'),(674,20,44,4,4.00,'','2025-09-25 17:11:04'),(675,20,48,8,8.00,'','2025-09-25 17:11:04'),(676,20,52,3,3.00,'','2025-09-25 17:11:04'),(677,20,56,4,4.00,'','2025-09-25 17:11:04'),(678,20,60,3,3.00,'','2025-09-25 17:11:04'),(679,20,64,3,3.00,'','2025-09-25 17:11:04'),(680,20,68,7,7.00,'','2025-09-25 17:11:04'),(681,20,72,8,8.00,'','2025-09-25 17:11:04'),(682,20,76,8,8.00,'','2025-09-25 17:11:04'),(683,20,80,8,8.00,'','2025-09-25 17:11:04'),(684,20,84,3,3.00,'','2025-09-25 17:11:04'),(685,20,88,2,2.00,'','2025-09-25 17:11:04'),(686,20,92,3,3.00,'','2025-09-25 17:11:04'),(687,20,96,8,8.00,'','2025-09-25 17:11:04'),(688,20,100,3,3.00,'','2025-09-25 17:11:04'),(689,20,104,3,3.00,'','2025-09-25 17:11:04'),(690,20,108,4,4.00,'','2025-09-25 17:11:04'),(691,20,112,2,2.00,'','2025-09-25 17:11:04'),(692,20,116,3,3.00,'','2025-09-25 17:11:04'),(693,20,120,2,2.00,'','2025-09-25 17:11:04'),(694,20,124,2,2.00,'','2025-09-25 17:11:04'),(695,20,128,3,3.00,'','2025-09-25 17:11:04'),(696,20,132,2,2.00,'','2025-09-25 17:11:04'),(697,20,136,4,4.00,'','2025-09-25 17:11:04'),(698,20,140,8,8.00,'','2025-09-25 17:11:04'),(699,20,144,8,8.00,'','2025-09-25 17:11:04'),(700,20,148,4,4.00,'','2025-09-25 17:11:04'),(701,20,152,8,8.00,'','2025-09-25 17:11:04'),(702,20,156,3,3.00,'','2025-09-25 17:11:04'),(703,20,160,8,8.00,'','2025-09-25 17:11:04'),(704,20,164,8,8.00,'','2025-09-25 17:11:04'),(705,20,168,3,3.00,'','2025-09-25 17:11:04'),(706,20,172,4,4.00,'','2025-09-25 17:11:04'),(707,20,176,4,4.00,'','2025-09-25 17:11:04'),(708,20,180,2,2.00,'','2025-09-25 17:11:04'),(709,20,184,2,2.00,'','2025-09-25 17:11:04'),(710,20,188,3,3.00,'','2025-09-25 17:11:04'),(711,20,192,4,4.00,'','2025-09-25 17:11:04'),(712,20,196,2,2.00,'','2025-09-25 17:11:04'),(713,20,200,2,2.00,'','2025-09-25 17:11:04'),(714,20,204,1,1.00,'','2025-09-25 17:11:04'),(919,25,4,4,4.00,'','2025-10-02 17:46:39'),(920,25,8,2,2.00,'','2025-10-02 17:46:39'),(921,25,12,3,3.00,'','2025-10-02 17:46:39'),(922,25,16,2,2.00,'','2025-10-02 17:46:39'),(923,25,20,2,2.00,'','2025-10-02 17:46:39'),(924,25,24,4,4.00,'','2025-10-02 17:46:39'),(925,25,28,2,2.00,'','2025-10-02 17:46:39'),(926,25,32,3,3.00,'','2025-10-02 17:46:39'),(927,25,36,3,3.00,'','2025-10-02 17:46:39'),(928,25,40,4,4.00,'','2025-10-02 17:46:39'),(929,25,44,4,4.00,'','2025-10-02 17:46:39'),(930,25,48,8,8.00,'','2025-10-02 17:46:39'),(931,25,52,3,3.00,'','2025-10-02 17:46:39'),(932,25,56,4,4.00,'','2025-10-02 17:46:39'),(933,25,60,3,3.00,'','2025-10-02 17:46:39'),(934,25,64,3,3.00,'','2025-10-02 17:46:39'),(935,25,68,8,8.00,'','2025-10-02 17:46:39'),(936,25,72,8,8.00,'','2025-10-02 17:46:39'),(937,25,76,8,8.00,'','2025-10-02 17:46:39'),(938,25,80,7,7.00,'','2025-10-02 17:46:39'),(939,25,84,4,4.00,'','2025-10-02 17:46:39'),(940,25,88,2,2.00,'','2025-10-02 17:46:39'),(941,25,92,3,3.00,'','2025-10-02 17:46:39'),(942,25,96,8,8.00,'','2025-10-02 17:46:39'),(943,25,100,3,3.00,'','2025-10-02 17:46:39'),(944,25,104,4,4.00,'','2025-10-02 17:46:39'),(945,25,108,3,3.00,'','2025-10-02 17:46:39'),(946,25,112,2,2.00,'','2025-10-02 17:46:39'),(947,25,116,3,3.00,'','2025-10-02 17:46:39'),(948,25,120,2,2.00,'','2025-10-02 17:46:39'),(949,25,124,2,2.00,'','2025-10-02 17:46:39'),(950,25,128,4,4.00,'','2025-10-02 17:46:39'),(951,25,132,2,2.00,'','2025-10-02 17:46:39'),(952,25,136,3,3.00,'','2025-10-02 17:46:39'),(953,25,140,7,7.00,'','2025-10-02 17:46:39'),(954,25,144,7,7.00,'','2025-10-02 17:46:39'),(955,25,148,4,4.00,'','2025-10-02 17:46:39'),(956,25,152,7,7.00,'','2025-10-02 17:46:39'),(957,25,156,3,3.00,'','2025-10-02 17:46:39'),(958,25,160,7,7.00,'','2025-10-02 17:46:39'),(959,25,164,8,8.00,'','2025-10-02 17:46:39'),(960,25,168,4,4.00,'','2025-10-02 17:46:39'),(961,25,172,4,4.00,'','2025-10-02 17:46:39'),(962,25,176,3,3.00,'','2025-10-02 17:46:39'),(963,25,180,2,2.00,'','2025-10-02 17:46:39'),(964,25,184,2,2.00,'','2025-10-02 17:46:39'),(965,25,188,3,3.00,'','2025-10-02 17:46:39'),(966,25,192,3,3.00,'','2025-10-02 17:46:39'),(967,25,196,2,2.00,'','2025-10-02 17:46:39'),(968,25,200,2,2.00,'','2025-10-02 17:46:39'),(969,25,204,1,1.00,'','2025-10-02 17:46:39'),(1032,30,3,4,4.00,'','2025-10-03 23:28:30'),(1033,30,7,2,2.00,'','2025-10-03 23:28:30'),(1034,30,11,4,4.00,'','2025-10-04 15:24:02'),(1035,30,15,2,2.00,'','2025-10-04 15:24:02'),(1036,30,19,2,2.00,'','2025-10-04 15:24:02'),(1037,30,23,3,3.00,'','2025-10-04 15:24:02'),(1038,30,27,2,2.00,'','2025-10-04 15:39:52'),(1039,30,31,3,3.00,'','2025-10-04 15:39:52'),(1040,30,35,4,4.00,'','2025-10-04 15:39:52'),(1041,30,39,3,3.00,'','2025-10-04 15:39:52'),(1042,30,79,8,8.00,'','2025-10-04 15:39:52'),(1043,30,83,4,4.00,'','2025-10-04 15:39:52'),(1044,30,87,2,2.00,'','2025-10-04 15:39:52'),(1045,30,91,4,4.00,'','2025-10-04 15:39:52'),(1046,30,95,8,8.00,'','2025-10-04 15:39:52'),(1047,30,99,4,4.00,'','2025-10-04 15:39:52'),(1048,30,103,3,3.00,'','2025-10-04 15:39:52'),(1049,30,107,3,3.00,'','2025-10-04 15:39:52'),(1050,30,111,2,2.00,'','2025-10-04 15:39:52'),(1051,30,115,4,4.00,'','2025-10-04 15:39:52'),(1052,30,119,1,1.00,'','2025-10-04 15:39:52'),(1053,30,123,2,2.00,'','2025-10-04 15:39:52'),(1054,30,127,3,3.00,'','2025-10-04 15:39:52'),(1055,30,131,2,2.00,'','2025-10-04 15:39:52'),(1056,30,135,4,4.00,'','2025-10-04 15:39:52'),(1057,30,139,7,7.00,'','2025-10-04 15:39:52'),(1058,30,143,8,8.00,'','2025-10-04 15:39:52'),(1059,30,147,3,3.00,'','2025-10-04 15:39:52'),(1060,30,151,8,8.00,'','2025-10-04 15:39:52'),(1061,30,155,3,3.00,'','2025-10-04 15:39:52'),(1062,30,159,8,8.00,'','2025-10-04 15:39:52'),(1063,30,163,8,8.00,'','2025-10-04 15:39:52'),(1064,30,167,3,3.00,'','2025-10-04 15:39:52'),(1065,30,171,4,4.00,'','2025-10-04 15:39:52'),(1066,30,175,3,3.00,'','2025-10-04 15:39:52'),(1067,30,179,2,2.00,'','2025-10-04 15:39:52'),(1068,30,183,2,2.00,'','2025-10-04 15:39:52'),(1069,30,187,3,3.00,'','2025-10-04 15:39:52'),(1070,30,191,3,3.00,'','2025-10-04 15:39:52'),(1071,30,195,2,2.00,'','2025-10-04 15:39:52'),(1072,30,199,2,2.00,'','2025-10-04 15:39:52'),(1073,30,203,2,2.00,'','2025-10-04 15:39:52'),(1074,30,43,4,4.00,'','2025-10-10 20:01:50'),(1075,30,47,7,7.00,'','2025-10-10 20:01:50'),(1076,30,51,4,4.00,'','2025-10-10 20:01:50'),(1077,30,55,3,3.00,'','2025-10-10 20:01:50'),(1078,30,59,4,4.00,'','2025-10-10 20:01:50'),(1079,30,63,4,4.00,'','2025-10-10 20:01:50'),(1080,30,67,8,8.00,'','2025-10-10 20:01:50'),(1081,30,71,7,7.00,'','2025-10-10 20:01:50'),(1082,30,75,8,8.00,'','2025-10-10 20:01:50'),(1083,31,3,4,4.00,'','2025-10-10 20:03:40'),(1084,31,7,2,2.00,'','2025-10-10 20:03:40'),(1085,31,11,4,4.00,'','2025-10-10 20:03:40'),(1086,31,15,2,2.00,'','2025-10-10 20:03:40'),(1087,31,19,1,1.00,'','2025-10-10 20:03:40'),(1088,31,23,4,4.00,'','2025-10-10 20:03:40'),(1089,31,27,2,2.00,'','2025-10-10 20:03:40'),(1090,31,31,3,3.00,'','2025-10-10 20:03:40'),(1091,31,35,4,4.00,'','2025-10-10 20:03:40'),(1092,31,39,4,4.00,'','2025-10-10 20:03:40'),(1093,31,43,3,3.00,'','2025-10-10 20:03:40'),(1094,31,47,8,8.00,'','2025-10-10 20:03:40'),(1095,31,51,3,3.00,'','2025-10-10 20:03:40'),(1096,31,55,4,4.00,'','2025-10-10 20:03:40'),(1097,31,59,3,3.00,'','2025-10-10 20:03:40'),(1098,31,63,4,4.00,'','2025-10-10 20:03:40'),(1099,31,67,8,8.00,'','2025-10-10 20:03:40'),(1100,31,71,7,7.00,'','2025-10-10 20:03:40'),(1101,31,75,8,8.00,'','2025-10-10 20:03:40'),(1102,31,79,7,7.00,'','2025-10-10 20:03:40'),(1103,31,83,3,3.00,'','2025-10-10 20:03:40'),(1104,31,87,2,2.00,'','2025-10-10 20:03:40'),(1105,31,91,4,4.00,'','2025-10-10 20:03:40'),(1106,31,95,8,8.00,'','2025-10-10 20:03:40'),(1107,31,99,4,4.00,'','2025-10-10 20:03:40'),(1108,31,103,4,4.00,'','2025-10-10 20:03:40'),(1109,31,107,3,3.00,'','2025-10-10 20:03:40'),(1110,31,111,2,2.00,'','2025-10-10 20:03:40'),(1111,31,115,3,3.00,'','2025-10-10 20:03:40'),(1112,31,119,2,2.00,'','2025-10-10 20:03:40'),(1113,31,123,1,1.00,'','2025-10-10 20:03:40'),(1114,31,127,3,3.00,'','2025-10-10 20:03:40'),(1115,31,131,2,2.00,'','2025-10-10 20:03:40'),(1116,31,135,3,3.00,'','2025-10-10 20:03:40'),(1117,31,139,8,8.00,'','2025-10-10 20:03:40'),(1118,31,143,8,8.00,'','2025-10-10 20:03:40'),(1119,31,147,3,3.00,'','2025-10-10 20:03:40'),(1120,31,151,8,8.00,'','2025-10-10 20:03:40'),(1121,31,155,3,3.00,'','2025-10-10 20:03:40'),(1122,31,159,8,8.00,'','2025-10-10 20:03:40'),(1123,31,163,8,8.00,'','2025-10-10 20:03:40'),(1124,31,167,3,3.00,'','2025-10-10 20:03:40'),(1125,31,171,4,4.00,'','2025-10-10 20:03:40'),(1126,31,175,3,3.00,'','2025-10-10 20:03:40'),(1127,31,179,2,2.00,'','2025-10-10 20:03:40'),(1128,31,183,1,1.00,'','2025-10-10 20:03:40'),(1129,31,187,3,3.00,'','2025-10-10 20:03:40'),(1130,31,191,3,3.00,'','2025-10-10 20:03:40'),(1131,31,195,2,2.00,'','2025-10-10 20:03:40'),(1132,31,199,1,1.00,'','2025-10-10 20:03:40'),(1133,31,203,2,2.00,'','2025-10-10 20:03:40'),(1134,32,3,4,4.00,'','2025-10-10 20:51:10'),(1135,32,7,2,2.00,'','2025-10-10 20:51:10'),(1136,32,11,4,4.00,'','2025-10-10 20:51:10'),(1137,32,15,2,2.00,'','2025-10-10 20:51:10'),(1138,32,19,1,1.00,'','2025-10-10 20:51:10'),(1139,32,23,4,4.00,'','2025-10-10 20:51:10'),(1140,32,27,2,2.00,'','2025-10-10 20:51:10'),(1141,32,31,3,3.00,'','2025-10-10 20:51:10'),(1142,32,35,4,4.00,'','2025-10-10 20:51:10'),(1143,32,39,4,4.00,'','2025-10-10 20:51:10'),(1144,32,43,3,3.00,'','2025-10-10 20:51:10'),(1145,32,47,8,8.00,'','2025-10-10 20:51:10'),(1146,32,51,3,3.00,'','2025-10-10 20:51:10'),(1147,32,55,4,4.00,'','2025-10-10 20:51:10'),(1148,32,59,3,3.00,'','2025-10-10 20:51:10'),(1149,32,63,4,4.00,'','2025-10-10 20:51:10'),(1150,32,67,8,8.00,'','2025-10-10 20:51:10'),(1151,32,71,7,7.00,'','2025-10-10 20:51:10'),(1152,32,75,8,8.00,'','2025-10-10 20:51:10'),(1153,32,79,7,7.00,'','2025-10-10 20:51:10'),(1154,32,83,3,3.00,'','2025-10-10 20:51:10'),(1155,32,87,2,2.00,'','2025-10-10 20:51:10'),(1156,32,91,4,4.00,'','2025-10-10 20:51:10'),(1157,32,95,8,8.00,'','2025-10-10 20:51:10'),(1158,32,99,4,4.00,'','2025-10-10 20:51:10'),(1159,32,103,4,4.00,'','2025-10-10 20:51:10'),(1160,32,107,3,3.00,'','2025-10-10 20:51:10'),(1161,32,111,2,2.00,'','2025-10-10 20:51:10'),(1162,32,115,3,3.00,'','2025-10-10 20:51:10'),(1163,32,119,2,2.00,'','2025-10-10 20:51:10'),(1164,32,123,1,1.00,'','2025-10-10 20:51:10'),(1165,32,127,3,3.00,'','2025-10-10 20:51:10'),(1166,32,131,2,2.00,'','2025-10-10 20:51:10'),(1167,32,135,3,3.00,'','2025-10-10 20:51:10'),(1168,32,139,8,8.00,'','2025-10-10 20:51:10'),(1169,32,143,8,8.00,'','2025-10-10 20:51:10'),(1170,32,147,3,3.00,'','2025-10-10 20:51:10'),(1171,32,151,8,8.00,'','2025-10-10 20:51:10'),(1172,32,155,3,3.00,'','2025-10-10 20:51:10'),(1173,32,159,8,8.00,'','2025-10-10 20:51:10'),(1174,32,163,8,8.00,'','2025-10-10 20:51:10'),(1175,32,167,3,3.00,'','2025-10-10 20:51:10'),(1176,32,171,4,4.00,'','2025-10-10 20:51:10'),(1177,32,175,3,3.00,'','2025-10-10 20:51:10'),(1178,32,179,2,2.00,'','2025-10-10 20:51:10'),(1179,32,183,1,1.00,'','2025-10-10 20:51:10'),(1180,32,187,3,3.00,'','2025-10-10 20:51:10'),(1181,32,191,3,3.00,'','2025-10-10 20:51:10'),(1182,32,195,2,2.00,'','2025-10-10 20:51:10'),(1183,32,199,1,1.00,'','2025-10-10 20:51:10'),(1184,32,203,2,2.00,'','2025-10-10 20:51:10'),(1185,42,3,4,4.00,'','2025-10-10 21:14:23'),(1186,42,7,2,2.00,'','2025-10-10 21:14:23'),(1187,42,11,4,4.00,'','2025-10-10 21:14:23'),(1188,42,15,2,2.00,'','2025-10-10 21:14:23'),(1189,42,19,1,1.00,'','2025-10-10 21:14:23'),(1190,42,23,4,4.00,'','2025-10-10 21:14:23'),(1191,42,27,2,2.00,'','2025-10-10 21:14:23'),(1192,42,31,3,3.00,'','2025-10-10 21:14:23'),(1193,42,35,4,4.00,'','2025-10-10 21:14:23'),(1194,42,39,4,4.00,'','2025-10-10 21:14:23'),(1195,42,43,3,3.00,'','2025-10-10 21:14:23'),(1196,42,47,8,8.00,'','2025-10-10 21:14:23'),(1197,42,51,3,3.00,'','2025-10-10 21:14:23'),(1198,42,55,4,4.00,'','2025-10-10 21:14:23'),(1199,42,59,3,3.00,'','2025-10-10 21:14:23'),(1200,42,63,4,4.00,'','2025-10-10 21:14:23'),(1201,42,67,8,8.00,'','2025-10-10 21:14:23'),(1202,42,71,7,7.00,'','2025-10-10 21:14:23'),(1203,42,75,8,8.00,'','2025-10-10 21:14:23'),(1204,42,79,7,7.00,'','2025-10-10 21:14:23'),(1205,42,83,3,3.00,'','2025-10-10 21:14:23'),(1206,42,87,2,2.00,'','2025-10-10 21:14:23'),(1207,42,91,4,4.00,'','2025-10-10 21:14:23'),(1208,42,95,8,8.00,'','2025-10-10 21:14:23'),(1209,42,99,4,4.00,'','2025-10-10 21:14:23'),(1210,42,103,4,4.00,'','2025-10-10 21:14:23'),(1211,42,107,3,3.00,'','2025-10-10 21:14:23'),(1212,42,111,2,2.00,'','2025-10-10 21:14:23'),(1213,42,115,3,3.00,'','2025-10-10 21:14:23'),(1214,42,119,2,2.00,'','2025-10-10 21:14:23'),(1215,42,123,1,1.00,'','2025-10-10 21:14:23'),(1216,42,127,3,3.00,'','2025-10-10 21:14:23'),(1217,42,131,2,2.00,'','2025-10-10 21:14:23'),(1218,42,135,3,3.00,'','2025-10-10 21:14:23'),(1219,42,139,8,8.00,'','2025-10-10 21:14:23'),(1220,42,143,8,8.00,'','2025-10-10 21:14:23'),(1221,42,147,3,3.00,'','2025-10-10 21:14:23'),(1222,42,151,8,8.00,'','2025-10-10 21:14:23'),(1223,42,155,3,3.00,'','2025-10-10 21:14:23'),(1224,42,159,8,8.00,'','2025-10-10 21:14:23'),(1225,42,163,8,8.00,'','2025-10-10 21:14:23'),(1226,42,167,3,3.00,'','2025-10-10 21:14:23'),(1227,42,171,4,4.00,'','2025-10-10 21:14:23'),(1228,42,175,3,3.00,'','2025-10-10 21:14:23'),(1229,42,179,2,2.00,'','2025-10-10 21:14:23'),(1230,42,183,1,1.00,'','2025-10-10 21:14:23'),(1231,42,187,3,3.00,'','2025-10-10 21:14:23'),(1232,42,191,3,3.00,'','2025-10-10 21:14:23'),(1233,42,195,2,2.00,'','2025-10-10 21:14:23'),(1234,42,199,1,1.00,'','2025-10-10 21:14:23'),(1235,42,203,2,2.00,'','2025-10-10 21:14:23'),(1236,43,3,4,4.00,'','2025-10-10 21:21:38'),(1237,43,7,2,2.00,'','2025-10-10 21:21:38'),(1238,43,11,3,3.00,'','2025-10-10 21:21:38'),(1239,43,15,2,2.00,'','2025-10-10 21:21:38'),(1240,43,19,2,2.00,'','2025-10-10 21:21:38'),(1241,43,23,3,3.00,'','2025-10-10 21:21:38'),(1242,43,27,2,2.00,'','2025-10-10 21:21:38'),(1243,43,31,3,3.00,'','2025-10-10 21:21:38'),(1244,43,35,3,3.00,'','2025-10-10 21:21:38'),(1245,43,39,3,3.00,'','2025-10-10 21:21:38'),(1246,43,43,4,4.00,'','2025-10-10 21:21:38'),(1247,43,47,8,8.00,'','2025-10-10 21:21:38'),(1248,43,51,4,4.00,'','2025-10-10 21:21:38'),(1249,43,55,4,4.00,'','2025-10-10 21:21:38'),(1250,43,59,3,3.00,'','2025-10-10 21:21:38'),(1251,43,63,4,4.00,'','2025-10-10 21:21:38'),(1252,43,67,7,7.00,'','2025-10-10 21:21:38'),(1253,43,71,8,8.00,'','2025-10-10 21:21:38'),(1254,43,75,8,8.00,'','2025-10-10 21:21:38'),(1255,43,79,8,8.00,'','2025-10-10 21:21:38'),(1256,43,83,3,3.00,'','2025-10-10 21:21:38'),(1257,43,87,2,2.00,'','2025-10-10 21:21:38'),(1258,43,91,3,3.00,'','2025-10-10 21:21:38'),(1259,43,95,8,8.00,'','2025-10-10 21:21:38'),(1260,43,99,3,3.00,'','2025-10-10 21:21:38'),(1261,43,103,4,4.00,'','2025-10-10 21:21:38'),(1262,43,107,4,4.00,'','2025-10-10 21:21:38'),(1263,43,111,2,2.00,'','2025-10-10 21:21:38'),(1264,43,115,4,4.00,'','2025-10-10 21:21:38'),(1265,43,119,2,2.00,'','2025-10-10 21:21:38'),(1266,43,123,1,1.00,'','2025-10-10 21:21:38'),(1267,43,127,4,4.00,'','2025-10-10 21:21:38'),(1268,43,131,2,2.00,'','2025-10-10 21:21:38'),(1269,43,135,4,4.00,'','2025-10-10 21:21:38'),(1270,43,139,7,7.00,'','2025-10-10 21:21:38'),(1271,43,143,8,8.00,'','2025-10-10 21:21:38'),(1272,43,147,3,3.00,'','2025-10-10 21:21:38'),(1273,43,151,8,8.00,'','2025-10-10 21:21:38'),(1274,43,155,3,3.00,'','2025-10-10 21:21:38'),(1275,43,159,7,7.00,'','2025-10-10 21:21:38'),(1276,43,163,8,8.00,'','2025-10-10 21:21:38'),(1277,43,167,4,4.00,'','2025-10-10 21:21:38'),(1278,43,171,3,3.00,'','2025-10-10 21:21:38'),(1279,43,175,4,4.00,'','2025-10-10 21:21:38'),(1280,43,179,2,2.00,'','2025-10-10 21:21:38'),(1281,43,183,2,2.00,'','2025-10-10 21:21:38'),(1282,43,187,3,3.00,'','2025-10-10 21:21:38'),(1283,43,191,4,4.00,'','2025-10-10 21:21:38'),(1284,43,195,2,2.00,'','2025-10-10 21:21:38'),(1285,43,199,2,2.00,'','2025-10-10 21:21:38'),(1286,43,203,2,2.00,'','2025-10-10 21:21:38'),(1287,44,4,4,4.00,'','2025-10-10 21:25:39'),(1288,44,8,1,1.00,'','2025-10-10 21:25:39'),(1289,44,12,4,4.00,'','2025-10-10 21:25:39'),(1290,44,16,2,2.00,'','2025-10-10 21:25:39'),(1291,44,20,2,2.00,'','2025-10-10 21:25:39'),(1292,44,24,3,3.00,'','2025-10-10 21:25:39'),(1293,44,28,2,2.00,'','2025-10-10 21:25:39'),(1294,44,32,4,4.00,'','2025-10-10 21:25:39'),(1295,44,36,4,4.00,'','2025-10-10 21:25:39'),(1296,44,40,4,4.00,'','2025-10-10 21:25:39'),(1297,44,44,3,3.00,'','2025-10-10 21:25:39'),(1298,44,48,8,8.00,'','2025-10-10 21:25:39'),(1299,44,52,3,3.00,'','2025-10-10 21:25:39'),(1300,44,56,4,4.00,'','2025-10-10 21:25:39'),(1301,44,60,3,3.00,'','2025-10-10 21:25:39'),(1302,44,64,3,3.00,'','2025-10-10 21:25:39'),(1303,44,68,8,8.00,'','2025-10-10 21:25:39'),(1304,44,72,8,8.00,'','2025-10-10 21:25:39'),(1305,44,76,8,8.00,'','2025-10-10 21:25:39'),(1306,44,80,8,8.00,'','2025-10-10 21:25:39'),(1307,44,84,3,3.00,'','2025-10-10 21:25:39'),(1308,44,88,1,1.00,'','2025-10-10 21:25:39'),(1309,44,92,3,3.00,'','2025-10-10 21:25:39'),(1310,44,96,8,8.00,'','2025-10-10 21:25:39'),(1311,44,100,3,3.00,'','2025-10-10 21:25:39'),(1312,44,104,3,3.00,'','2025-10-10 21:25:39'),(1313,44,108,3,3.00,'','2025-10-10 21:25:39'),(1314,44,112,2,2.00,'','2025-10-10 21:25:39'),(1315,44,116,3,3.00,'','2025-10-10 21:25:39'),(1316,44,120,2,2.00,'','2025-10-10 21:25:39'),(1317,44,124,1,1.00,'','2025-10-10 21:25:39'),(1318,44,128,3,3.00,'','2025-10-10 21:25:39'),(1319,44,132,2,2.00,'','2025-10-10 21:25:39'),(1320,44,136,3,3.00,'','2025-10-10 21:25:39'),(1321,44,140,7,7.00,'','2025-10-10 21:25:39'),(1322,44,144,8,8.00,'','2025-10-10 21:25:39'),(1323,44,148,3,3.00,'','2025-10-10 21:25:39'),(1324,44,152,8,8.00,'','2025-10-10 21:25:39'),(1325,44,156,3,3.00,'','2025-10-10 21:25:39'),(1326,44,160,8,8.00,'','2025-10-10 21:25:39'),(1327,44,164,8,8.00,'','2025-10-10 21:25:39'),(1328,44,168,3,3.00,'','2025-10-10 21:25:39'),(1329,44,172,3,3.00,'','2025-10-10 21:25:39'),(1330,44,176,4,4.00,'','2025-10-10 21:25:39'),(1331,44,180,2,2.00,'','2025-10-10 21:25:39'),(1332,44,184,1,1.00,'','2025-10-10 21:25:39'),(1333,44,188,4,4.00,'','2025-10-10 21:25:39'),(1334,44,192,3,3.00,'','2025-10-10 21:25:39'),(1335,44,196,2,2.00,'','2025-10-10 21:25:39'),(1336,44,200,1,1.00,'','2025-10-10 21:25:39'),(1337,44,204,2,2.00,'','2025-10-10 21:25:39'),(1338,45,4,1,1.00,'','2025-10-10 21:42:58'),(1339,45,3,0,0.00,'','2025-10-10 21:50:08'),(1340,45,7,1,1.00,'','2025-10-10 21:50:08'),(1341,45,8,2,2.00,'','2025-10-10 21:50:08'),(1342,45,11,1,1.00,'','2025-10-10 21:50:08'),(1343,45,12,1,1.00,'','2025-10-10 21:50:08'),(1344,45,15,2,2.00,'','2025-10-10 21:50:08'),(1345,45,16,2,2.00,'','2025-10-10 21:50:08'),(1346,45,19,1,1.00,'','2025-10-10 21:50:08'),(1347,45,20,1,1.00,'','2025-10-10 21:50:08'),(1348,45,23,2,2.00,'','2025-10-10 21:50:08'),(1349,45,24,2,2.00,'','2025-10-10 21:50:08'),(1350,45,28,1,1.00,'','2025-10-10 21:50:08'),(1351,45,32,2,2.00,'','2025-10-10 21:50:08'),(1352,45,36,1,1.00,'','2025-10-10 21:50:08'),(1353,45,40,2,2.00,'','2025-10-10 21:50:08'),(1354,45,44,1,1.00,'','2025-10-10 21:50:08'),(1355,45,48,2,2.00,'','2025-10-10 21:50:08'),(1356,45,52,2,2.00,'','2025-10-10 21:50:08'),(1357,45,56,1,1.00,'','2025-10-10 21:50:08'),(1358,45,60,2,2.00,'','2025-10-10 21:50:08'),(1359,45,64,1,1.00,'','2025-10-10 21:50:08'),(1360,45,68,2,2.00,'','2025-10-10 21:50:08'),(1361,45,72,1,1.00,'','2025-10-10 21:50:08'),(1362,45,76,2,2.00,'','2025-10-10 21:50:08'),(1363,45,80,1,1.00,'','2025-10-10 21:50:08'),(1364,45,84,1,1.00,'','2025-10-10 21:50:08'),(1365,45,88,2,2.00,'','2025-10-10 21:50:08'),(1366,45,92,1,1.00,'','2025-10-10 21:50:08'),(1367,45,96,2,2.00,'','2025-10-10 21:50:08'),(1368,45,100,1,1.00,'','2025-10-10 21:50:08'),(1369,45,104,1,1.00,'','2025-10-10 21:50:08'),(1370,45,112,1,1.00,'','2025-10-10 21:50:08'),(1371,45,116,2,2.00,'','2025-10-10 21:50:08'),(1372,45,120,1,1.00,'','2025-10-10 21:50:08'),(1373,45,124,2,2.00,'','2025-10-10 21:50:08'),(1374,45,128,2,2.00,'','2025-10-10 21:50:08'),(1375,45,132,1,1.00,'','2025-10-10 21:50:08'),(1376,45,136,2,2.00,'','2025-10-10 21:50:08'),(1377,45,140,2,2.00,'','2025-10-10 21:50:08'),(1378,45,144,2,2.00,'','2025-10-10 21:50:08'),(1379,45,148,1,1.00,'','2025-10-10 21:50:08'),(1380,45,152,2,2.00,'','2025-10-10 21:50:08'),(1381,45,156,2,2.00,'','2025-10-10 21:50:08'),(1382,45,160,3,3.00,'','2025-10-10 21:50:08'),(1383,45,164,1,1.00,'','2025-10-10 21:50:08'),(1384,45,168,2,2.00,'','2025-10-10 21:50:08'),(1385,45,172,1,1.00,'','2025-10-10 21:50:08'),(1386,45,176,1,1.00,'','2025-10-10 21:50:08'),(1387,45,180,2,2.00,'','2025-10-10 21:50:08'),(1388,45,184,1,1.00,'','2025-10-10 21:50:08'),(1389,45,188,1,1.00,'','2025-10-10 21:50:08'),(1390,45,192,2,2.00,'','2025-10-10 21:50:08'),(1391,45,196,1,1.00,'','2025-10-10 21:50:08'),(1392,45,200,2,2.00,'','2025-10-10 21:50:08'),(1393,45,204,1,1.00,'','2025-10-10 21:50:08'),(1394,45,358,1,1.00,'','2025-10-10 21:50:08'),(1395,45,359,1,1.00,'','2025-10-10 21:50:08'),(1396,45,360,1,1.00,'','2025-10-10 21:50:08'),(1397,45,361,2,2.00,'','2025-10-10 21:50:08'),(1398,45,362,1,1.00,'','2025-10-10 21:50:08'),(1399,45,363,2,2.00,'','2025-10-10 21:50:08'),(1400,45,364,2,2.00,'','2025-10-10 21:50:08'),(1401,45,365,2,2.00,'','2025-10-10 21:50:08'),(1402,45,366,3,3.00,'','2025-10-10 21:50:08'),(1403,45,367,1,1.00,'','2025-10-10 21:50:08'),(1404,45,368,2,2.00,'','2025-10-10 21:50:08'),(1405,46,4,0,0.00,'','2025-10-10 22:36:03'),(1406,46,8,1,1.00,'','2025-10-10 22:36:03'),(1407,46,12,0,0.00,'','2025-10-10 22:36:03'),(1408,46,16,1,1.00,'','2025-10-10 22:36:03'),(1409,46,20,1,1.00,'','2025-10-10 22:36:03'),(1410,46,24,1,1.00,'','2025-10-10 22:36:04'),(1411,46,28,1,1.00,'','2025-10-10 22:36:04'),(1412,46,32,1,1.00,'','2025-10-10 22:36:04'),(1413,46,36,1,1.00,'','2025-10-10 22:36:04'),(1414,46,40,1,1.00,'','2025-10-10 22:36:04'),(1415,46,44,1,1.00,'','2025-10-10 22:36:04'),(1416,46,48,1,1.00,'','2025-10-10 22:36:04'),(1417,46,52,1,1.00,'','2025-10-10 22:36:04'),(1418,46,56,1,1.00,'','2025-10-10 22:36:04'),(1419,46,60,2,2.00,'','2025-10-10 22:36:04'),(1420,46,64,2,2.00,'','2025-10-10 22:36:04'),(1421,46,68,1,1.00,'','2025-10-10 22:36:04'),(1422,46,72,2,2.00,'','2025-10-10 22:36:04'),(1423,46,76,1,1.00,'','2025-10-10 22:36:04'),(1424,46,80,1,1.00,'','2025-10-10 22:36:04'),(1425,46,84,2,2.00,'','2025-10-10 22:36:04'),(1426,46,88,1,1.00,'','2025-10-10 22:36:04'),(1427,46,92,1,1.00,'','2025-10-10 22:36:04'),(1428,46,96,2,2.00,'','2025-10-10 22:36:04'),(1429,46,100,1,1.00,'','2025-10-10 22:36:04'),(1430,46,104,1,1.00,'','2025-10-10 22:36:04'),(1431,46,108,2,2.00,'','2025-10-10 22:36:04'),(1432,46,112,1,1.00,'','2025-10-10 22:36:04'),(1433,46,116,1,1.00,'','2025-10-10 22:36:04'),(1434,46,120,1,1.00,'','2025-10-10 22:36:04'),(1435,46,124,1,1.00,'','2025-10-10 22:36:04'),(1436,46,128,1,1.00,'','2025-10-10 22:36:04'),(1437,46,132,1,1.00,'','2025-10-10 22:36:04'),(1438,46,136,1,1.00,'','2025-10-10 22:36:04'),(1439,46,140,1,1.00,'','2025-10-10 22:36:04'),(1440,46,144,1,1.00,'','2025-10-10 22:36:04'),(1441,46,148,1,1.00,'','2025-10-10 22:36:04'),(1442,46,152,1,1.00,'','2025-10-10 22:36:04'),(1443,46,156,1,1.00,'','2025-10-10 22:36:04'),(1444,46,160,1,1.00,'','2025-10-10 22:36:04'),(1445,46,164,1,1.00,'','2025-10-10 22:36:04'),(1446,46,168,1,1.00,'','2025-10-10 22:36:04'),(1447,46,172,1,1.00,'','2025-10-10 22:36:04'),(1448,46,176,1,1.00,'','2025-10-10 22:36:04'),(1449,46,180,1,1.00,'','2025-10-10 22:36:04'),(1450,46,184,1,1.00,'','2025-10-10 22:36:04'),(1451,46,188,1,1.00,'','2025-10-10 22:36:04'),(1452,46,192,1,1.00,'','2025-10-10 22:36:04'),(1453,46,196,1,1.00,'','2025-10-10 22:36:04'),(1454,46,200,2,2.00,'','2025-10-10 22:36:04'),(1455,46,204,1,1.00,'','2025-10-10 22:36:04');
/*!40000 ALTER TABLE inspeccion_detalles ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspecciones`
--

/*!40000 ALTER TABLE inspecciones DISABLE KEYS */;
INSERT INTO inspecciones (id, establecimiento_id, inspector_id, encargado_id, fecha, hora_inicio, hora_fin, observaciones, puntaje_total, puntaje_maximo_posible, porcentaje_cumplimiento, puntos_criticos_perdidos, estado, firma_inspector, firma_encargado, fecha_firma_inspector, fecha_firma_encargado, created_at, updated_at) VALUES (16,1,1,2,'2025-09-01',NULL,'10:28:55','Mejorar la limpieza de pisos',208.00,220.00,94.55,5,'completada','/static/img/firmas/firma_inspector_16_1_20250901_102855_d27924f4.avif','/static/img/firmas/firma_encargado_16_2_20250901_102855_ac82360e.jpeg','2025-09-01 10:28:55','2025-09-01 10:28:55','2025-09-01 15:28:55','2025-09-01 15:28:55'),(17,1,1,2,'2025-09-12',NULL,'14:46:53','Todo está correcto',208.00,220.00,94.55,3,'completada','/static/img/firmas/firma_inspector_17_1_20250912_144653_6d75c00f.jpeg','/static/img/firmas/firma_encargado_17_2_20250912_144653_3e3fa9b1.avif','2025-09-12 14:46:53','2025-09-12 14:46:53','2025-09-12 19:46:53','2025-09-12 19:46:53'),(19,1,1,2,'2025-09-25',NULL,'10:51:18','Todo se encontró limpio',200.00,220.00,90.91,3,'completada','/static/img/firmas/firma_inspector_19_1_20250925_105118_cd5ed2d8.jpeg','/static/img/firmas/firma_encargado_19_2_20250925_105118_98d94faf.jpeg','2025-09-25 10:51:18','2025-09-25 10:51:18','2025-09-25 15:51:18','2025-09-25 15:51:19'),(20,1,1,2,'2025-09-25',NULL,'12:11:04','Todo está correcto',202.00,220.00,91.82,1,'completada','/static/img/firmas/firma_inspector_20_1_20250925_121103_e9861281.jpeg','/static/img/firmas/firma_encargado_20_2_20250925_121103_8c4a9334.jpeg','2025-09-25 12:11:04','2025-09-25 12:11:04','2025-09-25 17:11:04','2025-09-25 17:11:04'),(25,1,1,2,'2025-10-02',NULL,'12:46:39','Falta higiene ',199.00,220.00,90.45,5,'completada','/static/img/firmas/firma_inspector_1_20251002_115150.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-02 12:46:39','2025-10-02 12:46:39','2025-10-02 17:46:39','2025-10-02 17:46:39'),(30,2,1,3,'2025-10-03','18:28:30','16:15:56','',203.00,220.00,92.27,3,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-03 18:28:30','2025-10-10 16:15:56','2025-10-03 23:28:30','2025-10-10 21:15:56'),(31,2,1,3,'2025-10-10','15:03:40','16:17:18','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 15:03:40','2025-10-10 16:17:18','2025-10-10 20:03:40','2025-10-10 21:17:18'),(32,2,1,3,'2025-10-10','15:51:10','16:16:31','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 15:51:10','2025-10-10 16:16:31','2025-10-10 20:51:10','2025-10-10 21:16:31'),(42,2,1,3,'2025-10-10',NULL,'16:14:23','',199.00,220.00,90.45,2,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:14:23','2025-10-10 16:14:23','2025-10-10 21:14:23','2025-10-10 21:14:23'),(43,2,1,3,'2025-10-10',NULL,'16:21:38','Observados',203.00,220.00,92.27,3,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:21:38','2025-10-10 16:21:38','2025-10-10 21:21:38','2025-10-10 21:21:38'),(44,1,1,2,'2025-10-10',NULL,'16:25:39','',196.00,220.00,89.09,1,'completada','/static/img/firmas/firma_inspector_1_20251002_124757.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:25:39','2025-10-10 16:25:39','2025-10-10 21:25:39','2025-10-10 21:25:39'),(45,1,13,2,'2025-10-10','16:42:58','16:50:08','',101.00,270.00,37.41,68,'completada','/static/img/firmas/firma_inspector_13_20251007_094518.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 16:42:58','2025-10-10 16:42:58','2025-10-10 21:42:58','2025-10-10 21:50:08'),(46,1,13,2,'2025-10-10',NULL,'17:36:03','',56.00,220.00,25.45,75,'completada','/static/img/firmas/firma_inspector_13_20251010_172854.jpg','/static/img/firmas/Déjà_vu/firma_2_20251001_105453.jpg','2025-10-10 17:36:03','2025-10-10 17:36:03','2025-10-10 22:36:03','2025-10-10 22:36:04');
/*!40000 ALTER TABLE inspecciones ENABLE KEYS */;

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

/*!40000 ALTER TABLE inspector_establecimientos DISABLE KEYS */;
INSERT INTO inspector_establecimientos (id, inspector_id, establecimiento_id, fecha_asignacion, fecha_fin_asignacion, es_principal, activo, created_at) VALUES (1,1,1,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01'),(2,1,2,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01'),(3,1,3,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01'),(4,1,4,'2025-08-16',NULL,1,1,'2025-08-19 16:30:01'),(5,6,9,'2025-10-07',NULL,1,1,'2025-10-07 17:53:39');
/*!40000 ALTER TABLE inspector_establecimientos ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_base`
--

/*!40000 ALTER TABLE items_evaluacion_base DISABLE KEYS */;
INSERT INTO items_evaluacion_base (id, categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden, activo, created_at) VALUES (1,1,'1.1','Pisos y paredes sin suciedad visible ni humedad','Mayor',1,4,1,1,'2025-08-19 16:30:01'),(2,1,'1.2','Lavaderos libres de residuos','Menor',1,2,2,1,'2025-08-19 16:30:01'),(3,1,'1.3','Campana extractora limpia y operativa','Mayor',1,4,3,1,'2025-08-19 16:30:01'),(4,1,'1.4','Iluminación adecuada','Menor',1,2,4,1,'2025-08-19 16:30:01'),(5,1,'1.5','Gel antibacterial / Jabón líquido','Menor',1,2,5,1,'2025-08-19 16:30:01'),(6,1,'1.6','Personal de cocina con uniforme completo, limpio y buena higiene personal','Mayor',1,4,6,1,'2025-08-19 16:30:01'),(7,1,'1.7','Presencia de personas ajenas','Menor',1,2,7,1,'2025-08-19 16:30:01'),(8,1,'1.8','Insumos de limpieza alejados de alimentos y hornillas','Mayor',1,4,8,1,'2025-08-19 16:30:01'),(9,2,'2.1','Equipos completos, operativos y en buen estado','Mayor',1,4,1,1,'2025-08-19 16:30:01'),(10,2,'2.2','Limpieza y conservación de equipos','Mayor',1,4,2,1,'2025-08-19 16:30:01'),(11,2,'2.3','Constancia de mantenimiento de sus equipos cada 6 meses','Mayor',1,4,3,1,'2025-08-19 16:30:01'),(12,3,'3.1','Mise en place de carnes, pescados y mariscos','Crítico',1,8,1,1,'2025-08-19 16:30:01'),(13,3,'3.2','Mise en place de vegetales','Mayor',1,4,2,1,'2025-08-19 16:30:01'),(14,3,'3.3','Mise en place de complementos','Mayor',1,4,3,1,'2025-08-19 16:30:01'),(15,3,'3.4','Mise en place de salsas','Mayor',1,4,4,1,'2025-08-19 16:30:01'),(16,4,'4.1','Aspecto limpio del aceite','Mayor',1,4,1,1,'2025-08-19 16:30:01'),(17,4,'4.2','Separación de alimentos crudos y cocidos','Crítico',1,8,2,1,'2025-08-19 16:30:01'),(18,4,'4.3','Descongelación adecuada','Crítico',1,8,3,1,'2025-08-19 16:30:01'),(19,4,'4.4','Insumos en buen estado','Crítico',1,8,4,1,'2025-08-19 16:30:01'),(20,4,'4.5','Rotulado de productos','Crítico',1,8,5,1,'2025-08-19 16:30:01'),(21,4,'4.6','Verificación del agua potable (bidón y filtros de agua)','Mayor',1,4,6,1,'2025-08-19 16:30:01'),(22,5,'5.1','Basureros adecuados','Menor',1,2,1,1,'2025-08-19 16:30:01'),(23,5,'5.2','Eliminación diaria de basura en el lugar adecuado','Mayor',1,4,2,1,'2025-08-19 16:30:01'),(24,5,'5.3','Ausencia de insectos y cualquier animal','Crítico',1,8,3,1,'2025-08-19 16:30:01'),(25,5,'5.4','Bitácoras de limpieza y gestión de plagas','Mayor',1,4,4,1,'2025-08-19 16:30:01'),(26,6,'6.1','Buen estado de conservación','Mayor',1,4,1,1,'2025-08-19 16:30:01'),(27,6,'6.2','Vajillas y Utensilios limpios','Mayor',1,4,2,1,'2025-08-19 16:30:01'),(28,6,'6.3','Secado adecuado','Menor',1,2,3,1,'2025-08-19 16:30:01'),(29,6,'6.4','Tablas de picar separadas por color, en buen estado y limpias (se recomienda acero)','Mayor',1,4,4,1,'2025-08-19 16:30:01'),(30,7,'7.1','Pisos limpios','Menor',1,2,1,1,'2025-08-19 16:30:01'),(31,7,'7.2','Mesas y manteles limpios','Menor',1,2,2,1,'2025-08-19 16:30:01'),(32,7,'7.3','Personal con uniforme completo y limpio y buena higiene personal','Mayor',1,4,3,1,'2025-08-19 16:30:01'),(33,7,'7.4','Contar con implementos de atención','Menor',1,2,4,1,'2025-08-19 16:30:01'),(34,8,'8.1','Ordenado y limpio','Mayor',1,4,1,1,'2025-08-19 16:30:01'),(35,8,'8.2','Enlatados en buen estado y vigentes','Crítico',1,8,2,1,'2025-08-19 16:30:01'),(36,8,'8.3','Control de fechas de vencimiento de todos los productos','Crítico',1,8,3,1,'2025-08-19 16:30:01'),(37,8,'8.4','Ausencia de sustancias químicas','Mayor',1,4,4,1,'2025-08-19 16:30:01'),(38,9,'9.1','Extintores operativos y vigentes (plateado y rojo) con señalización, tarjeta de inspección y certificado','Crítico',1,8,1,1,'2025-08-19 16:30:01'),(39,9,'9.2','Botiquín de primeros auxilios completo con señalización','Mayor',1,4,2,1,'2025-08-19 16:30:01'),(40,9,'9.3','Balones de Gas: con seguridad y señalización','Crítico',1,8,3,1,'2025-08-19 16:30:01'),(41,9,'9.4','Sistema contra incendios operativo','Crítico',1,8,4,1,'2025-08-19 16:30:01'),(42,9,'9.5','Otras señalizaciones de salida, entrada, aforo, horario de atención, zona segura','Mayor',1,4,5,1,'2025-08-19 16:30:01'),(43,9,'9.6','Pisos antideslizantes en las cocinas y cintas en las escaleras y rampas','Mayor',1,4,6,1,'2025-08-19 16:30:01'),(44,9,'9.7','Luces de emergencia operativas con señalética y con certificado','Mayor',1,4,7,1,'2025-08-19 16:30:01'),(45,10,'10.1','POS operativo','Menor',1,2,1,1,'2025-08-19 16:30:01'),(46,10,'10.2','Caja chica disponible','Menor',1,2,2,1,'2025-08-19 16:30:01'),(47,10,'10.3','Facturas y boletas vigentes','Mayor',1,4,3,1,'2025-08-19 16:30:01'),(48,10,'10.4','Libro de reclamaciones','Mayor',1,4,4,1,'2025-08-19 16:30:01'),(49,10,'10.5','Cartas en buen estado','Menor',1,2,5,1,'2025-08-19 16:30:01'),(50,10,'10.6','Stock de bebidas','Menor',1,2,6,1,'2025-08-19 16:30:01'),(51,10,'10.7','Stock de envases y sachet','Menor',1,2,7,1,'2025-08-19 16:30:01'),(55,1,'1.9','Paredes con suciedad visible','Mayor',0,4,9,1,'2025-10-10 19:29:48'),(56,10,'10.8','Letreros en buen estado','Menor',0,2,8,1,'2025-10-10 22:06:59');
/*!40000 ALTER TABLE items_evaluacion_base ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=637 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_establecimiento`
--

/*!40000 ALTER TABLE items_evaluacion_establecimiento DISABLE KEYS */;
INSERT INTO items_evaluacion_establecimiento (id, establecimiento_id, item_base_id, descripcion_personalizada, factor_ajuste, activo, created_at) VALUES (1,4,1,NULL,1.00,1,'2025-08-19 16:30:01'),(2,3,1,NULL,1.00,1,'2025-08-19 16:30:01'),(3,2,1,NULL,1.00,1,'2025-08-19 16:30:01'),(4,1,1,NULL,1.00,1,'2025-08-19 16:30:01'),(5,4,2,NULL,1.00,1,'2025-08-19 16:30:01'),(6,3,2,NULL,1.00,1,'2025-08-19 16:30:01'),(7,2,2,NULL,1.00,1,'2025-08-19 16:30:01'),(8,1,2,NULL,1.00,1,'2025-08-19 16:30:01'),(9,4,3,NULL,1.00,1,'2025-08-19 16:30:01'),(10,3,3,NULL,1.00,1,'2025-08-19 16:30:01'),(11,2,3,NULL,1.00,1,'2025-08-19 16:30:01'),(12,1,3,NULL,1.00,1,'2025-08-19 16:30:01'),(13,4,4,NULL,1.00,1,'2025-08-19 16:30:01'),(14,3,4,NULL,1.00,1,'2025-08-19 16:30:01'),(15,2,4,NULL,1.00,1,'2025-08-19 16:30:01'),(16,1,4,NULL,1.00,1,'2025-08-19 16:30:01'),(17,4,5,NULL,1.00,1,'2025-08-19 16:30:01'),(18,3,5,NULL,1.00,1,'2025-08-19 16:30:01'),(19,2,5,NULL,1.00,1,'2025-08-19 16:30:01'),(20,1,5,NULL,1.00,1,'2025-08-19 16:30:01'),(21,4,6,NULL,1.00,1,'2025-08-19 16:30:01'),(22,3,6,NULL,1.00,1,'2025-08-19 16:30:01'),(23,2,6,NULL,1.00,1,'2025-08-19 16:30:01'),(24,1,6,NULL,1.00,1,'2025-08-19 16:30:01'),(25,4,7,NULL,1.00,1,'2025-08-19 16:30:01'),(26,3,7,NULL,1.00,1,'2025-08-19 16:30:01'),(27,2,7,NULL,1.00,1,'2025-08-19 16:30:01'),(28,1,7,NULL,1.00,1,'2025-08-19 16:30:01'),(29,4,8,NULL,1.00,1,'2025-08-19 16:30:01'),(30,3,8,NULL,1.00,1,'2025-08-19 16:30:01'),(31,2,8,NULL,1.00,1,'2025-08-19 16:30:01'),(32,1,8,NULL,1.00,1,'2025-08-19 16:30:01'),(33,4,9,NULL,1.00,1,'2025-08-19 16:30:01'),(34,3,9,NULL,1.00,1,'2025-08-19 16:30:01'),(35,2,9,NULL,1.00,1,'2025-08-19 16:30:01'),(36,1,9,NULL,1.00,1,'2025-08-19 16:30:01'),(37,4,10,NULL,1.00,1,'2025-08-19 16:30:01'),(38,3,10,NULL,1.00,1,'2025-08-19 16:30:01'),(39,2,10,NULL,1.00,1,'2025-08-19 16:30:01'),(40,1,10,NULL,1.00,1,'2025-08-19 16:30:01'),(41,4,11,NULL,1.00,1,'2025-08-19 16:30:01'),(42,3,11,NULL,1.00,1,'2025-08-19 16:30:01'),(43,2,11,NULL,1.00,1,'2025-08-19 16:30:01'),(44,1,11,NULL,1.00,1,'2025-08-19 16:30:01'),(45,4,12,NULL,1.00,1,'2025-08-19 16:30:01'),(46,3,12,NULL,1.00,1,'2025-08-19 16:30:01'),(47,2,12,NULL,1.00,1,'2025-08-19 16:30:01'),(48,1,12,NULL,1.00,1,'2025-08-19 16:30:01'),(49,4,13,NULL,1.00,1,'2025-08-19 16:30:01'),(50,3,13,NULL,1.00,1,'2025-08-19 16:30:01'),(51,2,13,NULL,1.00,1,'2025-08-19 16:30:01'),(52,1,13,NULL,1.00,1,'2025-08-19 16:30:01'),(53,4,14,NULL,1.00,1,'2025-08-19 16:30:01'),(54,3,14,NULL,1.00,1,'2025-08-19 16:30:01'),(55,2,14,NULL,1.00,1,'2025-08-19 16:30:01'),(56,1,14,NULL,1.00,1,'2025-08-19 16:30:01'),(57,4,15,NULL,1.00,1,'2025-08-19 16:30:01'),(58,3,15,NULL,1.00,1,'2025-08-19 16:30:01'),(59,2,15,NULL,1.00,1,'2025-08-19 16:30:01'),(60,1,15,NULL,1.00,1,'2025-08-19 16:30:01'),(61,4,16,NULL,1.00,1,'2025-08-19 16:30:01'),(62,3,16,NULL,1.00,1,'2025-08-19 16:30:01'),(63,2,16,NULL,1.00,1,'2025-08-19 16:30:01'),(64,1,16,NULL,1.00,1,'2025-08-19 16:30:01'),(65,4,17,NULL,1.00,1,'2025-08-19 16:30:01'),(66,3,17,NULL,1.00,1,'2025-08-19 16:30:01'),(67,2,17,NULL,1.00,1,'2025-08-19 16:30:01'),(68,1,17,NULL,1.00,1,'2025-08-19 16:30:01'),(69,4,18,NULL,1.00,1,'2025-08-19 16:30:01'),(70,3,18,NULL,1.00,1,'2025-08-19 16:30:01'),(71,2,18,NULL,1.00,1,'2025-08-19 16:30:01'),(72,1,18,NULL,1.00,1,'2025-08-19 16:30:01'),(73,4,19,NULL,1.00,1,'2025-08-19 16:30:01'),(74,3,19,NULL,1.00,1,'2025-08-19 16:30:01'),(75,2,19,NULL,1.00,1,'2025-08-19 16:30:01'),(76,1,19,NULL,1.00,1,'2025-08-19 16:30:01'),(77,4,20,NULL,1.00,1,'2025-08-19 16:30:01'),(78,3,20,NULL,1.00,1,'2025-08-19 16:30:01'),(79,2,20,NULL,1.00,1,'2025-08-19 16:30:01'),(80,1,20,NULL,1.00,1,'2025-08-19 16:30:01'),(81,4,21,NULL,1.00,1,'2025-08-19 16:30:01'),(82,3,21,NULL,1.00,1,'2025-08-19 16:30:01'),(83,2,21,NULL,1.00,1,'2025-08-19 16:30:01'),(84,1,21,NULL,1.00,1,'2025-08-19 16:30:01'),(85,4,22,NULL,1.00,1,'2025-08-19 16:30:01'),(86,3,22,NULL,1.00,1,'2025-08-19 16:30:01'),(87,2,22,NULL,1.00,1,'2025-08-19 16:30:01'),(88,1,22,NULL,1.00,1,'2025-08-19 16:30:01'),(89,4,23,NULL,1.00,1,'2025-08-19 16:30:01'),(90,3,23,NULL,1.00,1,'2025-08-19 16:30:01'),(91,2,23,NULL,1.00,1,'2025-08-19 16:30:01'),(92,1,23,NULL,1.00,1,'2025-08-19 16:30:01'),(93,4,24,NULL,1.00,1,'2025-08-19 16:30:01'),(94,3,24,NULL,1.00,1,'2025-08-19 16:30:01'),(95,2,24,NULL,1.00,1,'2025-08-19 16:30:01'),(96,1,24,NULL,1.00,1,'2025-08-19 16:30:01'),(97,4,25,NULL,1.00,1,'2025-08-19 16:30:01'),(98,3,25,NULL,1.00,1,'2025-08-19 16:30:01'),(99,2,25,NULL,1.00,1,'2025-08-19 16:30:01'),(100,1,25,NULL,1.00,1,'2025-08-19 16:30:01'),(101,4,26,NULL,1.00,1,'2025-08-19 16:30:01'),(102,3,26,NULL,1.00,1,'2025-08-19 16:30:01'),(103,2,26,NULL,1.00,1,'2025-08-19 16:30:01'),(104,1,26,NULL,1.00,1,'2025-08-19 16:30:01'),(105,4,27,NULL,1.00,1,'2025-08-19 16:30:01'),(106,3,27,NULL,1.00,1,'2025-08-19 16:30:01'),(107,2,27,NULL,1.00,1,'2025-08-19 16:30:01'),(108,1,27,NULL,1.00,1,'2025-08-19 16:30:01'),(109,4,28,NULL,1.00,1,'2025-08-19 16:30:01'),(110,3,28,NULL,1.00,1,'2025-08-19 16:30:01'),(111,2,28,NULL,1.00,1,'2025-08-19 16:30:01'),(112,1,28,NULL,1.00,1,'2025-08-19 16:30:01'),(113,4,29,NULL,1.00,1,'2025-08-19 16:30:01'),(114,3,29,NULL,1.00,1,'2025-08-19 16:30:01'),(115,2,29,NULL,1.00,1,'2025-08-19 16:30:01'),(116,1,29,NULL,1.00,1,'2025-08-19 16:30:01'),(117,4,30,NULL,1.00,1,'2025-08-19 16:30:01'),(118,3,30,NULL,1.00,1,'2025-08-19 16:30:01'),(119,2,30,NULL,1.00,1,'2025-08-19 16:30:01'),(120,1,30,NULL,1.00,1,'2025-08-19 16:30:01'),(121,4,31,NULL,1.00,1,'2025-08-19 16:30:01'),(122,3,31,NULL,1.00,1,'2025-08-19 16:30:01'),(123,2,31,NULL,1.00,1,'2025-08-19 16:30:01'),(124,1,31,NULL,1.00,1,'2025-08-19 16:30:01'),(125,4,32,NULL,1.00,1,'2025-08-19 16:30:01'),(126,3,32,NULL,1.00,1,'2025-08-19 16:30:01'),(127,2,32,NULL,1.00,1,'2025-08-19 16:30:01'),(128,1,32,NULL,1.00,1,'2025-08-19 16:30:01'),(129,4,33,NULL,1.00,1,'2025-08-19 16:30:01'),(130,3,33,NULL,1.00,1,'2025-08-19 16:30:01'),(131,2,33,NULL,1.00,1,'2025-08-19 16:30:01'),(132,1,33,NULL,1.00,1,'2025-08-19 16:30:01'),(133,4,34,NULL,1.00,1,'2025-08-19 16:30:01'),(134,3,34,NULL,1.00,1,'2025-08-19 16:30:01'),(135,2,34,NULL,1.00,1,'2025-08-19 16:30:01'),(136,1,34,NULL,1.00,1,'2025-08-19 16:30:01'),(137,4,35,NULL,1.00,1,'2025-08-19 16:30:01'),(138,3,35,NULL,1.00,1,'2025-08-19 16:30:01'),(139,2,35,NULL,1.00,1,'2025-08-19 16:30:01'),(140,1,35,NULL,1.00,1,'2025-08-19 16:30:01'),(141,4,36,NULL,1.00,1,'2025-08-19 16:30:01'),(142,3,36,NULL,1.00,1,'2025-08-19 16:30:01'),(143,2,36,NULL,1.00,1,'2025-08-19 16:30:01'),(144,1,36,NULL,1.00,1,'2025-08-19 16:30:01'),(145,4,37,NULL,1.00,1,'2025-08-19 16:30:01'),(146,3,37,NULL,1.00,1,'2025-08-19 16:30:01'),(147,2,37,NULL,1.00,1,'2025-08-19 16:30:01'),(148,1,37,NULL,1.00,1,'2025-08-19 16:30:01'),(149,4,38,NULL,1.00,1,'2025-08-19 16:30:01'),(150,3,38,NULL,1.00,1,'2025-08-19 16:30:01'),(151,2,38,NULL,1.00,1,'2025-08-19 16:30:01'),(152,1,38,NULL,1.00,1,'2025-08-19 16:30:01'),(153,4,39,NULL,1.00,1,'2025-08-19 16:30:01'),(154,3,39,NULL,1.00,1,'2025-08-19 16:30:01'),(155,2,39,NULL,1.00,1,'2025-08-19 16:30:01'),(156,1,39,NULL,1.00,1,'2025-08-19 16:30:01'),(157,4,40,NULL,1.00,1,'2025-08-19 16:30:01'),(158,3,40,NULL,1.00,1,'2025-08-19 16:30:01'),(159,2,40,NULL,1.00,1,'2025-08-19 16:30:01'),(160,1,40,NULL,1.00,1,'2025-08-19 16:30:01'),(161,4,41,NULL,1.00,1,'2025-08-19 16:30:01'),(162,3,41,NULL,1.00,1,'2025-08-19 16:30:01'),(163,2,41,NULL,1.00,1,'2025-08-19 16:30:01'),(164,1,41,NULL,1.00,1,'2025-08-19 16:30:01'),(165,4,42,NULL,1.00,1,'2025-08-19 16:30:01'),(166,3,42,NULL,1.00,1,'2025-08-19 16:30:01'),(167,2,42,NULL,1.00,1,'2025-08-19 16:30:01'),(168,1,42,NULL,1.00,1,'2025-08-19 16:30:01'),(169,4,43,NULL,1.00,1,'2025-08-19 16:30:01'),(170,3,43,NULL,1.00,1,'2025-08-19 16:30:01'),(171,2,43,NULL,1.00,1,'2025-08-19 16:30:01'),(172,1,43,NULL,1.00,1,'2025-08-19 16:30:01'),(173,4,44,NULL,1.00,1,'2025-08-19 16:30:01'),(174,3,44,NULL,1.00,1,'2025-08-19 16:30:01'),(175,2,44,NULL,1.00,1,'2025-08-19 16:30:01'),(176,1,44,NULL,1.00,1,'2025-08-19 16:30:01'),(177,4,45,NULL,1.00,1,'2025-08-19 16:30:01'),(178,3,45,NULL,1.00,1,'2025-08-19 16:30:01'),(179,2,45,NULL,1.00,1,'2025-08-19 16:30:01'),(180,1,45,NULL,1.00,1,'2025-08-19 16:30:01'),(181,4,46,NULL,1.00,1,'2025-08-19 16:30:01'),(182,3,46,NULL,1.00,1,'2025-08-19 16:30:01'),(183,2,46,NULL,1.00,1,'2025-08-19 16:30:01'),(184,1,46,NULL,1.00,1,'2025-08-19 16:30:01'),(185,4,47,NULL,1.00,1,'2025-08-19 16:30:01'),(186,3,47,NULL,1.00,1,'2025-08-19 16:30:01'),(187,2,47,NULL,1.00,1,'2025-08-19 16:30:01'),(188,1,47,NULL,1.00,1,'2025-08-19 16:30:01'),(189,4,48,NULL,1.00,1,'2025-08-19 16:30:01'),(190,3,48,NULL,1.00,1,'2025-08-19 16:30:01'),(191,2,48,NULL,1.00,1,'2025-08-19 16:30:01'),(192,1,48,NULL,1.00,1,'2025-08-19 16:30:01'),(193,4,49,NULL,1.00,1,'2025-08-19 16:30:01'),(194,3,49,NULL,1.00,1,'2025-08-19 16:30:01'),(195,2,49,NULL,1.00,1,'2025-08-19 16:30:01'),(196,1,49,NULL,1.00,1,'2025-08-19 16:30:01'),(197,4,50,NULL,1.00,1,'2025-08-19 16:30:01'),(198,3,50,NULL,1.00,1,'2025-08-19 16:30:01'),(199,2,50,NULL,1.00,1,'2025-08-19 16:30:01'),(200,1,50,NULL,1.00,1,'2025-08-19 16:30:01'),(201,4,51,NULL,1.00,1,'2025-08-19 16:30:01'),(202,3,51,NULL,1.00,1,'2025-08-19 16:30:01'),(203,2,51,NULL,1.00,1,'2025-08-19 16:30:01'),(204,1,51,NULL,1.00,1,'2025-08-19 16:30:01'),(307,6,1,NULL,1.00,1,'2025-09-16 22:22:19'),(308,6,2,NULL,1.00,1,'2025-09-16 22:22:19'),(309,6,3,NULL,1.00,1,'2025-09-16 22:22:19'),(310,6,4,NULL,1.00,1,'2025-09-16 22:22:19'),(311,6,5,NULL,1.00,1,'2025-09-16 22:22:19'),(312,6,6,NULL,1.00,1,'2025-09-16 22:22:19'),(313,6,7,NULL,1.00,1,'2025-09-16 22:22:19'),(314,6,8,NULL,1.00,1,'2025-09-16 22:22:19'),(315,6,9,NULL,1.00,1,'2025-09-16 22:22:19'),(316,6,10,NULL,1.00,1,'2025-09-16 22:22:19'),(317,6,11,NULL,1.00,1,'2025-09-16 22:22:19'),(318,6,12,NULL,1.00,1,'2025-09-16 22:22:19'),(319,6,13,NULL,1.00,1,'2025-09-16 22:22:19'),(320,6,14,NULL,1.00,1,'2025-09-16 22:22:19'),(321,6,15,NULL,1.00,1,'2025-09-16 22:22:19'),(322,6,16,NULL,1.00,1,'2025-09-16 22:22:19'),(323,6,17,NULL,1.00,1,'2025-09-16 22:22:19'),(324,6,18,NULL,1.00,1,'2025-09-16 22:22:19'),(325,6,19,NULL,1.00,1,'2025-09-16 22:22:19'),(326,6,20,NULL,1.00,1,'2025-09-16 22:22:19'),(327,6,21,NULL,1.00,1,'2025-09-16 22:22:19'),(328,6,22,NULL,1.00,1,'2025-09-16 22:22:19'),(329,6,23,NULL,1.00,1,'2025-09-16 22:22:19'),(330,6,24,NULL,1.00,1,'2025-09-16 22:22:19'),(331,6,25,NULL,1.00,1,'2025-09-16 22:22:19'),(332,6,26,NULL,1.00,1,'2025-09-16 22:22:19'),(333,6,27,NULL,1.00,1,'2025-09-16 22:22:19'),(334,6,28,NULL,1.00,1,'2025-09-16 22:22:19'),(335,6,29,NULL,1.00,1,'2025-09-16 22:22:19'),(336,6,30,NULL,1.00,1,'2025-09-16 22:22:19'),(337,6,31,NULL,1.00,1,'2025-09-16 22:22:19'),(338,6,32,NULL,1.00,1,'2025-09-16 22:22:19'),(339,6,33,NULL,1.00,1,'2025-09-16 22:22:19'),(340,6,34,NULL,1.00,1,'2025-09-16 22:22:19'),(341,6,35,NULL,1.00,1,'2025-09-16 22:22:19'),(342,6,36,NULL,1.00,1,'2025-09-16 22:22:19'),(343,6,37,NULL,1.00,1,'2025-09-16 22:22:19'),(344,6,38,NULL,1.00,1,'2025-09-16 22:22:19'),(345,6,39,NULL,1.00,1,'2025-09-16 22:22:19'),(346,6,40,NULL,1.00,1,'2025-09-16 22:22:19'),(347,6,41,NULL,1.00,1,'2025-09-16 22:22:19'),(348,6,42,NULL,1.00,1,'2025-09-16 22:22:19'),(349,6,43,NULL,1.00,1,'2025-09-16 22:22:19'),(350,6,44,NULL,1.00,1,'2025-09-16 22:22:19'),(351,6,45,NULL,1.00,1,'2025-09-16 22:22:19'),(352,6,46,NULL,1.00,1,'2025-09-16 22:22:19'),(353,6,47,NULL,1.00,1,'2025-09-16 22:22:19'),(354,6,48,NULL,1.00,1,'2025-09-16 22:22:19'),(355,6,49,NULL,1.00,1,'2025-09-16 22:22:19'),(356,6,50,NULL,1.00,1,'2025-09-16 22:22:19'),(357,6,51,NULL,1.00,1,'2025-09-16 22:22:19'),(358,7,1,NULL,1.00,1,'2025-10-02 22:55:34'),(359,7,2,NULL,1.00,1,'2025-10-02 22:55:34'),(360,7,3,NULL,1.00,1,'2025-10-02 22:55:34'),(361,7,4,NULL,1.00,1,'2025-10-02 22:55:34'),(362,7,5,NULL,1.00,1,'2025-10-02 22:55:34'),(363,7,6,NULL,1.00,1,'2025-10-02 22:55:34'),(364,7,7,NULL,1.00,1,'2025-10-02 22:55:34'),(365,7,8,NULL,1.00,1,'2025-10-02 22:55:34'),(366,7,9,NULL,1.00,1,'2025-10-02 22:55:34'),(367,7,10,NULL,1.00,1,'2025-10-02 22:55:34'),(368,7,11,NULL,1.00,1,'2025-10-02 22:55:34'),(369,7,12,NULL,1.00,1,'2025-10-02 22:55:34'),(370,7,13,NULL,1.00,1,'2025-10-02 22:55:34'),(371,7,14,NULL,1.00,1,'2025-10-02 22:55:34'),(372,7,15,NULL,1.00,1,'2025-10-02 22:55:34'),(373,7,16,NULL,1.00,1,'2025-10-02 22:55:34'),(374,7,17,NULL,1.00,1,'2025-10-02 22:55:34'),(375,7,18,NULL,1.00,1,'2025-10-02 22:55:34'),(376,7,19,NULL,1.00,1,'2025-10-02 22:55:34'),(377,7,20,NULL,1.00,1,'2025-10-02 22:55:34'),(378,7,21,NULL,1.00,1,'2025-10-02 22:55:34'),(379,7,22,NULL,1.00,1,'2025-10-02 22:55:34'),(380,7,23,NULL,1.00,1,'2025-10-02 22:55:34'),(381,7,24,NULL,1.00,1,'2025-10-02 22:55:34'),(382,7,25,NULL,1.00,1,'2025-10-02 22:55:34'),(383,7,26,NULL,1.00,1,'2025-10-02 22:55:34'),(384,7,27,NULL,1.00,1,'2025-10-02 22:55:34'),(385,7,28,NULL,1.00,1,'2025-10-02 22:55:34'),(386,7,29,NULL,1.00,1,'2025-10-02 22:55:34'),(387,7,30,NULL,1.00,1,'2025-10-02 22:55:34'),(388,7,31,NULL,1.00,1,'2025-10-02 22:55:34'),(389,7,32,NULL,1.00,1,'2025-10-02 22:55:34'),(390,7,33,NULL,1.00,1,'2025-10-02 22:55:34'),(391,7,34,NULL,1.00,1,'2025-10-02 22:55:34'),(392,7,35,NULL,1.00,1,'2025-10-02 22:55:34'),(393,7,36,NULL,1.00,1,'2025-10-02 22:55:34'),(394,7,37,NULL,1.00,1,'2025-10-02 22:55:34'),(395,7,38,NULL,1.00,1,'2025-10-02 22:55:34'),(396,7,39,NULL,1.00,1,'2025-10-02 22:55:34'),(397,7,40,NULL,1.00,1,'2025-10-02 22:55:34'),(398,7,41,NULL,1.00,1,'2025-10-02 22:55:34'),(399,7,42,NULL,1.00,1,'2025-10-02 22:55:34'),(400,7,43,NULL,1.00,1,'2025-10-02 22:55:34'),(401,7,44,NULL,1.00,1,'2025-10-02 22:55:34'),(402,7,45,NULL,1.00,1,'2025-10-02 22:55:34'),(403,7,46,NULL,1.00,1,'2025-10-02 22:55:34'),(404,7,47,NULL,1.00,1,'2025-10-02 22:55:34'),(405,7,48,NULL,1.00,1,'2025-10-02 22:55:34'),(406,7,49,NULL,1.00,1,'2025-10-02 22:55:34'),(407,7,50,NULL,1.00,1,'2025-10-02 22:55:34'),(408,7,51,NULL,1.00,1,'2025-10-02 22:55:34'),(460,9,1,NULL,1.00,1,'2025-10-07 17:53:39'),(461,9,2,NULL,1.00,1,'2025-10-07 17:53:39'),(462,9,3,NULL,1.00,1,'2025-10-07 17:53:39'),(463,9,4,NULL,1.00,1,'2025-10-07 17:53:39'),(464,9,5,NULL,1.00,1,'2025-10-07 17:53:39'),(465,9,6,NULL,1.00,1,'2025-10-07 17:53:39'),(466,9,7,NULL,1.00,1,'2025-10-07 17:53:39'),(467,9,8,NULL,1.00,1,'2025-10-07 17:53:39'),(468,9,9,NULL,1.00,1,'2025-10-07 17:53:39'),(469,9,10,NULL,1.00,1,'2025-10-07 17:53:39'),(470,9,11,NULL,1.00,1,'2025-10-07 17:53:39'),(471,9,12,NULL,1.00,1,'2025-10-07 17:53:39'),(472,9,13,NULL,1.00,1,'2025-10-07 17:53:39'),(473,9,14,NULL,1.00,1,'2025-10-07 17:53:39'),(474,9,15,NULL,1.00,1,'2025-10-07 17:53:39'),(475,9,30,NULL,1.00,0,'2025-10-07 17:53:39'),(476,10,1,NULL,1.00,1,'2025-10-07 21:15:18'),(478,10,2,NULL,1.00,1,'2025-10-07 21:16:02'),(481,10,3,NULL,1.00,1,'2025-10-07 21:16:55'),(482,10,20,NULL,1.00,1,'2025-10-07 21:17:16'),(488,10,4,NULL,1.00,1,'2025-10-07 21:23:38'),(489,10,32,NULL,1.00,1,'2025-10-07 21:24:01'),(490,10,5,NULL,1.00,1,'2025-10-07 21:38:39'),(491,10,6,NULL,1.00,1,'2025-10-07 21:38:39'),(492,10,7,NULL,1.00,1,'2025-10-07 21:38:39'),(493,10,8,NULL,1.00,1,'2025-10-07 21:38:39'),(494,10,9,NULL,1.00,1,'2025-10-07 21:38:39'),(495,10,10,NULL,1.00,1,'2025-10-07 21:38:39'),(496,10,11,NULL,1.00,1,'2025-10-07 21:38:39'),(497,10,12,NULL,1.00,1,'2025-10-07 21:38:39'),(498,10,13,NULL,1.00,1,'2025-10-07 21:38:39'),(499,10,14,NULL,1.00,1,'2025-10-07 21:38:39'),(500,10,15,NULL,1.00,1,'2025-10-07 21:38:39'),(501,10,16,NULL,1.00,1,'2025-10-07 21:38:39'),(502,10,17,NULL,1.00,1,'2025-10-07 21:38:39'),(503,10,18,NULL,1.00,1,'2025-10-07 21:38:39'),(504,10,19,NULL,1.00,1,'2025-10-07 21:38:39'),(505,10,21,NULL,1.00,1,'2025-10-07 21:38:39'),(506,10,22,NULL,1.00,1,'2025-10-07 21:38:39'),(507,10,23,NULL,1.00,1,'2025-10-07 21:38:39'),(508,10,24,NULL,1.00,1,'2025-10-07 21:38:39'),(509,10,25,NULL,1.00,1,'2025-10-07 21:38:39'),(510,10,26,NULL,1.00,1,'2025-10-07 21:38:39'),(511,10,27,NULL,1.00,1,'2025-10-07 21:38:39'),(512,10,28,NULL,1.00,1,'2025-10-07 21:38:39'),(513,10,29,NULL,1.00,1,'2025-10-07 21:38:39'),(514,10,30,NULL,1.00,1,'2025-10-07 21:38:39'),(515,10,31,NULL,1.00,1,'2025-10-07 21:38:39'),(516,10,33,NULL,1.00,1,'2025-10-07 21:38:39'),(517,10,34,NULL,1.00,1,'2025-10-07 21:38:39'),(518,10,35,NULL,1.00,1,'2025-10-07 21:38:39'),(519,10,36,NULL,1.00,1,'2025-10-07 21:38:39'),(520,10,37,NULL,1.00,1,'2025-10-07 21:38:39'),(521,10,38,NULL,1.00,1,'2025-10-07 21:38:39'),(522,10,39,NULL,1.00,1,'2025-10-07 21:38:39'),(523,10,40,NULL,1.00,1,'2025-10-07 21:38:39'),(524,10,41,NULL,1.00,1,'2025-10-07 21:38:39'),(525,10,42,NULL,1.00,1,'2025-10-07 21:38:39'),(526,10,43,NULL,1.00,1,'2025-10-07 21:38:39'),(527,10,44,NULL,1.00,1,'2025-10-07 21:38:39'),(528,10,45,NULL,1.00,1,'2025-10-07 21:38:39'),(529,10,46,NULL,1.00,1,'2025-10-07 21:38:39'),(530,10,47,NULL,1.00,1,'2025-10-07 21:38:39'),(531,10,48,NULL,1.00,1,'2025-10-07 21:38:39'),(532,10,49,NULL,1.00,1,'2025-10-07 21:38:39'),(533,10,50,NULL,1.00,1,'2025-10-07 21:38:39'),(534,10,51,NULL,1.00,1,'2025-10-07 21:38:39');
/*!40000 ALTER TABLE items_evaluacion_establecimiento ENABLE KEYS */;

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
  descripcion_personalizada text COLLATE utf8mb4_unicode_ci,
  factor_ajuste decimal(3,2) DEFAULT '1.00',
  obligatorio tinyint(1) DEFAULT '1',
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  riesgo_personalizado varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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

/*!40000 ALTER TABLE items_plantilla_checklist DISABLE KEYS */;
INSERT INTO items_plantilla_checklist (id, plantilla_id, item_base_id, descripcion_personalizada, factor_ajuste, obligatorio, orden, activo, created_at, riesgo_personalizado, puntaje_minimo_personalizado, puntaje_maximo_personalizado) VALUES (1,1,1,NULL,1.00,1,0,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(2,1,2,NULL,1.00,1,1,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(3,1,3,NULL,1.00,1,2,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(4,1,4,NULL,1.00,1,3,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(5,1,5,NULL,1.00,1,4,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(6,1,6,NULL,1.00,1,5,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(7,1,7,NULL,1.00,1,6,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(8,1,8,NULL,1.00,1,7,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(9,1,9,NULL,1.00,1,8,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(10,1,10,NULL,1.00,1,9,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(11,1,11,NULL,1.00,1,10,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(12,1,12,NULL,1.00,1,11,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(13,1,13,NULL,1.00,1,12,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(14,1,14,NULL,1.00,1,13,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(15,1,15,NULL,1.00,1,14,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(16,2,1,NULL,1.00,1,0,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(17,2,2,NULL,1.00,1,1,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(18,2,3,NULL,1.00,1,2,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(19,2,4,NULL,1.00,1,3,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(20,2,5,NULL,1.00,1,4,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(21,2,6,NULL,1.00,1,5,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(22,2,7,NULL,1.00,1,6,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(23,2,8,NULL,1.00,1,7,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(24,2,9,NULL,1.00,1,8,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(25,2,10,NULL,1.00,1,9,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(26,2,11,NULL,1.00,1,10,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(27,2,12,NULL,1.00,1,11,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(28,2,13,NULL,1.00,1,12,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(29,2,14,NULL,1.00,1,13,1,'2025-10-07 09:59:45',NULL,NULL,NULL),(30,2,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(31,2,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(32,2,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(33,2,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(34,2,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(35,2,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(36,2,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(37,2,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(38,2,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(39,2,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(40,2,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(41,3,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(42,3,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(43,3,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(44,3,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(45,3,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(46,3,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(47,3,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(48,3,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(49,3,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(50,3,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(51,3,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(52,3,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(53,3,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(54,3,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(55,3,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(56,3,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(57,3,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(58,3,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(59,3,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(60,3,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(61,3,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(62,3,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(63,3,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(64,3,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(65,3,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(66,3,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(67,3,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(68,3,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(69,3,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(70,3,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(71,3,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(72,3,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(73,3,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(74,3,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(75,3,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(76,3,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(77,3,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(78,3,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(79,3,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(80,3,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(81,3,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(82,3,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(83,3,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(84,3,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(85,3,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(86,3,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(87,3,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(88,3,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(89,3,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(90,3,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(91,3,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(92,4,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(93,4,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(94,4,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(95,4,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(96,4,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(97,4,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(98,4,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(99,4,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(100,4,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(101,4,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(102,4,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(103,4,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(104,4,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(105,4,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(106,4,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(107,4,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(108,4,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(109,4,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(110,4,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(111,4,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(112,4,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(113,4,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(114,4,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(115,4,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(116,4,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(117,5,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(118,5,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(119,5,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(120,5,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(121,5,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(122,5,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(123,5,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(124,5,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(125,5,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(126,5,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(127,5,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(128,5,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(129,5,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(130,5,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(131,5,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(132,5,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(133,5,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(134,5,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(135,5,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(136,5,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(137,5,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(138,5,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(139,5,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(140,5,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(141,5,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(142,5,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(143,5,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(144,5,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(145,5,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(146,5,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(147,5,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(148,5,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(149,5,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(150,5,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(151,5,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(152,5,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(153,5,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(154,5,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(155,5,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(156,5,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(157,5,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(158,5,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(159,5,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(160,5,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(161,5,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(162,5,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(163,5,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(164,5,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(165,5,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(166,5,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(167,5,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(168,6,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(169,6,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(170,6,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(171,6,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(172,6,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(173,6,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(174,6,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(175,6,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(176,6,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(177,6,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(178,6,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(179,6,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(180,6,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(181,6,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(182,6,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(183,6,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(184,6,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(185,6,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(186,6,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(187,6,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(188,6,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(189,6,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(190,6,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(191,6,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(192,6,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(193,7,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(194,7,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(195,7,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(196,7,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(197,7,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(198,7,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(199,7,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(200,7,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(201,7,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(202,7,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(203,7,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(204,7,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(205,7,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(206,7,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(207,7,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(208,8,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(209,8,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(210,8,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(211,8,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(212,8,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(213,8,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(214,8,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(215,8,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(216,8,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(217,8,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(218,8,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(219,8,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(220,8,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(221,8,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(222,8,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(223,8,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(224,8,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(225,8,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(226,8,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(227,8,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(228,8,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(229,8,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(230,8,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(231,8,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(232,8,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(233,9,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(234,9,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(235,9,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(236,9,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(237,9,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(238,9,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(239,9,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(240,9,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(241,9,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(242,9,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(243,9,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(244,9,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(245,9,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(246,9,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(247,9,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(248,9,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(249,9,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(250,9,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(251,9,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(252,9,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(253,9,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(254,9,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(255,9,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(256,9,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(257,9,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(258,9,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(259,9,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(260,9,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(261,9,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(262,9,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(263,9,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(264,9,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(265,9,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(266,9,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(267,9,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(268,9,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(269,9,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(270,9,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(271,9,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(272,9,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(273,9,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(274,9,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(275,9,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(276,9,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(277,9,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(278,9,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(279,9,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(280,9,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(281,9,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(282,9,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(283,9,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(284,10,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(285,10,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(286,10,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(287,10,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(288,10,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(289,10,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(290,10,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(291,10,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(292,10,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(293,10,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(294,10,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(295,10,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(296,10,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(297,10,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(298,10,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(299,10,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(300,10,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(301,10,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(302,10,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(303,10,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(304,10,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(305,10,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(306,10,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(307,10,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(308,10,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(309,11,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(310,11,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(311,11,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(312,11,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(313,11,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(314,11,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(315,11,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(316,11,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(317,11,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(318,11,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(319,11,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(320,11,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(321,11,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(322,11,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(323,11,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(324,11,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(325,11,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(326,11,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(327,11,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(328,11,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(329,11,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(330,11,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(331,11,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(332,11,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(333,11,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(334,11,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(335,11,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(336,11,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(337,11,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(338,11,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(339,11,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(340,11,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(341,11,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(342,11,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(343,11,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(344,11,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(345,11,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(346,11,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(347,11,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(348,11,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(349,11,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(350,11,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(351,11,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(352,11,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(353,11,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(354,11,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(355,11,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(356,11,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(357,11,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(358,11,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(359,11,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(360,12,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(361,12,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(362,12,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(363,12,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(364,12,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(365,12,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(366,12,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(367,12,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(368,12,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(369,12,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(370,12,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(371,12,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(372,12,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(373,12,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(374,12,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(375,12,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(376,12,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(377,12,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(378,12,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(379,12,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(380,12,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(381,12,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(382,12,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(383,12,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(384,12,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(385,13,1,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(386,13,2,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(387,13,3,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(388,13,4,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(389,13,5,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(390,13,6,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(391,13,7,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(392,13,8,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(393,13,9,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(394,13,10,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(395,13,11,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(396,13,12,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(397,13,13,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(398,13,14,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(399,13,15,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(400,14,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(401,14,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(402,14,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(403,14,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(404,14,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(405,14,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(406,14,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(407,14,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(408,14,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(409,14,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(410,14,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(411,14,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(412,14,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(413,14,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(414,14,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(415,14,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(416,14,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(417,14,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(418,14,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(419,14,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(420,14,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(421,14,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(422,14,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(423,14,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(424,14,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(425,15,1,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(426,15,2,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(427,15,3,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(428,15,4,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(429,15,5,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(430,15,6,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(431,15,7,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(432,15,8,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(433,15,9,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(434,15,10,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(435,15,11,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(436,15,12,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(437,15,13,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(438,15,14,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(439,15,15,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(440,15,16,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(441,15,17,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(442,15,18,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(443,15,19,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(444,15,20,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(445,15,21,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(446,15,22,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(447,15,23,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(448,15,24,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(449,15,25,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(450,15,26,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(451,15,27,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(452,15,28,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(453,15,29,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(454,15,30,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(455,15,31,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(456,15,32,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(457,15,33,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(458,15,34,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(459,15,35,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(460,15,36,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(461,15,37,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(462,15,38,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(463,15,39,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(464,15,40,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(465,15,41,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(466,15,42,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(467,15,43,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(468,15,44,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(469,15,45,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(470,15,46,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(471,15,47,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(472,15,48,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(473,15,49,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(474,15,50,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(475,15,51,NULL,1.00,1,51,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(476,16,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(477,16,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(478,16,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(479,16,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(480,16,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(481,16,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(482,16,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(483,16,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(484,16,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(485,16,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(486,16,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(487,16,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(488,16,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(489,16,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(490,16,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(491,16,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(492,16,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(493,16,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(494,16,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(495,16,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(496,16,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(497,16,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(498,16,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(499,16,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(500,16,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(501,17,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(502,17,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(503,17,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(504,17,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(505,17,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(506,17,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(507,17,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(508,17,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(509,17,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(510,17,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(511,17,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(512,17,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(513,17,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(514,17,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(515,17,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(516,17,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(517,17,17,NULL,1.00,1,16,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(518,17,18,NULL,1.00,1,17,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(519,17,19,NULL,1.00,1,18,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(520,17,20,NULL,1.00,1,19,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(521,17,21,NULL,1.00,1,20,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(522,17,22,NULL,1.00,1,21,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(523,17,23,NULL,1.00,1,22,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(524,17,24,NULL,1.00,1,23,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(525,17,25,NULL,1.00,1,24,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(526,17,26,NULL,1.00,1,25,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(527,17,27,NULL,1.00,1,26,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(528,17,28,NULL,1.00,1,27,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(529,17,29,NULL,1.00,1,28,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(530,17,30,NULL,1.00,1,29,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(531,17,31,NULL,1.00,1,30,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(532,17,32,NULL,1.00,1,31,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(533,17,33,NULL,1.00,1,32,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(534,17,34,NULL,1.00,1,33,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(535,17,35,NULL,1.00,1,34,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(536,17,36,NULL,1.00,1,35,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(537,17,37,NULL,1.00,1,36,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(538,17,38,NULL,1.00,1,37,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(539,17,39,NULL,1.00,1,38,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(540,17,40,NULL,1.00,1,39,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(541,17,41,NULL,1.00,1,40,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(542,17,42,NULL,1.00,1,41,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(543,17,43,NULL,1.00,1,42,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(544,17,44,NULL,1.00,1,43,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(545,17,45,NULL,1.00,1,44,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(546,17,46,NULL,1.00,1,45,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(547,17,47,NULL,1.00,1,46,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(548,17,48,NULL,1.00,1,47,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(549,17,49,NULL,1.00,1,48,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(550,17,50,NULL,1.00,1,49,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(551,17,51,NULL,1.00,1,50,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(552,18,1,NULL,1.00,1,0,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(553,18,2,NULL,1.00,1,1,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(554,18,3,NULL,1.00,1,2,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(555,18,4,NULL,1.00,1,3,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(556,18,5,NULL,1.00,1,4,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(557,18,6,NULL,1.00,1,5,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(558,18,7,NULL,1.00,1,6,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(559,18,8,NULL,1.00,1,7,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(560,18,9,NULL,1.00,1,8,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(561,18,10,NULL,1.00,1,9,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(562,18,11,NULL,1.00,1,10,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(563,18,12,NULL,1.00,1,11,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(564,18,13,NULL,1.00,1,12,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(565,18,14,NULL,1.00,1,13,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(566,18,15,NULL,1.00,1,14,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(567,18,16,NULL,1.00,1,15,1,'2025-10-07 09:59:46',NULL,NULL,NULL),(568,18,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(569,18,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(570,18,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(571,18,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(572,18,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(573,18,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(574,18,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(575,18,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(576,18,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(577,19,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(578,19,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(579,19,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(580,19,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(581,19,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(582,19,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(583,19,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(584,19,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(585,19,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(586,19,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(587,19,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(588,19,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(589,19,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(590,19,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(591,19,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(592,20,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(593,20,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(594,20,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(595,20,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(596,20,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(597,20,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(598,20,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(599,20,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(600,20,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(601,20,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(602,20,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(603,20,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(604,20,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(605,20,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(606,20,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(607,20,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(608,20,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(609,20,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(610,20,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(611,20,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(612,20,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(613,20,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(614,20,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(615,20,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(616,20,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(617,21,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(618,21,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(619,21,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(620,21,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(621,21,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(622,21,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(623,21,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(624,21,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(625,21,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(626,21,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(627,21,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(628,21,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(629,21,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(630,21,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(631,21,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(632,21,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(633,21,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(634,21,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(635,21,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(636,21,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(637,21,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(638,21,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(639,21,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(640,21,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(641,21,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(642,21,26,NULL,1.00,1,25,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(643,21,27,NULL,1.00,1,26,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(644,21,28,NULL,1.00,1,27,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(645,21,29,NULL,1.00,1,28,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(646,21,30,NULL,1.00,1,29,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(647,21,31,NULL,1.00,1,30,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(648,21,32,NULL,1.00,1,31,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(649,21,33,NULL,1.00,1,32,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(650,21,34,NULL,1.00,1,33,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(651,21,35,NULL,1.00,1,34,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(652,21,36,NULL,1.00,1,35,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(653,21,37,NULL,1.00,1,36,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(654,21,38,NULL,1.00,1,37,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(655,21,39,NULL,1.00,1,38,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(656,21,40,NULL,1.00,1,39,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(657,21,41,NULL,1.00,1,40,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(658,21,42,NULL,1.00,1,41,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(659,21,43,NULL,1.00,1,42,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(660,21,44,NULL,1.00,1,43,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(661,21,45,NULL,1.00,1,44,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(662,21,46,NULL,1.00,1,45,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(663,21,47,NULL,1.00,1,46,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(664,21,48,NULL,1.00,1,47,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(665,21,49,NULL,1.00,1,48,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(666,21,50,NULL,1.00,1,49,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(667,21,51,NULL,1.00,1,50,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(668,22,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(669,22,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(670,22,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(671,22,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(672,22,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(673,22,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(674,22,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(675,22,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(676,22,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(677,22,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(678,22,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(679,22,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(680,22,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(681,22,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(682,22,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(683,22,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(684,22,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(685,22,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(686,22,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(687,22,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(688,22,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(689,22,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(690,22,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(691,22,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(692,22,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(693,23,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(694,23,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(695,23,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(696,23,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(697,23,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(698,23,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(699,23,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(700,23,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(701,23,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(702,23,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(703,23,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(704,23,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(705,23,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(706,23,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(707,23,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(708,23,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(709,23,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(710,23,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(711,23,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(712,23,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(713,23,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(714,23,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(715,23,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(716,23,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(717,23,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(718,23,26,NULL,1.00,1,25,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(719,23,27,NULL,1.00,1,26,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(720,23,28,NULL,1.00,1,27,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(721,23,29,NULL,1.00,1,28,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(722,23,30,NULL,1.00,1,29,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(723,23,31,NULL,1.00,1,30,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(724,23,32,NULL,1.00,1,31,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(725,23,33,NULL,1.00,1,32,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(726,23,34,NULL,1.00,1,33,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(727,23,35,NULL,1.00,1,34,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(728,23,36,NULL,1.00,1,35,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(729,23,37,NULL,1.00,1,36,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(730,23,38,NULL,1.00,1,37,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(731,23,39,NULL,1.00,1,38,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(732,23,40,NULL,1.00,1,39,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(733,23,41,NULL,1.00,1,40,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(734,23,42,NULL,1.00,1,41,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(735,23,43,NULL,1.00,1,42,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(736,23,44,NULL,1.00,1,43,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(737,23,45,NULL,1.00,1,44,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(738,23,46,NULL,1.00,1,45,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(739,23,47,NULL,1.00,1,46,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(740,23,48,NULL,1.00,1,47,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(741,23,49,NULL,1.00,1,48,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(742,23,50,NULL,1.00,1,49,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(743,23,51,NULL,1.00,1,50,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(744,24,1,NULL,1.00,1,0,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(745,24,2,NULL,1.00,1,1,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(746,24,3,NULL,1.00,1,2,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(747,24,4,NULL,1.00,1,3,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(748,24,5,NULL,1.00,1,4,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(749,24,6,NULL,1.00,1,5,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(750,24,7,NULL,1.00,1,6,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(751,24,8,NULL,1.00,1,7,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(752,24,9,NULL,1.00,1,8,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(753,24,10,NULL,1.00,1,9,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(754,24,11,NULL,1.00,1,10,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(755,24,12,NULL,1.00,1,11,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(756,24,13,NULL,1.00,1,12,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(757,24,14,NULL,1.00,1,13,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(758,24,15,NULL,1.00,1,14,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(759,24,16,NULL,1.00,1,15,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(760,24,17,NULL,1.00,1,16,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(761,24,18,NULL,1.00,1,17,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(762,24,19,NULL,1.00,1,18,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(763,24,20,NULL,1.00,1,19,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(764,24,21,NULL,1.00,1,20,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(765,24,22,NULL,1.00,1,21,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(766,24,23,NULL,1.00,1,22,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(767,24,24,NULL,1.00,1,23,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(768,24,25,NULL,1.00,1,24,1,'2025-10-07 09:59:47',NULL,NULL,NULL),(771,3,55,NULL,1.00,1,51,1,'2025-10-10 19:29:48',NULL,1,4),(772,1,30,NULL,1.00,1,15,1,'2025-10-10 22:05:00',NULL,NULL,NULL),(773,1,56,NULL,1.00,1,16,1,'2025-10-10 22:06:59',NULL,0,2);
/*!40000 ALTER TABLE items_plantilla_checklist ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jefes_establecimientos`
--

/*!40000 ALTER TABLE jefes_establecimientos DISABLE KEYS */;
INSERT INTO jefes_establecimientos (id, usuario_id, establecimiento_id, fecha_inicio, fecha_fin, es_principal, comentario, activo, created_at) VALUES (1,7,1,'2025-08-28',NULL,1,'Jefe principal del establecimiento Déjà vu',1,'2025-08-28 16:30:01'),(2,8,2,'2025-08-28',NULL,1,'Jefe principal del establecimiento Silvia',1,'2025-08-28 16:30:01'),(3,9,3,'2025-08-28',NULL,1,'Jefe principal del establecimiento Náutica',1,'2025-08-28 16:30:01'),(27,61,4,'2025-10-10',NULL,1,'',1,'2025-10-10 22:26:19');
/*!40000 ALTER TABLE jefes_establecimientos ENABLE KEYS */;

--
-- Table structure for table `permisos_roles`
--

DROP TABLE IF EXISTS permisos_roles;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE permisos_roles (
  id int NOT NULL AUTO_INCREMENT,
  rol_id int NOT NULL,
  recurso varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'usuarios, establecimientos, inspecciones, etc.',
  accion varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'crear, editar, eliminar, ver, etc.',
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

/*!40000 ALTER TABLE permisos_roles DISABLE KEYS */;
INSERT INTO permisos_roles (id, rol_id, recurso, accion, condicion, activo, created_at) VALUES (1,1,'inspecciones','crear',NULL,1,'2025-09-01 15:59:50'),(2,1,'inspecciones','editar','{\"propias\": true}',1,'2025-09-01 15:59:51'),(3,1,'inspecciones','ver',NULL,1,'2025-09-01 15:59:51'),(4,1,'configuracion','editar','{\"solo_meta_semanal\": true}',1,'2025-09-01 15:59:52'),(5,1,'configuracion','ver',NULL,1,'2025-09-01 15:59:53'),(6,1,'establecimientos','ver',NULL,1,'2025-09-01 15:59:54'),(7,2,'inspecciones','ver','{\"propias\": true}',1,'2025-09-01 15:59:56'),(9,2,'inspecciones','firmar','{\"propias\": true}',1,'2025-09-01 15:59:58'),(10,2,'establecimientos','ver','{\"propios\": true}',1,'2025-09-01 16:00:00'),(11,3,'*','*',NULL,1,'2025-09-01 16:00:00'),(12,4,'establecimientos','ver','{\"propios\": true}',1,'2025-09-01 16:00:03'),(13,4,'establecimientos','editar','{\"propios\": true}',1,'2025-09-01 16:00:04'),(14,4,'encargados','gestionar','{\"establecimiento_propio\": true}',1,'2025-09-01 16:00:05'),(15,4,'inspecciones','ver','{\"establecimiento_propio\": true}',1,'2025-09-01 16:00:06'),(16,4,'firmas','cargar',NULL,1,'2025-09-01 16:00:07');
/*!40000 ALTER TABLE permisos_roles ENABLE KEYS */;

--
-- Table structure for table `permisos_usuarios`
--

DROP TABLE IF EXISTS permisos_usuarios;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE permisos_usuarios (
  id int NOT NULL AUTO_INCREMENT,
  usuario_id int NOT NULL,
  recurso varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  accion varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  permitido tinyint(1) NOT NULL COMMENT 'True permite, False deniega',
  condicion json DEFAULT NULL,
  razon varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Razón para el permiso/denegación específica',
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

/*!40000 ALTER TABLE permisos_usuarios DISABLE KEYS */;
/*!40000 ALTER TABLE permisos_usuarios ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plan_semanal`
--

/*!40000 ALTER TABLE plan_semanal DISABLE KEYS */;
INSERT INTO plan_semanal (id, establecimiento_id, semana, ano, evaluaciones_meta, evaluaciones_realizadas, created_at) VALUES (1,1,36,2025,3,1,'2025-09-01 19:34:33'),(2,2,36,2025,3,0,'2025-09-01 19:34:33'),(3,3,36,2025,3,0,'2025-09-01 19:34:33'),(4,4,36,2025,3,0,'2025-09-01 19:34:33'),(5,1,37,2025,3,1,'2025-09-09 16:45:14'),(6,2,37,2025,3,0,'2025-09-09 16:45:14'),(7,3,37,2025,3,0,'2025-09-09 16:45:14'),(8,4,37,2025,3,0,'2025-09-09 16:45:14'),(9,1,38,2025,3,0,'2025-09-16 16:18:08'),(10,2,38,2025,3,0,'2025-09-16 16:18:08'),(11,3,38,2025,3,0,'2025-09-16 16:18:08'),(12,4,38,2025,3,0,'2025-09-16 16:18:08'),(14,6,38,2025,3,0,'2025-09-16 22:22:19'),(15,1,39,2025,3,2,'2025-09-24 20:26:17'),(16,2,39,2025,3,0,'2025-09-24 20:26:17'),(17,3,39,2025,3,0,'2025-09-24 20:26:17'),(18,4,39,2025,3,0,'2025-09-24 20:26:17'),(20,6,39,2025,3,0,'2025-09-24 20:26:17'),(21,1,40,2025,3,1,'2025-10-01 15:00:56'),(22,2,40,2025,3,1,'2025-10-01 15:00:56'),(23,3,40,2025,3,0,'2025-10-01 15:00:56'),(24,4,40,2025,3,0,'2025-10-01 15:00:56'),(26,6,40,2025,3,0,'2025-10-01 15:00:56'),(27,7,40,2025,3,0,'2025-10-02 22:55:34'),(28,1,40,2024,3,0,'2025-10-03 22:13:31'),(30,1,41,2025,3,3,'2025-10-07 14:42:09'),(31,2,41,2025,3,4,'2025-10-07 14:42:09'),(32,3,41,2025,3,0,'2025-10-07 14:42:09'),(33,4,41,2025,3,0,'2025-10-07 14:42:09'),(34,6,41,2025,3,0,'2025-10-07 14:42:09'),(35,7,41,2025,3,0,'2025-10-07 14:42:09'),(36,9,41,2025,3,0,'2025-10-07 17:53:42'),(37,10,41,2025,3,0,'2025-10-07 20:48:54');
/*!40000 ALTER TABLE plan_semanal ENABLE KEYS */;

--
-- Table structure for table `plantillas_checklist`
--

DROP TABLE IF EXISTS plantillas_checklist;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE plantillas_checklist (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  descripcion text COLLATE utf8mb4_unicode_ci,
  tipo_establecimiento_id int DEFAULT NULL,
  tamano_local enum('pequeno','mediano','grande') COLLATE utf8mb4_unicode_ci DEFAULT 'mediano',
  tipo_restaurante varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
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

/*!40000 ALTER TABLE plantillas_checklist DISABLE KEYS */;
INSERT INTO plantillas_checklist (id, nombre, descripcion, tipo_establecimiento_id, tamano_local, tipo_restaurante, activo, created_at, updated_at) VALUES (1,'Restaurante - Checklist Básico Pequeño','Plantilla básica para locales pequeños',1,'pequeno',NULL,1,'2025-10-07 09:59:45','2025-10-07 09:59:45'),(2,'Restaurante - Checklist Estándar Mediano','Plantilla estándar para locales medianos',1,'mediano',NULL,1,'2025-10-07 09:59:45','2025-10-07 09:59:45'),(3,'Restaurante - Checklist Completo Principal','Plantilla completa para locales grandes',1,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-10 18:25:16'),(4,'Restaurante - Checklist Restaurante Casual','Para restaurantes de comida casual',1,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(5,'Restaurante - Checklist Restaurante Fino','Para restaurantes de alta cocina',1,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(6,'Restaurante - Checklist Bar Estándar','Para bares y pubs',1,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(7,'Cafetería - Checklist Básico Pequeño','Plantilla básica para locales pequeños',2,'pequeno',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(8,'Cafetería - Checklist Estándar Mediano','Plantilla estándar para locales medianos',2,'mediano',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(9,'Cafetería - Checklist Completo Grande','Plantilla completa para locales grandes',2,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(10,'Cafetería - Checklist Restaurante Casual','Para restaurantes de comida casual',2,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(11,'Cafetería - Checklist Restaurante Fino','Para restaurantes de alta cocina',2,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(12,'Cafetería - Checklist Bar Estándar','Para bares y pubs',2,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(13,'Bar - Checklist Básico Pequeño','Plantilla básica para locales pequeños',3,'pequeno',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(14,'Bar - Checklist Estándar Mediano','Plantilla estándar para locales medianos',3,'mediano',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(15,'Bar - Checklist Completo Grande','Plantilla completa para locales grandes',3,'grande',NULL,1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(16,'Bar - Checklist Restaurante Casual','Para restaurantes de comida casual',3,'mediano','casual',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(17,'Bar - Checklist Restaurante Fino','Para restaurantes de alta cocina',3,'grande','fino',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(18,'Bar - Checklist Bar Estándar','Para bares y pubs',3,'mediano','bar',1,'2025-10-07 09:59:46','2025-10-07 09:59:46'),(19,'Food Court - Checklist Básico Pequeño','Plantilla básica para locales pequeños',4,'pequeno',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47'),(20,'Food Court - Checklist Estándar Mediano','Plantilla estándar para locales medianos',4,'mediano',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47'),(21,'Food Court - Checklist Completo Grande','Plantilla completa para locales grandes',4,'grande',NULL,1,'2025-10-07 09:59:47','2025-10-07 09:59:47'),(22,'Food Court - Checklist Restaurante Casual','Para restaurantes de comida casual',4,'mediano','casual',1,'2025-10-07 09:59:47','2025-10-07 09:59:47'),(23,'Food Court - Checklist Restaurante Fino','Para restaurantes de alta cocina',4,'grande','fino',1,'2025-10-07 09:59:47','2025-10-07 09:59:47'),(24,'Food Court - Checklist Bar Estándar','Para bares y pubs',4,'mediano','bar',1,'2025-10-07 09:59:47','2025-10-07 09:59:47');
/*!40000 ALTER TABLE plantillas_checklist ENABLE KEYS */;

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

/*!40000 ALTER TABLE roles DISABLE KEYS */;
INSERT INTO roles (id, nombre, descripcion, permisos, created_at) VALUES (1,'Inspector','Puede crear jefes de establecimiento y gestionar inspecciones','{\"informes\": {\"ver_todos\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"ver_todos\": true}}','2025-08-19 16:30:01'),(2,'Encargado','Acceso limitado para realizar inspecciones','{\"informes\": {\"ver_propios\": true}, \"inspecciones\": {\"firmar\": true, \"ver_propias\": true}}','2025-08-19 16:30:01'),(3,'Administrador','Acceso completo al sistema','{\"informes\": {\"ver_todos\": true}, \"usuarios\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"cambiar_roles\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"ver_todos\": true}, \"establecimientos\": {\"crear\": true, \"editar\": true, \"eliminar\": true}}','2025-08-19 16:30:01'),(4,'Jefe de Establecimiento','Puede crear encargados y gestionar su establecimiento','{\"firmas\": {\"validar\": true, \"cargar_encargados\": true}, \"encargados\": {\"habilitar\": true, \"deshabilitar\": true, \"cargar_firmas\": true, \"ver_todos_establecimiento\": true}, \"inspecciones\": {\"supervisar\": true, \"ver_establecimiento\": true}, \"establecimientos\": {\"ver_propio\": true, \"editar_propio\": true, \"gestionar_encargados\": true}}','2025-08-28 16:30:01');
/*!40000 ALTER TABLE roles ENABLE KEYS */;

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

/*!40000 ALTER TABLE tipos_establecimiento DISABLE KEYS */;
INSERT INTO tipos_establecimiento (id, nombre, descripcion, activo, created_at) VALUES (1,'Restaurante','Establecimiento de servicio de alimentos y bebidas',1,'2025-08-19 16:30:01'),(2,'Cafetería','Establecimiento especializado en café y aperitivos',1,'2025-08-19 16:30:01'),(3,'Bar','Establecimiento especializado en bebidas',1,'2025-08-19 16:30:01'),(4,'Food Court','Área común de diversos establecimientos de comida',1,'2025-08-19 16:30:01');
/*!40000 ALTER TABLE tipos_establecimiento ENABLE KEYS */;

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
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

/*!40000 ALTER TABLE usuarios DISABLE KEYS */;
INSERT INTO usuarios (id, nombre, apellido, correo, contrasena, rol_id, activo, en_linea, ultimo_acceso, telefono, dni, ruta_firma, fecha_creacion, created_at, updated_at, cambiar_contrasena) VALUES (1,'Jesus','Isique','desarrollo@castillodechancay.com','$2b$12$C58u.bPb.cR45jpC9QxLf.i05oucxUGq/XABKPCL2X.N5jOVkd7Sq',1,1,0,'2025-10-10 17:18:28','987654321','45678912','img/firmas/firma_inspector_1_20251002_124757.jpg','2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-10 21:47:54',0),(2,'Jhon','Doe','jhondoe@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',2,1,0,'2025-10-10 21:48:37','987654322','12345678',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-10 22:41:11',0),(3,'María','García','maria.garcia@example.com','$2b$12$LfnXh.QTjJW1rjw16I1Nse2wLZRGQw6ZVXegdPAoLhxeW12yDymTu',2,1,0,'2025-10-10 19:56:24','987654323','87654321',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-10 21:22:35',0),(4,'Carlos','López','carlos.lopez@example.com','$2b$12$G6AjqJNIRp5CaNwOH3ZN9OhLqMOPSXdhzFR.bIawHhI8UqohZH40m',2,1,0,'2025-08-19 16:30:01','987654324','45678913',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-08-19 16:30:01',0),(5,'Ana','Martínez','ana.martinez@example.com','$2b$12$4rxq9BvEThorOft1eMRSQe.DDpK3gIFX/rXZ/feJZ/hgXiz6PnrC.',2,1,0,'2025-08-19 16:30:01','987654325','78912345',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-08-19 16:30:01',0),(6,'Admin','Sistema','estadistica@castillodechancay.com','$2b$12$jeZG0C.IXQsL/zmrvCS/4OBnfPIHDdDQs2KrdqUWVUqPnXPdTeyte',3,1,0,'2025-10-09 22:14:54','987654326','11111111',NULL,'2025-08-19 16:30:01','2025-08-19 16:30:01','2025-10-09 22:51:10',0),(7,'Roberto','Fernández','jefe.dejavu@chancay.com','$2b$12$MFbKMeEyu0VPqAkjeDSF0uOWNyH58XqeQrKdJqXUWP1eQIOLevs.6',4,1,0,'2025-10-10 21:23:04','987654327','55555555',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-10-10 21:24:16',0),(8,'Patricia','Morales','jefe.silvia@chancay.com','$2b$12$EjtmpMwAROy73Df9CYRdyejducZpGhhPgpbvVyLTES6IIqLOUmy9y',4,1,0,'2025-08-28 16:30:01','987654328','66666666',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-08-28 16:30:01',0),(9,'Miguel','Herrera','jefe.nautica@chancay.com','$2b$12$w6a5mjIqjy7Nzi8lLYFSfeuu7ArtK2Xdv/EJ9zZytM3tgd3LUY/my',4,1,0,'2025-08-28 16:30:01','987654329','77777777',NULL,'2025-08-28 16:30:01','2025-08-28 16:30:01','2025-08-28 16:30:01',0),(10,'Jhon2','Doe2','encargado.dejavu@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',2,1,1,'2025-10-02 15:22:41','978541259','84524685',NULL,'2025-09-12 16:35:12','2025-09-12 16:35:12','2025-10-02 15:22:41',0),(13,'Janet',NULL,'alimentosybebidas@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',1,1,1,'2025-10-10 22:31:56','985236985','74589635','img/firmas/firma_inspector_13_20251010_172854.jpg','2025-10-02 17:14:46','2025-10-02 17:14:46','2025-10-10 22:31:56',0),(61,'Luz','Serrato','Luz@gamil.com','$2b$12$NXwtnE32at7CfCgD1o11UeXwY9lql7xlj8k1nGqoDR3maRl7Sj5Fi',4,1,0,'2025-10-10 22:26:19','982841347','72487591',NULL,'2025-10-10 22:26:19','2025-10-10 22:26:19','2025-10-10 22:27:28',1);
/*!40000 ALTER TABLE usuarios ENABLE KEYS */;

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

-- Dump completed on 2025-10-11 12:42:19
