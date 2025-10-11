-- Migración para agregar campo cambiar_contrasena a la tabla usuarios
-- Fecha: 2024
-- Descripción: Agrega campo para controlar si el usuario debe cambiar contraseña en el próximo login

USE alimentosybebidas;

-- Agregar columna cambiar_contrasena con valor por defecto FALSE
ALTER TABLE usuarios
ADD cambiar_contrasena BOOLEAN NOT NULL DEFAULT FALSE;

-- Para usuarios existentes que puedan tener contraseña temporal, marcar como que necesitan cambiar
-- Esto es opcional, dependiendo de si queremos forzar cambio a usuarios existentes
-- UPDATE usuarios SET cambiar_contrasena = TRUE WHERE contrasena LIKE '%Temp123!%' OR LENGTH(contrasena) < 10;