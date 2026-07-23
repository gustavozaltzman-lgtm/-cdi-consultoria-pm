const express = require('express');
const { pool } = require('./db');
const { computeAuditKpis } = require('../public/js/audit-kpis');

const ok = (data) => ({ success: true, data });
const fail = (message) => ({ success: false, error: message });

function asyncRoute(fn) {
  return (req, res) => fn(req, res).catch((err) => {
    console.error(err);
    res.status(500).json(fail(err.message || 'Error interno'));
  });
}

const router = express.Router();

const AUDIT_COLUMNS = [
  'branch_name', 'audit_date', 'duration_minutes', 'total_skus_counted', 'exact_skus',
  'total_theoretical_val', 'total_physical_val', 'ghost_locations_count', 'pos_cross_errors_count',
  'auditor_name'
];

// Historial de KPIs calculados de toda la empresa (para gráficos de tendencia).
// Declarado antes de '/:id' para que no lo capture la ruta con parámetro.
router.get('/kpi-history', asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM kpi_history WHERE company_id = $1 ORDER BY recorded_at ASC, id ASC',
    [req.companyId]
  );
  res.json(ok(rows));
}));

router.get('/', asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM audit_logs WHERE company_id = $1 ORDER BY audit_date DESC, id DESC',
    [req.companyId]
  );
  res.json(ok(rows));
}));

router.get('/:id', asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM audit_logs WHERE id = $1 AND company_id = $2',
    [req.params.id, req.companyId]
  );
  if (!rows.length) return res.status(404).json(fail('No encontrado'));
  const kpis = await pool.query(
    'SELECT * FROM kpi_history WHERE audit_id = $1 AND company_id = $2 ORDER BY id',
    [req.params.id, req.companyId]
  );
  res.json(ok({ ...rows[0], kpis: kpis.rows }));
}));

// Captura un conteo crudo, calcula los KPIs del ciclo y guarda ambos en una
// sola transacción: la auditoría queda huérfana de KPIs si el cálculo falla.
router.post('/', asyncRoute(async (req, res) => {
  const body = req.body || {};
  const branchName = String(body.branch_name || '').trim();
  const totalSkus = Number(body.total_skus_counted);
  const exactSkus = Number(body.exact_skus);

  if (!branchName) return res.status(400).json(fail('Falta branch_name'));
  if (!Number.isFinite(totalSkus) || totalSkus < 0) return res.status(400).json(fail('total_skus_counted inválido'));
  if (!Number.isFinite(exactSkus) || exactSkus < 0) return res.status(400).json(fail('exact_skus inválido'));
  if (exactSkus > totalSkus) return res.status(400).json(fail('exact_skus no puede superar a total_skus_counted'));

  const keys = AUDIT_COLUMNS.filter((c) => body[c] !== undefined && body[c] !== '');
  const values = keys.map((k) => body[k]);
  const placeholders = keys.map((_, i) => `$${i + 2}`).join(', ');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const inserted = await client.query(
      `INSERT INTO audit_logs (company_id, ${keys.join(', ')}) VALUES ($1, ${placeholders}) RETURNING *`,
      [req.companyId, ...values]
    );
    const auditLog = inserted.rows[0];
    const kpis = computeAuditKpis(auditLog);

    const kpiRows = [];
    const updatedKpis = [];
    for (const kpi of kpis) {
      const inserted = await client.query(
        `INSERT INTO kpi_history (company_id, audit_id, kpi_category, kpi_name, calculated_value)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [req.companyId, auditLog.id, kpi.kpi_category, kpi.kpi_name, kpi.calculated_value]
      );
      kpiRows.push(inserted.rows[0]);

      // Si alguna tarjeta manual de kpis está vinculada a este KPI calculado,
      // su current_value se actualiza solo con el resultado de este ciclo.
      const linked = await client.query(
        `UPDATE kpis SET current_value = $1 WHERE company_id = $2 AND linked_audit_kpi_name = $3 RETURNING *`,
        [kpi.calculated_value, req.companyId, kpi.kpi_name]
      );
      updatedKpis.push(...linked.rows);
    }
    await client.query('COMMIT');
    res.status(201).json(ok({ ...auditLog, kpis: kpiRows, updated_kpis: updatedKpis }));
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}));

router.delete('/:id', asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    'DELETE FROM audit_logs WHERE id = $1 AND company_id = $2 RETURNING id',
    [req.params.id, req.companyId]
  );
  if (!rows.length) return res.status(404).json(fail('No encontrado'));
  res.json(ok({ id: rows[0].id }));
}));

module.exports = router;
