import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final String size;

  CartItemModel({
    required this.product,
    required this.size,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;
}