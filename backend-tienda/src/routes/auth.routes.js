const router = require('express').Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { verificarToken } = require('../middleware/auth');

/**
 * @swagger
 * /auth/login:
 *   post:
 *     tags: [Auth]
 *     summary: Iniciar sesión (admin o cliente)
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email: { type: string, example: admin@modastyle.com }
 *               password: { type: string, example: "123456" }
 *     responses:
 *       200: { description: Token JWT y datos del usuario }
 *       401: { description: Credenciales inválidas }
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Email y contraseña requeridos' });
    }

    const { rows } = await pool.query(
      `select u.id, u.encrypted_password, p.nombre, p.rol
         from auth.users u
         join public.perfiles p on p.id = u.id
        where lower(u.email) = lower($1)`,
      [email]
    );
    const user = rows[0];

    const ok = user && (await bcrypt.compare(password, user.encrypted_password));
    if (!ok) return res.status(401).json({ message: 'Credenciales inválidas' });

    const token = jwt.sign(
      { id: user.id, rol: user.rol },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES }
    );
    res.json({ token, usuario: { id: user.id, nombre: user.nombre, rol: user.rol } });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

/**
 * @swagger
 * /auth/me:
 *   get:
 *     tags: [Auth]
 *     summary: Datos del usuario autenticado
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Perfil del usuario }
 *       401: { description: Sin token }
 */
router.get('/me', verificarToken, async (req, res) => {
  const { rows } = await pool.query(
    'select id, nombre, email, rol, telefono, direccion, created_at from public.perfiles where id = $1',
    [req.user.id]
  );
  res.json(rows[0] || null);
});

module.exports = router;