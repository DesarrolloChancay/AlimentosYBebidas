-- ==========================================
-- Ajuste del modulo de reglamento para bases existentes
-- Destino: MySQL / MariaDB
-- Ejecutar sentencia por sentencia o como script del cliente SQL
-- No usa START TRANSACTION porque varios clientes MySQL envian
-- multiples sentencias como un solo bloque y fallan con DDL
-- ==========================================

CREATE TABLE IF NOT EXISTS items_reglamento_restaurante (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    descripcion TEXT NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    riesgo VARCHAR(20) NOT NULL,
    puntaje INT NOT NULL,
    tipo_validacion VARCHAR(20) NOT NULL DEFAULT 'si_no',
    logica_inversa TINYINT(1) NOT NULL DEFAULT 0,
    valor_umbral DECIMAL(10, 2) NULL,
    operador_comparacion VARCHAR(10) NULL,
    orden INT DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_items_reglamento_codigo (codigo),
    KEY idx_items_reglamento_activo (activo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reuniones_reglamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establecimiento_id INT NOT NULL,
    semana INT NOT NULL,
    ano INT NOT NULL,
    fecha_reunion DATE NOT NULL,
    fecha_inicio_semana DATE NOT NULL,
    fecha_fin_semana DATE NOT NULL,
    total_inspecciones INT DEFAULT 0,
    total_infracciones INT DEFAULT 0,
    total_puntos INT DEFAULT 0,
    total_platos_sancion INT DEFAULT 0,
    observaciones TEXT,
    estado VARCHAR(20) DEFAULT 'pendiente',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_reuniones_reglamento_establecimiento_semana (establecimiento_id, semana, ano),
    KEY idx_reuniones_reglamento_fecha (fecha_reunion),
    CONSTRAINT fk_reuniones_reglamento_establecimiento
        FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS evaluaciones_reglamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reunion_id INT NOT NULL,
    item_id INT NOT NULL,
    cumple TINYINT(1) NOT NULL,
    numero_infracciones INT DEFAULT 0,
    puntaje_aplicado INT NOT NULL DEFAULT 0,
    valor_medido DECIMAL(10, 2) NULL,
    observacion TEXT,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_evaluaciones_reglamento_reunion_item (reunion_id, item_id),
    KEY idx_evaluaciones_reglamento_item (item_id),
    CONSTRAINT fk_evaluaciones_reglamento_reunion
        FOREIGN KEY (reunion_id) REFERENCES reuniones_reglamento(id) ON DELETE CASCADE,
    CONSTRAINT fk_evaluaciones_reglamento_item
        FOREIGN KEY (item_id) REFERENCES items_reglamento_restaurante(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @col_items_tipo_validacion := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'items_reglamento_restaurante'
      AND COLUMN_NAME = 'tipo_validacion'
);
SET @sql_items_tipo_validacion := IF(
    @col_items_tipo_validacion = 0,
    'ALTER TABLE items_reglamento_restaurante ADD COLUMN tipo_validacion VARCHAR(20) NOT NULL DEFAULT ''si_no''',
    'SELECT 1'
);
PREPARE stmt_items_tipo_validacion FROM @sql_items_tipo_validacion;
EXECUTE stmt_items_tipo_validacion;
DEALLOCATE PREPARE stmt_items_tipo_validacion;

SET @col_items_logica_inversa := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'items_reglamento_restaurante'
      AND COLUMN_NAME = 'logica_inversa'
);
SET @sql_items_logica_inversa := IF(
    @col_items_logica_inversa = 0,
    'ALTER TABLE items_reglamento_restaurante ADD COLUMN logica_inversa TINYINT(1) NOT NULL DEFAULT 0',
    'SELECT 1'
);
PREPARE stmt_items_logica_inversa FROM @sql_items_logica_inversa;
EXECUTE stmt_items_logica_inversa;
DEALLOCATE PREPARE stmt_items_logica_inversa;

SET @col_items_valor_umbral := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'items_reglamento_restaurante'
      AND COLUMN_NAME = 'valor_umbral'
);
SET @sql_items_valor_umbral := IF(
    @col_items_valor_umbral = 0,
    'ALTER TABLE items_reglamento_restaurante ADD COLUMN valor_umbral DECIMAL(10, 2) NULL',
    'SELECT 1'
);
PREPARE stmt_items_valor_umbral FROM @sql_items_valor_umbral;
EXECUTE stmt_items_valor_umbral;
DEALLOCATE PREPARE stmt_items_valor_umbral;

SET @col_items_operador := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'items_reglamento_restaurante'
      AND COLUMN_NAME = 'operador_comparacion'
);
SET @sql_items_operador := IF(
    @col_items_operador = 0,
    'ALTER TABLE items_reglamento_restaurante ADD COLUMN operador_comparacion VARCHAR(10) NULL',
    'SELECT 1'
);
PREPARE stmt_items_operador FROM @sql_items_operador;
EXECUTE stmt_items_operador;
DEALLOCATE PREPARE stmt_items_operador;

SET @col_reuniones_fecha_inicio := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'reuniones_reglamento'
      AND COLUMN_NAME = 'fecha_inicio_semana'
);
SET @sql_reuniones_fecha_inicio := IF(
    @col_reuniones_fecha_inicio = 0,
    'ALTER TABLE reuniones_reglamento ADD COLUMN fecha_inicio_semana DATE NULL',
    'SELECT 1'
);
PREPARE stmt_reuniones_fecha_inicio FROM @sql_reuniones_fecha_inicio;
EXECUTE stmt_reuniones_fecha_inicio;
DEALLOCATE PREPARE stmt_reuniones_fecha_inicio;

SET @col_reuniones_fecha_fin := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'reuniones_reglamento'
      AND COLUMN_NAME = 'fecha_fin_semana'
);
SET @sql_reuniones_fecha_fin := IF(
    @col_reuniones_fecha_fin = 0,
    'ALTER TABLE reuniones_reglamento ADD COLUMN fecha_fin_semana DATE NULL',
    'SELECT 1'
);
PREPARE stmt_reuniones_fecha_fin FROM @sql_reuniones_fecha_fin;
EXECUTE stmt_reuniones_fecha_fin;
DEALLOCATE PREPARE stmt_reuniones_fecha_fin;

SET @col_reuniones_total_puntos := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'reuniones_reglamento'
      AND COLUMN_NAME = 'total_puntos'
);
SET @sql_reuniones_total_puntos := IF(
    @col_reuniones_total_puntos = 0,
    'ALTER TABLE reuniones_reglamento ADD COLUMN total_puntos INT DEFAULT 0',
    'SELECT 1'
);
PREPARE stmt_reuniones_total_puntos FROM @sql_reuniones_total_puntos;
EXECUTE stmt_reuniones_total_puntos;
DEALLOCATE PREPARE stmt_reuniones_total_puntos;

SET @col_reuniones_observaciones := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'reuniones_reglamento'
      AND COLUMN_NAME = 'observaciones'
);
SET @sql_reuniones_observaciones := IF(
    @col_reuniones_observaciones = 0,
    'ALTER TABLE reuniones_reglamento ADD COLUMN observaciones TEXT',
    'SELECT 1'
);
PREPARE stmt_reuniones_observaciones FROM @sql_reuniones_observaciones;
EXECUTE stmt_reuniones_observaciones;
DEALLOCATE PREPARE stmt_reuniones_observaciones;

SET @col_evaluaciones_puntaje := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'evaluaciones_reglamento'
      AND COLUMN_NAME = 'puntaje_aplicado'
);
SET @sql_evaluaciones_puntaje := IF(
    @col_evaluaciones_puntaje = 0,
    'ALTER TABLE evaluaciones_reglamento ADD COLUMN puntaje_aplicado INT NOT NULL DEFAULT 0',
    'SELECT 1'
);
PREPARE stmt_evaluaciones_puntaje FROM @sql_evaluaciones_puntaje;
EXECUTE stmt_evaluaciones_puntaje;
DEALLOCATE PREPARE stmt_evaluaciones_puntaje;

SET @col_evaluaciones_valor_medido := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'evaluaciones_reglamento'
      AND COLUMN_NAME = 'valor_medido'
);
SET @sql_evaluaciones_valor_medido := IF(
    @col_evaluaciones_valor_medido = 0,
    'ALTER TABLE evaluaciones_reglamento ADD COLUMN valor_medido DECIMAL(10, 2) NULL',
    'SELECT 1'
);
PREPARE stmt_evaluaciones_valor_medido FROM @sql_evaluaciones_valor_medido;
EXECUTE stmt_evaluaciones_valor_medido;
DEALLOCATE PREPARE stmt_evaluaciones_valor_medido;

SET @idx_reuniones := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'reuniones_reglamento'
      AND INDEX_NAME = 'uq_reuniones_reglamento_establecimiento_semana'
);
SET @sql_reuniones := IF(
    @idx_reuniones = 0,
    'ALTER TABLE reuniones_reglamento ADD UNIQUE KEY uq_reuniones_reglamento_establecimiento_semana (establecimiento_id, semana, ano)',
    'SELECT 1'
);
PREPARE stmt_reuniones FROM @sql_reuniones;
EXECUTE stmt_reuniones;
DEALLOCATE PREPARE stmt_reuniones;

SET @idx_evaluaciones := (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'evaluaciones_reglamento'
      AND INDEX_NAME = 'uq_evaluaciones_reglamento_reunion_item'
);
SET @sql_evaluaciones := IF(
    @idx_evaluaciones = 0,
    'ALTER TABLE evaluaciones_reglamento ADD UNIQUE KEY uq_evaluaciones_reglamento_reunion_item (reunion_id, item_id)',
    'SELECT 1'
);
PREPARE stmt_evaluaciones FROM @sql_evaluaciones;
EXECUTE stmt_evaluaciones;
DEALLOCATE PREPARE stmt_evaluaciones;

INSERT INTO items_reglamento_restaurante (
    codigo, descripcion, categoria, riesgo, puntaje, tipo_validacion,
    logica_inversa, valor_umbral, operador_comparacion, orden, activo
) VALUES
('A-01', 'Obtener una calificacion Regular x checklist', 'Checklist (3 veces por semana)', 'Mayor', 3, 'si_no', 1, NULL, NULL, 1, 1),
('A-02', 'Obtener una calificacion Mala x checklist', 'Checklist (3 veces por semana)', 'Crítico', 5, 'si_no', 1, NULL, NULL, 2, 1),
('A-03', 'Incumplir 2 veces seguidas o alternadas en una misma semana el mismo item del checklist', 'Checklist (3 veces por semana)', 'Mayor', 3, 'si_no', 1, NULL, NULL, 3, 1),
('A-04', 'Incumplir las observaciones inopinadas (por el personal encargado)', 'Checklist (3 veces por semana)', 'Menor', 1, 'si_no', 1, NULL, NULL, 4, 1),
('A-05', 'Obtener un porcentaje menor al 85% en las evaluaciones de satisfaccion del cliente', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'porcentaje', 0, 85.00, '<', 5, 1),
('A-06', 'Obtener un porcentaje menor al 90% en las recomendaciones de los clientes, segun las encuestas', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'porcentaje', 0, 90.00, '<', 6, 1),
('A-07', 'Si se acumulan 10 comentarios negativos en las encuestas de lunes a viernes', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'numerico', 0, 10.00, '>=', 7, 1),
('A-08', 'Si se acumulan 15 comentarios negativos en las encuestas de sabado y domingo', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'numerico', 0, 15.00, '>=', 8, 1),
('A-09', 'No entregar el libro de reclamaciones cuando sea requerido por los clientes', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', 1, NULL, NULL, 9, 1),
('A-10', 'Quejas graves de clientes ya sean en las encuestas o directamente (puede implicar o no libro de reclamaciones)', 'Satisfacción al cliente - Encuestas', 'Crítico', 5, 'si_no', 1, NULL, NULL, 10, 1),
('A-11', 'Realizar publicidad engañosa por no respetar los precios establecidos en las cartas y/o no cumplir con las promociones y/o cortesias ofrecidas', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', 1, NULL, NULL, 11, 1),
('A-12', 'El tiempo de espera de un pedido de comida debe durar como maximo 20 minutos y llegar a 20 demoras detiene la venta', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', 1, NULL, NULL, 12, 1),
('A-13', 'Permitir que sus trabajadores fijos laboren sin contar con el respectivo carnet de sanidad', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', 1, NULL, NULL, 13, 1),
('A-14', 'Contratar trabajadores menores de edad y/o personal extranjero que no cuente con la documentacion correspondiente para trabajar en el pais', 'Incumplimientos Laborales', 'Mayor', 3, 'si_no', 1, NULL, NULL, 14, 1),
('A-15', 'Prohibido contratar personal que este en lista roja', 'Incumplimientos Laborales', 'Mayor', 3, 'si_no', 1, NULL, NULL, 15, 1),
('A-16', 'Contratar al personal de otros concesionarios y/o del castillo mientras laboran en otras entidades y/o antes de cumplir 3 meses desde su ultima relacion laboral sin coordinacion previa', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', 1, NULL, NULL, 16, 1),
('A-17', 'No tener al personal en planilla y con contratos', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', 1, NULL, NULL, 17, 1),
('A-18', 'Incumplimiento de los acuerdos adoptados en las reuniones semanales', 'Otros incumplimientos', 'Mayor', 3, 'si_no', 1, NULL, NULL, 18, 1),
('A-19', 'No cumplir con la programacion semanal del personal acordado en reunion. De lunes a viernes, sabado, domingo o feriado', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 19, 1),
('A-20', 'Realizar sus operaciones sin contar con el certificado de fumigacion vigente', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 20, 1),
('A-21', 'No preparar el chancho al palo con los parametros de seguridad establecidos segun compromiso firmado', 'Otros incumplimientos', 'Mayor', 3, 'si_no', 1, NULL, NULL, 21, 1),
('A-22', 'Ingreso de mercaderia en horarios no establecidos (6:00-10:00 y 5:00-7:00)', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 22, 1),
('A-23', 'Depositar desperdicios o basura en espacios no permitidos y dejar el espacio sucio', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 23, 1),
('A-24', 'Anular cupos o tickets sin autorizacion o sin previa autorizacion del Castillo', 'Otros incumplimientos', 'Mayor', 3, 'si_no', 1, NULL, NULL, 24, 1),
('A-25', 'Usar tickets o comandas distintas a las aprobadas', 'Otros incumplimientos', 'Mayor', 3, 'si_no', 1, NULL, NULL, 25, 1),
('A-26', 'Inasistencia injustificada de los dueños de restaurantes o establecimientos concesionados a reuniones semanales, extraordinarias y/o capacitaciones', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 26, 1),
('A-27', 'No respetar el monto acordado para los descuentos a los turistas', 'Otros incumplimientos', 'Mayor', 3, 'si_no', 1, NULL, NULL, 27, 1),
('A-28', 'Falta de respeto entre concesionarios y/o personal', 'Otros incumplimientos', 'Crítico', 5, 'si_no', 1, NULL, NULL, 28, 1),
('A-29', 'Tomar objetos ajenos del restaurante que no le pertenecen', 'Otros incumplimientos', 'Menor', 1, 'si_no', 1, NULL, NULL, 29, 1),
('A-30', 'Adulterar las fechas de rotulado', 'Otros incumplimientos', 'Crítico', 5, 'si_no', 1, NULL, NULL, 30, 1),
('A-31', 'No cumplir con el pago de impuestos (fecha de pagos entre el dia 25 y 30 de cada mes). Enviar los documentos de SUNAT', 'Incumplimiento en pagos', 'Menor', 1, 'si_no', 1, NULL, NULL, 31, 1),
('A-32', 'No cumplir con el pago a sus proveedores o personal que pueda generar mala reputacion al Castillo', 'Incumplimiento en pagos', 'Crítico', 5, 'si_no', 1, NULL, NULL, 32, 1),
('A-33', 'No cumplir con el pago del alquiler segun las fechas establecidas (50% hasta el dia 7 y 50% restante hasta el dia 15)', 'Incumplimiento en pagos', 'Crítico', 5, 'si_no', 1, NULL, NULL, 33, 1)
ON DUPLICATE KEY UPDATE
    descripcion = VALUES(descripcion),
    categoria = VALUES(categoria),
    riesgo = VALUES(riesgo),
    puntaje = VALUES(puntaje),
    tipo_validacion = VALUES(tipo_validacion),
    logica_inversa = VALUES(logica_inversa),
    valor_umbral = VALUES(valor_umbral),
    operador_comparacion = VALUES(operador_comparacion),
    orden = VALUES(orden),
    activo = VALUES(activo);

UPDATE evaluaciones_reglamento er
INNER JOIN items_reglamento_restaurante i ON i.id = er.item_id
SET er.puntaje_aplicado = i.puntaje
WHERE er.puntaje_aplicado IS NULL OR er.puntaje_aplicado = 0;

UPDATE reuniones_reglamento rr
LEFT JOIN (
    SELECT
        er.reunion_id,
        SUM(
            CASE
                WHEN er.cumple = 0 THEN GREATEST(COALESCE(er.numero_infracciones, 0), 1)
                ELSE 0
            END
        ) AS total_infracciones,
        SUM(
            CASE
                WHEN er.cumple = 0 THEN COALESCE(er.puntaje_aplicado, 0) * GREATEST(COALESCE(er.numero_infracciones, 0), 1)
                ELSE 0
            END
        ) AS total_puntos
    FROM evaluaciones_reglamento er
    GROUP BY er.reunion_id
) resumen ON resumen.reunion_id = rr.id
SET rr.total_infracciones = COALESCE(resumen.total_infracciones, 0),
    rr.total_puntos = COALESCE(resumen.total_puntos, 0),
    rr.total_platos_sancion = CASE
        WHEN COALESCE(resumen.total_puntos, 0) <= 2 THEN 0
        WHEN COALESCE(resumen.total_puntos, 0) BETWEEN 3 AND 4 THEN 5
        WHEN COALESCE(resumen.total_puntos, 0) BETWEEN 5 AND 6 THEN 10
        WHEN COALESCE(resumen.total_puntos, 0) BETWEEN 7 AND 8 THEN 15
        WHEN COALESCE(resumen.total_puntos, 0) BETWEEN 9 AND 10 THEN 20
        WHEN COALESCE(resumen.total_puntos, 0) >= 11 THEN 25
        ELSE 0
    END;
