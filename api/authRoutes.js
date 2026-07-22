const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('./db');
const { requireAuth } = require('./authMiddleware');

const ok = (data) => ({ success: true, data });
const fail = (message) => ({ success: false, error: message });

function asyncRoute(fn) {
  return (req, res) => fn(req, res).catch((err) => {
    console.error(err);
    res.status(500).json(fail(err.message || 'Error interno'));
  });
}

const router = express.Router();

router.post('/login', asyncRoute(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  if (!email || !password) return res.status(400).json(fail('Email y contraseña requeridos'));

  const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];
  if (!user) return res.status(401).json(fail('Credenciales inválidas'));

  const validPassword = await bcrypt.compare(password, user.password_hash);
  if (!validPassword) return res.status(401).json(fail('Credenciales inválidas'));

  const token = jwt.sign(
    { sub: user.id, role: user.role, company_id: user.company_id },
    process.env.JWT_SECRET,
    { expiresIn: '12h' }
  );

  let companyName = null;
  if (user.company_id) {
    const c = await pool.query('SELECT name FROM companies WHERE id = $1', [user.company_id]);
    companyName = c.rows[0]?.name || null;
  }

  res.json(ok({
    token,
    user: { id: user.id, name: user.name, email: user.email, role: user.role, company_id: user.company_id, company_name: companyName }
  }));
}));

router.get('/me', requireAuth, asyncRoute(async (req, res) => {
  const { rows } = await pool.query(
    `SELECT u.id, u.name, u.email, u.role, u.company_id, c.name AS company_name
     FROM users u LEFT JOIN companies c ON c.id = u.company_id
     WHERE u.id = $1`,
    [req.user.sub]
  );
  if (!rows.length) return res.status(404).json(fail('Usuario no encontrado'));
  res.json(ok(rows[0]));
}));

module.exports = router;
