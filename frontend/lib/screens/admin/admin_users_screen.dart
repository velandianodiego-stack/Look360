import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'admin_user_edit_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_product_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final users = await SupabaseService.instance.getTodosLosUsuarios();
    setState(() {
      _allUsers = users;
      _filtered = users;
      _loading = false;
    });
  }

  void _filter(String query) {
    setState(() {
      _filtered = _allUsers
          .where(
            (u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SupabaseService.instance.eliminarUsuario(user.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('Panel Admin'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
              Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Compras'),
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: TextField(
                    onChanged: _filter,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o correo',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final user = _filtered[index];
                              return Card(
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: user.isAdmin
                                        ? Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    child: Icon(
                                      user.isAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  title: Text(
                                    user.name.isEmpty
                                        ? '(sin nombre)'
                                        : user.name,
                                  ),
                                  subtitle: Text(
                                    '${user.email}\n${user.phone.isEmpty ? 'Sin celular' : user.phone}  ·  ${user.role}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AdminUserEditScreen(
                                                    user: user,
                                                  ),
                                            ),
                                          );
                                          _load();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDelete(user),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            const AdminOrdersScreen(),
            const AdminProductsScreen(),
          ],
        ),
      ),
    );
  }
}
