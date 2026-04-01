-- ==========================================
-- Script para inicializar Reglamento de Restaurante - MySQL
-- Descripción: Crea las tablas e inserta los items del reglamento
-- Lógica: Compatible con MySQL, usa AUTO_INCREMENT, ENUM y sintaxis específica
-- Ejemplo: mysql -u root -p alimentosybebidas < inicializar_reglamento_restaurante_mysql.sql
-- ==========================================

-- Tabla: items_reglamento
-- Descripción: Almacena los items del checklist del reglamento
CREATE TABLE IF NOT EXISTS items_reglamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    tipo_sancion VARCHAR(100),
    sancion_por_plato INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: reglamento_restaurantes
-- Descripción: Almacena las reuniones semanales del reglamento
CREATE TABLE IF NOT EXISTS reglamento_restaurantes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establecimiento_id INT NOT NULL,
    semana INT NOT NULL,
    ano INT NOT NULL,
    fecha_reunion DATE,
    estado VARCHAR(20) DEFAULT 'pendiente',
    jefe_responsable_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id),
    FOREIGN KEY (jefe_responsable_id) REFERENCES usuarios(id),
    UNIQUE KEY unique_establecimiento_semana (establecimiento_id, semana, ano)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla: evaluaciones_reglamento
-- Descripción: Almacena las evaluaciones de cada item por reunión
CREATE TABLE IF NOT EXISTS evaluaciones_reglamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reglamento_id INT NOT NULL,
    item_id INT NOT NULL,
    estado ENUM('cumple', 'no_cumple') DEFAULT 'cumple',
    infracciones_detectadas INT DEFAULT 0,
    observaciones TEXT,
    sancion_aplicada INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (reglamento_id) REFERENCES reglamento_restaurantes(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items_reglamento(id),
    UNIQUE KEY unique_reglamento_item (reglamento_id, item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- INSERTAR ITEMS DEL REGLAMENTO
-- ==========================================

-- A. ASISTENCIA PUNTUAL A LA REUNION DE COORDINACION
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('A-1', 'Asistencia puntual a la reunión de coordinación semanal (lunes 9:00 am)', 'Falta injustificada', 5);

-- B. ASISTENCIA DE ENCARGADOS
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('B-1', 'El encargado deberá asistir obligatoriamente todos los días que esté programado', 'Por cada falta injustificada', 10),
('B-2', 'Los encargados deben permanecer durante todo el horario laboral', 'Por retiro anticipado sin justificación', 5);

-- C. PERSONAL DE COCINA Y SERVICIO
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('C-1', 'Personal de cocina completo según programación', 'Por cada persona faltante', 3),
('C-2', 'Personal de servicio completo según programación', 'Por cada persona faltante', 3),
('C-3', 'Personal con uniforme completo y limpio', 'Por incumplimiento', 2);

-- D. LIMPIEZA Y ORDEN
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('D-1', 'Área de cocina limpia y ordenada', 'Por incumplimiento', 5),
('D-2', 'Área de comedor limpia y ordenada', 'Por incumplimiento', 5),
('D-3', 'Baños limpios y abastecidos', 'Por incumplimiento', 3),
('D-4', 'Eliminación adecuada de basura', 'Por incumplimiento', 3);

-- E. CALIDAD DE ALIMENTOS
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('E-1', 'Alimentos en buen estado y frescos', 'Por incumplimiento', 10),
('E-2', 'Temperaturas de conservación adecuadas', 'Por incumplimiento', 8),
('E-3', 'Etiquetado y rotulado correcto', 'Por incumplimiento', 5);

-- F. SERVICIO AL CLIENTE
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('F-1', 'Atención cordial y respetuosa', 'Por quejas de clientes', 5),
('F-2', 'Tiempo de espera menor a 20 minutos', 'Por cada demora injustificada', 3),
('F-3', 'Entrega de libro de reclamaciones cuando se solicite', 'Por negativa', 10);

-- G. DOCUMENTACIÓN
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('G-1', 'Certificado de fumigación vigente', 'Por vencimiento', 5),
('G-2', 'Carnets de sanidad del personal vigentes', 'Por cada carnet vencido', 2),
('G-3', 'Contratos laborales al día', 'Por incumplimiento', 5);

-- H. PAGOS
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('H-1', 'Pago de alquiler en fechas establecidas', 'Por retraso', 15),
('H-2', 'Pago de impuestos al día', 'Por incumplimiento', 10),
('H-3', 'Pago a proveedores al día', 'Por reclamos', 10);

-- I. OTROS
INSERT INTO items_reglamento (codigo, descripcion, tipo_sancion, sancion_por_plato) VALUES
('I-1', 'Cumplimiento de acuerdos de reuniones', 'Por incumplimiento', 5),
('I-2', 'Respeto entre concesionarios y personal', 'Por falta de respeto', 15),
('I-3', 'Uso de comandas aprobadas', 'Por uso de comandas no autorizadas', 5);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_reglamento_establecimiento ON reglamento_restaurantes(establecimiento_id);
CREATE INDEX idx_reglamento_fecha ON reglamento_restaurantes(fecha_reunion);
CREATE INDEX idx_evaluaciones_reglamento ON evaluaciones_reglamento(reglamento_id);
CREATE INDEX idx_evaluaciones_item ON evaluaciones_reglamento(item_id);

-- Verificar la inserción
SELECT COUNT(*) as total_items FROM items_reglamento;
