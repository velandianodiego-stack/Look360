const router = require('express').Router();
const pool = require('../db');
const { verificarToken, permitirRoles } = require('../middleware/auth');

/**
 * @swagger
 * /devoluciones:
 *   get:
 *     tags: [Devoluciones]
 *     summary: Admin ve todas; cliente solo las suyas
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Lista de devoluciones }
 */
router.get('/', verificarToken, async (req, res) => {
  const esAdmin = req.user.rol === 'admin';
  const { rows } = esAdmin
    ? await pool.query('select * from public.devoluciones order by fecha desc')
    : await pool.query(
        'select * from public.devoluciones where usuario_id = $1 order by fecha desc',
        [req.user.id]
      );
  res.json(rows);
});

/**
 * @swagger
 * /devoluciones:
 *   post:
 *     tags: [Devoluciones]
 *     summary: Solicitar devolución de un pedido propio (cliente)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [pedido_id, motivo]
 *             properties:
 *               pedido_id: { type: string }
 *               motivo: { type: string, example: Talla incorrecta }
 *     responses:
 *       201: { description: Devolución creada }
 *       404: { description: El pedido no existe o no es tuyo }
 */
router.post('/', verificarToken, permitirRoles('user'), async (req, res) => {
  try {
    const { pedido_id, motivo } = req.body;
    if (!pedido_id || !motivo || !motivo.trim()) {
      return res.status(400).json({ message: 'pedido_id y motivo son requeridos' });
    }

    const pedido = await pool.query(
      'select id from public.pedidos where id = $1 and usuario_id = $2',
      [pedido_id, req.user.id]
    );
    if (!pedido.rows[0]) {
      return res.status(404).json({ message: 'Pedido no encontrado' });
    }

    const { rows } = await pool.query(
      `insert into public.devoluciones (pedido_id, usuario_id, motivo, estado)
       values ($1, $2, $3, 'pendiente') returning *`,
      [pedido_id, req.user.id, motivo.trim()]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Error del servidor' });
  }
});

/**
 * @swagger
 * /devoluciones/{id}/estado:
 *   patch:
 *     tags: [Devoluciones]
 *     summary: Cambiar estado de una devolución (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string } }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [estado]
 *             properties:
 *               estado: { type: string, enum: [pendiente, aprobada, rechazada] }
 *     responses:
 *       200: { description: Devolución actualizada }
 *       403: { description: Solo admin }
 */
router.patch('/:id/estado', verificarToken, permitirRoles('admin'), async (req, res) => {
  const { estado } = req.body;
  if (!['pendiente', 'aprobada', 'rechazada'].includes(estado)) {
    return res.status(400).json({ message: 'Estado inválido' });
  }
  const { rows } = await pool.query(
    'update public.devoluciones set estado = $1 where id = $2 returning *',
    [estado, req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ message: 'Devolución no encontrada' });
  res.json(rows[0]);
});

module.exports = router;