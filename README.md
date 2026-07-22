# CDI Consultoría — Gestión de Proyectos

SPA + API multi-empresa para el seguimiento de proyectos de consultoría en logística e inventarios.
Cada empresa/cliente ("company") tiene sus datos completamente aislados; el acceso es por login.

## Stack
- **DB**: Neon PostgreSQL (serverless)
- **API**: Node.js + Express (`api/app.js`), corre en Render (`server.js`) o Vercel Serverless (`api/index.js`)
- **Auth**: JWT propio (`jsonwebtoken` + `bcryptjs`), sin librerías de sesión externas
- **Frontend**: `public/index.html` único — Tailwind CDN, Chart.js, SheetJS. Sin build step. Vive en `public/` para que Vercel lo sirva como estático (si quedara en la raíz, Vercel lo enruta como Express zero-config y lo pisa la función serverless).

## Modelo multi-tenant
- `companies`: una fila por empresa/cliente.
- `users`: login. `role = 'admin'` (equipo de CDI, `company_id` NULL, puede elegir cualquier empresa desde un selector) o `role = 'client'` (fijo a una empresa, no puede ver ni elegir otra).
- Todas las tablas de datos (`tasks`, `plan_stages`, `risks`, `minutes`, `actions`, `kpis`, `before_after`, `team_members`, `config`) tienen `company_id` y el backend filtra **siempre** por la empresa resuelta del JWT — un `client` no puede leer ni escribir datos de otra empresa aunque manipule los parámetros de la request.

## Setup

1. Crear una base en Neon y copiar el connection string.
2. `cp .env.example .env` y completar `DATABASE_URL` y `JWT_SECRET` (un string largo y aleatorio).
3. `npm install`
4. Base nueva (vacía):
   ```bash
   node scripts/run-sql.js sql/schema.sql
   node scripts/run-sql.js sql/seed.sql   # opcional, carga una empresa de demo
   ```
   Base ya existente creada con la versión single-tenant anterior:
   ```bash
   node scripts/run-sql.js sql/schema_v2_multitenant_upgrade.sql
   ```
   (Es idempotente: si ya está aplicada, no hace nada.)
5. Crear el usuario admin de CDI:
   ```bash
   node scripts/create-user.js --role admin --email vos@cdiconsultoria.com --password unaContraseñaSegura --name "Tu Nombre"
   ```
6. Crear una empresa nueva y su usuario de acceso (o hacerlo desde la app ya logueado como admin, vía `POST /api/companies` y `POST /api/companies/:id/users`):
   ```bash
   node scripts/create-user.js --role client --email contacto@cliente.com --password unaContraseñaSegura --name "Contacto Cliente" --company-slug slug-de-la-empresa
   ```

## Correr localmente (backend)
```bash
npm run dev
```
La API queda en `http://localhost:3001/api`. Abrir `public/index.html` (o servirlo con cualquier static server) — pide login. Si el frontend no vive en el mismo dominio que la API, ajustar `API_BASE` en `public/index.html`.

## Deploy
- **Backend en Render**: Web Service, build `npm install`, start `npm start`, variables `DATABASE_URL` y `JWT_SECRET`.
- **Frontend + API en Vercel**: un solo proyecto. `vercel.json` enruta `/api/*` a `api/index.js`; todo lo demás lo sirve Vercel automáticamente desde `public/`. Configurar `DATABASE_URL` y `JWT_SECRET` como variables de entorno del proyecto.

## Modo Demo vs Producción
El selector superior (visible solo después de loguearse) alterna entre datos locales de prueba (LocalStorage) y la API real de la empresa seleccionada. Al loguearse, arranca en Producción automáticamente. La edición inline funciona en ambos modos con actualización optimista; en Producción, si la API no responde, los cambios quedan en LocalStorage y el indicador pasa a "Sin Conexión" hasta reconectar.
