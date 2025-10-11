CREATE DATABASE  IF NOT EXISTS `gestion_caja` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `gestion_caja`;
-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: gestion_caja
-- ------------------------------------------------------
-- Server version	8.0.43

-- Table structure for table `roles`
CREATE TABLE roles (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(50) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `roles`
INSERT INTO roles
  (id, nombre)
VALUES
  (1,'admin'),
  (2,'vendedor'),
  (3,'verificador'),
  (4,'contabilidad');


-- Table structure for table `empresas`
CREATE TABLE empresas (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `empresas`
INSERT INTO empresas
  (id, nombre)
VALUES
  (1,'RESORT');


-- Table structure for table `areas`
CREATE TABLE areas (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `areas`
INSERT INTO areas
  (id, nombre)
VALUES
  (1,'HOTEL'),
  (2,'GRUPOS CORPORATIVOS'),
  (3,'COMERCIAL');


-- Table structure for table `entidades_banco`
CREATE TABLE entidades_banco (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `entidades_banco`
INSERT INTO entidades_banco
  (id, nombre)
VALUES
  (1,'BCP'),
  (2,'BBVA'),
  (3,'Scotiabank'),
  (4,'Interbank'),
  (5,'PAGO LINK'),
  (6,'FALABELLA'),
  (7,'OTROS');


-- Table structure for table `medios_pago`
CREATE TABLE medios_pago (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `medios_pago`
INSERT INTO medios_pago
  (id, nombre)
VALUES
  (1,'EFECTIVO'),
  (2,'POS - YAPE'),
  (3,'TARJETA'),
  (4,'POS - PLIN'),
  (5,'PAGO LINK'),
  (6,'DEPOSITO'),
  (7,'TRANSFERENCIA'),
  (8,'OTROS');


-- Table structure for table `centros_costo`
CREATE TABLE centros_costo (
  id int NOT NULL AUTO_INCREMENT,
  nombre varchar(255) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `centros_costo`
INSERT INTO centros_costo
  (id, nombre)
VALUES
  (1,'Caja - Hotel'),
  (2,'Caja - Redes'),
  (3,'Caja - Comercial');


-- Table structure for table `usuarios`
CREATE TABLE usuarios (
  id varchar(100) NOT NULL,
  nombre varchar(255) NOT NULL,
  correo varchar(255) NOT NULL,
  contrasena varchar(255) NOT NULL,
  rol_id int NOT NULL,
  session_active tinyint(1) DEFAULT '0',
  activo tinyint(1) DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE KEY correo (correo),
  KEY rol_id (rol_id),
  CONSTRAINT usuarios_ibfk_1 FOREIGN KEY (rol_id) REFERENCES roles (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `usuarios`
INSERT INTO usuarios
  (id, nombre, correo, contrasena, rol_id, session_active, activo)
VALUES
  ('admin01','Alfredo Huaman','estadistica@castillodechancay.com','$2b$12$jeZG0C.IXQsL/zmrvCS/4OBnfPIHDdDQs2KrdqUWVUqPnXPdTeyte',1,0,1),
  ('cont01','Wendy','contabilidad@castillodechancay.com','$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO',4,0,1),
  ('SYSTEM','Sistema','sistema@castillodechancay.com','$2b$12$GF3wych4N14sa/WBzxyoH.MxcCD5ruIsFNVn2UUR73S.JK0ATLkZC',1,0,1),
  ('vend01','Sebastian Moran','ventas@castillodechancay.com','$2b$12$3yXJSC8hk9.yr46fsUdjs.IH4clkB1311UTgHzWMd.tX.iS1BuNJW',2,0,1),
  ('vend02','Estefany Aguirre','redes@castillodechancay.com','$2b$12$MiwMi8t.URMdCr3cdD9wceCtK5bnkUkkiGLxg/GP2GMWlt1NOXx6.',2,0,1),
  ('vend03','Elias Sanchez','ventas2@castillodechancay.com','$2b$12$VzyVakHHzTeaynbFsCkeaObdl29CceeV4FnTEg8hbFbBepNzQNENy',2,0,1),
  ('verif01','Ana Zavala','asistente.gerencia.lima@castillodechancay.com','$2b$12$vXn/LKmrYSyB50ex202nSuBvfATlroXWtLNMEEjXBZ5XhndTNDBi2',3,0,1),
  ('verif02','Yolanda Pacheco','gerenciacastillochancay@hotmail.com','$2b$12$k2yfxjtEGCqcZ3mriHfeUe7lLSHbfS6mOQRkDCwyC0khQ3uhd/G9.',3,0,1);


-- Table structure for table `registros_ventas`
CREATE TABLE registros_ventas (
  id int NOT NULL AUTO_INCREMENT,
  id_xafiro varchar(100) DEFAULT NULL,
  recibo varchar(100) DEFAULT NULL,
  medio_pago_id int DEFAULT NULL,
  entidad_banco_id int DEFAULT NULL,
  area_id int DEFAULT NULL,
  centro_costo_id int DEFAULT NULL,
  detalle text,
  empresa_id int DEFAULT NULL,
  monto decimal(10,2) DEFAULT NULL,
  confirmado tinyint(1) DEFAULT '0',
  fecha_registro_pago date DEFAULT NULL,
  fecha_comprobante datetime DEFAULT NULL,
  fecha_ingreso_cuenta date DEFAULT NULL,
  fecha_confirmacion_redes datetime DEFAULT NULL,
  fecha_confirmacion_gerencia datetime DEFAULT NULL,
  confirmado_redes tinyint(1) DEFAULT '0',
  vendedor_id varchar(100) DEFAULT NULL,
  confirmador_voucher varchar(100) DEFAULT NULL,
  confirmador_cuenta varchar(100) DEFAULT NULL,
  voucher_imagen_url varchar(500) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY recibo (recibo),
  KEY empresa_id (empresa_id),
  KEY area_id (area_id),
  KEY medio_pago_id (medio_pago_id),
  KEY entidad_banco_id (entidad_banco_id),
  KEY centro_costo_id (centro_costo_id),
  KEY confirmador_cuenta (confirmador_cuenta),
  KEY confirmador_voucher (confirmador_voucher),
  CONSTRAINT registros_ventas_ibfk_1 FOREIGN KEY (empresa_id) REFERENCES empresas (id),
  CONSTRAINT registros_ventas_ibfk_2 FOREIGN KEY (area_id) REFERENCES areas (id),
  CONSTRAINT registros_ventas_ibfk_3 FOREIGN KEY (medio_pago_id) REFERENCES medios_pago (id),
  CONSTRAINT registros_ventas_ibfk_4 FOREIGN KEY (entidad_banco_id) REFERENCES entidades_banco (id),
  CONSTRAINT registros_ventas_ibfk_5 FOREIGN KEY (centro_costo_id) REFERENCES centros_costo (id),
  CONSTRAINT registros_ventas_ibfk_6 FOREIGN KEY (confirmador_cuenta) REFERENCES usuarios (id),
  CONSTRAINT registros_ventas_ibfk_7 FOREIGN KEY (confirmador_voucher) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Table structure for table `auditoria_registros_ventas`
CREATE TABLE auditoria_registros_ventas (
  id int NOT NULL AUTO_INCREMENT,
  registro_venta_id int NOT NULL,
  usuario_id varchar(100) NOT NULL,
  accion enum('INSERT','UPDATE','DELETE') NOT NULL,
  campo_modificado varchar(100) DEFAULT NULL,
  valor_anterior text,
  valor_nuevo text,
  fecha_cambio datetime DEFAULT CURRENT_TIMESTAMP,
  motivo_cambio text,
  ip_usuario varchar(45) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY usuario_id (usuario_id),
  KEY idx_registro_fecha (registro_venta_id,fecha_cambio),
  CONSTRAINT auditoria_registros_ventas_ibfk_1 FOREIGN KEY (registro_venta_id) REFERENCES registros_ventas (id),
  CONSTRAINT auditoria_registros_ventas_ibfk_2 FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Table structure for table `conversaciones`
CREATE TABLE conversaciones (
  id int NOT NULL AUTO_INCREMENT,
  titulo varchar(255) NOT NULL,
  tipo enum('directo','grupo') DEFAULT 'directo',
  registro_venta_id int DEFAULT NULL,
  creado_por varchar(100) NOT NULL,
  fecha_creacion datetime DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  activo tinyint(1) DEFAULT '1',
  PRIMARY KEY (id),
  KEY creado_por (creado_por),
  KEY idx_conversaciones_registro (registro_venta_id),
  KEY idx_conversaciones_activo (activo),
  CONSTRAINT conversaciones_ibfk_1 FOREIGN KEY (registro_venta_id) REFERENCES registros_ventas (id) ON DELETE CASCADE,
  CONSTRAINT conversaciones_ibfk_2 FOREIGN KEY (creado_por) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `conversaciones`
INSERT INTO conversaciones
  (id, titulo, tipo, registro_venta_id, creado_por, fecha_creacion, fecha_actualizacion, activo)
VALUES
  (1,'Pendientes','grupo',NULL,'verif01','2025-01-01 00:00:00','2025-01-01 00:00:00',1);


-- Table structure for table `participantes_conversacion`
CREATE TABLE participantes_conversacion (
  id int NOT NULL AUTO_INCREMENT,
  conversacion_id int NOT NULL,
  usuario_id varchar(100) NOT NULL,
  fecha_union datetime DEFAULT CURRENT_TIMESTAMP,
  activo tinyint(1) DEFAULT '1',
  PRIMARY KEY (id),
  UNIQUE KEY unique_participante (conversacion_id,usuario_id),
  KEY idx_participantes_usuario (usuario_id),
  KEY idx_participantes_activo (activo),
  CONSTRAINT participantes_conversacion_ibfk_1 FOREIGN KEY (conversacion_id) REFERENCES conversaciones (id) ON DELETE CASCADE,
  CONSTRAINT participantes_conversacion_ibfk_2 FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Dumping data for table `participantes_conversacion`
INSERT INTO participantes_conversacion
  (id, conversacion_id, usuario_id, fecha_union, activo)
VALUES
(1,1,'SYSTEM','2025-01-01 00:00:00',1),
(2,1,'vend02','2025-01-01 00:00:00',1),
(3,1,'verif02','2025-01-01 00:00:00',1),
(4,1,'verif01','2025-01-01 00:00:00',1),
(5,1,'cont01','2025-01-01 00:00:00',1),
(6,1,'vend01','2025-01-01 00:00:00',1),
(7,1,'vend03','2025-01-01 00:00:00',1);



-- Table structure for table `mensajes`
CREATE TABLE mensajes (
  id int NOT NULL AUTO_INCREMENT,
  conversacion_id int NOT NULL,
  remitente_id varchar(100) NOT NULL,
  contenido text NOT NULL,
  tipo enum('texto','imagen','archivo') DEFAULT 'texto',
  url_archivo varchar(500) DEFAULT NULL,
  fecha_envio datetime DEFAULT CURRENT_TIMESTAMP,
  leido tinyint(1) DEFAULT '0',
  fecha_lectura datetime DEFAULT NULL,
  PRIMARY KEY (id),
  KEY remitente_id (remitente_id),
  KEY idx_mensajes_conversacion (conversacion_id),
  KEY idx_mensajes_fecha (fecha_envio),
  CONSTRAINT mensajes_ibfk_1 FOREIGN KEY (conversacion_id) REFERENCES conversaciones (id) ON DELETE CASCADE,
  CONSTRAINT mensajes_ibfk_2 FOREIGN KEY (remitente_id) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table structure for table `mensajes_leidos`
CREATE TABLE mensajes_leidos (
  id int NOT NULL AUTO_INCREMENT,
  mensaje_id int NOT NULL,
  usuario_id varchar(100) NOT NULL,
  fecha_lectura datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY unique_lectura (mensaje_id,usuario_id),
  KEY usuario_id (usuario_id),
  CONSTRAINT mensajes_leidos_ibfk_1 FOREIGN KEY (mensaje_id) REFERENCES mensajes (id) ON DELETE CASCADE,
  CONSTRAINT mensajes_leidos_ibfk_2 FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- Variables de sesión para el contexto de auditoría, mira esto lo agrego para setear estas variables en un inicio
SET @current_user_id = NULL;
SET @change_reason   = NULL;
SET @user_ip         = NULL;

-- TRIGGERS PARA AUDITORÍA AUTOMÁTICA
DELIMITER $$

-- TRIGGER PARA el INSERT
CREATE TRIGGER tr_registros_ventas_insert
AFTER INSERT ON registros_ventas
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_registros_ventas (
        registro_venta_id, usuario_id, accion, campo_modificado,
        valor_anterior, valor_nuevo, motivo_cambio, ip_usuario
    ) VALUES (
        NEW.id,
        COALESCE(@current_user_id, 'SYSTEM'),
        'INSERT',
        'REGISTRO_COMPLETO',
        NULL,
        CONCAT('recibo:', IFNULL(NEW.recibo, 'NULL'),
               '; monto:', IFNULL(NEW.monto, 'NULL'),
               '; empresa_id:', IFNULL(NEW.empresa_id, 'NULL')),
        @change_reason,
        @user_ip
    );
END$$


-- TRIGGER PARA el UPDATE

CREATE TRIGGER tr_registros_ventas_update 
AFTER UPDATE ON registros_ventas
FOR EACH ROW
BEGIN
    -- Helper para comparar NULL-safe: NOT (OLD <=> NEW) detecta cambios incluyendo NULL
    -- recibo
    IF NOT (OLD.recibo <=> NEW.recibo) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'recibo', OLD.recibo, NEW.recibo, @change_reason, @user_ip);
    END IF;

    -- monto
    IF NOT (OLD.monto <=> NEW.monto) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'monto', OLD.monto, NEW.monto, @change_reason, @user_ip);
    END IF;

    -- fecha_comprobante
    IF NOT (OLD.fecha_comprobante <=> NEW.fecha_comprobante) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'fecha_comprobante', OLD.fecha_comprobante, NEW.fecha_comprobante, @change_reason, @user_ip);
    END IF;

    -- fecha_ingreso_cuenta
    IF NOT (OLD.fecha_ingreso_cuenta <=> NEW.fecha_ingreso_cuenta) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'fecha_ingreso_cuenta', OLD.fecha_ingreso_cuenta, NEW.fecha_ingreso_cuenta, @change_reason, @user_ip);
    END IF;

    -- confirmado_redes
    IF NOT (OLD.confirmado_redes <=> NEW.confirmado_redes) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'confirmado_redes', OLD.confirmado_redes, NEW.confirmado_redes, @change_reason, @user_ip);
    END IF;

    -- confirmado (gerencia)
    IF NOT (OLD.confirmado <=> NEW.confirmado) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'confirmado', OLD.confirmado, NEW.confirmado, @change_reason, @user_ip);
    END IF;

    -- confirmador_voucher (antes: confirmador_voucher)
    IF NOT (OLD.confirmador_voucher <=> NEW.confirmador_voucher) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'confirmador_voucher', OLD.confirmador_voucher, NEW.confirmador_voucher, @change_reason, @user_ip);
    END IF;

    -- confirmador_cuenta (antes: confirmador_cuenta)
    IF NOT (OLD.confirmador_cuenta <=> NEW.confirmador_cuenta) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'confirmador_cuenta', OLD.confirmador_cuenta, NEW.confirmador_cuenta, @change_reason, @user_ip);
    END IF;

    -- detalle
    IF NOT (OLD.detalle <=> NEW.detalle) THEN
        INSERT INTO auditoria_registros_ventas
        (registro_venta_id, usuario_id, accion, campo_modificado, valor_anterior, valor_nuevo, motivo_cambio, ip_usuario)
        VALUES (NEW.id, COALESCE(@current_user_id, 'SYSTEM'), 'UPDATE', 'detalle', OLD.detalle, NEW.detalle, @change_reason, @user_ip);
    END IF;

END$$

-- TRIGGER PARA DELETE
CREATE TRIGGER tr_registros_ventas_delete 
BEFORE DELETE ON registros_ventas
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_registros_ventas (
        registro_venta_id, usuario_id, accion, campo_modificado,
        valor_anterior, valor_nuevo, motivo_cambio, ip_usuario
    ) VALUES (
        OLD.id,
        COALESCE(@current_user_id, 'SYSTEM'),
        'DELETE',
        'REGISTRO_COMPLETO',
        CONCAT('recibo:', IFNULL(OLD.recibo, 'NULL'),
               '; monto:', IFNULL(OLD.monto, 'NULL'),
               '; empresa_id:', IFNULL(OLD.empresa_id, 'NULL')),
        NULL,
        @change_reason,
        @user_ip
    );
END$$

DELIMITER ;

-- store procedure para manejar el contexto de auditoría ( el seteo y la limpieza )
DELIMITER $$

CREATE PROCEDURE SetAuditContext(
    IN p_user_id VARCHAR(100),
    IN p_reason TEXT,
    IN p_ip VARCHAR(45)
)
BEGIN
    SET @current_user_id = p_user_id;
    SET @change_reason   = p_reason;
    SET @user_ip         = p_ip;
END$$

CREATE PROCEDURE ClearAuditContext()
BEGIN
    SET @current_user_id = NULL;
    SET @change_reason   = NULL;
    SET @user_ip         = NULL;
END$$

DELIMITER ;

-- Aquí te agrego una vista, nos servirá para ver la auditoría de forma más easy xd
CREATE OR REPLACE VIEW v_auditoria_registros AS
SELECT 
    a.id,
    a.registro_venta_id,
    r.recibo,
    u.nombre AS usuario_nombre,
    u.correo AS usuario_correo,
    a.accion,
    a.campo_modificado,
    a.valor_anterior,
    a.valor_nuevo,
    a.fecha_cambio,
    a.motivo_cambio,
    a.ip_usuario
FROM auditoria_registros_ventas a
LEFT JOIN registros_ventas r ON a.registro_venta_id = r.id
LEFT JOIN usuarios u ON a.usuario_id = u.id
ORDER BY a.fecha_cambio DESC;

-- Triggers para actualizar fecha de conversación cuando hay nuevo mensaje
DELIMITER $$

CREATE TRIGGER actualizar_fecha_conversacion
AFTER INSERT ON mensajes
FOR EACH ROW
BEGIN
    UPDATE conversaciones
    SET fecha_actualizacion = NEW.fecha_envio
    WHERE id = NEW.conversacion_id;
END$$

DELIMITER ;

-- Vista para obtener conversaciones con información de último mensaje
CREATE OR REPLACE VIEW v_conversaciones_usuario AS
SELECT
    c.id,
    c.titulo,
    c.tipo,
    c.registro_venta_id,
    c.fecha_creacion,
    c.fecha_actualizacion,
    c.activo,
    -- Información del último mensaje
    m.contenido as ultimo_mensaje,
    m.fecha_envio as fecha_ultimo_mensaje,
    u.nombre as nombre_remitente,
    -- Conteo de mensajes no leídos
    (SELECT COUNT(*)
     FROM mensajes m2
     LEFT JOIN mensajes_leidos ml ON m2.id = ml.mensaje_id AND ml.usuario_id = pc.usuario_id
     WHERE m2.conversacion_id = c.id
     AND ml.id IS NULL
     AND m2.remitente_id != pc.usuario_id) as mensajes_no_leidos
FROM conversaciones c
JOIN participantes_conversacion pc ON c.id = pc.conversacion_id
LEFT JOIN mensajes m ON c.id = m.conversacion_id
LEFT JOIN usuarios u ON m.remitente_id = u.id
WHERE pc.activo = 1
AND c.activo = 1
AND (m.id IS NULL OR m.id = (
    SELECT MAX(id) FROM mensajes WHERE conversacion_id = c.id
));

-- Vista para obtener mensajes con información del remitente
CREATE OR REPLACE VIEW v_mensajes_conversacion AS
SELECT
    m.id,
    m.conversacion_id,
    m.remitente_id,
    u.nombre as nombre_remitente,
    r.nombre as rol_remitente,
    m.contenido,
    m.tipo,
    m.url_archivo,
    m.fecha_envio,
    m.leido,
    m.fecha_lectura
FROM mensajes m
JOIN usuarios u ON m.remitente_id = u.id
JOIN roles r ON u.rol_id = r.id
ORDER BY m.fecha_envio ASC;