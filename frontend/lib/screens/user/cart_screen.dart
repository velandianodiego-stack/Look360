import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/stripe_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  Future<void> _procesarPago(CartProvider cart) async {
    setState(() => _isLoading = true);

    try {
      // 1. Procesar el pago con Stripe
      if (kIsWeb) {
        await StripeService.instance.guardarPedidoPendiente(
          total: cart.total,
          items: cart.items,
        );
      }
      final paymentId = await StripeService.instance.pagar(total: cart.total);

      if (paymentId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(kIsWeb
                  ? 'Se abrió Stripe Checkout para completar el pago.'
                  : 'El pago fue cancelado o falló'),
            ),
          );
        }
        return;
      }

      // 2. Crear la orden en Supabase asociando el ID de Stripe
      await SupabaseService.instance.crearPedido(
        total: cart.total,
        items: cart.items,
        stripePaymentId: paymentId,
      );

      // 3. Limpiar carrito
      cart.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Pago exitoso! Pedido realizado 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la compra: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Carrito de compras')),
      body: cart.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Tu carrito está vacío', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.product.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.checkroom),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Talla: ${item.size}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    Text(
                                      formatter.format(item.product.price),
                                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => context
                                            .read<CartProvider>()
                                            .updateQuantity(item, item.quantity - 1),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => context
                                            .read<CartProvider>()
                                            .updateQuantity(item, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.read<CartProvider>().removeItem(item),
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16)),
                            Text(
                              formatter.format(cart.total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _procesarPago(cart),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Pagar y realizar pedido'),
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