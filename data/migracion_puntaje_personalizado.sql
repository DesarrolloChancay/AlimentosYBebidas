-- Migración para agregar campos de puntaje personalizado a items_plantilla_checklist
-- Fecha: 7 de octubre de 2025

ALTER TABLE items_plantilla_checklist
ADD COLUMN puntaje_minimo_personalizado INT,
ADD COLUMN puntaje_maximo_personalizado INT;

-- Comentarios para documentación
-- COMMENT ON COLUMN items_plantilla_checklist.puntaje_minimo_personalizado IS 'Puntaje mínimo personalizado que reemplaza al del item base';
-- COMMENT ON COLUMN items_plantilla_checklist.puntaje_maximo_personalizado IS 'Puntaje máximo personalizado que reemplaza al del item base';