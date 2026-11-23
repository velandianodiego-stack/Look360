import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.sizes.isNotEmpty
        ? widget.product.sizes.first
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.checkroom_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(product.price),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'Prenda seleccionada de nuestra colección ModaStyle.'
                        : product.description,
                    style: const TextStyle(height: 1.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Talla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: product.sizes
                        .map(
                          (size) => ChoiceChip(
                            label: Text(size),
                            selected: size == _selectedSize,
                            onSelected: (_) =>
                                setState(() => _selectedSize = size),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tiempo de entrega: 3 a 5 días hábiles',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Añadir al carrito'),
                      onPressed: () {
                        context.read<CartProvider>().addItem(
                          product,
                          _selectedSize,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} añadido al carrito'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
