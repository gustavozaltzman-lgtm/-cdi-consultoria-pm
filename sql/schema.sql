-- CDI Consultoría — Gestión de Proyectos de Consultoría en Logística e Inventarios
-- schema.sql — Neon PostgreSQL (serverless)
-- Ejecutar una sola vez sobre una base nueva.

BEGIN;

-- =========================================================
-- 1. config — datos generales del proyecto (fila única)
-- =========================================================
CREATE TABLE IF NOT EXISTS config (
  id INT PRIMARY KEY CHECK (id = 1),
  project_name TEXT NOT NULL DEFAULT 'Proyecto de Consultoría',
  client_name  TEXT NOT NULL DEFAULT 'Cliente',
  start_date   DATE,
  end_date     DATE,
  status       TEXT NOT NULL DEFAULT 'En proceso'
               CHECK (status IN ('No iniciado','En proceso','Bloqueado','Finalizado')),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 2. tasks — cronograma / Gantt
-- =========================================================
CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  stage         TEXT NOT NULL,
  activity      TEXT NOT NULL,
  description   TEXT,
  responsible   TEXT,
  priority      TEXT NOT NULL DEFAULT 'Media'
                CHECK (priority IN ('Baja','Media','Alta','Crítica')),
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  duration      INT GENERATED ALWAYS AS (end_date - start_date + 1) STORED,
  dependency    INT REFERENCES tasks(id) ON DELETE SET NULL,
  status        TEXT NOT NULL DEFAULT 'No iniciado'
                CHECK (status IN ('No iniciado','En proceso','Bloqueado','Finalizado')),
  progress      DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  observations  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);
CREATE INDEX IF NOT EXISTS idx_tasks_stage ON tasks(stage);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

-- =========================================================
-- 3. plan_stages — plan metodológico CDI (árbol por etapas)
-- =========================================================
CREATE TABLE IF NOT EXISTS plan_stages (
  id SERIAL PRIMARY KEY,
  stage               TEXT NOT NULL,
  activity_id         TEXT NOT NULL UNIQUE,
  activity            TEXT NOT NULL,
  description         TEXT,
  deliverable         TEXT,
  estimated_duration  TEXT,
  dependencies        TEXT,
  completed           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_plan_stages_stage ON plan_stages(stage);

-- =========================================================
-- 4. risks — matriz de riesgos
-- =========================================================
CREATE TABLE IF NOT EXISTS risks (
  id SERIAL PRIMARY KEY,
  risk              TEXT NOT NULL,
  category          TEXT,
  probability       TEXT NOT NULL CHECK (probability IN ('Baja','Media','Alta')),
  impact            TEXT NOT NULL CHECK (impact IN ('Bajo','Medio','Alto')),
  level TEXT GENERATED ALWAYS AS (
    CASE
      WHEN probability = 'Alta' AND impact = 'Alto' THEN 'CRÍTICO'
      WHEN probability = 'Alta' AND impact = 'Medio' THEN 'CRÍTICO'
      WHEN probability = 'Media' AND impact = 'Alto' THEN 'CRÍTICO'
      WHEN probability = 'Alta' AND impact = 'Bajo' THEN 'MEDIO'
      WHEN probability = 'Media' AND impact = 'Medio' THEN 'MEDIO'
      WHEN probability = 'Baja' AND impact = 'Alto' THEN 'MEDIO'
      ELSE 'BAJO'
    END
  ) STORED,
  responsible       TEXT,
  mitigation        TEXT,
  contingency_plan  TEXT,
  status            TEXT NOT NULL DEFAULT 'Activo'
                    CHECK (status IN ('Activo','Mitigado','Cerrado')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 5. minutes — minutas de reunión
-- =========================================================
CREATE TABLE IF NOT EXISTS minutes (
  id                SERIAL PRIMARY KEY,
  meeting_date      DATE NOT NULL,
  meeting_type      TEXT,
  participants      TEXT,
  topic             TEXT NOT NULL,
  decisions         TEXT,
  actions           TEXT,
  responsible       TEXT,
  commitment_date   DATE,
  status            TEXT NOT NULL DEFAULT 'Pendiente'
                    CHECK (status IN ('Cerrada','En curso','Pendiente')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 6. actions — acciones (pueden originarse en minutas)
-- =========================================================
CREATE TABLE IF NOT EXISTS actions (
  id                SERIAL PRIMARY KEY,
  action_name       TEXT NOT NULL,
  description       TEXT,
  stage             TEXT,
  responsible       TEXT,
  priority          TEXT NOT NULL DEFAULT 'Media'
                    CHECK (priority IN ('Baja','Media','Alta','Crítica')),
  start_date        DATE,
  commitment_date   DATE,
  status            TEXT NOT NULL DEFAULT 'No iniciada'
                    CHECK (status IN ('No iniciada','En curso','Bloqueada','Cerrada')),
  progress          DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  origin            TEXT,
  origin_minute_id  INT REFERENCES minutes(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 7. kpis — indicadores logísticos
-- =========================================================
CREATE TABLE IF NOT EXISTS kpis (
  id             SERIAL PRIMARY KEY,
  category       TEXT NOT NULL,
  indicator      TEXT NOT NULL,
  unit           TEXT,
  initial_value  DECIMAL(12,2),
  target_value   DECIMAL(12,2),
  current_value  DECIMAL(12,2),
  responsible    TEXT,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 8. before_after — comparativa antes/después
-- =========================================================
CREATE TABLE IF NOT EXISTS before_after (
  id             SERIAL PRIMARY KEY,
  area           TEXT NOT NULL,
  indicator      TEXT NOT NULL,
  unit           TEXT,
  initial_value  DECIMAL(12,2) NOT NULL,
  final_value    DECIMAL(12,2),
  observations   TEXT
);

-- =========================================================
-- 9. team_members
-- =========================================================
CREATE TABLE IF NOT EXISTS team_members (
  id      SERIAL PRIMARY KEY,
  name    TEXT NOT NULL,
  role    TEXT,
  email   TEXT UNIQUE,
  color   TEXT DEFAULT '#1e3a5f'
);

-- Config por defecto (fila única, idempotente)
INSERT INTO config (id, project_name, client_name, start_date, end_date, status)
VALUES (1, 'Optimización de Almacenes e Inventarios', 'Cliente CDI', CURRENT_DATE, CURRENT_DATE + INTERVAL '120 days', 'En proceso')
ON CONFLICT (id) DO NOTHING;

COMMIT;
