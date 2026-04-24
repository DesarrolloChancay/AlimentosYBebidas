-- Active: 1765918504258@@3.151.150.11@3306@alimentosybebidas_pruebas
-- Tabla para almacenar evidencias de reuniones del reglamento interno
CREATE TABLE IF NOT EXISTS evidencias_reunion_reglamento (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reunion_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(500) NOT NULL,
    mime_type VARCHAR(100) NULL,
    tamano_bytes INT NULL,
    descripcion VARCHAR(500) NULL,
    uploaded_by INT NULL,
    uploaded_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_evidencias_reunion_reglamento_reunion (reunion_id),
    CONSTRAINT fk_evidencias_reunion_reglamento_reunion
        FOREIGN KEY (reunion_id) REFERENCES reuniones_reglamento(id)
        ON DELETE CASCADE
);