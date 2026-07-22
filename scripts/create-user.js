// Crea un usuario de acceso (admin de CDI o cliente de una empresa).
// Uso:
//   node scripts/create-user.js --role admin  --email a@cdi.com --password xxxxxxxx --name "Gustavo"
//   node scripts/create-user.js --role client --email a@cliente.com --password xxxxxxxx --name "Contacto" --company-slug distribuidora-andina
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

function parseArgs() {
  const args = {};
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i += 2) {
    args[argv[i].replace(/^--/, '')] = argv[i + 1];
  }
  return args;
}

async function main() {
  const { role, email, password, name, 'company-slug': companySlug } = parseArgs();

  if (!role || !['admin', 'client'].includes(role)) {
    console.error('Falta --role admin|client'); process.exit(1);
  }
  if (!email || !password) {
    console.error('Faltan --email y --password'); process.exit(1);
  }
  if (password.length < 8) {
    console.error('La contraseña debe tener al menos 8 caracteres'); process.exit(1);
  }
  if (role === 'client' && !companySlug) {
    console.error('Falta --company-slug para un usuario client'); process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('Falta DATABASE_URL en el entorno'); process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

  let companyId = null;
  if (role === 'client') {
    const { rows } = await pool.query('SELECT id FROM companies WHERE slug = $1', [companySlug]);
    if (!rows.length) {
      console.error(`No existe ninguna empresa con slug "${companySlug}"`);
      await pool.end(); process.exit(1);
    }
    companyId = rows[0].id;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const { rows } = await pool.query(
    `INSERT INTO users (company_id, name, email, password_hash, role)
     VALUES ($1, $2, $3, $4, $5)
     ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash, name = EXCLUDED.name, role = EXCLUDED.role, company_id = EXCLUDED.company_id
     RETURNING id, name, email, role, company_id`,
    [companyId, name || null, email.trim().toLowerCase(), passwordHash, role]
  );

  console.log('Usuario creado/actualizado:', rows[0]);
  await pool.end();
}

main().catch((err) => { console.error(err); process.exit(1); });
