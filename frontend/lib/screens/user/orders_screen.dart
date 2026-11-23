import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../models/order_model.dart';
import '../../services/supabase_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await SupabaseService.instance.getPedidosUsuario();
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  Future<void> _solicitarDevolucion(OrderModel order) async {
    final motivoCtrl = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Solicitar devolución'),
        content: TextField(
          controller: motivoCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motivo de la devolución',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar == true && motivoCtrl.text.trim().isNotEmpty) {
      final error = await SupabaseService.instance.solicitarDevolucion(
        order.id,
        motivoCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Devolución solicitada correctamente'),
          ),
        );
      }
      _load();
    }
  }

  void _showOrderDetails(
    OrderModel order,
    NumberFormat formatter,
    DateFormat dateFormatter, {
    required bool returnsOnly,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Wrap(
            runSpacing: 14,
            children: [
              Text(
                returnsOnly ? 'Detalle de devolución' : 'Detalle de compra',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${returnsOnly ? 'Devolución' : 'Pedido'} #${order.id.substring(0, 8)}  ·  ${dateFormatter.format(order.fecha)}',
                style: const TextStyle(color: Colors.black54),
              ),
              ...order.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: item.imagenUrl.isEmpty
                        ? Container(
                            width: 52,
                            height: 52,
                            color: const Color(0xFFE5E5E2),
                            child: const Icon(Icons.checkroom_outlined),
                          )
                        : Image.network(
                            item.imagenUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                  ),
                  title: Text(item.nombreProducto),
                  subtitle: Text(
                    'Talla ${item.talla}  ·  ${item.cantidad} unidad(es)',
                  ),
                  trailing: Text(
                    formatter.format(item.precioUnitario * item.cantidad),
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatter.format(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (returnsOnly)
                Text(
                  'Estado: ${order.devolucionEstado ?? 'solicitada'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(
    OrderModel order,
    NumberFormat formatter,
    DateFormat dateFormatter, {
    bool returnsOnly = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          returnsOnly
              ? 'Devolución #${order.id.substring(0, 8)}'
              : 'Pedido #${order.id.substring(0, 8)}',
        ),
        subtitle: Text(
          dateFormatter.format(order.fecha),
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: SizedBox(
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: returnsOnly
                      ? const Color(0xFFE8E8E5)
                      : const Color(0xFFDCDCDC),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  returnsOnly
                      ? (order.devolucionEstado ?? 'solicitada')
                      : order.estado,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        children: [
          ...order.items.map(
            (item) => ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imagenUrl.isEmpty
                    ? Container(
                        width: 54,
                        height: 54,
                        color: const Color(0xFFE5E5E2),
                        child: const Icon(Icons.checkroom_outlined),
                      )
                    : Image.network(
                        item.imagenUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
              ),
              title: Text(item.nombreProducto),
              subtitle: Text(
                'Talla ${item.talla}  ·  Cantidad ${item.cantidad}',
              ),
              trailing: Text(
                formatter.format(item.precioUnitario * item.cantidad),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (!returnsOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Ver más'),
                    onPressed: () => _showOrderDetails(
                      order,
                      formatter,
                      dateFormatter,
                      returnsOnly: returnsOnly,
                    ),
                  ),
                  const Spacer(),
                  if (order.devolucionEstado != null)
                    Chip(label: Text('Devolución: ${order.devolucionEstado}'))
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Devolver'),
                      onPressed: () => _solicitarDevolucion(order),
                    ),
                ],
              ),
            ),
          if (returnsOnly)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextButton.icon(
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver más'),
                  onPressed: () => _showOrderDetails(
                    order,
                    formatter,
                    dateFormatter,
                    returnsOnly: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderList(
    List<OrderModel> orders,
    NumberFormat formatter,
    DateFormat dateFormatter,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No hay registros todavía',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: orders.length,
        itemBuilder: (_, index) => _orderCard(
          orders[index],
          formatter,
          dateFormatter,
          returnsOnly: orders[index].devolucionEstado != null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy hh:mm a');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Mis compras'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Pedidos'),
              Tab(
                icon: Icon(Icons.assignment_return_outlined),
                text: 'Devoluciones',
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Actualizar pedidos',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _orders.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Aún no tienes pedidos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  final returns = _orders
                      .where((order) => order.devolucionEstado != null)
                      .toList();
                  final orders = _orders
                      .where((order) => order.devolucionEstado == null)
                      .toList();
                  return TabBarView(
                    children: [
                      _orderList(orders, formatter, dateFormatter),
                      _orderList(returns, formatter, dateFormatter),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
