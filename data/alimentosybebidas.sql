-- =====================================================
-- BASE DE DATOS CORREGIDA SEGÚN PEDIDO.TXT
-- Sistema de Inspecciones de Alimentos y Bebidas
-- =====================================================

CREATE DATABASE IF NOT EXISTS alimentosybebidas
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_general_ci;
USE alimentosybebidas;

-- =====================================================
-- TABLA: roles
-- =====================================================
CREATE TABLE roles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  permisos JSON, -- Para almacenar permisos específicos del rol
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: usuarios (incluye inspectores, encargados y administradores)
-- =====================================================
CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100),
  correo VARCHAR(150) NOT NULL UNIQUE,
  contrasena VARCHAR(255) NOT NULL,
  rol_id INT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  en_linea BOOLEAN NOT NULL DEFAULT FALSE,
  ultimo_acceso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  telefono VARCHAR(30),
  dni VARCHAR(20),
  ruta_firma VARCHAR(500), -- ruta a la imagen de firma
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (rol_id) REFERENCES roles(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX idx_usuarios_correo (correo),
  INDEX idx_usuarios_dni (dni),
  INDEX idx_usuarios_rol (rol_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: tipos_establecimiento
-- =====================================================
CREATE TABLE tipos_establecimiento (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: establecimientos
-- =====================================================
CREATE TABLE establecimientos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tipo_establecimiento_id INT NULL,
  nombre VARCHAR(150) NOT NULL,
  direccion VARCHAR(255),
  telefono VARCHAR(30),
  correo VARCHAR(150),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (tipo_establecimiento_id) REFERENCES tipos_establecimiento(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  INDEX idx_establecimientos_activo (activo)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: inspector_establecimientos (NUEVA)
-- Para asignar inspectores a establecimientos específicos
-- =====================================================
CREATE TABLE inspector_establecimientos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  inspector_id INT NOT NULL,
  establecimiento_id INT NOT NULL,
  fecha_asignacion DATE NOT NULL,
  fecha_fin_asignacion DATE NULL,
  es_principal BOOLEAN DEFAULT FALSE,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (inspector_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  INDEX idx_inspector_establecimiento (inspector_id, establecimiento_id),
  INDEX idx_inspector_activo (activo)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: encargados_establecimientos
-- Un encargado puede estar asignado a múltiples establecimientos
-- y un establecimiento puede tener diferentes encargados por fecha
-- =====================================================
CREATE TABLE encargados_establecimientos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL, -- referencia al usuario que es encargado
  establecimiento_id INT NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE DEFAULT NULL,
  es_principal BOOLEAN DEFAULT FALSE, -- indica si es el encargado principal
  comentario VARCHAR(255),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  INDEX idx_encargado_establecimiento_fecha (establecimiento_id, fecha_inicio, fecha_fin),
  INDEX idx_encargado_activo (activo)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: categorias_evaluacion
-- =====================================================
CREATE TABLE categorias_evaluacion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  orden INT DEFAULT 0,
  activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: items_evaluacion_base (catálogo base de items)
-- =====================================================
CREATE TABLE items_evaluacion_base (
  id INT AUTO_INCREMENT PRIMARY KEY,
  categoria_id INT NOT NULL,
  codigo VARCHAR(20) NOT NULL,
  descripcion TEXT NOT NULL,
  riesgo ENUM('Menor','Mayor','Crítico') NOT NULL DEFAULT 'Menor',
  puntaje_minimo INT NOT NULL, -- puede empezar en 0 o 1
  puntaje_maximo INT NOT NULL,
  orden INT DEFAULT 0,
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (categoria_id) REFERENCES categorias_evaluacion(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  UNIQUE KEY uk_categoria_codigo (categoria_id, codigo)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: items_evaluacion_establecimiento
-- Items específicos por establecimiento (personalización)
-- Los puntajes se toman de items_evaluacion_base para evitar redundancia
-- =====================================================
CREATE TABLE items_evaluacion_establecimiento (
  id INT AUTO_INCREMENT PRIMARY KEY,
  establecimiento_id INT NOT NULL,
  item_base_id INT NOT NULL,
  descripcion_personalizada TEXT NULL, -- si quiere personalizar la descripción
  factor_ajuste DECIMAL(3,2) DEFAULT 1.00, -- factor para ajustar puntajes (ej: 0.5, 1.0, 1.5)
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_base_id) REFERENCES items_evaluacion_base(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  UNIQUE KEY uk_establecimiento_item (establecimiento_id, item_base_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: inspecciones
-- Estados corregidos según pedido.txt: pendiente, en_proceso, completada
-- =====================================================
CREATE TABLE inspecciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  establecimiento_id INT NOT NULL,
  inspector_id INT NOT NULL,
  encargado_id INT NULL, -- quien era el encargado en esa fecha
  fecha DATE NOT NULL,
  hora_inicio TIME NULL,
  hora_fin TIME NULL,
  observaciones TEXT, -- UNA SOLA OBSERVACIÓN POR INSPECCIÓN según pedido.txt
  puntaje_total DECIMAL(6,2) DEFAULT NULL,
  puntaje_maximo_posible DECIMAL(6,2) DEFAULT NULL,
  porcentaje_cumplimiento DECIMAL(5,2) DEFAULT NULL,
  puntos_criticos_perdidos INT DEFAULT NULL,
  estado ENUM('pendiente','en_proceso','completada') DEFAULT 'pendiente', -- Corregido según pedido.txt
  
  -- Firmas
  firma_inspector VARCHAR(500) NULL, -- ruta de la firma del inspector
  firma_encargado VARCHAR(500) NULL, -- ruta de la firma del encargado
  fecha_firma_inspector TIMESTAMP NULL,
  fecha_firma_encargado TIMESTAMP NULL,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (inspector_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  FOREIGN KEY (encargado_id) REFERENCES usuarios(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
  INDEX idx_inspecciones_fecha (fecha),
  INDEX idx_inspecciones_establecimiento_fecha (establecimiento_id, fecha),
  INDEX idx_inspecciones_estado (estado),
  INDEX idx_inspecciones_inspector (inspector_id),
  INDEX idx_inspecciones_encargado (encargado_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: inspeccion_detalles
-- =====================================================
CREATE TABLE inspeccion_detalles (
  id INT AUTO_INCREMENT PRIMARY KEY,
  inspeccion_id INT NOT NULL,
  item_establecimiento_id INT NOT NULL, -- referencia al item específico del establecimiento
  rating INT NULL, -- valor seleccionado por el inspector
  score DECIMAL(5,2) NULL, -- puntaje calculado/normalizado
  observacion_item TEXT, -- observación específica del item
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (inspeccion_id) REFERENCES inspecciones(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_establecimiento_id) REFERENCES items_evaluacion_establecimiento(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
  UNIQUE KEY uk_inspeccion_item (inspeccion_id, item_establecimiento_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: evidencias_inspeccion
-- Para respaldar las observaciones con imágenes
-- =====================================================
CREATE TABLE evidencias_inspeccion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  inspeccion_id INT NOT NULL,
  item_detalle_id INT NULL, -- si la evidencia es específica de un item
  filename VARCHAR(255) NOT NULL,
  ruta_archivo VARCHAR(500) NOT NULL, -- ruta relativa en el proyecto
  descripcion VARCHAR(500),
  mime_type VARCHAR(100),
  tamano_bytes INT,
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (inspeccion_id) REFERENCES inspecciones(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_detalle_id) REFERENCES inspeccion_detalles(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
  INDEX idx_evidencias_inspeccion (inspeccion_id)
) ENGINE=InnoDB;

-- =====================================================
-- TABLA: plan_semanal
-- =====================================================
CREATE TABLE plan_semanal (
  id INT AUTO_INCREMENT PRIMARY KEY,
  establecimiento_id INT NOT NULL,
  semana INT NOT NULL,
  ano INT NOT NULL,
  evaluaciones_meta INT DEFAULT 3,
  evaluaciones_realizadas INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE (establecimiento_id, semana, ano),
  FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS CORREGIDOS
-- =====================================================

DELIMITER $$

-- =====================================================
-- 1. SP para obtener el encargado activo de un establecimiento en una fecha específica
-- =====================================================
CREATE PROCEDURE sp_obtener_encargado_por_fecha(
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
END$$

-- =====================================================
-- 2. SP para obtener inspectores asignados a un establecimiento
-- =====================================================
CREATE PROCEDURE sp_obtener_inspectores_establecimiento(
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
END$$

-- =====================================================
-- 3. SP para obtener items de evaluación de un establecimiento
-- =====================================================
CREATE PROCEDURE sp_obtener_items_establecimiento(
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
END$$

-- =====================================================
-- 4. SP para crear items por defecto para un establecimiento nuevo
-- =====================================================
CREATE PROCEDURE sp_crear_items_defecto_establecimiento(
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
END$$

-- =====================================================
-- 5. SP para obtener inspección completa con detalles
-- =====================================================
CREATE PROCEDURE sp_obtener_inspeccion_completa(
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
END$$

-- =====================================================
-- 6. SP para filtrar inspecciones según pedido.txt
-- =====================================================
CREATE PROCEDURE sp_filtrar_inspecciones(
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
END$$

-- =====================================================
-- 7. SP para calcular puntajes de una inspección
-- =====================================================
CREATE PROCEDURE sp_calcular_puntajes_inspeccion(
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
END$$

-- =====================================================
-- 8. SP para obtener plan semanal actualizado
-- =====================================================
CREATE PROCEDURE sp_obtener_plan_semanal_actual(
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
END$$

DELIMITER ;

-- =====================================================
-- INSERCIONES PARA LA BASE DE DATOS CORREGIDA
-- =====================================================

-- Inserción de roles (INCLUYE ADMINISTRADOR)
INSERT INTO roles (id, nombre, descripcion, permisos) VALUES
(1, 'Inspector', 'Personal encargado de realizar las inspecciones sanitarias', 
 '{"inspecciones": {"crear": true, "editar": true, "ver_todos": true}, "informes": {"ver_todos": true}}'),
(2, 'Encargado', 'Personal responsable del establecimiento', 
 '{"inspecciones": {"ver_propias": true, "firmar": true}, "informes": {"ver_propios": true}}'),
(3, 'Administrador', 'Administrador del sistema con acceso total',
 '{"inspecciones": {"crear": true, "editar": true, "eliminar": true, "ver_todos": true}, "establecimientos": {"crear": true, "editar": true, "eliminar": true}, "usuarios": {"crear": true, "editar": true, "eliminar": true, "cambiar_roles": true}, "informes": {"ver_todos": true}}');

-- Inserción de tipos de establecimiento
INSERT INTO tipos_establecimiento (id, nombre, descripcion) VALUES
(1, 'Restaurante', 'Establecimiento de servicio de alimentos y bebidas'),
(2, 'Cafetería', 'Establecimiento especializado en café y aperitivos'),
(3, 'Bar', 'Establecimiento especializado en bebidas'),
(4, 'Food Court', 'Área común de diversos establecimientos de comida');

-- Inserción de establecimientos
INSERT INTO establecimientos (tipo_establecimiento_id, nombre, direccion, telefono, correo, activo) VALUES
(1, 'Déjà vu', 'Dirección Déjà vu', '123456789', 'dejavu@chancay.com', true),
(1, 'Silvia', 'Dirección Silvia', '123456789', 'silvia@chancay.com', true),
(1, 'Náutica', 'Dirección Náutica', '123456789', 'nautica@chancay.com', true),
(1, 'Rincón del Norte', 'Dirección Rincón del Norte', '123456789', 'rinconnorte@chancay.com', true);

-- Inserción de usuarios (inspectores, encargados y administrador)
INSERT INTO usuarios (nombre, apellido, correo, contrasena, rol_id, activo, telefono, dni) VALUES
-- Inspector
('Jesus', 'Isique', 'desarrollo@castillodechancay.com', '$2b$12$C58u.bPb.cR45jpC9QxLf.i05oucxUGq/XABKPCL2X.N5jOVkd7Sq', 1, true, '987654321', '45678912'),
-- Encargados
('Jhon', 'Doe', 'jhondoe@castillodechancay.com', '$2b$12$/98in5H5an.yCAeYx2YiiOd65lQO6YBGDMDWweuo5KPK/U/Z3SKiO', 2, true, '987654322', '12345678'),
('María', 'García', 'maria.garcia@example.com', 'hashed_password', 2, true, '987654323', '87654321'),
('Carlos', 'López', 'carlos.lopez@example.com', 'hashed_password', 2, true, '987654324', '45678913'),
('Ana', 'Martínez', 'ana.martinez@example.com', 'hashed_password', 2, true, '987654325', '78912345'),
-- Administrador
('Admin', 'Sistema', 'estadistica@castillodechancay.com', '$2b$12$jeZG0C.IXQsL/zmrvCS/4OBnfPIHDdDQs2KrdqUWVUqPnXPdTeyte', 3, true, '987654326', '11111111');

-- Asignación de inspector a establecimientos
INSERT INTO inspector_establecimientos (inspector_id, establecimiento_id, fecha_asignacion, es_principal, activo) VALUES
(1, 1, '2025-08-16', true, true),  -- Jesus - Déjà vu
(1, 2, '2025-08-16', true, true),  -- Jesus - Silvia
(1, 3, '2025-08-16', true, true),  -- Jesus - Náutica
(1, 4, '2025-08-16', true, true);  -- Jesus - Rincón del Norte

-- Inserción de encargados_establecimientos
INSERT INTO encargados_establecimientos (usuario_id, establecimiento_id, fecha_inicio, es_principal, activo) VALUES
(2, 1, '2025-08-16', true, true),  -- Juan - Déjà vu
(3, 2, '2025-08-16', true, true),  -- María - Silvia
(4, 3, '2025-08-16', true, true),  -- Carlos - Náutica
(5, 4, '2025-08-16', true, true);  -- Ana - Rincón del Norte

-- Inserción de categorías de evaluación
INSERT INTO categorias_evaluacion (id, nombre, descripcion, orden, activo) VALUES
(1, 'Higiene y Bioseguridad - Cocinas', 'Evaluación de higiene y bioseguridad en áreas de cocina', 1, true),
(2, 'Equipamiento - Cocinas', 'Evaluación del equipamiento en cocinas', 2, true),
(3, 'Producción y Almacenamiento previo', 'Evaluación de procesos de producción y almacenamiento', 3, true),
(4, 'Preparación de alimentos', 'Evaluación de procesos de preparación de alimentos', 4, true),
(5, 'Gestión de residuos y plagas', 'Evaluación de manejo de residuos y control de plagas', 5, true),
(6, 'Vajillas y Utensilios', 'Evaluación de vajillas y utensilios de cocina', 6, true),
(7, 'Higiene general - Comedor', 'Evaluación de higiene en área de comedor', 7, true),
(8, 'Almacenes', 'Evaluación de áreas de almacenamiento', 8, true),
(9, 'Seguridad - Defensa Civil', 'Evaluación de medidas de seguridad', 9, true),
(10, 'Administración', 'Evaluación de aspectos administrativos', 10, true);

-- Inserción de items de evaluación base
INSERT INTO items_evaluacion_base (categoria_id, codigo, descripcion, riesgo, puntaje_minimo, puntaje_maximo, orden) VALUES
(1,'1.1','Pisos y paredes sin suciedad visible ni humedad','Mayor',1,4,1),
(1,'1.2','Lavaderos libres de residuos','Menor',1,2,2),
(1,'1.3','Campana extractora limpia y operativa','Mayor',1,4,3),
(1,'1.4','Iluminación adecuada','Menor',1,2,4),
(1,'1.5','Gel antibacterial / Jabón líquido','Menor',1,2,5),
(1,'1.6','Personal de cocina con uniforme completo, limpio y buena higiene personal','Mayor',1,4,6),
(1,'1.7','Presencia de personas ajenas','Menor',1,2,7),
(1,'1.8','Insumos de limpieza alejados de alimentos y hornillas','Mayor',1,4,8),
(2,'2.1','Equipos completos, operativos y en buen estado','Mayor',1,4,1),
(2,'2.2','Limpieza y conservación de equipos','Mayor',1,4,2),
(2,'2.3','Constancia de mantenimiento de sus equipos cada 6 meses','Mayor',1,4,3),
(3,'3.1','Mise en place de carnes, pescados y mariscos','Crítico',1,8,1),
(3,'3.2','Mise en place de vegetales','Mayor',1,4,2),
(3,'3.3','Mise en place de complementos','Mayor',1,4,3),
(3,'3.4','Mise en place de salsas','Mayor',1,4,4),
(4,'4.1','Aspecto limpio del aceite','Mayor',1,4,1),
(4,'4.2','Separación de alimentos crudos y cocidos','Crítico',1,8,2),
(4,'4.3','Descongelación adecuada','Crítico',1,8,3),
(4,'4.4','Insumos en buen estado','Crítico',1,8,4),
(4,'4.5','Rotulado de productos','Crítico',1,8,5),
(4,'4.6','Verificación del agua potable (bidón y filtros de agua)','Mayor',1,4,6),
(5,'5.1','Basureros adecuados','Menor',1,2,1),
(5,'5.2','Eliminación diaria de basura en el lugar adecuado','Mayor',1,4,2),
(5,'5.3','Ausencia de insectos y cualquier animal','Crítico',1,8,3),
(5,'5.4','Bitácoras de limpieza y gestión de plagas','Mayor',1,4,4),
(6,'6.1','Buen estado de conservación','Mayor',1,4,1),
(6,'6.2','Vajillas y Utensilios limpios','Mayor',1,4,2),
(6,'6.3','Secado adecuado','Menor',1,2,3),
(6,'6.4','Tablas de picar separadas por color, en buen estado y limpias (se recomienda acero)','Mayor',1,4,4),
(7,'7.1','Pisos limpios','Menor',1,2,1),
(7,'7.2','Mesas y manteles limpios','Menor',1,2,2),
(7,'7.3','Personal con uniforme completo y limpio y buena higiene personal','Mayor',1,4,3),
(7,'7.4','Contar con implementos de atención','Menor',1,2,4),
(8,'8.1','Ordenado y limpio','Mayor',1,4,1),
(8,'8.2','Enlatados en buen estado y vigentes','Crítico',1,8,2),
(8,'8.3','Control de fechas de vencimiento de todos los productos','Crítico',1,8,3),
(8,'8.4','Ausencia de sustancias químicas','Mayor',1,4,4),
(9,'9.1','Extintores operativos y vigentes (plateado y rojo) con señalización, tarjeta de inspección y certificado','Crítico',1,8,1),
(9,'9.2','Botiquín de primeros auxilios completo con señalización','Mayor',1,4,2),
(9,'9.3','Balones de Gas: con seguridad y señalización','Crítico',1,8,3),
(9,'9.4','Sistema contra incendios operativo','Crítico',1,8,4),
(9,'9.5','Otras señalizaciones de salida, entrada, aforo, horario de atención, zona segura','Mayor',1,4,5),
(9,'9.6','Pisos antideslizantes en las cocinas y cintas en las escaleras y rampas','Mayor',1,4,6),
(9,'9.7','Luces de emergencia operativas con señalética y con certificado','Mayor',1,4,7),
(10,'10.1','POS operativo','Menor',1,2,1),
(10,'10.2','Caja chica disponible','Menor',1,2,2),
(10,'10.3','Facturas y boletas vigentes','Mayor',1,4,3),
(10,'10.4','Libro de reclamaciones','Mayor',1,4,4),
(10,'10.5','Cartas en buen estado','Menor',1,2,5),
(10,'10.6','Stock de bebidas','Menor',1,2,6),
(10,'10.7','Stock de envases y sachet','Menor',1,2,7);

-- Crear items de evaluación para cada establecimiento
INSERT INTO items_evaluacion_establecimiento 
    (establecimiento_id, item_base_id, factor_ajuste, activo)
SELECT 
    e.id as establecimiento_id,
    i.id as item_base_id,
    1.00 as factor_ajuste, -- Factor por defecto
    true as activo
FROM establecimientos e
CROSS JOIN items_evaluacion_base i
WHERE e.activo = true;

-- Inserción de inspecciones con estados corregidos
INSERT INTO inspecciones (
    establecimiento_id, 
    inspector_id, 
    encargado_id,
    fecha, 
    hora_inicio,
    hora_fin,
    observaciones, -- UNA SOLA OBSERVACIÓN GENERAL
    puntaje_total,
    puntaje_maximo_posible,
    porcentaje_cumplimiento,
    puntos_criticos_perdidos,
    estado, -- Estados corregidos: pendiente, en_proceso, completada
    firma_inspector,
    firma_encargado,
    fecha_firma_inspector,
    fecha_firma_encargado
) VALUES
(1, 1, 2, '2025-08-16', '09:00:00', '10:30:00', 'Inspección regular mensual. El establecimiento cumple con la mayoría de estándares, se observaron mejoras en la limpieza general.', 
 35.00, 40.00, 87.50, 0, 'completada', 
 '/firmas/inspectores/jesus_isique_20250816.jpg', '/firmas/encargados/juan_perez_20250816.jpg', 
 '2025-08-16 10:25:00', '2025-08-16 10:28:00'),
(2, 1, 3, '2025-08-17', '11:00:00', '12:30:00', 'Inspección regular mensual. Excelente estado general del establecimiento.', 
 38.00, 40.00, 95.00, 0, 'completada',
 '/firmas/inspectores/jesus_isique_20250817.jpg', '/firmas/encargados/maria_garcia_20250817.jpg',
 '2025-08-17 12:25:00', '2025-08-17 12:28:00'),
(3, 1, 4, '2025-08-18', '14:00:00', NULL, 'Inspección en proceso. Revisando área de cocina y almacén.', 
 NULL, NULL, NULL, NULL, 'en_proceso', NULL, NULL, NULL, NULL),
(4, 1, NULL, '2025-08-19', NULL, NULL, 'Inspección programada para revisión de seguridad.', 
 NULL, NULL, NULL, NULL, 'pendiente', NULL, NULL, NULL, NULL);
