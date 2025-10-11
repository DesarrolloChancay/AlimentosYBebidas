-- Migración para agregar campo riesgo_personalizado a items_plantilla_checklist
-- Fecha: 7 de octubre de 2025
-- Descripción: Permite personalizar el nivel de riesgo de items individuales en plantillas

ALTER TABLE items_plantilla_checklist ADD riesgo_personalizado VARCHAR(20) NULL;