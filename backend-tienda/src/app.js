require('dotenv').config();
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./swagger');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use('/auth', require('./routes/auth.routes'));
app.use('/productos', require('./routes/productos.routes'));
app.use('/pedidos', require('./routes/pedidos.routes'));
app.use('/perfiles', require('./routes/perfiles.routes'));
app.use('/devoluciones', require('./routes/devoluciones.routes'));

app.listen(process.env.PORT, () =>
  console.log(`API en http://localhost:${process.env.PORT}/api-docs`)
);