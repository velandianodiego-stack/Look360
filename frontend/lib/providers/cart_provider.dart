import 'package:material_ui/material_ui.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get total => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  void addItem(ProductModel product, String size) {
    final index = _items.indexWhere((i) => i.product.id == product.id && i.size == size);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItemModel(product: product, size: size));
    }
    notifyListeners();
  }

  void removeItem(CartItemModel item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItemModel item, int quantity) {
    if (quantity <= 0) {
      removeItem(item);
      return;
    }
    item.quantity = quantity;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}