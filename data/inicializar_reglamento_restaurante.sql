-- ==========================================
-- Script para inicializar Items del Reglamento de Restaurante
-- Basado en "REGLAMENTO RESTAURANTE"
-- ==========================================

-- Crear tabla de items si no existe
CREATE TABLE IF NOT EXISTS items_reglamento_restaurante (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL UNIQUE,
    descripcion TEXT NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    riesgo VARCHAR(20) NOT NULL,
    puntaje INTEGER NOT NULL,
    orden INTEGER DEFAULT 0,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de reuniones si no existe
CREATE TABLE IF NOT EXISTS reuniones_reglamento (
    id SERIAL PRIMARY KEY,
    establecimiento_id INTEGER NOT NULL REFERENCES establecimientos(id),
    semana INTEGER NOT NULL,
    ano INTEGER NOT NULL,
    fecha_reunion DATE NOT NULL,
    fecha_inicio_semana DATE NOT NULL,
    fecha_fin_semana DATE NOT NULL,
    total_inspecciones INTEGER DEFAULT 0,
    total_infracciones INTEGER DEFAULT 0,
    total_platos_sancion INTEGER DEFAULT 0,
    observaciones TEXT,
    estado VARCHAR(20) DEFAULT 'pendiente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de evaluaciones si no existe
CREATE TABLE IF NOT EXISTS evaluaciones_reglamento (
    id SERIAL PRIMARY KEY,
    reunion_id INTEGER NOT NULL REFERENCES reuniones_reglamento(id) ON DELETE CASCADE,
    item_id INTEGER NOT NULL REFERENCES items_reglamento_restaurante(id),
    cumple BOOLEAN NOT NULL,
    numero_infracciones INTEGER DEFAULT 0,
    observacion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Limpiar datos existentes
TRUNCATE items_reglamento_restaurante CASCADE;

-- ==========================================
-- CHECKLIST (3 veces por semana)
-- ==========================================

INSERT INTO items_reglamento_restaurante (codigo, descripcion, categoria, riesgo, puntaje, orden) VALUES
('A-01', 'Obtener una calificación Regular x checklist', 'Checklist (3 veces por semana)', 'Mayor', 3, 1),
('A-02', 'Obtener una calificación Mala x checklist', 'Checklist (3 veces por semana)', 'Crítico', 5, 2),
('A-03', 'Incumplir 2 veces seguidas o alternadas en una misma semana el mismo ítem del check list', 'Checklist (3 veces por semana)', 'Mayor', 3, 3),
('A-04', 'Incumplir las observaciones nominadas (por el personal encargado)', 'Checklist (3 veces por semana)', 'Menor', 1, 4);

-- ==========================================
-- SATISFACCIÓN AL CLIENTE - ENCUESTAS
-- ==========================================

INSERT INTO items_reglamento_restaurante (codigo, descripcion, categoria, riesgo, puntaje, orden) VALUES
('A-05', 'Obtener un promedio menor al 85% en las evaluaciones de satisfacción del cliente', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 5),
('A-06', 'Obtener un % menor al 90% en las recomendaciones de los clientes, según las encuestas', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 6),
('A-07', 'Si se acumulan 10 comentarios en las encuestas de lunes a viernes', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 7),
('A-08', 'Si se acumulan 15 comentarios negativos en las encuestas de sábado y domingo', 'Satisfacción al cliente - Encuestas', 'Menor', 1, 8),
('A-09', 'No entregar el libro de reclamaciones si el cliente lo solicita', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 9),
('A-10', 'Quejas graves de clientes ya sean en las encuestas o directamente (puede implicar o no libro de reclamaciones)', 'Satisfacción al cliente - Encuestas', 'Crítico', 5, 10),
('A-11', 'Realizar publicidad personal que no respete al establecimiento con las cartas y/o no contrate con las promociones y/o cortesías ofrecidas', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 11),
('A-12', 'El tiempo de espera de un pedido de comida debe durar como máximo de 20 minutos y al llegar a las 20 demoras se le para la venta', 'Satisfacción al cliente - Encuestas', 'Mayor', 3, 12);

-- ==========================================
-- INCUMPLIMIENTOS LABORALES
-- ==========================================

INSERT INTO items_reglamento_restaurante (codigo, descripcion, categoria, riesgo, puntaje, orden) VALUES
('A-13', 'Permitir que sus trabajadores fijos laboren sin contar con el respectivo carnet de sanidad', 'Incumplimientos laborales', 'Menor', 1, 13),
('A-14', 'Contratar trabajadores menores de edad y/o extranjeros sin contar con la documentación correspondiente para trabajar en el país', 'Incumplimientos laborales', 'Mayor', 3, 14),
('A-15', 'Prohibido contratar personal que este en lista roja', 'Incumplimientos laborales', 'Mayor', 3, 15),
('A-16', 'Contratar al personal en planilla y con contratos. No con casilla VD del castillo mientras los mismos se encuentran laborando en dichas otras entidades y/o antes que se cumplan los 3 meses desde que culmino su relación laboral con su anterior empleador o previa coordinación con el concesionario anterior', 'Incumplimientos laborales', 'Menor', 1, 16),
('A-17', 'No tener el personal en planilla y con contratos', 'Incumplimientos laborales', 'Menor', 1, 17);

-- ==========================================
-- OTROS INCUMPLIMIENTOS
-- ==========================================

INSERT INTO items_reglamento_restaurante (codigo, descripcion, categoria, riesgo, puntaje, orden) VALUES
('A-18', 'Incumplimiento de los acuerdos adoptados en las reuniones semanales', 'Otros incumplimientos', 'Mayor', 3, 18),
('A-19', 'No cumplir con la programación semanal del personal acordado en reunión. De lunes a viernes. De sábado o de Domingo o feriado', 'Otros incumplimientos', 'Menor', 1, 19),
('A-20', 'Realizar sus operaciones sin contar con el certificado de fumigación vigente', 'Otros incumplimientos', 'Menor', 1, 20),
('A-21', 'No preparar el chancho al palo con los parámetros de seguridad establecidos. (según compromiso firmado)', 'Otros incumplimientos', 'Mayor', 3, 21),
('A-22', 'Ingreso de mercadería a través del bodestock, (5.00% hasta $ 500 y 7.00)', 'Otros incumplimientos', 'Menor', 1, 22),
('A-23', 'Depositar desperdicios o basura en espacios no permitidos y dejar el espacio sucio. (en el depósito del castillo, mas no en los tachos dentro del castillo)', 'Otros incumplimientos', 'Menor', 1, 23),
('A-24', 'Anular comandas directas o sin previa aprobación del castillo', 'Otros incumplimientos', 'Mayor', 3, 24),
('A-25', 'Usar tickets o comandas distintas a las aprobadas', 'Otros incumplimientos', 'Mayor', 3, 25),
('A-26', 'Insistencia injustificada de los dueños de los restaurantes o establecimientos concesionados a las reuniones semanales, reuniones extraordinarias y/o capacitaciones programadas', 'Otros incumplimientos', 'Menor', 1, 26),
('A-27', 'No respetar el monto acordado para los descuentos a los turistas', 'Otros incumplimientos', 'Mayor', 3, 27),
('A-28', 'Falta de respeto entre concesionarios y/o personal', 'Otros incumplimientos', 'Crítico', 5, 28),
('A-29', 'Tomar objetos ajenos del restaurante que no le pertenecen', 'Otros incumplimientos', 'Menor', 1, 29),
('A-30', 'Adulterar las fechas de rotulado', 'Otros incumplimientos', 'Crítico', 5, 30);

-- ==========================================
-- INCUMPLIMIENTO EN PAGOS
-- ==========================================

INSERT INTO items_reglamento_restaurante (codigo, descripcion, categoria, riesgo, puntaje, orden) VALUES
('A-30', 'No cumplir con el pago de impuestos (fecha de pagos entre el día 25 al 30 de cada mes). Enviar los documentos de SUNAT', 'Incumplimiento en pagos', 'Menor', 1, 31),
('A-31', 'No cumplir con el pago a sus proveedores o personal que pueda generar mala reputación al Castillo', 'Incumplimiento en pagos', 'Crítico', 5, 32),
('A-32', 'No cumplir con el pago del alquiler según las fechas establecidas. (50% hasta el día 7 y el 50% restante hasta el día 15)', 'Incumplimiento en pagos', 'Crítico', 5, 33);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_reuniones_establecimiento ON reuniones_reglamento(establecimiento_id);
CREATE INDEX IF NOT EXISTS idx_reuniones_fecha ON reuniones_reglamento(fecha_reunion);
CREATE INDEX IF NOT EXISTS idx_evaluaciones_reunion ON evaluaciones_reglamento(reunion_id);
CREATE INDEX IF NOT EXISTS idx_items_activo ON items_reglamento_restaurante(activo);

-- Verificar la inserción
SELECT 
    COUNT(*) as total_items,
    COUNT(*) FILTER (WHERE riesgo = 'Mayor') as items_mayor,
    COUNT(*) FILTER (WHERE riesgo = 'Crítico') as items_critico,
    COUNT(*) FILTER (WHERE riesgo = 'Menor') as items_menor
FROM items_reglamento_restaurante;

COMMIT;
