import 'package:material_ui/material_ui.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;
  bool cargando = true; // carga inicial al abrir la app
  String? errorMessage;

  bool get logueado => currentUser != null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  Future<void> cargarSesion() async {
    final user = SupabaseService.instance.currentAuthUser;
    if (user != null) {
      currentUser = await SupabaseService.instance.getCurrentProfile();
    }
    cargando = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await SupabaseService.instance.login(email, password);
    if (error != null) {
      isLoading = false;
      errorMessage = error;
      notifyListeners();
      return false;
    }
    currentUser = await SupabaseService.instance.getCurrentProfile();
    isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register(String nombre, String email, String password, String telefono) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final error = await SupabaseService.instance.register(nombre, email, password, telefono);
    if (error != null) {
      isLoading = false;
      errorMessage = error;
      notifyListeners();
      return false;
    }
    currentUser = await SupabaseService.instance.getCurrentProfile();
    isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await SupabaseService.instance.logout();
    currentUser = null;
    notifyListeners();
  }
    void actualizarUsuarioLocal(UserModel updated) {
    currentUser = updated;
    notifyListeners();
  }
}