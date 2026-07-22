-- CDI Consultoría — Gestión de Proyectos de Consultoría en Logística e Inventarios
-- schema.sql — Neon PostgreSQL (serverless)
-- Multi-tenant: cada empresa/cliente es un "company" y su información
-- está completamente separada por company_id.
-- Ejecutar una sola vez sobre una base nueva (vacía).
-- Si ya tenías una base creada con la versión anterior (single-tenant),
-- usá sql/schema_v2_multitenant_upgrade.sql en su lugar.

BEGIN;

-- =========================================================
-- 0. companies — empresas/clientes (tenants)
-- =========================================================
CREATE TABLE IF NOT EXISTS companies (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================
-- 0b. users — usuarios de acceso (admin de CDI o clientes)
--     admin  -> company_id NULL, ve y elige cualquier empresa
--     client -> company_id fijo, solo ve su propia empresa
-- =========================================================
CREATE TABLE IF NOT EXISTS users (
  id             SERIAL PRIMARY KEY,
  company_id     INT REFERENCES companies(id) ON DELETE CASCADE,
  name           TEXT,
  email          TEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  role           TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('admin','client')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK ( (role = 'admin' AND company_id IS NULL) OR (role = 'client' AND company_id IS NOT NULL) )
);
CREATE INDEX IF NOT EXISTS idx_users_company ON users(company_id);

-- =========================================================
-- 1. config — datos generales del proyecto (una fila por empresa)
-- =========================================================
CREATE TABLE IF NOT EXISTS config (
  company_id   INT PRIMARY KEY REFERENCES companies(id) ON DELETE CASCADE,
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
  id            SERIAL PRIMARY KEY,
  company_id    INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_tasks_company ON tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_stage ON tasks(stage);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);

-- =========================================================
-- 3. plan_stages — plan metodológico CDI (árbol por etapas)
-- =========================================================
CREATE TABLE IF NOT EXISTS plan_stages (
  id                  SERIAL PRIMARY KEY,
  company_id          INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  stage               TEXT NOT NULL,
  activity_id         TEXT NOT NULL,
  activity            TEXT NOT NULL,
  description         TEXT,
  deliverable         TEXT,
  estimated_duration  TEXT,
  dependencies        TEXT,
  completed           BOOLEAN NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (company_id, activity_id)
);
CREATE INDEX IF NOT EXISTS idx_plan_stages_company ON plan_stages(company_id);
CREATE INDEX IF NOT EXISTS idx_plan_stages_stage ON plan_stages(stage);

-- =========================================================
-- 4. risks — matriz de riesgos
-- =========================================================
CREATE TABLE IF NOT EXISTS risks (
  id                SERIAL PRIMARY KEY,
  company_id        INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_risks_company ON risks(company_id);

-- =========================================================
-- 5. minutes — minutas de reunión
-- =========================================================
CREATE TABLE IF NOT EXISTS minutes (
  id                SERIAL PRIMARY KEY,
  company_id        INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_minutes_company ON minutes(company_id);

-- =========================================================
-- 6. actions — acciones (pueden originarse en minutas)
-- =========================================================
CREATE TABLE IF NOT EXISTS actions (
  id                SERIAL PRIMARY KEY,
  company_id        INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
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
CREATE INDEX IF NOT EXISTS idx_actions_company ON actions(company_id);

-- =========================================================
-- 7. kpis — indicadores logísticos
-- =========================================================
CREATE TABLE IF NOT EXISTS kpis (
  id             SERIAL PRIMARY KEY,
  company_id     INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  category       TEXT NOT NULL,
  indicator      TEXT NOT NULL,
  unit           TEXT,
  initial_value  DECIMAL(12,2),
  target_value   DECIMAL(12,2),
  current_value  DECIMAL(12,2),
  responsible    TEXT,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_kpis_company ON kpis(company_id);

-- =========================================================
-- 8. before_after — comparativa antes/después
-- =========================================================
CREATE TABLE IF NOT EXISTS before_after (
  id             SERIAL PRIMARY KEY,
  company_id     INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  area           TEXT NOT NULL,
  indicator      TEXT NOT NULL,
  unit           TEXT,
  initial_value  DECIMAL(12,2) NOT NULL,
  final_value    DECIMAL(12,2),
  observations   TEXT
);
CREATE INDEX IF NOT EXISTS idx_before_after_company ON before_after(company_id);

-- =========================================================
-- 9. team_members
-- =========================================================
CREATE TABLE IF NOT EXISTS team_members (
  id          SERIAL PRIMARY KEY,
  company_id  INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  role        TEXT,
  email       TEXT,
  color       TEXT DEFAULT '#1e3a5f'
);
CREATE INDEX IF NOT EXISTS idx_team_members_company ON team_members(company_id);
-- Único por empresa solo cuando hay email (permite integrantes sin email cargado).
CREATE UNIQUE INDEX IF NOT EXISTS uq_team_members_company_email ON team_members(company_id, email) WHERE email IS NOT NULL;

COMMIT;
