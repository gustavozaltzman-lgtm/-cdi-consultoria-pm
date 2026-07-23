-- CDI Consultoría — vínculo opcional entre tareas del Gantt (tasks) y los
-- hitos de la metodología (plan_stages). Relación MUCHAS tareas a UN hito
-- (no 1:1): un plan_stage suele agrupar varias tareas de ejecución día a día.
-- Ejecutar después de sql/schema_v4_kpi_audit_link.sql. Idempotente.

BEGIN;

ALTER TABLE tasks ADD COLUMN IF NOT EXISTS stage_activity_id TEXT;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_tasks_plan_stage') THEN
    ALTER TABLE tasks
      ADD CONSTRAINT fk_tasks_plan_stage
      FOREIGN KEY (company_id, stage_activity_id)
      REFERENCES plan_stages (company_id, activity_id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_tasks_stage_activity ON tasks(company_id, stage_activity_id);

-- Backfill: vincula tareas existentes sin hito a un plan_stage de la misma
-- etapa (mismo texto de "stage"), cuando existe ese texto en el plan de esa
-- empresa. Si una etapa agrupa más de un hito (ej. D-1 y D-2 comparten
-- "Diagnóstico Inicial y Matriz ABC"), se vincula al de menor activity_id
-- de esa etapa — desempate determinístico, ajustable a mano después desde
-- la UI si corresponde a otro hito.
WITH stage_pick AS (
  SELECT DISTINCT ON (company_id, stage) company_id, stage, activity_id
  FROM plan_stages
  ORDER BY company_id, stage, activity_id
)
UPDATE tasks t
SET stage_activity_id = sp.activity_id
FROM stage_pick sp
WHERE t.company_id = sp.company_id
  AND t.stage = sp.stage
  AND t.stage_activity_id IS NULL;

COMMIT;
