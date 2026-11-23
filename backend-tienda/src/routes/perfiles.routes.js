const router = require('express').Router();
const pool = require('../db');
const { verificarToken, permitirRoles } = require('../middleware/auth');

/**
 * @swagger
 * /perfiles:
 *   get:
 *     tags: [Perfiles]
 *     summary: Listar todos los perfiles (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Lista de perfiles }
 *       403: { description: Solo admin }
 */
router.get('/', verificarToken, permitirRoles('admin'), async (req, res) => {
  const { rows } = await pool.query(
    'select id, nombre, email, rol, telefono, direccion, created_at from public.perfiles order by created_at desc'
  );
  res.json(rows);
});

/**
 * @swagger
 * /perfiles/{id}:
 *   get:
 *     tags: [Perfiles]
 *     summary: Ver un perfil (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string } }
 *     responses:
 *       200: { description: Perfil }
 *       404: { description: No existe }
 */
router.get('/:id', verificarToken, permitirRoles('admin'), async (req, res) => {
  const { rows } = await pool.query(
    'select id, nombre, email, rol, telefono, direccion, created_at from public.perfiles where id = $1',
    [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ message: 'Perfil no encontrado' });
  res.json(rows[0]);
});

module.exports = router;