-- CDI Consultoría — upgrade a multi-tenant
-- Para bases YA creadas con la versión single-tenant original de schema.sql
-- (la que tiene "config" con id=1 y ninguna tabla con company_id).
-- Es seguro re-ejecutarlo: si detecta que ya está aplicado, no hace nada.
-- Los datos existentes quedan asignados a una única empresa creada a
-- partir del "config" actual.

BEGIN;

CREATE TABLE IF NOT EXISTS companies (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

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

DO $$
DECLARE
  v_company_id INT;
  v_client_name TEXT;
  v_slug TEXT;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'config' AND column_name = 'company_id') THEN
    RAISE NOTICE 'Migración ya aplicada, se omite.';
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'config' AND column_name = 'id')
     AND EXISTS (SELECT 1 FROM config WHERE id = 1) THEN
    SELECT client_name INTO v_client_name FROM config WHERE id = 1;
  ELSE
    v_client_name := 'Cliente Demo';
  END IF;

  v_slug := lower(regexp_replace(regexp_replace(v_client_name, '[^a-zA-Z0-9]+', '-', 'g'), '(^-+|-+$)', '', 'g'));
  IF v_slug IS NULL OR v_slug = '' THEN
    v_slug := 'empresa-' || floor(random() * 100000)::text;
  END IF;

  INSERT INTO companies (name, slug) VALUES (v_client_name, v_slug)
  RETURNING id INTO v_company_id;

  ALTER TABLE tasks ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE plan_stages ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE risks ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE minutes ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE actions ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE kpis ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE before_after ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;
  ALTER TABLE team_members ADD COLUMN IF NOT EXISTS company_id INT REFERENCES companies(id) ON DELETE CASCADE;

  UPDATE tasks SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE plan_stages SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE risks SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE minutes SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE actions SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE kpis SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE before_after SET company_id = v_company_id WHERE company_id IS NULL;
  UPDATE team_members SET company_id = v_company_id WHERE company_id IS NULL;

  -- config pasa de fila única (id=1) a una fila por empresa (company_id)
  CREATE TABLE config_new (
    company_id   INT PRIMARY KEY REFERENCES companies(id) ON DELETE CASCADE,
    project_name TEXT NOT NULL DEFAULT 'Proyecto de Consultoría',
    client_name  TEXT NOT NULL DEFAULT 'Cliente',
    start_date   DATE,
    end_date     DATE,
    status       TEXT NOT NULL DEFAULT 'En proceso'
                 CHECK (status IN ('No iniciado','En proceso','Bloqueado','Finalizado')),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
  );

  IF EXISTS (SELECT 1 FROM config WHERE id = 1) THEN
    INSERT INTO config_new (company_id, project_name, client_name, start_date, end_date, status, updated_at)
    SELECT v_company_id, project_name, client_name, start_date, end_date, status, updated_at
    FROM config WHERE id = 1;
  ELSE
    INSERT INTO config_new (company_id) VALUES (v_company_id);
  END IF;

  DROP TABLE config;
  ALTER TABLE config_new RENAME TO config;

  RAISE NOTICE 'Migración aplicada. company_id de la empresa migrada: %', v_company_id;
END $$;

ALTER TABLE tasks ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE plan_stages ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE risks ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE minutes ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE actions ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE kpis ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE before_after ALTER COLUMN company_id SET NOT NULL;
ALTER TABLE team_members ALTER COLUMN company_id SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_company ON tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_plan_stages_company ON plan_stages(company_id);
CREATE INDEX IF NOT EXISTS idx_risks_company ON risks(company_id);
CREATE INDEX IF NOT EXISTS idx_minutes_company ON minutes(company_id);
CREATE INDEX IF NOT EXISTS idx_actions_company ON actions(company_id);
CREATE INDEX IF NOT EXISTS idx_kpis_company ON kpis(company_id);
CREATE INDEX IF NOT EXISTS idx_before_after_company ON before_after(company_id);
CREATE INDEX IF NOT EXISTS idx_team_members_company ON team_members(company_id);

-- team_members.email: de único global a único por empresa
ALTER TABLE team_members DROP CONSTRAINT IF EXISTS team_members_email_key;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uq_team_members_company_email') THEN
    CREATE UNIQUE INDEX uq_team_members_company_email ON team_members(company_id, email) WHERE email IS NOT NULL;
  END IF;
END $$;

-- plan_stages.activity_id: de único global a único por empresa
ALTER TABLE plan_stages DROP CONSTRAINT IF EXISTS plan_stages_activity_id_key;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'uq_plan_stages_company_activity_id') THEN
    CREATE UNIQUE INDEX uq_plan_stages_company_activity_id ON plan_stages(company_id, activity_id);
  END IF;
END $$;

COMMIT;
