-- CDI Consultoría — Auditorías cíclicas de inventario + historial de KPIs calculados
-- Ejecutar sobre una base que ya tiene sql/schema.sql (y schema_v2 si corresponde) aplicados.
-- Idempotente: usa IF NOT EXISTS, se puede correr varias veces sin romper nada.

BEGIN;

-- =========================================================
-- 10. audit_logs — conteos físicos de auditorías cíclicas (datos crudos)
-- =========================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id                      SERIAL PRIMARY KEY,
  company_id              INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  branch_name             TEXT NOT NULL,
  audit_date              DATE NOT NULL DEFAULT CURRENT_DATE,
  duration_minutes        INT,
  total_skus_counted      INT NOT NULL CHECK (total_skus_counted >= 0),
  exact_skus              INT NOT NULL CHECK (exact_skus >= 0),
  total_theoretical_val   DECIMAL(12,2),
  total_physical_val      DECIMAL(12,2),
  ghost_locations_count   INT NOT NULL DEFAULT 0 CHECK (ghost_locations_count >= 0),
  pos_cross_errors_count  INT NOT NULL DEFAULT 0 CHECK (pos_cross_errors_count >= 0),
  auditor_name            TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (exact_skus <= total_skus_counted)
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_company ON audit_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_branch ON audit_logs(company_id, branch_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_date ON audit_logs(company_id, audit_date);

-- =========================================================
-- 11. kpi_history — foto histórica de los KPIs calculados por auditoría
-- =========================================================
CREATE TABLE IF NOT EXISTS kpi_history (
  id                SERIAL PRIMARY KEY,
  company_id        INT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  audit_id          INT NOT NULL REFERENCES audit_logs(id) ON DELETE CASCADE,
  kpi_category      TEXT NOT NULL,
  kpi_name          TEXT NOT NULL,
  calculated_value  DECIMAL(10,2) NOT NULL,
  recorded_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_kpi_history_company ON kpi_history(company_id);
CREATE INDEX IF NOT EXISTS idx_kpi_history_audit ON kpi_history(audit_id);
CREATE INDEX IF NOT EXISTS idx_kpi_history_name ON kpi_history(company_id, kpi_name);

COMMIT;
