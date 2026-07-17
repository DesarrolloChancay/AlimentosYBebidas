-- ==========================================
-- Inicializacion del modulo de Registro de Personal
-- Estructura alineada con el modelo ORM actual
-- (app/models/RegistroPersonal_models.py)
-- Destino: MySQL / MariaDB
-- Ejecutar sentencia por sentencia o como script del cliente SQL
-- No usa START TRANSACTION porque varios clientes MySQL envian
-- multiples sentencias como un solo bloque y fallan con DDL
-- ==========================================

CREATE TABLE IF NOT EXISTS registro_personal_diario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establecimiento_id INT NOT NULL,
    fecha DATE NOT NULL,
    registrado_por INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_registro_personal_establecimiento_fecha (establecimiento_id, fecha),
    CONSTRAINT fk_registro_personal_establecimiento
        FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id),
    CONSTRAINT fk_registro_personal_usuario
        FOREIGN KEY (registrado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS registro_personal_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    registro_id INT NOT NULL,
    rol_nombre VARCHAR(100) NOT NULL,
    cantidad INT NULL,
    nombres TEXT NULL,
    es_rol_libre TINYINT(1) DEFAULT 0,
    orden INT DEFAULT 0,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_registro_personal_detalle_registro (registro_id),
    CONSTRAINT fk_registro_personal_detalle_registro
        FOREIGN KEY (registro_id) REFERENCES registro_personal_diario(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles_personal_minimo (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establecimiento_id INT NULL,
    rol_nombre VARCHAR(100) NOT NULL,
    dia_semana TINYINT NOT NULL COMMENT '0=Lunes .. 6=Domingo',
    cantidad_minima INT NOT NULL DEFAULT 0,
    opcional TINYINT(1) DEFAULT 0,
    activo TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_roles_personal_minimo_establecimiento_rol_dia (establecimiento_id, rol_nombre, dia_semana),
    CONSTRAINT fk_roles_personal_minimo_establecimiento
        FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================
-- Plantilla base (establecimiento_id NULL) derivada de la hoja de Silvia
-- (private/imagen_silvia.md). Sirve como default configurable,
-- ajustable luego por establecimiento desde la pantalla de configuracion.
-- dia_semana: 0=Lunes, 1=Martes, 2=Miercoles, 3=Jueves, 4=Viernes, 5=Sabado, 6=Domingo
-- ==========================================

DELETE FROM roles_personal_minimo WHERE establecimiento_id IS NULL;

INSERT INTO roles_personal_minimo
    (establecimiento_id, rol_nombre, dia_semana, cantidad_minima, opcional, activo)
VALUES
-- Encargado: presente todos los dias
(NULL, 'Encargado', 0, 1, 0, 1),
(NULL, 'Encargado', 1, 1, 0, 1),
(NULL, 'Encargado', 2, 1, 0, 1),
(NULL, 'Encargado', 3, 1, 0, 1),
(NULL, 'Encargado', 4, 1, 0, 1),
(NULL, 'Encargado', 5, 1, 0, 1),
(NULL, 'Encargado', 6, 1, 0, 1),
-- Caja: presente todos los dias
(NULL, 'Caja', 0, 1, 0, 1),
(NULL, 'Caja', 1, 1, 0, 1),
(NULL, 'Caja', 2, 1, 0, 1),
(NULL, 'Caja', 3, 1, 0, 1),
(NULL, 'Caja', 4, 1, 0, 1),
(NULL, 'Caja', 5, 1, 0, 1),
(NULL, 'Caja', 6, 1, 0, 1),
-- Jalador: opcional todos los dias
(NULL, 'Jalador', 0, 1, 1, 1),
(NULL, 'Jalador', 1, 1, 1, 1),
(NULL, 'Jalador', 2, 1, 1, 1),
(NULL, 'Jalador', 3, 1, 1, 1),
(NULL, 'Jalador', 4, 1, 1, 1),
(NULL, 'Jalador', 5, 1, 1, 1),
(NULL, 'Jalador', 6, 1, 1, 1),
-- Mozos: entre semana 3, fin de semana 7
(NULL, 'Mozos', 0, 3, 0, 1),
(NULL, 'Mozos', 1, 3, 0, 1),
(NULL, 'Mozos', 2, 3, 0, 1),
(NULL, 'Mozos', 3, 3, 0, 1),
(NULL, 'Mozos', 4, 3, 0, 1),
(NULL, 'Mozos', 5, 7, 0, 1),
(NULL, 'Mozos', 6, 7, 0, 1),
-- Cocina: entre semana 3, fin de semana 5
(NULL, 'Cocina', 0, 3, 0, 1),
(NULL, 'Cocina', 1, 3, 0, 1),
(NULL, 'Cocina', 2, 3, 0, 1),
(NULL, 'Cocina', 3, 3, 0, 1),
(NULL, 'Cocina', 4, 3, 0, 1),
(NULL, 'Cocina', 5, 5, 0, 1),
(NULL, 'Cocina', 6, 5, 0, 1),
-- Cantante: no aplica entre semana, fin de semana 1
(NULL, 'Cantante', 0, 0, 1, 1),
(NULL, 'Cantante', 1, 0, 1, 1),
(NULL, 'Cantante', 2, 0, 1, 1),
(NULL, 'Cantante', 3, 0, 1, 1),
(NULL, 'Cantante', 4, 0, 1, 1),
(NULL, 'Cantante', 5, 1, 0, 1),
(NULL, 'Cantante', 6, 1, 0, 1),
-- Barra: no aparece entre semana, fin de semana 1
(NULL, 'Barra', 0, 0, 1, 1),
(NULL, 'Barra', 1, 0, 1, 1),
(NULL, 'Barra', 2, 0, 1, 1),
(NULL, 'Barra', 3, 0, 1, 1),
(NULL, 'Barra', 4, 0, 1, 1),
(NULL, 'Barra', 5, 1, 0, 1),
(NULL, 'Barra', 6, 1, 0, 1),
-- Lavaplatos: no aparece entre semana, fin de semana 1
(NULL, 'Lavaplatos', 0, 0, 1, 1),
(NULL, 'Lavaplatos', 1, 0, 1, 1),
(NULL, 'Lavaplatos', 2, 0, 1, 1),
(NULL, 'Lavaplatos', 3, 0, 1, 1),
(NULL, 'Lavaplatos', 4, 0, 1, 1),
(NULL, 'Lavaplatos', 5, 1, 0, 1),
(NULL, 'Lavaplatos', 6, 1, 0, 1),
-- Dueño: presencia deseable pero no cuantificada, opcional todos los dias
(NULL, 'Dueño', 0, 1, 1, 1),
(NULL, 'Dueño', 1, 1, 1, 1),
(NULL, 'Dueño', 2, 1, 1, 1),
(NULL, 'Dueño', 3, 1, 1, 1),
(NULL, 'Dueño', 4, 1, 1, 1),
(NULL, 'Dueño', 5, 1, 1, 1),
(NULL, 'Dueño', 6, 1, 1, 1),
-- Preventa: entre semana y sabado 1, domingo 2
(NULL, 'Preventa', 0, 1, 0, 1),
(NULL, 'Preventa', 1, 1, 0, 1),
(NULL, 'Preventa', 2, 1, 0, 1),
(NULL, 'Preventa', 3, 1, 0, 1),
(NULL, 'Preventa', 4, 1, 0, 1),
(NULL, 'Preventa', 5, 1, 0, 1),
(NULL, 'Preventa', 6, 2, 0, 1);
