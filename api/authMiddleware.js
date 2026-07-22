const jwt = require('jsonwebtoken');

if (!process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET no está configurada');
}

const fail = (message) => ({ success: false, error: message });

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json(fail('No autenticado'));
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (e) {
    res.status(401).json(fail('Token inválido o expirado'));
  }
}

function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') return res.status(403).json(fail('Requiere rol admin'));
  next();
}

// Determina la empresa efectiva para la request:
// - client: siempre su propia empresa (no puede elegir otra)
// - admin: la que pida por query ?company_id=, obligatorio
function resolveCompany(req, res, next) {
  if (req.user.role === 'client') {
    req.companyId = req.user.company_id;
    return next();
  }
  const companyId = parseInt(req.query.company_id, 10);
  if (!companyId) return res.status(400).json(fail('Falta company_id (el admin debe especificar la empresa)'));
  req.companyId = companyId;
  next();
}

module.exports = { requireAuth, requireAdmin, resolveCompany };
