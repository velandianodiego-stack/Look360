import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  bool _sessionReady = false;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _waitForRecoverySession();
  }

  Future<void> _waitForRecoverySession() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession != null) {
      if (mounted) setState(() => _sessionReady = true);
      return;
    }

    try {
      final queryCode = Uri.base.queryParameters['code'];
      if (queryCode != null && queryCode.isNotEmpty) {
        await client.auth.exchangeCodeForSession(queryCode);
      } else {
        final fragment = Uri.base.fragment;
        final fragmentValues = Uri.splitQueryString(fragment);
        final refreshToken = fragmentValues['refresh_token'];
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await client.auth.setSession(refreshToken);
        }
      }

      if (client.auth.currentSession == null) {
        await client.auth.onAuthStateChange
            .where((event) => event.session != null)
            .first
            .timeout(const Duration(seconds: 12));
      }
      if (mounted) setState(() => _sessionReady = true);
    } catch (_) {
      if (mounted) {
        setState(() => _sessionError = 'El enlace no pudo validarse. Solicita otro correo y ábrelo directamente desde Gmail.');
      }
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_sessionReady) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada correctamente.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                const Text('Crea una nueva contraseña', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                if (_sessionError != null)
                  Text(_sessionError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                if (!_sessionReady && _sessionError == null)
                  const Center(child: CircularProgressIndicator()),
                if (_sessionReady) ...[
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (value) => value != null && value.length >= 6 ? null : 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure,
                  decoration: const InputDecoration(labelText: 'Repite la contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (value) => value == _passwordCtrl.text ? null : 'Las contraseñas no coinciden',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving ? null : _savePassword,
                  child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar contraseña'),
                ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}