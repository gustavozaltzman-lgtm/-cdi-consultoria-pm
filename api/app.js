const express = require('express');
const cors = require('cors');
const path = require('path');
const bcrypt = require('bcryptjs');
const { pool } = require('./db');
const authRoutes = require('./authRoutes');
const { requireAuth, requireAdmin, resolveCompany } = require('./authMiddleware');

const app = express();
app.use(cors());
app.use(express.json());
// Vercel enruta todas las requests (incluida "/") a esta función, así que
// el propio Express sirve el frontend estático en vez de depender del
// enrutamiento automático de archivos de Vercel.
app.use(express.static(path.join(__dirname, '..', 'public')));

const ok = (data) => ({ success: true, data });
const fail = (message) => ({ success: false, error: message });

function asyncRoute(fn) {
  return (req, res) => fn(req, res).catch((err) => {
    console.error(err);
    res.status(500).json(fail(err.message || 'Error interno'));
  });
}

app.get('/api/health', (req, res) => res.json(ok({ status: 'up', time: new Date().toISOString() })));

app.use('/api/auth', authRoutes);

// --- Administración de empresas (solo admin de CDI) ---
app.get('/api/companies', requireAuth, requireAdmin, asyncRoute(async (req, res) => {
  const { rows } = await pool.query('SELECT id, name, slug, created_at FROM companies ORDER BY name');
  res.json(ok(rows));
}));

app.post('/api/companies', requireAuth, requireAdmin, asyncRoute(async (req, res) => {
  const name = String(req.body.name || '').trim();
  if (!name) return res.status(400).json(fail('Falta el nombre de la empresa'));
  const slug = String(req.body.slug || name)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-+|-+$)/g, '') || `empresa-${Date.now()}`;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'INSERT INTO companies (name, slug) VALUES ($1, $2) RETURNING *',
      [name, slug]
    );
    await client.query('INSERT INTO config (company_id) VALUES ($1)', [rows[0].id]);
    await client.query('COMMIT');
    res.status(201).json(ok(rows[0]));
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}));

// Crear el usuario de login de una empresa (rol client)
app.post('/api/companies/:id/users', requireAuth, requireAdmin, asyncRoute(async (req, res) => {
  const companyId = Number(req.params.id);
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const name = String(req.body.name || '').trim() || null;
  if (!email || !password) return res.status(400).json(fail('Email y contraseña requeridos'));
  if (password.length < 8) return res.status(400).json(fail('La contraseña debe tener al menos 8 caracteres'));

  const companyCheck = await pool.query('SELECT id FROM companies WHERE id = $1', [companyId]);
  if (!companyCheck.rows.length) return res.status(404).json(fail('Empresa no encontrada'));

  const passwordHash = await bcrypt.hash(password, 10);
  const { rows } = await pool.query(
    `INSERT INTO users (company_id, name, email, password_hash, role)
     VALUES ($1, $2, $3, $4, 'client')
     RETURNING id, name, email, role, company_id, created_at`,
    [companyId, name, email, passwordHash]
  );
  res.status(201).json(ok(rows[0]));
}));

// A partir de acá, todas las rutas requieren usuario autenticado y quedan
// acotadas a una sola empresa (req.companyId).
app.use('/api', requireAuth, resolveCompany);

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
  const hasUpdatedAt = ['tasks', 'plan_stages', 'risks', 'minutes', 'actions'].includes(table);

  router.get('/', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`SELECT * FROM ${table} WHERE company_id = $1 ORDER BY ${order}`, [req.companyId]);
    res.json(ok(rows));
  }));

  router.get('/:id', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`SELECT * FROM ${table} WHERE id = $1 AND company_id = $2`, [req.params.id, req.companyId]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok(rows[0]));
  }));

  router.post('/', asyncRoute(async (req, res) => {
    const keys = columns.filter((c) => req.body[c] !== undefined);
    if (!keys.length) return res.status(400).json(fail('Body vacío'));
    const values = keys.map((k) => req.body[k]);
    const placeholders = keys.map((_, i) => `$${i + 2}`).join(', ');
    const { rows } = await pool.query(
      `INSERT INTO ${table} (company_id, ${keys.join(', ')}) VALUES ($1, ${placeholders}) RETURNING *`,
      [req.companyId, ...values]
    );
    res.status(201).json(ok(rows[0]));
  }));

  function update(req, res) {
    const keys = columns.filter((c) => req.body[c] !== undefined);
    if (!keys.length) return Promise.resolve(res.status(400).json(fail('Body vacío')));
    const values = keys.map((k) => req.body[k]);
    const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
    const query = `UPDATE ${table} SET ${setClause}${hasUpdatedAt ? ', updated_at = now()' : ''} WHERE id = $${keys.length + 1} AND company_id = $${keys.length + 2} RETURNING *`;
    return pool.query(query, [...values, req.params.id, req.companyId]).then(({ rows }) => {
      if (!rows.length) return res.status(404).json(fail('No encontrado'));
      res.json(ok(rows[0]));
    });
  }
  router.put('/:id', asyncRoute(update));
  // PATCH behaves the same as PUT (partial update).
  router.patch('/:id', asyncRoute(update));

  router.delete('/:id', asyncRoute(async (req, res) => {
    const { rows } = await pool.query(`DELETE FROM ${table} WHERE id = $1 AND company_id = $2 RETURNING id`, [req.params.id, req.companyId]);
    if (!rows.length) return res.status(404).json(fail('No encontrado'));
    res.json(ok({ id: rows[0].id }));
  }));

  return router;
}

Object.keys(TABLES).forEach((table) => {
  const routePath = '/' + table.replace(/_/g, '-');
  app.use(`/api${routePath}`, buildCrudRouter(table));
});

// audit_logs / kpi_history — ruta dedicada (no CRUD genérico) porque crear una
// auditoría implica calcular y persistir sus KPIs en la misma transacción.
app.use('/api/audit-logs', require('./auditRoutes'));

// config — una fila por empresa, sin DELETE/POST, solo GET y PUT
app.get('/api/config', asyncRoute(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM config WHERE company_id = $1', [req.companyId]);
  res.json(ok(rows[0] || null));
}));

app.put('/api/config', asyncRoute(async (req, res) => {
  const columns = ['project_name', 'client_name', 'start_date', 'end_date', 'status'];
  const keys = columns.filter((c) => req.body[c] !== undefined);
  if (!keys.length) return res.status(400).json(fail('Body vacío'));
  const values = keys.map((k) => req.body[k]);
  const setClause = keys.map((k, i) => `${k} = $${i + 1}`).join(', ');
  const { rows } = await pool.query(
    `UPDATE config SET ${setClause}, updated_at = now() WHERE company_id = $${keys.length + 1} RETURNING *`,
    [...values, req.companyId]
  );
  if (!rows.length) return res.status(404).json(fail('No encontrado'));
  res.json(ok(rows[0]));
}));

// tasks/stats — agregados calculados para el Dashboard
app.get('/api/tasks/stats', asyncRoute(async (req, res) => {
  const [overall, byStatus, byStage, cfg] = await Promise.all([
    pool.query('SELECT COALESCE(AVG(progress), 0) AS avg_progress, COUNT(*) AS total FROM tasks WHERE company_id = $1', [req.companyId]),
    pool.query('SELECT status, COUNT(*) AS count FROM tasks WHERE company_id = $1 GROUP BY status', [req.companyId]),
    pool.query(`
      SELECT stage,
             COUNT(*) AS total,
             COALESCE(AVG(progress), 0) AS avg_progress,
             COUNT(*) FILTER (WHERE status = 'Finalizado') AS done
      FROM tasks
      WHERE company_id = $1
      GROUP BY stage
      ORDER BY MIN(start_date)
    `, [req.companyId]),
    pool.query('SELECT start_date, end_date FROM config WHERE company_id = $1', [req.companyId])
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

app.use((req, res) => res.status(404).json(fail('Ruta no encontrada')));

module.exports = app;
