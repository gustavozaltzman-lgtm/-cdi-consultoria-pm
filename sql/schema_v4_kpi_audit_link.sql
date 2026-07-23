-- CDI Consultoría — vínculo opcional entre una tarjeta manual de kpis y uno
-- de los 4 KPIs calculados automáticamente por auditorías cíclicas.
-- Al guardar una auditoría (POST /api/audit-logs), si alguna fila de kpis
-- tiene linked_audit_kpi_name = <nombre del KPI calculado>, su current_value
-- se actualiza solo con el valor de ese ciclo.
-- Ejecutar después de sql/schema_v3_audit_cycles.sql. Idempotente.

BEGIN;

ALTER TABLE kpis ADD COLUMN IF NOT EXISTS linked_audit_kpi_name TEXT
  CHECK (linked_audit_kpi_name IS NULL OR linked_audit_kpi_name IN (
    'IRA % (Exactitud de Inventario)',
    'Descalce Monetario %',
    'Ubicaciones Fantasma %',
    'Errores de Cruce POS %'
  ));

CREATE INDEX IF NOT EXISTS idx_kpis_linked_audit_kpi ON kpis(company_id, linked_audit_kpi_name)
  WHERE linked_audit_kpi_name IS NOT NULL;

COMMIT;
