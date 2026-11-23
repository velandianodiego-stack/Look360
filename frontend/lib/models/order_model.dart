class OrderItemModel {
  final String nombreProducto;
  final String talla;
  final int cantidad;
  final double precioUnitario;
  final String imagenUrl;

  OrderItemModel({
    required this.nombreProducto,
    required this.talla,
    required this.cantidad,
    required this.precioUnitario,
    this.imagenUrl = '',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
      nombreProducto: json['nombre_producto'] ?? '',
      talla: json['talla'] ?? '',
      cantidad: json['cantidad'] ?? 1,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      imagenUrl: json['imagen_url'] ?? '',
      );
}

class OrderModel {
  final String id;
  final double total;
  final String estado;
  final DateTime fecha;
  final List<OrderItemModel> items;
  String? devolucionEstado; // null = no se ha pedido devolución para este pedido

  OrderModel({
    required this.id,
    required this.total,
    required this.estado,
    required this.fecha,
    required this.items,
    this.devolucionEstado,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
      id: json['id'],
      total: (json['total'] as num).toDouble(),
      estado: json['estado'] ?? 'pendiente',
      fecha: DateTime.parse(json['fecha']),
      items: (json['pedido_items'] as List? ?? [])
            .map((e) => OrderItemModel.fromJson(e))
            .toList(),
      );
}