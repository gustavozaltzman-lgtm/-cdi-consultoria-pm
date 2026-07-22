// Entry point standalone para Render (o cualquier host Node.js tradicional).
const app = require('./api/app');

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`CDI Consultoría API escuchando en puerto ${PORT}`);
});
