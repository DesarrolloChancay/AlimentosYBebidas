-- ==========================================
-- Ajuste del modulo de reglamento para bases existentes
-- Destino: PostgreSQL
-- ==========================================

BEGIN;

ALTER TABLE items_reglamento_restaurante
    ADD COLUMN IF NOT EXISTS tipo_validacion VARCHAR(20) NOT NULL DEFAULT 'si_no',
    ADD COLUMN IF NOT EXISTS logica_inversa BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS valor_umbral NUMERIC(10, 2),
    ADD COLUMN IF NOT EXISTS operador_comparacion VARCHAR(10);

ALTER TABLE reuniones_reglamento
    ADD COLUMN IF NOT EXISTS total_puntos INTEGER DEFAULT 0;

ALTER TABLE evaluaciones_reglamento
    ADD COLUMN IF NOT EXISTS puntaje_aplicado INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS valor_medido NUMERIC(10, 2);

CREATE UNIQUE INDEX IF NOT EXISTS uq_reuniones_reglamento_establecimiento_semana
    ON reuniones_reglamento (establecimiento_id, semana, ano);

CREATE UNIQUE INDEX IF NOT EXISTS uq_evaluaciones_reglamento_reunion_item
    ON evaluaciones_reglamento (reunion_id, item_id);

INSERT INTO items_reglamento_restaurante (
    codigo, descripcion, categoria, riesgo, puntaje, tipo_validacion,
    logica_inversa, valor_umbral, operador_comparacion, orden, activo
) VALUES
('A-01', 'Obtener una calificacion Regular x checklist', 'Checklist (3 veces por semana)', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 1, TRUE),
('A-02', 'Obtener una calificacion Mala x checklist', 'Checklist (3 veces por semana)', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 2, TRUE),
('A-03', 'Incumplir 2 veces seguidas o alternadas en una misma semana el mismo item del checklist', 'Checklist (3 veces por semana)', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 3, TRUE),
('A-04', 'Incumplir las observaciones inopinadas (por el personal encargado)', 'Checklist (3 veces por semana)', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 4, TRUE),
('A-05', 'Obtener un porcentaje menor al 85% en las evaluaciones de satisfaccion del cliente', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'porcentaje', FALSE, 85.00, '<', 5, TRUE),
('A-06', 'Obtener un porcentaje menor al 90% en las recomendaciones de los clientes, segun las encuestas', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'porcentaje', FALSE, 90.00, '<', 6, TRUE),
('A-07', 'Si se acumulan 10 comentarios negativos en las encuestas de lunes a viernes', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'numerico', FALSE, 10.00, '>=', 7, TRUE),
('A-08', 'Si se acumulan 15 comentarios negativos en las encuestas de sabado y domingo', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 'numerico', FALSE, 15.00, '>=', 8, TRUE),
('A-09', 'No entregar el libro de reclamaciones cuando sea requerido por los clientes', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 9, TRUE),
('A-10', 'Quejas graves de clientes ya sean en las encuestas o directamente (puede implicar o no libro de reclamaciones)', 'Satisfacción al cliente - Encuestas', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 10, TRUE),
('A-11', 'Realizar publicidad engañosa por no respetar los precios establecidos en las cartas y/o no cumplir con las promociones y/o cortesias ofrecidas', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 11, TRUE),
('A-12', 'El tiempo de espera de un pedido de comida debe durar como maximo 20 minutos y llegar a 20 demoras detiene la venta', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 12, TRUE),
('A-13', 'Permitir que sus trabajadores fijos laboren sin contar con el respectivo carnet de sanidad', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 13, TRUE),
('A-14', 'Contratar trabajadores menores de edad y/o personal extranjero que no cuente con la documentacion correspondiente para trabajar en el pais', 'Incumplimientos Laborales', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 14, TRUE),
('A-15', 'Prohibido contratar personal que este en lista roja', 'Incumplimientos Laborales', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 15, TRUE),
('A-16', 'Contratar al personal de otros concesionarios y/o del castillo mientras laboran en otras entidades y/o antes de cumplir 3 meses desde su ultima relacion laboral sin coordinacion previa', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 16, TRUE),
('A-17', 'No tener al personal en planilla y con contratos', 'Incumplimientos Laborales', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 17, TRUE),
('A-18', 'Incumplimiento de los acuerdos adoptados en las reuniones semanales', 'Otros incumplimientos', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 18, TRUE),
('A-19', 'No cumplir con la programacion semanal del personal acordado en reunion. De lunes a viernes, sabado, domingo o feriado', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 19, TRUE),
('A-20', 'Realizar sus operaciones sin contar con el certificado de fumigacion vigente', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 20, TRUE),
('A-21', 'No preparar el chancho al palo con los parametros de seguridad establecidos segun compromiso firmado', 'Otros incumplimientos', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 21, TRUE),
('A-22', 'Ingreso de mercaderia en horarios no establecidos (6:00-10:00 y 5:00-7:00)', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 22, TRUE),
('A-23', 'Depositar desperdicios o basura en espacios no permitidos y dejar el espacio sucio', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 23, TRUE),
('A-24', 'Anular cupos o tickets sin autorizacion o sin previa autorizacion del Castillo', 'Otros incumplimientos', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 24, TRUE),
('A-25', 'Usar tickets o comandas distintas a las aprobadas', 'Otros incumplimientos', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 25, TRUE),
('A-26', 'Inasistencia injustificada de los dueños de restaurantes o establecimientos concesionados a reuniones semanales, extraordinarias y/o capacitaciones', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 26, TRUE),
('A-27', 'No respetar el monto acordado para los descuentos a los turistas', 'Otros incumplimientos', 'Mayor', 3, 'si_no', TRUE, NULL, NULL, 27, TRUE),
('A-28', 'Falta de respeto entre concesionarios y/o personal', 'Otros incumplimientos', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 28, TRUE),
('A-29', 'Tomar objetos ajenos del restaurante que no le pertenecen', 'Otros incumplimientos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 29, TRUE),
('A-30', 'Adulterar las fechas de rotulado', 'Otros incumplimientos', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 30, TRUE),
('A-31', 'No cumplir con el pago de impuestos (fecha de pagos entre el dia 25 y 30 de cada mes). Enviar los documentos de SUNAT', 'Incumplimiento en pagos', 'Menor', 1, 'si_no', TRUE, NULL, NULL, 31, TRUE),
('A-32', 'No cumplir con el pago a sus proveedores o personal que pueda generar mala reputacion al Castillo', 'Incumplimiento en pagos', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 32, TRUE),
('A-33', 'No cumplir con el pago del alquiler segun las fechas establecidas (50% hasta el dia 7 y 50% restante hasta el dia 15)', 'Incumplimiento en pagos', 'Crítico', 5, 'si_no', TRUE, NULL, NULL, 33, TRUE)
ON CONFLICT (codigo) DO UPDATE SET
    descripcion = EXCLUDED.descripcion,
    categoria = EXCLUDED.categoria,
    riesgo = EXCLUDED.riesgo,
    puntaje = EXCLUDED.puntaje,
    tipo_validacion = EXCLUDED.tipo_validacion,
    logica_inversa = EXCLUDED.logica_inversa,
    valor_umbral = EXCLUDED.valor_umbral,
    operador_comparacion = EXCLUDED.operador_comparacion,
    orden = EXCLUDED.orden,
    activo = EXCLUDED.activo;

UPDATE evaluaciones_reglamento er
SET puntaje_aplicado = i.puntaje
FROM items_reglamento_restaurante i
WHERE i.id = er.item_id
  AND (er.puntaje_aplicado IS NULL OR er.puntaje_aplicado = 0);

WITH resumen AS (
    SELECT
        er.reunion_id,
        COALESCE(SUM(
            CASE
                WHEN er.cumple = FALSE THEN GREATEST(COALESCE(er.numero_infracciones, 0), 1)
                ELSE 0
            END
        ), 0) AS total_infracciones,
        COALESCE(SUM(
            CASE
                WHEN er.cumple = FALSE THEN COALESCE(er.puntaje_aplicado, 0) * GREATEST(COALESCE(er.numero_infracciones, 0), 1)
                ELSE 0
            END
        ), 0) AS total_puntos
    FROM evaluaciones_reglamento er
    GROUP BY er.reunion_id
)
UPDATE reuniones_reglamento rr
SET total_infracciones = COALESCE(r.total_infracciones, 0),
    total_puntos = COALESCE(r.total_puntos, 0),
    total_platos_sancion = CASE
        WHEN COALESCE(r.total_puntos, 0) <= 2 THEN 0
        WHEN COALESCE(r.total_puntos, 0) BETWEEN 3 AND 4 THEN 5
        WHEN COALESCE(r.total_puntos, 0) BETWEEN 5 AND 6 THEN 10
        WHEN COALESCE(r.total_puntos, 0) BETWEEN 7 AND 8 THEN 15
        WHEN COALESCE(r.total_puntos, 0) BETWEEN 9 AND 10 THEN 20
        WHEN COALESCE(r.total_puntos, 0) >= 11 THEN 25
        ELSE 0
    END
FROM resumen r
WHERE rr.id = r.reunion_id;

UPDATE reuniones_reglamento
SET total_infracciones = 0,
    total_puntos = 0,
    total_platos_sancion = 0
WHERE id NOT IN (SELECT reunion_id FROM evaluaciones_reglamento);

COMMIT;
