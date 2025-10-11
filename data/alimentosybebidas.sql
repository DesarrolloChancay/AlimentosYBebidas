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
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `categorias_evaluacion`
--

DROP TABLE IF EXISTS categorias_evaluacion;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE categorias_evaluacion (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci,
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categorias_evaluacion`
--

/*!40000 ALTER TABLE categorias_evaluacion DISABLE KEYS */;
INSERT INTO categorias_evaluacion VALUES 
(1,'Higiene y Bioseguridad - Cocinas','Evaluación de higiene y bioseguridad en áreas de cocina',1,1),
(2,'Equipamiento - Cocinas','Evaluación del equipamiento en cocinas',2,1),
(3,'Producción y Almacenamiento previo','Evaluación de procesos de producción y almacenamiento',3,1),
(4,'Preparación de alimentos','Evaluación de procesos de preparación de alimentos',4,1),
(5,'Gestión de residuos y plagas','Evaluación de manejo de residuos y control de plagas',5,1),
(6,'Vajillas y Utensilios','Evaluación de vajillas y utensilios de cocina',6,1),
(7,'Higiene general - Comedor','Evaluación de higiene en área de comedor',7,1),
(8,'Almacenes','Evaluación de áreas de almacenamiento',8,1),
(9,'Seguridad - Defensa Civil','Evaluación de medidas de seguridad',9,1),
(10,'Administración','Evaluación de aspectos administrativos',10,1);
/*!40000 ALTER TABLE categorias_evaluacion ENABLE KEYS */;

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
  comentario varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  habilitado_por int DEFAULT NULL,
  fecha_habilitacion timestamp NULL DEFAULT NULL,
  observaciones_jefe text COLLATE utf8mb4_general_ci DEFAULT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY idx_encargado_establecimiento_fecha (establecimiento_id,fecha_inicio,fecha_fin),
  KEY idx_encargado_activo (activo),
  KEY idx_encargado_habilitado_por (habilitado_por),
  UNIQUE KEY uk_encargado_establecimiento_activo (establecimiento_id, activo),
  CONSTRAINT encargados_establecimientos_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT encargados_establecimientos_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT encargados_establecimientos_ibfk_3 FOREIGN KEY (habilitado_por) REFERENCES usuarios (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

-- Alter table to drop the unique constraint allowing multiple active encargados per establishment
ALTER TABLE encargados_establecimientos DROP INDEX uk_encargado_establecimiento_activo;

--
-- Dumping data for table `encargados_establecimientos`
--

/*!40000 ALTER TABLE encargados_establecimientos DISABLE KEYS */;
INSERT INTO encargados_establecimientos VALUES
(1,2,1,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 21:30:01'),
(2,3,2,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 21:30:01'),
(3,4,3,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 21:30:01'),
(4,5,4,'2025-08-16',NULL,1,NULL,1,NULL,NULL,NULL,'2025-08-19 21:30:01');
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
  nombre varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  direccion varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  telefono varchar(30) COLLATE utf8mb4_general_ci DEFAULT NULL,
  correo varchar(150) COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY tipo_establecimiento_id (tipo_establecimiento_id),
  KEY idx_establecimientos_activo (activo),
  CONSTRAINT establecimientos_ibfk_1 FOREIGN KEY (tipo_establecimiento_id) REFERENCES tipos_establecimiento (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `establecimientos`
--

/*!40000 ALTER TABLE establecimientos DISABLE KEYS */;
INSERT INTO establecimientos VALUES
(1,1,'Déjà vu','Dirección Déjà vu','123456789','dejavu@chancay.com',1,'2025-08-19 21:30:01'),
(2,1,'Silvia','Dirección Silvia','123456789','silvia@chancay.com',1,'2025-08-19 21:30:01'),
(3,1,'Náutica','Dirección Náutica','123456789','nautica@chancay.com',1,'2025-08-19 21:30:01'),
(4,1,'Rincón del Norte','Dirección Rincón del Norte','123456789','rinconnorte@chancay.com',1,'2025-08-19 21:30:01');
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
  filename varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  ruta_archivo varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  mime_type varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  tamano_bytes int DEFAULT NULL,
  uploaded_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY item_detalle_id (item_detalle_id),
  KEY idx_evidencias_inspeccion (inspeccion_id),
  CONSTRAINT evidencias_inspeccion_ibfk_1 FOREIGN KEY (inspeccion_id) REFERENCES inspecciones (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT evidencias_inspeccion_ibfk_2 FOREIGN KEY (item_detalle_id) REFERENCES inspeccion_detalles (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


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
  observacion_item text COLLATE utf8mb4_general_ci,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_inspeccion_item (inspeccion_id,item_establecimiento_id),
  KEY item_establecimiento_id (item_establecimiento_id),
  CONSTRAINT inspeccion_detalles_ibfk_1 FOREIGN KEY (inspeccion_id) REFERENCES inspecciones (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT inspeccion_detalles_ibfk_2 FOREIGN KEY (item_establecimiento_id) REFERENCES items_evaluacion_establecimiento (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=511 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

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
  observaciones text COLLATE utf8mb4_general_ci,
  puntaje_total decimal(6,2) DEFAULT NULL,
  puntaje_maximo_posible decimal(6,2) DEFAULT NULL,
  porcentaje_cumplimiento decimal(5,2) DEFAULT NULL,
  puntos_criticos_perdidos int DEFAULT NULL,
  estado enum('pendiente','en_proceso','completada') COLLATE utf8mb4_general_ci DEFAULT 'pendiente',
  firma_inspector varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  firma_encargado varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;


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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspector_establecimientos`
--

/*!40000 ALTER TABLE inspector_establecimientos DISABLE KEYS */;
INSERT INTO inspector_establecimientos VALUES
(1,1,1,'2025-08-16',NULL,1,1,'2025-08-19 21:30:01'),
(2,1,2,'2025-08-16',NULL,1,1,'2025-08-19 21:30:01'),
(3,1,3,'2025-08-16',NULL,1,1,'2025-08-19 21:30:01'),
(4,1,4,'2025-08-16',NULL,1,1,'2025-08-19 21:30:01');
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
  codigo varchar(20) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci NOT NULL,
  riesgo enum('Menor','Mayor','Crítico') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Menor',
  puntaje_minimo int NOT NULL,
  puntaje_maximo int NOT NULL,
  orden int DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_categoria_codigo (categoria_id,codigo),
  CONSTRAINT items_evaluacion_base_ibfk_1 FOREIGN KEY (categoria_id) REFERENCES categorias_evaluacion (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_base`
--

/*!40000 ALTER TABLE items_evaluacion_base DISABLE KEYS */;
INSERT INTO items_evaluacion_base VALUES
(1,1,'1.1','Pisos y paredes sin suciedad visible ni humedad','Mayor',1,4,1,1,'2025-08-19 21:30:01'),
(2,1,'1.2','Lavaderos libres de residuos','Menor',1,2,2,1,'2025-08-19 21:30:01'),
(3,1,'1.3','Campana extractora limpia y operativa','Mayor',1,4,3,1,'2025-08-19 21:30:01'),
(4,1,'1.4','Iluminación adecuada','Menor',1,2,4,1,'2025-08-19 21:30:01'),
(5,1,'1.5','Gel antibacterial / Jabón líquido','Menor',1,2,5,1,'2025-08-19 21:30:01'),
(6,1,'1.6','Personal de cocina con uniforme completo, limpio y buena higiene personal','Mayor',1,4,6,1,'2025-08-19 21:30:01'),
(7,1,'1.7','Presencia de personas ajenas','Menor',1,2,7,1,'2025-08-19 21:30:01'),
(8,1,'1.8','Insumos de limpieza alejados de alimentos y hornillas','Mayor',1,4,8,1,'2025-08-19 21:30:01'),
(9,2,'2.1','Equipos completos, operativos y en buen estado','Mayor',1,4,1,1,'2025-08-19 21:30:01'),
(10,2,'2.2','Limpieza y conservación de equipos','Mayor',1,4,2,1,'2025-08-19 21:30:01'),
(11,2,'2.3','Constancia de mantenimiento de sus equipos cada 6 meses','Mayor',1,4,3,1,'2025-08-19 21:30:01'),
(12,3,'3.1','Mise en place de carnes, pescados y mariscos','Crítico',1,8,1,1,'2025-08-19 21:30:01'),
(13,3,'3.2','Mise en place de vegetales','Mayor',1,4,2,1,'2025-08-19 21:30:01'),
(14,3,'3.3','Mise en place de complementos','Mayor',1,4,3,1,'2025-08-19 21:30:01'),
(15,3,'3.4','Mise en place de salsas','Mayor',1,4,4,1,'2025-08-19 21:30:01'),
(16,4,'4.1','Aspecto limpio del aceite','Mayor',1,4,1,1,'2025-08-19 21:30:01'),
(17,4,'4.2','Separación de alimentos crudos y cocidos','Crítico',1,8,2,1,'2025-08-19 21:30:01'),
(18,4,'4.3','Descongelación adecuada','Crítico',1,8,3,1,'2025-08-19 21:30:01'),
(19,4,'4.4','Insumos en buen estado','Crítico',1,8,4,1,'2025-08-19 21:30:01'),
(20,4,'4.5','Rotulado de productos','Crítico',1,8,5,1,'2025-08-19 21:30:01'),
(21,4,'4.6','Verificación del agua potable (bidón y filtros de agua)','Mayor',1,4,6,1,'2025-08-19 21:30:01'),
(22,5,'5.1','Basureros adecuados','Menor',1,2,1,1,'2025-08-19 21:30:01'),
(23,5,'5.2','Eliminación diaria de basura en el lugar adecuado','Mayor',1,4,2,1,'2025-08-19 21:30:01'),
(24,5,'5.3','Ausencia de insectos y cualquier animal','Crítico',1,8,3,1,'2025-08-19 21:30:01'),
(25,5,'5.4','Bitácoras de limpieza y gestión de plagas','Mayor',1,4,4,1,'2025-08-19 21:30:01'),
(26,6,'6.1','Buen estado de conservación','Mayor',1,4,1,1,'2025-08-19 21:30:01'),
(27,6,'6.2','Vajillas y Utensilios limpios','Mayor',1,4,2,1,'2025-08-19 21:30:01'),
(28,6,'6.3','Secado adecuado','Menor',1,2,3,1,'2025-08-19 21:30:01'),
(29,6,'6.4','Tablas de picar separadas por color, en buen estado y limpias (se recomienda acero)','Mayor',1,4,4,1,'2025-08-19 21:30:01'),
(30,7,'7.1','Pisos limpios','Menor',1,2,1,1,'2025-08-19 21:30:01'),
(31,7,'7.2','Mesas y manteles limpios','Menor',1,2,2,1,'2025-08-19 21:30:01'),
(32,7,'7.3','Personal con uniforme completo y limpio y buena higiene personal','Mayor',1,4,3,1,'2025-08-19 21:30:01'),
(33,7,'7.4','Contar con implementos de atención','Menor',1,2,4,1,'2025-08-19 21:30:01'),
(34,8,'8.1','Ordenado y limpio','Mayor',1,4,1,1,'2025-08-19 21:30:01'),
(35,8,'8.2','Enlatados en buen estado y vigentes','Crítico',1,8,2,1,'2025-08-19 21:30:01'),
(36,8,'8.3','Control de fechas de vencimiento de todos los productos','Crítico',1,8,3,1,'2025-08-19 21:30:01'),
(37,8,'8.4','Ausencia de sustancias químicas','Mayor',1,4,4,1,'2025-08-19 21:30:01'),
(38,9,'9.1','Extintores operativos y vigentes (plateado y rojo) con señalización, tarjeta de inspección y certificado','Crítico',1,8,1,1,'2025-08-19 21:30:01'),
(39,9,'9.2','Botiquín de primeros auxilios completo con señalización','Mayor',1,4,2,1,'2025-08-19 21:30:01'),
(40,9,'9.3','Balones de Gas: con seguridad y señalización','Crítico',1,8,3,1,'2025-08-19 21:30:01'),
(41,9,'9.4','Sistema contra incendios operativo','Crítico',1,8,4,1,'2025-08-19 21:30:01'),
(42,9,'9.5','Otras señalizaciones de salida, entrada, aforo, horario de atención, zona segura','Mayor',1,4,5,1,'2025-08-19 21:30:01'),
(43,9,'9.6','Pisos antideslizantes en las cocinas y cintas en las escaleras y rampas','Mayor',1,4,6,1,'2025-08-19 21:30:01'),
(44,9,'9.7','Luces de emergencia operativas con señalética y con certificado','Mayor',1,4,7,1,'2025-08-19 21:30:01'),
(45,10,'10.1','POS operativo','Menor',1,2,1,1,'2025-08-19 21:30:01'),
(46,10,'10.2','Caja chica disponible','Menor',1,2,2,1,'2025-08-19 21:30:01'),
(47,10,'10.3','Facturas y boletas vigentes','Mayor',1,4,3,1,'2025-08-19 21:30:01'),
(48,10,'10.4','Libro de reclamaciones','Mayor',1,4,4,1,'2025-08-19 21:30:01'),
(49,10,'10.5','Cartas en buen estado','Menor',1,2,5,1,'2025-08-19 21:30:01'),
(50,10,'10.6','Stock de bebidas','Menor',1,2,6,1,'2025-08-19 21:30:01'),
(51,10,'10.7','Stock de envases y sachet','Menor',1,2,7,1,'2025-08-19 21:30:01');
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
  descripcion_personalizada text COLLATE utf8mb4_general_ci,
  factor_ajuste decimal(3,2) DEFAULT '1.00',
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_establecimiento_item (establecimiento_id,item_base_id),
  KEY item_base_id (item_base_id),
  CONSTRAINT items_evaluacion_establecimiento_ibfk_1 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT items_evaluacion_establecimiento_ibfk_2 FOREIGN KEY (item_base_id) REFERENCES items_evaluacion_base (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=256 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items_evaluacion_establecimiento`
--

/*!40000 ALTER TABLE items_evaluacion_establecimiento DISABLE KEYS */;
INSERT INTO items_evaluacion_establecimiento VALUES (1,4,1,NULL,1.00,1,'2025-08-19 21:30:01'),(2,3,1,NULL,1.00,1,'2025-08-19 21:30:01'),(3,2,1,NULL,1.00,1,'2025-08-19 21:30:01'),(4,1,1,NULL,1.00,1,'2025-08-19 21:30:01'),(5,4,2,NULL,1.00,1,'2025-08-19 21:30:01'),(6,3,2,NULL,1.00,1,'2025-08-19 21:30:01'),(7,2,2,NULL,1.00,1,'2025-08-19 21:30:01'),(8,1,2,NULL,1.00,1,'2025-08-19 21:30:01'),(9,4,3,NULL,1.00,1,'2025-08-19 21:30:01'),(10,3,3,NULL,1.00,1,'2025-08-19 21:30:01'),(11,2,3,NULL,1.00,1,'2025-08-19 21:30:01'),(12,1,3,NULL,1.00,1,'2025-08-19 21:30:01'),(13,4,4,NULL,1.00,1,'2025-08-19 21:30:01'),(14,3,4,NULL,1.00,1,'2025-08-19 21:30:01'),(15,2,4,NULL,1.00,1,'2025-08-19 21:30:01'),(16,1,4,NULL,1.00,1,'2025-08-19 21:30:01'),(17,4,5,NULL,1.00,1,'2025-08-19 21:30:01'),(18,3,5,NULL,1.00,1,'2025-08-19 21:30:01'),(19,2,5,NULL,1.00,1,'2025-08-19 21:30:01'),(20,1,5,NULL,1.00,1,'2025-08-19 21:30:01'),(21,4,6,NULL,1.00,1,'2025-08-19 21:30:01'),(22,3,6,NULL,1.00,1,'2025-08-19 21:30:01'),(23,2,6,NULL,1.00,1,'2025-08-19 21:30:01'),(24,1,6,NULL,1.00,1,'2025-08-19 21:30:01'),(25,4,7,NULL,1.00,1,'2025-08-19 21:30:01'),(26,3,7,NULL,1.00,1,'2025-08-19 21:30:01'),(27,2,7,NULL,1.00,1,'2025-08-19 21:30:01'),(28,1,7,NULL,1.00,1,'2025-08-19 21:30:01'),(29,4,8,NULL,1.00,1,'2025-08-19 21:30:01'),(30,3,8,NULL,1.00,1,'2025-08-19 21:30:01'),(31,2,8,NULL,1.00,1,'2025-08-19 21:30:01'),(32,1,8,NULL,1.00,1,'2025-08-19 21:30:01'),(33,4,9,NULL,1.00,1,'2025-08-19 21:30:01'),(34,3,9,NULL,1.00,1,'2025-08-19 21:30:01'),(35,2,9,NULL,1.00,1,'2025-08-19 21:30:01'),(36,1,9,NULL,1.00,1,'2025-08-19 21:30:01'),(37,4,10,NULL,1.00,1,'2025-08-19 21:30:01'),(38,3,10,NULL,1.00,1,'2025-08-19 21:30:01'),(39,2,10,NULL,1.00,1,'2025-08-19 21:30:01'),(40,1,10,NULL,1.00,1,'2025-08-19 21:30:01'),(41,4,11,NULL,1.00,1,'2025-08-19 21:30:01'),(42,3,11,NULL,1.00,1,'2025-08-19 21:30:01'),(43,2,11,NULL,1.00,1,'2025-08-19 21:30:01'),(44,1,11,NULL,1.00,1,'2025-08-19 21:30:01'),(45,4,12,NULL,1.00,1,'2025-08-19 21:30:01'),(46,3,12,NULL,1.00,1,'2025-08-19 21:30:01'),(47,2,12,NULL,1.00,1,'2025-08-19 21:30:01'),(48,1,12,NULL,1.00,1,'2025-08-19 21:30:01'),(49,4,13,NULL,1.00,1,'2025-08-19 21:30:01'),(50,3,13,NULL,1.00,1,'2025-08-19 21:30:01'),(51,2,13,NULL,1.00,1,'2025-08-19 21:30:01'),(52,1,13,NULL,1.00,1,'2025-08-19 21:30:01'),(53,4,14,NULL,1.00,1,'2025-08-19 21:30:01'),(54,3,14,NULL,1.00,1,'2025-08-19 21:30:01'),(55,2,14,NULL,1.00,1,'2025-08-19 21:30:01'),(56,1,14,NULL,1.00,1,'2025-08-19 21:30:01'),(57,4,15,NULL,1.00,1,'2025-08-19 21:30:01'),(58,3,15,NULL,1.00,1,'2025-08-19 21:30:01'),(59,2,15,NULL,1.00,1,'2025-08-19 21:30:01'),(60,1,15,NULL,1.00,1,'2025-08-19 21:30:01'),(61,4,16,NULL,1.00,1,'2025-08-19 21:30:01'),(62,3,16,NULL,1.00,1,'2025-08-19 21:30:01'),(63,2,16,NULL,1.00,1,'2025-08-19 21:30:01'),(64,1,16,NULL,1.00,1,'2025-08-19 21:30:01'),(65,4,17,NULL,1.00,1,'2025-08-19 21:30:01'),(66,3,17,NULL,1.00,1,'2025-08-19 21:30:01'),(67,2,17,NULL,1.00,1,'2025-08-19 21:30:01'),(68,1,17,NULL,1.00,1,'2025-08-19 21:30:01'),(69,4,18,NULL,1.00,1,'2025-08-19 21:30:01'),(70,3,18,NULL,1.00,1,'2025-08-19 21:30:01'),(71,2,18,NULL,1.00,1,'2025-08-19 21:30:01'),(72,1,18,NULL,1.00,1,'2025-08-19 21:30:01'),(73,4,19,NULL,1.00,1,'2025-08-19 21:30:01'),(74,3,19,NULL,1.00,1,'2025-08-19 21:30:01'),(75,2,19,NULL,1.00,1,'2025-08-19 21:30:01'),(76,1,19,NULL,1.00,1,'2025-08-19 21:30:01'),(77,4,20,NULL,1.00,1,'2025-08-19 21:30:01'),(78,3,20,NULL,1.00,1,'2025-08-19 21:30:01'),(79,2,20,NULL,1.00,1,'2025-08-19 21:30:01'),(80,1,20,NULL,1.00,1,'2025-08-19 21:30:01'),(81,4,21,NULL,1.00,1,'2025-08-19 21:30:01'),(82,3,21,NULL,1.00,1,'2025-08-19 21:30:01'),(83,2,21,NULL,1.00,1,'2025-08-19 21:30:01'),(84,1,21,NULL,1.00,1,'2025-08-19 21:30:01'),(85,4,22,NULL,1.00,1,'2025-08-19 21:30:01'),(86,3,22,NULL,1.00,1,'2025-08-19 21:30:01'),(87,2,22,NULL,1.00,1,'2025-08-19 21:30:01'),(88,1,22,NULL,1.00,1,'2025-08-19 21:30:01'),(89,4,23,NULL,1.00,1,'2025-08-19 21:30:01'),(90,3,23,NULL,1.00,1,'2025-08-19 21:30:01'),(91,2,23,NULL,1.00,1,'2025-08-19 21:30:01'),(92,1,23,NULL,1.00,1,'2025-08-19 21:30:01'),(93,4,24,NULL,1.00,1,'2025-08-19 21:30:01'),(94,3,24,NULL,1.00,1,'2025-08-19 21:30:01'),(95,2,24,NULL,1.00,1,'2025-08-19 21:30:01'),(96,1,24,NULL,1.00,1,'2025-08-19 21:30:01'),(97,4,25,NULL,1.00,1,'2025-08-19 21:30:01'),(98,3,25,NULL,1.00,1,'2025-08-19 21:30:01'),(99,2,25,NULL,1.00,1,'2025-08-19 21:30:01'),(100,1,25,NULL,1.00,1,'2025-08-19 21:30:01'),(101,4,26,NULL,1.00,1,'2025-08-19 21:30:01'),(102,3,26,NULL,1.00,1,'2025-08-19 21:30:01'),(103,2,26,NULL,1.00,1,'2025-08-19 21:30:01'),(104,1,26,NULL,1.00,1,'2025-08-19 21:30:01'),(105,4,27,NULL,1.00,1,'2025-08-19 21:30:01'),(106,3,27,NULL,1.00,1,'2025-08-19 21:30:01'),(107,2,27,NULL,1.00,1,'2025-08-19 21:30:01'),(108,1,27,NULL,1.00,1,'2025-08-19 21:30:01'),(109,4,28,NULL,1.00,1,'2025-08-19 21:30:01'),(110,3,28,NULL,1.00,1,'2025-08-19 21:30:01'),(111,2,28,NULL,1.00,1,'2025-08-19 21:30:01'),(112,1,28,NULL,1.00,1,'2025-08-19 21:30:01'),(113,4,29,NULL,1.00,1,'2025-08-19 21:30:01'),(114,3,29,NULL,1.00,1,'2025-08-19 21:30:01'),(115,2,29,NULL,1.00,1,'2025-08-19 21:30:01'),(116,1,29,NULL,1.00,1,'2025-08-19 21:30:01'),(117,4,30,NULL,1.00,1,'2025-08-19 21:30:01'),(118,3,30,NULL,1.00,1,'2025-08-19 21:30:01'),(119,2,30,NULL,1.00,1,'2025-08-19 21:30:01'),(120,1,30,NULL,1.00,1,'2025-08-19 21:30:01'),(121,4,31,NULL,1.00,1,'2025-08-19 21:30:01'),(122,3,31,NULL,1.00,1,'2025-08-19 21:30:01'),(123,2,31,NULL,1.00,1,'2025-08-19 21:30:01'),(124,1,31,NULL,1.00,1,'2025-08-19 21:30:01'),(125,4,32,NULL,1.00,1,'2025-08-19 21:30:01'),(126,3,32,NULL,1.00,1,'2025-08-19 21:30:01'),(127,2,32,NULL,1.00,1,'2025-08-19 21:30:01'),(128,1,32,NULL,1.00,1,'2025-08-19 21:30:01'),(129,4,33,NULL,1.00,1,'2025-08-19 21:30:01'),(130,3,33,NULL,1.00,1,'2025-08-19 21:30:01'),(131,2,33,NULL,1.00,1,'2025-08-19 21:30:01'),(132,1,33,NULL,1.00,1,'2025-08-19 21:30:01'),(133,4,34,NULL,1.00,1,'2025-08-19 21:30:01'),(134,3,34,NULL,1.00,1,'2025-08-19 21:30:01'),(135,2,34,NULL,1.00,1,'2025-08-19 21:30:01'),(136,1,34,NULL,1.00,1,'2025-08-19 21:30:01'),(137,4,35,NULL,1.00,1,'2025-08-19 21:30:01'),(138,3,35,NULL,1.00,1,'2025-08-19 21:30:01'),(139,2,35,NULL,1.00,1,'2025-08-19 21:30:01'),(140,1,35,NULL,1.00,1,'2025-08-19 21:30:01'),(141,4,36,NULL,1.00,1,'2025-08-19 21:30:01'),(142,3,36,NULL,1.00,1,'2025-08-19 21:30:01'),(143,2,36,NULL,1.00,1,'2025-08-19 21:30:01'),(144,1,36,NULL,1.00,1,'2025-08-19 21:30:01'),(145,4,37,NULL,1.00,1,'2025-08-19 21:30:01'),(146,3,37,NULL,1.00,1,'2025-08-19 21:30:01'),(147,2,37,NULL,1.00,1,'2025-08-19 21:30:01'),(148,1,37,NULL,1.00,1,'2025-08-19 21:30:01'),(149,4,38,NULL,1.00,1,'2025-08-19 21:30:01'),(150,3,38,NULL,1.00,1,'2025-08-19 21:30:01'),(151,2,38,NULL,1.00,1,'2025-08-19 21:30:01'),(152,1,38,NULL,1.00,1,'2025-08-19 21:30:01'),(153,4,39,NULL,1.00,1,'2025-08-19 21:30:01'),(154,3,39,NULL,1.00,1,'2025-08-19 21:30:01'),(155,2,39,NULL,1.00,1,'2025-08-19 21:30:01'),(156,1,39,NULL,1.00,1,'2025-08-19 21:30:01'),(157,4,40,NULL,1.00,1,'2025-08-19 21:30:01'),(158,3,40,NULL,1.00,1,'2025-08-19 21:30:01'),(159,2,40,NULL,1.00,1,'2025-08-19 21:30:01'),(160,1,40,NULL,1.00,1,'2025-08-19 21:30:01'),(161,4,41,NULL,1.00,1,'2025-08-19 21:30:01'),(162,3,41,NULL,1.00,1,'2025-08-19 21:30:01'),(163,2,41,NULL,1.00,1,'2025-08-19 21:30:01'),(164,1,41,NULL,1.00,1,'2025-08-19 21:30:01'),(165,4,42,NULL,1.00,1,'2025-08-19 21:30:01'),(166,3,42,NULL,1.00,1,'2025-08-19 21:30:01'),(167,2,42,NULL,1.00,1,'2025-08-19 21:30:01'),(168,1,42,NULL,1.00,1,'2025-08-19 21:30:01'),(169,4,43,NULL,1.00,1,'2025-08-19 21:30:01'),(170,3,43,NULL,1.00,1,'2025-08-19 21:30:01'),(171,2,43,NULL,1.00,1,'2025-08-19 21:30:01'),(172,1,43,NULL,1.00,1,'2025-08-19 21:30:01'),(173,4,44,NULL,1.00,1,'2025-08-19 21:30:01'),(174,3,44,NULL,1.00,1,'2025-08-19 21:30:01'),(175,2,44,NULL,1.00,1,'2025-08-19 21:30:01'),(176,1,44,NULL,1.00,1,'2025-08-19 21:30:01'),(177,4,45,NULL,1.00,1,'2025-08-19 21:30:01'),(178,3,45,NULL,1.00,1,'2025-08-19 21:30:01'),(179,2,45,NULL,1.00,1,'2025-08-19 21:30:01'),(180,1,45,NULL,1.00,1,'2025-08-19 21:30:01'),(181,4,46,NULL,1.00,1,'2025-08-19 21:30:01'),(182,3,46,NULL,1.00,1,'2025-08-19 21:30:01'),(183,2,46,NULL,1.00,1,'2025-08-19 21:30:01'),(184,1,46,NULL,1.00,1,'2025-08-19 21:30:01'),(185,4,47,NULL,1.00,1,'2025-08-19 21:30:01'),(186,3,47,NULL,1.00,1,'2025-08-19 21:30:01'),(187,2,47,NULL,1.00,1,'2025-08-19 21:30:01'),(188,1,47,NULL,1.00,1,'2025-08-19 21:30:01'),(189,4,48,NULL,1.00,1,'2025-08-19 21:30:01'),(190,3,48,NULL,1.00,1,'2025-08-19 21:30:01'),(191,2,48,NULL,1.00,1,'2025-08-19 21:30:01'),(192,1,48,NULL,1.00,1,'2025-08-19 21:30:01'),(193,4,49,NULL,1.00,1,'2025-08-19 21:30:01'),(194,3,49,NULL,1.00,1,'2025-08-19 21:30:01'),(195,2,49,NULL,1.00,1,'2025-08-19 21:30:01'),(196,1,49,NULL,1.00,1,'2025-08-19 21:30:01'),(197,4,50,NULL,1.00,1,'2025-08-19 21:30:01'),(198,3,50,NULL,1.00,1,'2025-08-19 21:30:01'),(199,2,50,NULL,1.00,1,'2025-08-19 21:30:01'),(200,1,50,NULL,1.00,1,'2025-08-19 21:30:01'),(201,4,51,NULL,1.00,1,'2025-08-19 21:30:01'),(202,3,51,NULL,1.00,1,'2025-08-19 21:30:01'),(203,2,51,NULL,1.00,1,'2025-08-19 21:30:01'),(204,1,51,NULL,1.00,1,'2025-08-19 21:30:01');
/*!40000 ALTER TABLE items_evaluacion_establecimiento ENABLE KEYS */;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plan_semanal`
--

/*!40000 ALTER TABLE plan_semanal DISABLE KEYS */;
/*!40000 ALTER TABLE plan_semanal ENABLE KEYS */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS roles;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE roles (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci,
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
INSERT INTO roles VALUES
(1,'Inspector','Personal encargado de realizar las inspecciones sanitarias','{\"informes\": {\"ver_todos\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"ver_todos\": true}}','2025-08-19 21:30:01'),
(2,'Encargado','Personal responsable del establecimiento','{\"informes\": {\"ver_propios\": true}, \"inspecciones\": {\"firmar\": true, \"ver_propias\": true}}','2025-08-19 21:30:01'),
(3,'Administrador','Administrador del sistema con acceso total','{\"informes\": {\"ver_todos\": true}, \"usuarios\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"cambiar_roles\": true}, \"inspecciones\": {\"crear\": true, \"editar\": true, \"eliminar\": true, \"ver_todos\": true}, \"establecimientos\": {\"crear\": true, \"editar\": true, \"eliminar\": true}}','2025-08-19 21:30:01'),
(4,'Jefe de Establecimiento','Jefe que supervisa y controla todo un establecimiento específico','{\"establecimientos\": {\"ver_propio\": true, \"editar_propio\": true, \"gestionar_encargados\": true}, \"encargados\": {\"habilitar\": true, \"deshabilitar\": true, \"cargar_firmas\": true, \"ver_todos_establecimiento\": true}, \"inspecciones\": {\"ver_establecimiento\": true, \"supervisar\": true}, \"firmas\": {\"cargar_encargados\": true, \"validar\": true}}','2025-08-28 21:30:01');
/*!40000 ALTER TABLE roles ENABLE KEYS */;

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
  comentario varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  activo tinyint(1) DEFAULT '1',
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY establecimiento_id (establecimiento_id),
  KEY idx_jefe_establecimiento_fecha (establecimiento_id,fecha_inicio,fecha_fin),
  KEY idx_jefe_activo (activo),
  CONSTRAINT jefes_establecimientos_ibfk_1 FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT jefes_establecimientos_ibfk_2 FOREIGN KEY (establecimiento_id) REFERENCES establecimientos (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jefes_establecimientos`
--

/*!40000 ALTER TABLE jefes_establecimientos DISABLE KEYS */;
INSERT INTO jefes_establecimientos VALUES
(1,7,1,'2025-08-28',NULL,1,'Jefe principal del establecimiento Déjà vu',1,'2025-08-28 21:30:01'),
(2,8,2,'2025-08-28',NULL,1,'Jefe principal del establecimiento Silvia',1,'2025-08-28 21:30:01'),
(3,9,3,'2025-08-28',NULL,1,'Jefe principal del establecimiento Náutica',1,'2025-08-28 21:30:01');
/*!40000 ALTER TABLE jefes_establecimientos ENABLE KEYS */;

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
  path_firma VARCHAR(250),
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
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `firmas_encargados_por_jefe`
--

/*!40000 ALTER TABLE firmas_encargados_por_jefe DISABLE KEYS */;
/*!40000 ALTER TABLE firmas_encargados_por_jefe ENABLE KEYS */;

--
-- Table structure for table `tipos_establecimiento`
--

DROP TABLE IF EXISTS tipos_establecimiento;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE tipos_establecimiento (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  descripcion text COLLATE utf8mb4_general_ci,
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
INSERT INTO tipos_establecimiento VALUES
(1,'Restaurante','Establecimiento de servicio de alimentos y bebidas',1,'2025-08-19 21:30:01'),
(2,'Cafetería','Establecimiento especializado en café y aperitivos',1,'2025-08-19 21:30:01'),
(3,'Bar','Establecimiento especializado en bebidas',1,'2025-08-19 21:30:01'),
(4,'Food Court','Área común de diversos establecimientos de comida',1,'2025-08-19 21:30:01');
/*!40000 ALTER TABLE tipos_establecimiento ENABLE KEYS */;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS usuarios;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE usuarios (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  apellido varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  correo varchar(150) COLLATE utf8mb4_general_ci NOT NULL,
  contrasena varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  rol_id int NOT NULL,
  activo tinyint(1) NOT NULL DEFAULT '1',
  en_linea tinyint(1) NOT NULL DEFAULT '0',
  ultimo_acceso timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  telefono varchar(30) COLLATE utf8mb4_general_ci DEFAULT NULL,
  dni varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  ruta_firma varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  fecha_creacion timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY correo (correo),
  KEY idx_usuarios_correo (correo),
  KEY idx_usuarios_dni (dni),
  KEY idx_usuarios_rol (rol_id),
  CONSTRAINT usuarios_ibfk_1 FOREIGN KEY (rol_id) REFERENCES roles (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

/*!40000 ALTER TABLE usuarios DISABLE KEYS */;
INSERT INTO usuarios VALUES
(1,'Jesus','Isique','desarrollo@castillodechancay.com','$2b$12$C58u.bPb.cR45jpC9QxLf.i05oucxUGq/XABKPCL2X.N5jOVkd7Sq',1,1,1,'2025-08-22 22:11:19','987654321','45678912',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-22 22:11:19'),
(2,'Jhon','Doe','jhondoe@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',2,1,0,'2025-08-22 21:23:12','987654322','12345678',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-22 21:25:34'),
(3,'María','García','maria.garcia@example.com','$2b$12$LfnXh.QTjJW1rjw16I1Nse2wLZRGQw6ZVXegdPAoLhxeW12yDymTu',2,1,0,'2025-08-19 21:30:01','987654323','87654321',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-19 21:30:01'),
(4,'Carlos','López','carlos.lopez@example.com','$2b$12$G6AjqJNIRp5CaNwOH3ZN9OhLqMOPSXdhzFR.bIawHhI8UqohZH40m',2,1,0,'2025-08-19 21:30:01','987654324','45678913',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-19 21:30:01'),
(5,'Ana','Martínez','ana.martinez@example.com','$2b$12$4rxq9BvEThorOft1eMRSQe.DDpK3gIFX/rXZ/feJZ/hgXiz6PnrC.',2,1,0,'2025-08-19 21:30:01','987654325','78912345',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-19 21:30:01'),
(6,'Admin','Sistema','estadistica@castillodechancay.com','$2b$12$jeZG0C.IXQsL/zmrvCS/4OBnfPIHDdDQs2KrdqUWVUqPnXPdTeyte',3,1,0,'2025-08-19 21:30:01','987654326','11111111',NULL,'2025-08-19 21:30:01','2025-08-19 21:30:01','2025-08-19 21:30:01'),
(7,'Roberto','Fernández','jefe.dejavu@chancay.com','$2b$12$FxkEfG4AX4a8QWZq6BbNr./5q6IsOWnngWl24Q8NNxxCSVamENcpa',4,1,0,'2025-08-28 21:30:01','987654327','55555555',NULL,'2025-08-28 21:30:01','2025-08-28 21:30:01','2025-08-28 21:30:01'),
(8,'Patricia','Morales','jefe.silvia@chancay.com','$2b$12$EjtmpMwAROy73Df9CYRdyejducZpGhhPgpbvVyLTES6IIqLOUmy9y',4,1,0,'2025-08-28 21:30:01','987654328','66666666',NULL,'2025-08-28 21:30:01','2025-08-28 21:30:01','2025-08-28 21:30:01'),
(9,'Miguel','Herrera','jefe.nautica@chancay.com','$2b$12$w6a5mjIqjy7Nzi8lLYFSfeuu7ArtK2Xdv/EJ9zZytM3tgd3LUY/my',4,1,0,'2025-08-28 21:30:01','987654329','77777777',NULL,'2025-08-28 21:30:01','2025-08-28 21:30:01','2025-08-28 21:30:01');
/*!40000 ALTER TABLE usuarios ENABLE KEYS */;

--
-- Dumping events for database 'alimentosybebidas'
--

--
-- Dumping routines for database 'alimentosybebidas'
--
/*!50003 DROP PROCEDURE IF EXISTS sp_calcular_puntajes_inspeccion */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_calcular_puntajes_inspeccion(
    IN p_inspeccion_id INT
)
BEGIN
    DECLARE v_puntaje_total DECIMAL(6,2) DEFAULT 0;
    DECLARE v_puntaje_maximo_posible DECIMAL(6,2) DEFAULT 0;
    DECLARE v_puntos_criticos_perdidos INT DEFAULT 0;
    DECLARE v_porcentaje DECIMAL(5,2) DEFAULT 0;
    
    -- Calcular puntajes
    SELECT 
        COALESCE(SUM(id.score), 0),
        COALESCE(SUM(ROUND(ibe.puntaje_maximo * iee.factor_ajuste)), 0), -- Usando puntaje_maximo de base con factor
        COALESCE(SUM(
            CASE 
                WHEN ibe.riesgo = 'Crítico' AND id.score < ROUND(ibe.puntaje_maximo * iee.factor_ajuste)
                THEN (ROUND(ibe.puntaje_maximo * iee.factor_ajuste) - COALESCE(id.score, 0))
                ELSE 0 
            END
        ), 0)
    INTO v_puntaje_total, v_puntaje_maximo_posible, v_puntos_criticos_perdidos
    FROM inspeccion_detalles id
    INNER JOIN items_evaluacion_establecimiento iee ON id.item_establecimiento_id = iee.id
    INNER JOIN items_evaluacion_base ibe ON iee.item_base_id = ibe.id
    WHERE id.inspeccion_id = p_inspeccion_id;
    
    -- Calcular porcentaje
    IF v_puntaje_maximo_posible > 0 THEN
        SET v_porcentaje = (v_puntaje_total * 100) / v_puntaje_maximo_posible;
    END IF;
    
    -- Actualizar inspección
    UPDATE inspecciones 
    SET 
        puntaje_total = v_puntaje_total,
        puntaje_maximo_posible = v_puntaje_maximo_posible,
        porcentaje_cumplimiento = v_porcentaje,
        puntos_criticos_perdidos = v_puntos_criticos_perdidos
    WHERE id = p_inspeccion_id;
    
    -- Retornar los valores calculados
    SELECT v_puntaje_total as puntaje_total, 
           v_puntaje_maximo_posible as puntaje_maximo_posible,
           v_porcentaje as porcentaje_cumplimiento,
           v_puntos_criticos_perdidos as puntos_criticos_perdidos;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_crear_items_defecto_establecimiento */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_crear_items_defecto_establecimiento(
    IN p_establecimiento_id INT
)
BEGIN
    INSERT INTO items_evaluacion_establecimiento 
        (establecimiento_id, item_base_id, factor_ajuste)
    SELECT 
        p_establecimiento_id,
        ibe.id,
        1.00 -- Factor de ajuste por defecto
    FROM items_evaluacion_base ibe
    WHERE ibe.activo = TRUE
        AND NOT EXISTS (
            SELECT 1 FROM items_evaluacion_establecimiento iee 
            WHERE iee.establecimiento_id = p_establecimiento_id 
                AND iee.item_base_id = ibe.id
        );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_filtrar_inspecciones */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_filtrar_inspecciones(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_establecimiento_id INT,
    IN p_inspector_id INT,
    IN p_encargado_id INT,
    IN p_estado VARCHAR(20)
)
BEGIN
    SELECT 
        i.id,
        i.fecha,
        i.hora_inicio,
        i.hora_fin,
        i.puntaje_total,
        i.puntaje_maximo_posible,
        i.porcentaje_cumplimiento,
        i.estado,
        
        -- Establecimiento
        e.nombre as establecimiento_nombre,
        
        -- Inspector
        ui.nombre as inspector_nombre,
        ui.apellido as inspector_apellido,
        
        -- Encargado
        ue.nombre as encargado_nombre,
        ue.apellido as encargado_apellido,
        
        -- Conteo de evidencias
        (SELECT COUNT(*) FROM evidencias_inspeccion ei WHERE ei.inspeccion_id = i.id) as total_evidencias
        
    FROM inspecciones i
    INNER JOIN establecimientos e ON i.establecimiento_id = e.id
    INNER JOIN usuarios ui ON i.inspector_id = ui.id
    LEFT JOIN usuarios ue ON i.encargado_id = ue.id
    WHERE 1=1
        AND (p_fecha_inicio IS NULL OR i.fecha >= p_fecha_inicio)
        AND (p_fecha_fin IS NULL OR i.fecha <= p_fecha_fin)
        AND (p_establecimiento_id IS NULL OR i.establecimiento_id = p_establecimiento_id)
        AND (p_inspector_id IS NULL OR i.inspector_id = p_inspector_id)
        AND (p_encargado_id IS NULL OR i.encargado_id = p_encargado_id)
        AND (p_estado IS NULL OR i.estado = p_estado)
    ORDER BY i.fecha DESC, i.created_at DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_obtener_encargado_por_fecha */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_obtener_encargado_por_fecha(
    IN p_establecimiento_id INT,
    IN p_fecha DATE
)
BEGIN
    SELECT 
        u.id as usuario_id,
        u.nombre,
        u.apellido,
        u.correo,
        u.telefono,
        u.dni,
        u.ruta_firma,
        ee.es_principal
    FROM usuarios u
    INNER JOIN encargados_establecimientos ee ON u.id = ee.usuario_id
    WHERE ee.establecimiento_id = p_establecimiento_id
        AND ee.activo = TRUE
        AND p_fecha >= ee.fecha_inicio
        AND (ee.fecha_fin IS NULL OR p_fecha <= ee.fecha_fin)
    ORDER BY ee.es_principal DESC, ee.fecha_inicio DESC
    LIMIT 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_obtener_inspeccion_completa */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_obtener_inspeccion_completa(
    IN p_inspeccion_id INT
)
BEGIN
    -- Información básica de la inspección
    SELECT 
        i.id,
        i.fecha,
        i.hora_inicio,
        i.hora_fin,
        i.observaciones, -- UNA SOLA OBSERVACIÓN
        i.puntaje_total,
        i.puntaje_maximo_posible,
        i.porcentaje_cumplimiento,
        i.puntos_criticos_perdidos,
        i.estado,
        i.firma_inspector,
        i.firma_encargado,
        i.fecha_firma_inspector,
        i.fecha_firma_encargado,
        
        -- Datos del establecimiento
        e.nombre as establecimiento_nombre,
        e.direccion as establecimiento_direccion,
        te.nombre as tipo_establecimiento,
        
        -- Datos del inspector
        ui.nombre as inspector_nombre,
        ui.apellido as inspector_apellido,
        ui.correo as inspector_correo,
        ui.ruta_firma as inspector_firma_default,
        
        -- Datos del encargado
        ue.nombre as encargado_nombre,
        ue.apellido as encargado_apellido,
        ue.correo as encargado_correo,
        ue.telefono as encargado_telefono,
        ue.ruta_firma as encargado_firma_default
        
    FROM inspecciones i
    INNER JOIN establecimientos e ON i.establecimiento_id = e.id
    LEFT JOIN tipos_establecimiento te ON e.tipo_establecimiento_id = te.id
    INNER JOIN usuarios ui ON i.inspector_id = ui.id
    LEFT JOIN usuarios ue ON i.encargado_id = ue.id
    WHERE i.id = p_inspeccion_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_obtener_inspectores_establecimiento */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_obtener_inspectores_establecimiento(
    IN p_establecimiento_id INT,
    IN p_fecha DATE
)
BEGIN
    SELECT 
        u.id as usuario_id,
        u.nombre,
        u.apellido,
        u.correo,
        u.telefono,
        u.dni,
        ie.es_principal,
        ie.fecha_asignacion
    FROM usuarios u
    INNER JOIN inspector_establecimientos ie ON u.id = ie.inspector_id
    WHERE ie.establecimiento_id = p_establecimiento_id
        AND ie.activo = TRUE
        AND p_fecha >= ie.fecha_asignacion
        AND (ie.fecha_fin_asignacion IS NULL OR p_fecha <= ie.fecha_fin_asignacion)
        AND u.rol_id = 1 -- Solo inspectores
    ORDER BY ie.es_principal DESC, ie.fecha_asignacion DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_obtener_items_establecimiento */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_obtener_items_establecimiento(
    IN p_establecimiento_id INT
)
BEGIN
    SELECT 
        iee.id as item_establecimiento_id,
        ibe.id as item_base_id,
        ce.id as categoria_id,
        ce.nombre as categoria_nombre,
        ce.orden as categoria_orden,
        ibe.codigo,
        COALESCE(iee.descripcion_personalizada, ibe.descripcion) as descripcion,
        ibe.riesgo,
        ibe.puntaje_minimo, -- Tomado de items_evaluacion_base
        ROUND(ibe.puntaje_maximo * iee.factor_ajuste) as puntaje_maximo, -- Aplicando factor de ajuste
        ibe.orden as item_orden,
        iee.factor_ajuste
    FROM items_evaluacion_establecimiento iee
    INNER JOIN items_evaluacion_base ibe ON iee.item_base_id = ibe.id
    INNER JOIN categorias_evaluacion ce ON ibe.categoria_id = ce.id
    WHERE iee.establecimiento_id = p_establecimiento_id
        AND iee.activo = TRUE
        AND ibe.activo = TRUE
        AND ce.activo = TRUE
    ORDER BY ce.orden, ibe.orden;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS sp_obtener_plan_semanal_actual */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=root@localhost PROCEDURE sp_obtener_plan_semanal_actual(
    IN p_semana INT,
    IN p_ano INT
)
BEGIN
    -- Crear registros faltantes para establecimientos activos
    INSERT IGNORE INTO plan_semanal (establecimiento_id, semana, ano)
    SELECT e.id, p_semana, p_ano
    FROM establecimientos e
    WHERE e.activo = TRUE;
    
    -- Actualizar conteos reales
    UPDATE plan_semanal ps
    SET evaluaciones_realizadas = (
        SELECT COUNT(*)
        FROM inspecciones i
        WHERE i.establecimiento_id = ps.establecimiento_id
            AND YEAR(i.fecha) = p_ano
            AND WEEK(i.fecha, 1) = p_semana
            AND i.estado = 'completada'
    )
    WHERE ps.semana = p_semana AND ps.ano = p_ano;
    
    -- Retornar resultado
    SELECT 
        ps.id,
        e.nombre as establecimiento_nombre,
        ps.evaluaciones_meta,
        ps.evaluaciones_realizadas,
        CASE 
            WHEN ps.evaluaciones_realizadas >= ps.evaluaciones_meta THEN 'Completado'
            ELSE 'Pendiente'
        END as estado
    FROM plan_semanal ps
    INNER JOIN establecimientos e ON ps.establecimiento_id = e.id
    WHERE ps.semana = p_semana 
        AND ps.ano = p_ano
        AND e.activo = TRUE
    ORDER BY e.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

--
-- =====================================================
-- EXTENSIONES PARA JEFE DE ESTABLECIMIENTO
-- Fecha: 28 de agosto 2025
-- =====================================================

--
-- CREATE VIEW: VISTA_JERARQUIA_ESTABLECIMIENTO
--

CREATE VIEW vista_jerarquia_establecimiento AS
SELECT 
    e.id as establecimiento_id,
    e.nombre as establecimiento_nombre,
    
    -- Información del jefe
    uj.id as jefe_id,
    uj.nombre as jefe_nombre,
    uj.apellido as jefe_apellido,
    uj.correo as jefe_correo,
    je.fecha_inicio as jefe_fecha_inicio,
    je.activo as jefe_activo,
    
    -- Información del encargado activo
    ue.id as encargado_id,
    ue.nombre as encargado_nombre,
    ue.apellido as encargado_apellido,
    ue.correo as encargado_correo,
    ee.fecha_inicio as encargado_fecha_inicio,
    ee.activo as encargado_activo,
    ee.habilitado_por as encargado_habilitado_por_jefe_id,
    ee.fecha_habilitacion as encargado_fecha_habilitacion,
    
    -- Información de firmas
    (SELECT COUNT(*) FROM firmas_encargados_por_jefe f 
     WHERE f.establecimiento_id = e.id AND f.activa = 1) as total_firmas_activas

FROM establecimientos e
LEFT JOIN jefes_establecimientos je ON e.id = je.establecimiento_id AND je.activo = 1
LEFT JOIN usuarios uj ON je.usuario_id = uj.id
LEFT JOIN encargados_establecimientos ee ON e.id = ee.establecimiento_id AND ee.activo = 1  
LEFT JOIN usuarios ue ON ee.usuario_id = ue.id
WHERE e.activo = 1;

--
-- STORED PROCEDURES PARA GESTIÓN DE JEFES Y ENCARGADOS
--

DELIMITER ;;

-- Procedure para asignar jefe a establecimiento
DROP PROCEDURE IF EXISTS sp_asignar_jefe_establecimiento;;
CREATE PROCEDURE sp_asignar_jefe_establecimiento(
    IN p_usuario_id INT,
    IN p_establecimiento_id INT,
    IN p_comentario VARCHAR(255)
)
BEGIN
    DECLARE v_rol_id INT DEFAULT 0;
    DECLARE v_existe_jefe INT DEFAULT 0;
    
    -- Verificar que el usuario tenga rol de jefe
    SELECT rol_id INTO v_rol_id FROM usuarios WHERE id = p_usuario_id;
    
    IF v_rol_id != 4 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El usuario debe tener rol de Jefe de Establecimiento';
    END IF;
    
    -- Verificar si ya existe un jefe activo para el establecimiento
    SELECT COUNT(*) INTO v_existe_jefe 
    FROM jefes_establecimientos 
    WHERE establecimiento_id = p_establecimiento_id AND activo = 1;
    
    IF v_existe_jefe > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un jefe activo para este establecimiento';
    END IF;
    
    -- Insertar nuevo jefe
    INSERT INTO jefes_establecimientos 
    (usuario_id, establecimiento_id, fecha_inicio, comentario, activo)
    VALUES 
    (p_usuario_id, p_establecimiento_id, CURDATE(), p_comentario, 1);
    
    SELECT 'Jefe asignado exitosamente' as mensaje;
END;;

-- Procedure para habilitar/deshabilitar encargado
DROP PROCEDURE IF EXISTS sp_gestionar_encargado;;
CREATE PROCEDURE sp_gestionar_encargado(
    IN p_jefe_id INT,
    IN p_encargado_id INT,
    IN p_establecimiento_id INT,
    IN p_accion ENUM('habilitar', 'deshabilitar'),
    IN p_observaciones TEXT
)
BEGIN
    DECLARE v_es_jefe INT DEFAULT 0;
    
    -- Verificar que el usuario sea jefe del establecimiento
    SELECT COUNT(*) INTO v_es_jefe
    FROM jefes_establecimientos 
    WHERE usuario_id = p_jefe_id 
    AND establecimiento_id = p_establecimiento_id 
    AND activo = 1;
    
    IF v_es_jefe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Usuario no autorizado para gestionar encargados de este establecimiento';
    END IF;
    
    IF p_accion = 'habilitar' THEN
        -- Deshabilitar cualquier encargado activo primero
        UPDATE encargados_establecimientos 
        SET activo = 0 
        WHERE establecimiento_id = p_establecimiento_id AND activo = 1;
        
        -- Habilitar el nuevo encargado
        UPDATE encargados_establecimientos 
        SET activo = 1, 
            habilitado_por = p_jefe_id,
            fecha_habilitacion = CURRENT_TIMESTAMP,
            observaciones_jefe = p_observaciones
        WHERE usuario_id = p_encargado_id 
        AND establecimiento_id = p_establecimiento_id;
        
    ELSE -- deshabilitar
        UPDATE encargados_establecimientos 
        SET activo = 0,
            observaciones_jefe = p_observaciones
        WHERE usuario_id = p_encargado_id 
        AND establecimiento_id = p_establecimiento_id;
    END IF;
    
    SELECT CONCAT('Encargado ', p_accion, ' exitosamente') as mensaje;
END;;

DELIMITER ;

-- Dump completed on 2025-08-22 12:40:00
