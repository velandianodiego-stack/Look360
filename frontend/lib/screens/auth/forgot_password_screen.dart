import 'package:material_ui/material_ui.dart';
import '../../services/supabase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRecoveryEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final error = await SupabaseService.instance.enviarRecuperacionPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Revisa tu Gmail: te enviamos el enlace para cambiar la contraseña.'),
      ),
    );
    if (error == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 18),
                const Text(
                  'Te enviaremos un correo a Gmail',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escribe tu correo y recibirás un enlace seguro para crear una nueva contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => value != null && value.contains('@')
                      ? null
                      : 'Escribe un correo válido',
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _sendRecoveryEmail,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'Enviando...' : 'Enviar correo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
