import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../auth/forgot_password_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  bool _saving = false;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;

    if (!_initialized) {
      _nameCtrl = TextEditingController(text: user.name);
      _phoneCtrl = TextEditingController(text: user.phone);
      _addressCtrl = TextEditingController(text: user.address);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF171717),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.email,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Correo (no editable)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Dirección de envío',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        user
                          ..name = _nameCtrl.text.trim()
                          ..phone = _phoneCtrl.text.trim()
                          ..address = _addressCtrl.text.trim();
                        await SupabaseService.instance.actualizarUsuario(user);
                        if (!context.mounted) return;
                        context.read<AuthProvider>().actualizarUsuarioLocal(
                          user,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Datos actualizados')),
                        );
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'No se pudieron guardar los datos: $error',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar cambios'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Cambiar contraseña'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ForgotPasswordScreen(initialEmail: user.email),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        ),
      ),
    );
  }
}
