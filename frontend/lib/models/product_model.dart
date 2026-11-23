class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final List<String> sizes;
  final int stock;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.sizes,
    required this.stock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'],
      name: json['nombre'] ?? '',
      description: json['descripcion'] ?? '',
      price: (json['precio'] as num).toDouble(),
      imageUrl: json['imagen_url'] ?? '',
      category: json['categoria'] ?? '',
        sizes: List<String>.from(json['tallas'] ?? []),
      stock: json['stock'] ?? 0,
      );
}