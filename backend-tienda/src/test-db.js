require('dotenv').config();
const pool = require('./db');

(async () => {
  console.log('DATABASE_URL cargada:', !!process.env.DATABASE_URL);
  console.log('JWT_SECRET cargado:', !!process.env.JWT_SECRET);
  try {
    const a = await pool.query('select now()');
    console.log('1. Conexión OK:', a.rows[0].now);

    const b = await pool.query('select count(*) from public.perfiles');
    console.log('2. perfiles OK, filas:', b.rows[0].count);

    const c = await pool.query('select count(*) from auth.users');
    console.log('3. auth.users OK, filas:', c.rows[0].count);
  } catch (e) {
    console.error('FALLÓ:', e.message);
  }
  process.exit();
})();