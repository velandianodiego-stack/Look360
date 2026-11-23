const router = require('express').Router();
const pool = require('../db');
const { verificarToken } = require('../middleware/auth');

/**
 * @swagger
 * /pedidos:
 *   get:
 *     tags: [Pedidos]
 *     summary: Admin ve todos los pedidos; cliente solo los suyos
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Lista de pedidos }
 */
router.get('/', verificarToken, async (req, res) => {
  const esAdmin = req.user.rol === 'admin';
  const { rows } = esAdmin
    ? await pool.query('select * from public.pedidos order by fecha desc')
    : await pool.query(
        'select * from public.pedidos where usuario_id = $1 order by fecha desc',
        [req.user.id]
      );
  res.json(rows);
});

module.exports = router;