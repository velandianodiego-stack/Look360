import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Número de celular',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  final phone = v?.trim() ?? '';
                  return phone.length < 7 ? 'Ingresa un número de celular válido' : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              if (auth.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(auth.errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await context.read<AuthProvider>().register(
                              _nameCtrl.text.trim(),
                              _emailCtrl.text.trim(),
                              _passCtrl.text.trim(),
                              _phoneCtrl.text.trim(),
                            );
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Registrarme'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}