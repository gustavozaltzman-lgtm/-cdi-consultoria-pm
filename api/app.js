const express = require('express');
const cors = require('cors');
const { pool } = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

const ok = (data) => ({ success: true, data });
const fail = (message) => ({ success: false, error: message });

function asyncRoute(fn) {
  return (req, res) => fn(req, res).catch((err) => {
    console.error(err);
    res.status(500).json(fail(err.message || 'Error interno'));
  });
}

// Whitelisted, editable columns per table — prevents arbitrary column injection from req.body.
const TABLES = {
  tasks: {
    columns: ['stage', 'activity', 'description', 'responsible', 'priority', 'start_date', 'end_date', 'dependency', 'status', 'progress', 'observations'],
    order: 'start_date ASC, id ASC'
  },
  plan_stages: {
    columns: ['stage', 'activity_id', 'activity', 'description', 'deliverable', 'estimated_duration', 'dependencies', 'completed'],
    order: 'id ASC'
  },
  risks: {
    columns: ['risk', 'category', 'probability', 'impact', 'responsible', 'mitigation', 'contingency_plan', 'status'],
    order: 'id ASC'
  },
  minutes: {
    columns: ['meeting_date', 'meeting_type', 'participants', 'topic', 'decisions', 'actions', 'responsible', 'commitment_date', 'status'],
    order: 'meeting_date DESC, id DESC'
  },
  actions: {
    columns: ['action_name', 'description', 'stage', 'responsible', 'priority', 'start_date', 'commitment_date', 'status', 'progress', 'origin', 'origin_minute_id'],
    order: 'id DESC'
  },
  kpis: {
    columns: ['category', 'indicator', 'unit', 'initial_value', 'target_value', 'current_value', 'responsible'],
    order: 'id ASC'
  },
  before_after: {
    columns: ['area', 'indicator', 'unit', 'initial_value', 'final_value', 'observations'],
    order: 'id ASC'
  },
  team_members: {
    columns: ['name', 'role', 'email', 'color'],
    order: 'id ASC'
  }
};

function buildCrudRouter(table) {
  const { columns, order } = TABLES[table];
  const router = express.Router();

  router.get('/', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`SELECT * FROM ${table} ORDER BY ${order}`);
    res.json(ok(rows));
  }));

  router.get('/:id', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`SELECT * FROM ${table} WHERE id = $1`, [req.params.id]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok(rows[0]));
  }));

  router.post('/', asyncRoute(async (req, res) => {
    const keys = columns.filter((c) => req.body[c] !== undefined);
    if (!keys.length) return res.status(400).json(fail('Body vacío'));
    const values = keys.map((k) => req.body[k]);
    const placeholders = keys.map((_, i) => `$${i + 1}`).join(', ');
    const { rows } = await pool.query(
      `INSERT INTO ${table} (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`,
      values
    );
    res.status(201).json(ok(rows[0]));
  }));

  router.put('/:id', asyncRoute(async (req, res) => {
    const keys = columns.filter((c) => req.body[c] !== undefined);
    if (!keys.length) return res.status(400).json(fail('Body vacío'));
    const values = keys.map((k) => req.body[k]);
    const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
    const hasUpdatedAt = ['tasks', 'plan_stages', 'risks', 'minutes', 'actions'].includes(table);
    const query = `UPDATE ${table} SET ${setClause}${hasUpdatedAt ? ', updated_at = now()' : ''} WHERE id = $${keys.length + 1} RETURNING *`;
    const { rows } = await pool.query(query, [...values, req.params.id]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok(rows[0]));
  }));

  // PATCH behaves the same as PUT (partial update).
  router.patch('/:id', asyncRoute(async (req, res) => {
    const keys = columns.filter((c) => req.body[c] !== undefined);
    if (!keys.length) return res.status(400).json(fail('Body vacío'));
    const values = keys.map((k) => req.body[k]);
    const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
    const hasUpdatedAt = ['tasks', 'plan_stages', 'risks', 'minutes', 'actions'].includes(table);
    const query = `UPDATE ${table} SET ${setClause}${hasUpdatedAt ? ', updated_at = now()' : ''} WHERE id = $${keys.length + 1} RETURNING *`;
    const { rows } = await pool.query(query, [...values, req.params.id]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok(rows[0]));
  }));

  router.delete('/:id', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`DELETE FROM ${table} WHERE id = $1 RETURNING id`, [req.params.id]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok({ id: rows[0].id }));
  }));

  return router;
}

Object.keys(TABLES).forEach((table) => {
  const routePath = '/' + table.replace(/_/g, '-');
  app.use(`/api${routePath}`, buildCrudRouter(table));
});

// config — fila única (id = 1), sin DELETE/POST, solo GET y PUT
app.get('/api/config', asyncRoute(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM config WHERE id = 1');
  res.json(ok(rows[0] || null));
}));

app.put('/api/config', asyncRoute(async (req, res) => {
  const columns = ['project_name', 'client_name', 'start_date', 'end_date', 'status'];
  const keys = columns.filter((c) => req.body[c] !== undefined);
  if (!keys.length) return res.status(400).json(fail('Body vacío'));
  const values = keys.map((k) => req.body[k]);
  const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
  const { rows } = await pool.query(
    `UPDATE config SET ${setClause}, updated_at = now() WHERE id = 1 RETURNING *`,
    values
  );
  res.json(ok(rows[0]));
}));

// tasks/stats — agregados calculados para el Dashboard
app.get('/api/tasks/stats', asyncRoute(async (req, res) => {
  const [overall, byStatus, byStage, cfg] = await Promise.all([
    pool.query('SELECT COALESCE(AVG(progress), 0) AS avg_progress, COUNT(*) AS total FROM tasks'),
    pool.query('SELECT status, COUNT(*) AS count FROM tasks GROUP BY status'),
    pool.query(`
      SELECT stage,
             COUNT(*) AS total,
             COALESCE(AVG(progress), 0) AS avg_progress,
             COUNT(*) FILTER (WHERE status = 'Finalizado') AS done
      FROM tasks
      GROUP BY stage
      ORDER BY MIN(start_date)
    `),
    pool.query('SELECT start_date, end_date FROM config WHERE id = 1')
  ]);

  let daysRemaining = null;
  if (cfg.rows[0] && cfg.rows[0].end_date) {
    const end = new Date(cfg.rows[0].end_date);
    const today = new Date();
    daysRemaining = Math.ceil((end - today) / (1000 * 60 * 60 * 24));
  }

  res.json(ok({
    overall_progress: Number(overall.rows[0].avg_progress).toFixed(1),
    total_tasks: Number(overall.rows[0].total),
    by_status: byStatus.rows,
    by_stage: byStage.rows.map((r) => ({
      stage: r.stage,
      total: Number(r.total),
      avg_progress: Number(r.avg_progress).toFixed(1),
      done: Number(r.done)
    })),
    days_remaining: daysRemaining
  }));
}));

app.get('/api/health', (req, res) => res.json(ok({ status: 'up', time: new Date().toISOString() })));

app.use((req, res) => res.status(404).json(fail('Ruta no encontrada')));

module.exports = app;
