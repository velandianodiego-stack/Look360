import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await SupabaseService.instance.getTodosLosPedidos();
    setState(() {
      _orders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy hh:mm a');

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_orders.isEmpty) {
      return const Center(child: Text('Aún no hay pedidos registrados', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          final perfil = order['perfiles'];
          final items = List<Map<String, dynamic>>.from(order['pedido_items'] ?? []);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(perfil != null ? (perfil['nombre'] ?? perfil['email']) : 'Usuario'),
              subtitle: Text(dateFormatter.format(DateTime.parse(order['fecha']))),
              trailing: SizedBox(
                width: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(order['total']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        order['estado'] ?? '',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              children: items
                  .map((item) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.checkroom_outlined, color: Theme.of(context).colorScheme.primary),
                        ),
                        title: Text(item['nombre_producto'] ?? ''),
                        subtitle: Text('Talla ${item['talla']} · Cantidad ${item['cantidad']}'),
                        trailing: Text(formatter.format(item['precio_unitario'] * item['cantidad'])),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}