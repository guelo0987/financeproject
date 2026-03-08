-- ================================================================
-- MENUDO — Complete Seed Data + Schema Analysis
-- ================================================================
-- Scenario: Two Dominican users (Marcos & Laura) who are partners.
-- They share a household space, each has personal accounts,
-- investments, budgets, and a full month of transactions (March 2026).
-- ================================================================

-- ────────────────────────────────────────────
-- PART 0: MISSING SCHEMA (tables/columns the frontend needs)
-- ────────────────────────────────────────────

-- The frontend's MenudoTransaction model has a `nota` field. DB is missing it.
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS nota text;

-- Budgets — the frontend has MenudoBudget, DB has nothing for it.
CREATE TABLE IF NOT EXISTS presupuestos (
  presupuesto_id  bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id      bigint NOT NULL REFERENCES usuarios(usuario_id),
  espacio_id      bigint REFERENCES espacios_compartidos(espacio_id),
  nombre          text NOT NULL,
  periodo         text NOT NULL CHECK (periodo IN ('mensual','quincenal','semanal','unico')),
  dia_inicio      int  NOT NULL DEFAULT 1 CHECK (dia_inicio BETWEEN 1 AND 31),
  ingresos        numeric NOT NULL DEFAULT 0,
  activo          boolean NOT NULL DEFAULT true,
  creado_en       timestamptz NOT NULL DEFAULT now(),
  actualizado_en  timestamptz NOT NULL DEFAULT now()
);

-- Budget → category spending limits (frontend: BudgetCategory.limite)
CREATE TABLE IF NOT EXISTS presupuesto_categorias (
  presupuesto_id  bigint NOT NULL REFERENCES presupuestos(presupuesto_id) ON DELETE CASCADE,
  categoria_id    bigint NOT NULL REFERENCES categorias(categoria_id),
  limite          numeric NOT NULL CHECK (limite > 0),
  PRIMARY KEY (presupuesto_id, categoria_id)
);

-- Recurring transactions (frontend: RecurringTransaction)
CREATE TABLE IF NOT EXISTS transacciones_recurrentes (
  recurrente_id     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id        bigint NOT NULL REFERENCES usuarios(usuario_id),
  activo_id         bigint REFERENCES activos(activo_id),
  categoria_id      bigint REFERENCES categorias(categoria_id),
  tipo              tipo_transaccion NOT NULL,
  monto             numeric NOT NULL CHECK (monto > 0),
  moneda            text NOT NULL DEFAULT 'DOP' CHECK (moneda IN ('DOP','USD')),
  descripcion       text,
  frecuencia        text NOT NULL CHECK (frecuencia IN ('mensual','quincenal','semanal')),
  dia_ejecucion     int  NOT NULL CHECK (dia_ejecucion BETWEEN 1 AND 31),
  activo            boolean NOT NULL DEFAULT true,
  proxima_ejecucion date,
  creado_en         timestamptz NOT NULL DEFAULT now(),
  actualizado_en    timestamptz NOT NULL DEFAULT now()
);


-- ────────────────────────────────────────────
-- PART 1: USUARIOS
-- ────────────────────────────────────────────
-- Marcos: salaried professional, active investor.
-- Laura:  freelance designer, early-stage saver.

INSERT INTO usuarios (usuario_id, nombre, email, password_hash, moneda_base, meta_financiera, meta_monto, meta_fecha)
OVERRIDING SYSTEM VALUE VALUES
  (1, 'Marcos Cruz',  'marcos@menudo.do',  '$2b$10$placeholder_hash_marcos', 'DOP', 'Fondo de emergencia de 500K', 500000, '2027-01-01'),
  (2, 'Laura Pérez',  'laura@menudo.do',   '$2b$10$placeholder_hash_laura',  'DOP', 'Viaje a Europa',              250000, '2026-12-15');


-- ────────────────────────────────────────────
-- PART 2: CATEGORÍAS
-- ────────────────────────────────────────────
-- System categories (usuario_id = NULL, es_sistema = true)
-- + a few custom categories per user.

INSERT INTO categorias (categoria_id, usuario_id, nombre, tipo, icono, color_hex, es_sistema)
OVERRIDING SYSTEM VALUE VALUES
  -- ── System: gastos ──
  ( 1, NULL, 'Vivienda',        'gasto',   'home',           '#3D6B5E', true),
  ( 2, NULL, 'Comida',          'gasto',   'utensils',       '#D4894A', true),
  ( 3, NULL, 'Transporte',      'gasto',   'car',            '#7C5CBF', true),
  ( 4, NULL, 'Entretenimiento', 'gasto',   'tv',             '#D45B8E', true),
  ( 5, NULL, 'Salud',           'gasto',   'heart-pulse',    '#4A90D9', true),
  ( 6, NULL, 'Educación',       'gasto',   'book-open',      '#5BBFD4', true),
  ( 7, NULL, 'Estilo de vida',  'gasto',   'sparkles',       '#D4A84A', true),
  ( 8, NULL, 'Servicios',       'gasto',   'wifi',           '#8B8B8B', true),
  -- ── System: ingresos ──
  ( 9, NULL, 'Salario',         'ingreso', 'landmark',       '#2E8B57', true),
  (10, NULL, 'Freelance',       'ingreso', 'monitor',        '#4682B4', true),
  (11, NULL, 'Inversiones',     'ingreso', 'trending-up',    '#DAA520', true),
  -- ── Custom: Marcos ──
  (12,    1, 'Gym',             'gasto',   'dumbbell',       '#E07A5F', false),
  (13,    1, 'Mascotas',        'gasto',   'dog',            '#81B29A', false),
  -- ── Custom: Laura ──
  (14,    2, 'Materiales arte', 'gasto',   'palette',        '#9B59B6', false),
  (15,    2, 'Cursos online',   'gasto',   'graduation-cap', '#3498DB', false);


-- ────────────────────────────────────────────
-- PART 3: ACTIVOS (wallets + investments + property)
-- ────────────────────────────────────────────
-- The DB uses "activos" for BOTH wallet accounts and investment assets.
-- tipo_activo enum: efectivo, cuenta_bancaria, inversion, crypto, inmueble, vehiculo, otro
--
-- Frontend's WalletAccount maps to:  tipo IN ('efectivo','cuenta_bancaria')
-- Frontend's Asset maps to:          tipo IN ('inversion','crypto','inmueble','vehiculo')

INSERT INTO activos (activo_id, usuario_id, nombre, tipo, institucion_nombre, institucion_codigo, moneda, valor_actual, ticker_simbolo)
OVERRIDING SYSTEM VALUE VALUES
  -- ── Marcos: wallets ──
  (1, 1, 'BHD León — Nómina',     'cuenta_bancaria', 'Banco BHD León',     'BHD',  'DOP',   45000.00, NULL),
  (2, 1, 'Popular — Crédito',     'cuenta_bancaria', 'Banco Popular',      'BPD',  'DOP',       0.00, NULL),   -- NOTE: credit card balance can't go negative (valor_actual >= 0). See analysis.
  (3, 1, 'Efectivo',              'efectivo',         NULL,                  NULL,  'DOP',    3200.00, NULL),
  (4, 1, 'Fondo Emergencia',      'cuenta_bancaria', 'Banco BHD León',     'BHD',  'DOP',  100000.00, NULL),
  -- ── Marcos: investments ──
  (5, 1, 'Apartamento Piantini',  'inmueble',         NULL,                  NULL,  'DOP', 5500000.00, NULL),
  (6, 1, 'Bitcoin',               'crypto',           NULL,                  NULL,  'USD',   15000.00, 'BTC'),
  (7, 1, 'AFI Popular',           'inversion',       'AFP Popular',        'AFPP',  'DOP',  320000.00, NULL),
  -- ── Laura: wallets ──
  (8, 2, 'Banreservas — Nómina',  'cuenta_bancaria', 'Banreservas',        'BNR',  'DOP',   28000.00, NULL),
  (9, 2, 'Efectivo',              'efectivo',         NULL,                  NULL,  'DOP',    1500.00, NULL),
  -- ── Laura: investments ──
  (10, 2, 'Ethereum',             'crypto',           NULL,                  NULL,  'USD',    3200.00, 'ETH');


-- ────────────────────────────────────────────
-- PART 4: HISTORIAL VALORES ACTIVOS (sparkline data)
-- ────────────────────────────────────────────
-- Bitcoin price history (in USD, activo 6)
INSERT INTO historial_valores_activos (activo_id, fecha, valor, moneda) VALUES
  (6, '2026-02-01', 12500.00, 'USD'),
  (6, '2026-02-08', 13100.00, 'USD'),
  (6, '2026-02-15', 12800.00, 'USD'),
  (6, '2026-02-22', 14200.00, 'USD'),
  (6, '2026-03-01', 14800.00, 'USD'),
  (6, '2026-03-08', 15000.00, 'USD');

-- Ethereum (activo 10)
INSERT INTO historial_valores_activos (activo_id, fecha, valor, moneda) VALUES
  (10, '2026-02-01', 2800.00, 'USD'),
  (10, '2026-02-15', 3000.00, 'USD'),
  (10, '2026-03-01', 3100.00, 'USD'),
  (10, '2026-03-08', 3200.00, 'USD');

-- Apartamento Piantini (activo 5) — quarterly
INSERT INTO historial_valores_activos (activo_id, fecha, valor, moneda) VALUES
  (5, '2025-06-01', 5200000.00, 'DOP'),
  (5, '2025-09-01', 5350000.00, 'DOP'),
  (5, '2025-12-01', 5450000.00, 'DOP'),
  (5, '2026-03-01', 5500000.00, 'DOP');

-- AFI Popular (activo 7) — monthly
INSERT INTO historial_valores_activos (activo_id, fecha, valor, moneda) VALUES
  (7, '2025-12-01', 305000.00, 'DOP'),
  (7, '2026-01-01', 310000.00, 'DOP'),
  (7, '2026-02-01', 315000.00, 'DOP'),
  (7, '2026-03-01', 320000.00, 'DOP');


-- ────────────────────────────────────────────
-- PART 5: ESPACIOS COMPARTIDOS + MIEMBROS
-- ────────────────────────────────────────────
-- Marcos & Laura share a household space.

INSERT INTO espacios_compartidos (espacio_id, nombre, descripcion, creado_por)
OVERRIDING SYSTEM VALUE VALUES
  (1, 'Casa Marcos & Laura', 'Gastos del hogar compartidos', 1);

INSERT INTO espacio_miembros (espacio_id, usuario_id, rol) VALUES
  (1, 1, 'admin'),
  (1, 2, 'miembro');

-- Marcos invited a friend (pending)
INSERT INTO espacio_invitaciones (invitacion_id, espacio_id, invitado_por, email_invitado)
OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 1, 'carlos@gmail.com');
  -- token, estado('pendiente'), expira_en all use defaults


-- ────────────────────────────────────────────
-- PART 6: TRANSACCIONES (March 2026 — full month)
-- ────────────────────────────────────────────
-- monto is ALWAYS positive (CHECK monto > 0). The 'tipo' column
-- determines if it's income, expense, or transfer.
-- origen defaults to 'app'. moneda defaults to 'DOP'.

INSERT INTO transacciones (transaccion_id, usuario_id, activo_id, activo_destino_id, tipo, monto, categoria_id, descripcion, fecha, nota, espacio_id)
OVERRIDING SYSTEM VALUE VALUES
  -- ═══════════════════════════════════════
  -- MARCOS — Ingresos
  -- ═══════════════════════════════════════
  ( 1, 1,  1, NULL, 'ingreso',       85000.00,  9, 'Salario BHD León',       '2026-03-01', 'Nómina mensual',               NULL),
  ( 2, 1,  1, NULL, 'ingreso',       10000.00, 10, 'Freelance diseño web',   '2026-03-01', 'Landing page para cliente DR',  NULL),

  -- ═══════════════════════════════════════
  -- MARCOS — Transferencias
  -- ═══════════════════════════════════════
  ( 3, 1,  1,    4, 'transferencia',  5000.00, NULL, 'Ahorro mensual',        '2026-03-03', 'Aporte al fondo de emergencia', NULL),
  ( 4, 1,  1,    3, 'transferencia',  3000.00, NULL, 'Retiro cajero',         '2026-03-10', NULL,                            NULL),

  -- ═══════════════════════════════════════
  -- MARCOS — Gastos personales
  -- ═══════════════════════════════════════
  ( 5, 1,  1, NULL, 'gasto',         25000.00,  1, 'Pago alquiler',          '2026-03-01', NULL,                              1),  -- shared space
  ( 6, 1,  1, NULL, 'gasto',          4500.00,  2, 'Supermercado Nacional',  '2026-03-02', 'Compra semanal',                  1),  -- shared
  ( 7, 1,  1, NULL, 'gasto',           350.00,  4, 'Spotify Premium',       '2026-03-02', NULL,                            NULL),
  ( 8, 1,  3, NULL, 'gasto',          1200.00,  5, 'Farmacia Carol',        '2026-03-04', 'Medicamentos gripe',            NULL),  -- cash
  ( 9, 1,  1, NULL, 'gasto',          2000.00,  3, 'Gasolina Shell',        '2026-03-05', NULL,                            NULL),
  (10, 1,  1, NULL, 'gasto',          2500.00,  8, 'Internet Claro',        '2026-03-05', 'Fibra 200Mbps',                   1),  -- shared
  (11, 1,  1, NULL, 'gasto',           850.00,  6, 'Libro programación',    '2026-03-06', 'System Design Interview',       NULL),
  (12, 1,  1, NULL, 'gasto',          4000.00,  2, 'Cena en SBG',           '2026-03-07', 'Cumpleaños de Carlos',          NULL),
  (13, 1,  1, NULL, 'gasto',           450.00,  3, 'Uber a casa',           '2026-03-07', NULL,                            NULL),
  (14, 1,  1, NULL, 'gasto',           750.00,  4, 'Netflix',               '2026-03-07', 'Plan múltiple pantallas',       NULL),
  (15, 1,  1, NULL, 'gasto',          2500.00, 12, 'Gym Body Shop',         '2026-03-08', 'Mensualidad marzo',             NULL),
  (16, 1,  3, NULL, 'gasto',           600.00, 13, 'Veterinario Max',       '2026-03-09', 'Vacuna antirrábica',            NULL),  -- cash
  (17, 1,  1, NULL, 'gasto',          1800.00,  3, 'Gasolina Total',        '2026-03-12', NULL,                            NULL),
  (18, 1,  1, NULL, 'gasto',          3500.00,  2, 'Supermercado Bravo',    '2026-03-14', NULL,                              1),  -- shared
  (19, 1,  1, NULL, 'gasto',          1500.00,  7, 'Ropa Zara',             '2026-03-15', 'Camisa oficina',                NULL),
  (20, 1,  3, NULL, 'gasto',           250.00,  2, 'Cafetería Don Pan',     '2026-03-16', NULL,                            NULL),  -- cash
  (21, 1,  1, NULL, 'gasto',          1200.00,  3, 'Peaje + parking',       '2026-03-18', 'Viaje Santiago trabajo',        NULL),
  (22, 1,  1, NULL, 'gasto',          5500.00,  2, 'Supermercado Nacional',  '2026-03-21', 'Compra grande del mes',           1),  -- shared
  (23, 1,  1, NULL, 'gasto',          2200.00,  7, 'Barbería + productos',  '2026-03-22', NULL,                            NULL),
  (24, 1,  1, NULL, 'gasto',          3000.00,  4, 'Boletos cine + cena',   '2026-03-23', 'Salida con Laura',              NULL),
  (25, 1,  1, NULL, 'gasto',          1800.00,  8, 'Agua CAASD',            '2026-03-25', NULL,                              1),  -- shared
  (26, 1,  1, NULL, 'gasto',          4200.00,  8, 'Luz EDESUR',            '2026-03-26', NULL,                              1),  -- shared

  -- ═══════════════════════════════════════
  -- LAURA — Ingresos
  -- ═══════════════════════════════════════
  (27, 2,  8, NULL, 'ingreso',       25000.00, 10, 'Freelance branding Café Lina',   '2026-03-01', 'Proyecto completo',     NULL),
  (28, 2,  8, NULL, 'ingreso',       15000.00, 10, 'Logo rediseño RD Solar',         '2026-03-06', NULL,                    NULL),
  (29, 2,  8, NULL, 'ingreso',        8000.00, 10, 'Ilustraciones Instagram',        '2026-03-18', '10 ilustraciones',      NULL),

  -- ═══════════════════════════════════════
  -- LAURA — Transferencias
  -- ═══════════════════════════════════════
  (30, 2,  8,    9, 'transferencia',  2000.00, NULL, 'Retiro efectivo',       '2026-03-04', NULL,                            NULL),

  -- ═══════════════════════════════════════
  -- LAURA — Gastos personales
  -- ═══════════════════════════════════════
  (31, 2,  8, NULL, 'gasto',          3200.00,  2, 'Supermercado Jumbo',     '2026-03-02', NULL,                              1),  -- shared
  (32, 2,  9, NULL, 'gasto',           380.00,  3, 'Uber Gazcue → PUCMM',   '2026-03-03', NULL,                            NULL),  -- cash
  (33, 2,  8, NULL, 'gasto',          1800.00, 14, 'Materiales arte',        '2026-03-05', 'Acuarelas Winsor & Newton',     NULL),
  (34, 2,  8, NULL, 'gasto',          3500.00,  8, 'Luz EDENORTE',           '2026-03-07', NULL,                              1),  -- shared
  (35, 2,  8, NULL, 'gasto',          2500.00, 15, 'Curso Domestika',        '2026-03-09', 'Lettering avanzado',            NULL),
  (36, 2,  9, NULL, 'gasto',           450.00,  2, 'Almuerzo con amiga',     '2026-03-10', NULL,                            NULL),  -- cash
  (37, 2,  8, NULL, 'gasto',          1200.00,  5, 'Consulta dentista',      '2026-03-12', NULL,                            NULL),
  (38, 2,  8, NULL, 'gasto',           950.00,  7, 'Skincare',               '2026-03-14', NULL,                            NULL),
  (39, 2,  8, NULL, 'gasto',          4200.00,  2, 'Supermercado Nacional',   '2026-03-20', 'Compra semanal',                  1),  -- shared
  (40, 2,  9, NULL, 'gasto',           300.00,  3, 'Motoconcho',             '2026-03-22', NULL,                            NULL),  -- cash
  (41, 2,  8, NULL, 'gasto',          1500.00, 14, 'Lienzos y pinceles',     '2026-03-24', NULL,                            NULL),
  (42, 2,  8, NULL, 'gasto',          2800.00,  2, 'Supermercado Bravo',     '2026-03-28', NULL,                              1);  -- shared


-- ────────────────────────────────────────────
-- PART 7: PRESUPUESTOS + LÍMITES POR CATEGORÍA
-- ────────────────────────────────────────────

INSERT INTO presupuestos (presupuesto_id, usuario_id, espacio_id, nombre, periodo, dia_inicio, ingresos, activo)
OVERRIDING SYSTEM VALUE VALUES
  (1, 1, NULL, 'Mi Mes 🇩🇴',             'mensual', 1, 95000, true),
  (2, 1,    1, 'Casa',                    'mensual', 1, 50000, true),   -- shared household budget
  (3, 2, NULL, 'Presupuesto Laura',       'mensual', 1, 48000, true),
  (4, 1, NULL, 'Viaje a Punta Cana',      'unico',  15, 40000, false); -- inactive past trip

INSERT INTO presupuesto_categorias (presupuesto_id, categoria_id, limite) VALUES
  -- Budget 1: "Mi Mes" (Marcos personal)
  (1,  1, 25000),  -- Vivienda
  (1,  2, 15000),  -- Comida
  (1,  3,  8000),  -- Transporte
  (1,  4,  5000),  -- Entretenimiento
  (1,  7, 12000),  -- Estilo de vida
  (1, 12,  3000),  -- Gym
  -- Budget 2: "Casa" (shared)
  (2,  1, 25000),  -- Vivienda (alquiler)
  (2,  2, 25000),  -- Comida (supermercado compartido)
  (2,  8, 10000),  -- Servicios (luz, agua, internet)
  -- Budget 3: "Presupuesto Laura"
  (3,  2, 10000),  -- Comida
  (3,  3,  3000),  -- Transporte
  (3, 14,  5000),  -- Materiales arte
  (3, 15,  4000),  -- Cursos online
  (3,  5,  3000),  -- Salud
  (3,  7,  3000),  -- Estilo de vida
  -- Budget 4: "Viaje Punta Cana" (inactive)
  (4,  2, 10000),  -- Comida
  (4,  7, 15000);  -- Estilo (tours/actividades)


-- ────────────────────────────────────────────
-- PART 8: TRANSACCIONES RECURRENTES
-- ────────────────────────────────────────────

INSERT INTO transacciones_recurrentes (recurrente_id, usuario_id, activo_id, categoria_id, tipo, monto, descripcion, frecuencia, dia_ejecucion, activo, proxima_ejecucion)
OVERRIDING SYSTEM VALUE VALUES
  -- Marcos
  (1, 1, 1,  9, 'ingreso',  85000, 'Salario BHD León',   'mensual', 1,  true,  '2026-04-01'),
  (2, 1, 1,  1, 'gasto',    25000, 'Pago alquiler',      'mensual', 1,  true,  '2026-04-01'),
  (3, 1, 1,  4, 'gasto',      750, 'Netflix',            'mensual', 7,  true,  '2026-04-07'),
  (4, 1, 1,  4, 'gasto',      350, 'Spotify Premium',    'mensual', 2,  true,  '2026-04-02'),
  (5, 1, 1, 12, 'gasto',     2500, 'Gym Body Shop',      'mensual', 1,  true,  '2026-04-01'),
  (6, 1, 1,  4, 'gasto',      550, 'Disney+',            'mensual', 15, false, NULL),  -- cancelled
  -- Laura
  (7, 2, 8,  8, 'gasto',     2500, 'Internet compartido','mensual', 5,  true,  '2026-04-05');


-- ────────────────────────────────────────────
-- PART 9: SUSCRIPCIONES (app plan)
-- ────────────────────────────────────────────

INSERT INTO suscripciones (suscripcion_id, usuario_id, estado, plan, precio_usd, trial_inicio, trial_fin, periodo_inicio, periodo_fin)
OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 'activa',  'mensual', 5.00, '2026-01-01', '2026-01-06', '2026-01-06', '2026-04-06'),
  (2, 2, 'prueba',  'mensual', 5.00, '2026-03-01', '2026-03-06', NULL,         NULL);


-- ────────────────────────────────────────────
-- PART 10: ALERTAS
-- ────────────────────────────────────────────

INSERT INTO alertas (alerta_id, usuario_id, tipo, titulo, cuerpo, datos_extra, espacio_id)
OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 'gasto_elevado',
    'Gastaste más de lo usual en Comida',
    'Llevas RD$ 17,950 en Comida este mes. Tu promedio es RD$ 12,000.',
    '{"categoria": "Comida", "monto_actual": 17950, "promedio": 12000}',
    NULL),
  (2, 2, 'meta_progreso',
    'Progreso: Viaje a Europa',
    'Llevas un 12% de tu meta. ¡Sigue ahorrando!',
    '{"meta": "Viaje a Europa", "progreso_pct": 12, "acumulado": 30000}',
    NULL),
  (3, 1, 'oportunidad_inversion',
    'Bitcoin subió 20% este mes',
    'Tu posición en BTC pasó de $12,500 a $15,000 USD.',
    '{"activo": "Bitcoin", "cambio_pct": 20}',
    NULL),
  (4, 1, 'suscripcion_vence',
    'Tu suscripción Menudo se renueva pronto',
    'Se renovará el 6 de abril por USD $5.00.',
    '{"fecha_renovacion": "2026-04-06", "monto": 5.00}',
    NULL),
  (5, 1, 'ia_insight',
    'Podrías ahorrar RD$ 3,500 al mes',
    'Tus gastos en Entretenimiento han crecido 40% en los últimos 3 meses. Considera establecer un límite.',
    '{"tipo_insight": "reduccion_gasto", "categoria": "Entretenimiento", "ahorro_potencial": 3500}',
    NULL);


-- ────────────────────────────────────────────
-- PART 11: CACHE — TASAS DE CAMBIO
-- ────────────────────────────────────────────

INSERT INTO cache_tasas_cambio (moneda_origen, moneda_destino, tasa, fuente, valido_hasta) VALUES
  ('USD', 'DOP', 58.50, 'bcrd', '2026-03-09 00:00:00+00'),
  ('DOP', 'USD',  0.0171, 'bcrd', '2026-03-09 00:00:00+00');


-- ────────────────────────────────────────────
-- PART 12: CACHE — PRECIOS CRYPTO
-- ────────────────────────────────────────────

INSERT INTO cache_precios_crypto (simbolo, nombre, precio_usd, cambio_24h_pct) VALUES
  ('BTC',  'Bitcoin',    65000.00,  2.30),
  ('ETH',  'Ethereum',    3200.00, -0.80),
  ('SOL',  'Solana',       145.00,  5.10),
  ('USDT', 'Tether',        1.00,  0.00);


-- ────────────────────────────────────────────
-- PART 13: CACHE — PRECIOS MERCADO
-- ────────────────────────────────────────────

INSERT INTO cache_precios_mercado (simbolo, nombre, tipo, precio_usd, cambio_24h_pct) VALUES
  ('SPY',  'S&P 500 ETF',       'etf',       520.00,  0.45),
  ('QQQ',  'Nasdaq 100 ETF',    'etf',       440.00, -0.30),
  ('GLD',  'Gold ETF',          'commodity', 215.00,  1.20),
  ('DJI',  'Dow Jones',         'indice',  39500.00,  0.15);


-- ────────────────────────────────────────────
-- PART 14: SYNC LOG
-- ────────────────────────────────────────────

INSERT INTO sync_log (sync_id, fuente, tabla_cache, registros_actualizados, estado, completado_en)
OVERRIDING SYSTEM VALUE VALUES
  (1, 'bcrd',             'cache_tasas_cambio',     2, 'exitoso', now()),
  (2, 'exchangerate_api', 'cache_precios_crypto',   4, 'exitoso', now()),
  (3, 'exchangerate_api', 'cache_precios_mercado',  4, 'parcial', now());


-- ────────────────────────────────────────────
-- PART 15: RESET SEQUENCES
-- ────────────────────────────────────────────
-- After inserting with explicit IDs, advance identity sequences
-- so future inserts don't collide.

SELECT setval(pg_get_serial_sequence('usuarios',                'usuario_id'),      (SELECT MAX(usuario_id)      FROM usuarios));
SELECT setval(pg_get_serial_sequence('categorias',              'categoria_id'),     (SELECT MAX(categoria_id)     FROM categorias));
SELECT setval(pg_get_serial_sequence('activos',                 'activo_id'),        (SELECT MAX(activo_id)        FROM activos));
SELECT setval(pg_get_serial_sequence('espacios_compartidos',    'espacio_id'),       (SELECT MAX(espacio_id)       FROM espacios_compartidos));
SELECT setval(pg_get_serial_sequence('espacio_invitaciones',    'invitacion_id'),    (SELECT MAX(invitacion_id)    FROM espacio_invitaciones));
SELECT setval(pg_get_serial_sequence('transacciones',           'transaccion_id'),   (SELECT MAX(transaccion_id)   FROM transacciones));
SELECT setval(pg_get_serial_sequence('presupuestos',            'presupuesto_id'),   (SELECT MAX(presupuesto_id)   FROM presupuestos));
SELECT setval(pg_get_serial_sequence('transacciones_recurrentes','recurrente_id'),   (SELECT MAX(recurrente_id)    FROM transacciones_recurrentes));
SELECT setval(pg_get_serial_sequence('suscripciones',           'suscripcion_id'),   (SELECT MAX(suscripcion_id)   FROM suscripciones));
SELECT setval(pg_get_serial_sequence('alertas',                 'alerta_id'),        (SELECT MAX(alerta_id)        FROM alertas));
SELECT setval(pg_get_serial_sequence('sync_log',                'sync_id'),          (SELECT MAX(sync_id)          FROM sync_log));


-- ================================================================
-- PART 16: ANALYSIS — UNNECESSARY OR PROBLEMATIC COLUMNS/TABLES
-- ================================================================
--
-- ┌─────────────────────────────────────────────────────────────────┐
-- │ COLUMNS THAT ARE UNNECESSARY OR REDUNDANT                      │
-- ├─────────────────────────────────────────────────────────────────┤
-- │                                                                 │
-- │ 1. historial_valores_activos.moneda                             │
-- │    WHY: The currency is already stored in activos.moneda.       │
-- │    An asset doesn't change currency. This is duplicated data    │
-- │    on every row. JOIN to activos to get it.                     │
-- │    → DROP COLUMN or ignore.                                     │
-- │                                                                 │
-- │ 2. transacciones.categoria_ia_sugerida (text)                   │
-- │    WHY: This stores a free-text category name. But you already  │
-- │    have categoria_id (FK to categorias). If AI suggests a       │
-- │    category, just set categoria_id to the suggested one and use │
-- │    categoria_ia_confianza for the confidence score. A separate  │
-- │    text field will drift out of sync with the categorias table. │
-- │    → DROP COLUMN. Keep only categoria_ia_confianza.             │
-- │                                                                 │
-- │ 3. transacciones.monto_dop                                      │
-- │    WHY: This is monto × tasa_cambio. Storing a computed value   │
-- │    means you have to keep it in sync. You can compute it in a   │
-- │    VIEW or GENERATED COLUMN instead.                            │
-- │    → Either make it a GENERATED ALWAYS AS (monto * COALESCE(    │
-- │      tasa_cambio,1)) STORED column, or drop it and use a view. │
-- │                                                                 │
-- │ 4. activos.institucion_codigo                                   │
-- │    WHY: This is a bank code like 'BHD', 'BPD'. The app never   │
-- │    displays it — it shows institucion_nombre. Unless you plan   │
-- │    to integrate with a banking API that needs the code, this    │
-- │    column adds nothing. I filled it in the seed but it felt     │
-- │    forced every time.                                           │
-- │    → DROP COLUMN unless you're building open-banking.           │
-- │                                                                 │
-- │ 5. usuarios.password_hash                                       │
-- │    WHY: If you're using Supabase Auth, passwords live in        │
-- │    auth.users and are managed by GoTrue. Storing your own       │
-- │    password_hash in a public table is a security liability AND  │
-- │    redundant. Your usuarios table should reference              │
-- │    auth.users.id via a UUID column instead.                     │
-- │    → REPLACE with: auth_uid UUID REFERENCES auth.users(id).    │
-- │                                                                 │
-- │ 6. suscripciones.apple_product_id                               │
-- │    WHY: RevenueCat abstracts over Apple/Google product IDs.     │
-- │    If you're using RevenueCat (you have revenuecat_id), you     │
-- │    never need the raw Apple product ID in your own DB.          │
-- │    RevenueCat's webhook/SDK provides this.                      │
-- │    → DROP COLUMN.                                               │
-- │                                                                 │
-- ├─────────────────────────────────────────────────────────────────┤
-- │ TABLES THAT ARE PREMATURE / CAN WAIT                           │
-- ├─────────────────────────────────────────────────────────────────┤
-- │                                                                 │
-- │ 7. cache_precios_mercado                                        │
-- │    WHY: For a personal finance app targeting Dominicans, stock/ │
-- │    ETF prices are a future feature. You don't have a screen    │
-- │    that displays SPY or QQQ data. This table adds schema       │
-- │    weight with zero frontend consumption right now.             │
-- │    → KEEP the table definition, but don't invest in the sync   │
-- │      pipeline until the Invest screen actually uses it.         │
-- │                                                                 │
-- │ 8. sync_log                                                     │
-- │    WHY: Operational infrastructure table. Fine to have, but    │
-- │    for MVP it's overhead. A cron job that fetches exchange      │
-- │    rates doesn't need audit logging yet. Add it when you have  │
-- │    multiple sync sources and need to debug failures.            │
-- │    → LOW PRIORITY, not blocking.                                │
-- │                                                                 │
-- ├─────────────────────────────────────────────────────────────────┤
-- │ DESIGN ISSUES NOTICED WHILE WRITING SEED DATA                 │
-- ├─────────────────────────────────────────────────────────────────┤
-- │                                                                 │
-- │ 9. activos.valor_actual >= 0 blocks credit card balances        │
-- │    The frontend's WalletAccount shows credit cards with         │
-- │    negative saldo (e.g. -12,500). The DB CHECK constraint       │
-- │    prevents this. You either need:                              │
-- │    a) Remove the >= 0 check and allow negatives for debt, OR   │
-- │    b) Add a separate "saldo_deuda" column, OR                  │
-- │    c) Track credit card spending purely via transacciones       │
-- │       (sum of gastos where activo_id = credit card).            │
-- │    Option (c) is cleanest: the "balance" is computed, not       │
-- │    stored. valor_actual stays 0 for credit cards, and the app  │
-- │    computes the debt from transaction history.                   │
-- │                                                                 │
-- │ 10. No "subtipo" for wallet accounts                            │
-- │    The frontend's WalletAccount.tipo = "ahorro"|"gasto"|"deuda" │
-- │    but DB's tipo_activo = "cuenta_bancaria"|"efectivo"|etc.     │
-- │    These are orthogonal classifications. A cuenta_bancaria can  │
-- │    be ahorro or deuda. Consider adding:                         │
-- │    ALTER TABLE activos ADD COLUMN subtipo text                  │
-- │      CHECK (subtipo IN ('ahorro','gasto','deuda','inversion')); │
-- │    This lets the frontend filter wallets by purpose.            │
-- │                                                                 │
-- │ 11. transacciones.nota was MISSING                              │
-- │    Added via ALTER TABLE at the top. The frontend model has     │
-- │    it, and it's genuinely useful (users add personal notes      │
-- │    to transactions). This was a gap in the original schema.     │
-- │                                                                 │
-- └─────────────────────────────────────────────────────────────────┘
