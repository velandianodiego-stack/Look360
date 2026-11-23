import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/stripe_service.dart';
import '../../services/supabase_service.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'orders_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  int _ordersVersion = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CatalogScreen(),
      OrdersScreen(key: ValueKey(_ordersVersion)),
      const CartScreen(),
      const AccountScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _completarPagoWeb());
  }

  Future<void> _completarPagoWeb() async {
    try {
      final payment = await StripeService.instance.recuperarPagoWebConfirmado();
      if (payment == null || !mounted) return;
      await SupabaseService.instance.crearPedido(
        total: payment.total,
        items: payment.items,
        stripePaymentId: payment.paymentId,
      );
      await StripeService.instance.limpiarPedidoPendiente();
      if (!mounted) return;
      context.read<CartProvider>().clear();
      setState(() {
        _ordersVersion++;
        _screens[1] = OrdersScreen(key: ValueKey(_ordersVersion));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago confirmado y pedido registrado.')),
      );
    } catch (error) {
      debugPrint('No se pudo registrar el pedido web: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El pago fue confirmado, pero no se pudo registrar: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
            body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            if (i == 1) {
              _ordersVersion++;
              _screens[1] = OrdersScreen(key: ValueKey(_ordersVersion));
            }
          }),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Catálogo'),
          const NavigationDestination(icon: Icon(Icons.assignment_return_outlined), label: 'Pedidos'),
          NavigationDestination(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Mi cuenta'),
        ],
      ),
    );
  }
}