# CDI Consultoría — Gestión de Proyectos

SPA + API para el seguimiento de proyectos de consultoría en logística e inventarios.

## Stack
- **DB**: Neon PostgreSQL (serverless)
- **API**: Node.js + Express (`api/app.js`), corre en Render (`server.js`) o Vercel Serverless (`api/index.js`)
- **Frontend**: `public/index.html` único — Tailwind CDN, Chart.js, SheetJS. Sin build step. Vive en `public/` para que Vercel lo sirva como estático (si quedara en la raíz, Vercel lo enruta como Express zero-config y lo pisa la función serverless).

## Setup

1. Crear una base en Neon y copiar el connection string.
2. `cp .env.example .env` y completar `DATABASE_URL`.
3. Ejecutar el schema y los datos de demo contra Neon:
   ```bash
   psql "$DATABASE_URL" -f sql/schema.sql
   psql "$DATABASE_URL" -f sql/seed.sql
   ```
4. `npm install`

## Correr localmente (backend)
```bash
npm run dev
```
La API queda en `http://localhost:3001/api`. Abrir `public/index.html` en el navegador (o servirlo con cualquier static server) y cambiar el selector superior a **Modo Producción**. Si el frontend no vive en el mismo dominio que la API, ajustar `API_BASE` en `public/index.html`.

## Deploy
- **Backend en Render**: Web Service, build `npm install`, start `npm start`, variable `DATABASE_URL`.
- **Frontend + API en Vercel**: un solo proyecto. `vercel.json` enruta `/api/*` a `api/index.js`; todo lo demás lo sirve Vercel automáticamente desde `public/`. Configurar `DATABASE_URL` como variable de entorno del proyecto.

## Modo Demo vs Producción
El selector superior alterna entre datos locales (LocalStorage, con seed embebido) y la API real. La edición inline funciona en ambos modos con actualización optimista; en Producción, si la API no responde, los cambios quedan en LocalStorage y el indicador pasa a "Sin Conexión" hasta reconectar.
