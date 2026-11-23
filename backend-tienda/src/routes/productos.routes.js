const router = require('express').Router();
const pool = require('../db');
const { verificarToken, permitirRoles } = require('../middleware/auth');

/**
 * @swagger
 * /productos:
 *   get:
 *     tags: [Productos]
 *     summary: Listar productos (admin y cliente)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Lista de productos }
 */
router.get('/', verificarToken, async (req, res) => {
  const { rows } = await pool.query('select * from public.productos order by nombre');
  res.json(rows);
});

/**
 * @swagger
 * /productos:
 *   post:
 *     tags: [Productos]
 *     summary: Crear producto (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [nombre, precio]
 *             properties:
 *               nombre: { type: string }
 *               descripcion: { type: string }
 *               precio: { type: number }
 *               imagen_url: { type: string }
 *               categoria: { type: string }
 *               tallas: { type: array, items: { type: string } }
 *               stock: { type: integer }
 *     responses:
 *       201: { description: Producto creado }
 *       403: { description: Solo admin }
 */
router.post('/', verificarToken, permitirRoles('admin'), async (req, res) => {
  const { nombre, descripcion, precio, imagen_url, categoria, tallas, stock } = req.body;
  const { rows } = await pool.query(
    `insert into public.productos (nombre, descripcion, precio, imagen_url, categoria, tallas, stock)
     values ($1,$2,$3,$4,$5,$6,$7) returning *`,
    [nombre, descripcion, precio, imagen_url, categoria, tallas, stock]
  );
  res.status(201).json(rows[0]);
});

/**
 * @swagger
 * /productos/{id}:
 *   delete:
 *     tags: [Productos]
 *     summary: Eliminar producto (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string } }
 *     responses:
 *       204: { description: Eliminado }
 *       403: { description: Solo admin }
 */
router.delete('/:id', verificarToken, permitirRoles('admin'), async (req, res) => {
  await pool.query('delete from public.productos where id = $1', [req.params.id]);
  res.status(204).send();
});
/**
 * @swagger
 * /productos/{id}:
 *   patch:
 *     tags: [Productos]
 *     summary: Editar producto (solo admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - { in: path, name: id, required: true, schema: { type: string } }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre: { type: string }
 *               descripcion: { type: string }
 *               precio: { type: number }
 *               stock: { type: integer }
 *     responses:
 *       200: { description: Producto actualizado }
 */
router.patch('/:id', verificarToken, permitirRoles('admin'), async (req, res) => {
  const { nombre, descripcion, precio, stock } = req.body;
  const { rows } = await pool.query(
    `update public.productos
        set nombre      = coalesce($1, nombre),
            descripcion = coalesce($2, descripcion),
            precio      = coalesce($3, precio),
            stock       = coalesce($4, stock)
      where id = $5 returning *`,
    [nombre, descripcion, precio, stock, req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ message: 'Producto no encontrado' });
  res.json(rows[0]);
});
module.exports = router;