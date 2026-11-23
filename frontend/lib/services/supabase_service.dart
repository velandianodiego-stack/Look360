import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ---------------- AUTENTICACIÓN ----------------
  Future<String?> register(
    String nombre,
    String email,
    String password,
    String telefono,
  ) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre, 'telefono': telefono},
      );
      if (res.user == null) return 'No se pudo crear la cuenta';
      if (res.session != null) {
        await _client
            .from('perfiles')
            .update({'telefono': telefono})
            .eq('id', res.user!.id);
      }
      return null; // éxito
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return 'Credenciales inválidas';
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> enviarRecuperacionPassword(String email) async {
    try {
      final redirectTo = kIsWeb
          ? '${Uri.base.origin}/reset-password'
          : 'http://localhost:3000/reset-password';
      await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'No se pudo enviar el correo: $e';
    }
  }

  Future<void> logout() async => _client.auth.signOut();

  User? get currentAuthUser => _client.auth.currentUser;

  Future<UserModel?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('perfiles')
        .select()
        .eq('id', user.id)
        .single();
    return UserModel.fromJson(data);
  }

  Future<List<ProductModel>> getProductos({
    String? search,
    String? category,
  }) async {
    var query = _client.from('productos').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('nombre', '%$search%');
    }
    if (category != null && category != 'Todas') {
      query = query.eq('categoria', category);
    }
    final data = await query;
    return (data as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  Future<void> crearProducto({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    required List<String> sizes,
    required int stock,
  }) async {
    await _client.from('productos').insert({
      'nombre': name,
      'descripcion': description,
      'precio': price,
      'imagen_url': imageUrl,
      'categoria': category,
      'tallas': sizes,
      'stock': stock,
    });
  }

  Future<void> eliminarProducto(String id) async {
    await _client.from('productos').delete().eq('id', id);
  }

  // ---------------- ADMIN: USUARIOS ----------------
  Future<List<UserModel>> getTodosLosUsuarios() async {
    final data = await _client
        .from('perfiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> actualizarUsuario(UserModel user) async {
    await _client.from('perfiles').update(user.toJson()).eq('id', user.id);
  }

  Future<void> eliminarUsuario(String id) async {
    // Borra el perfil. El usuario de Auth solo se puede borrar desde el backend
    // (no desde la app con la anonKey), así que aquí solo removemos su perfil/acceso.
    await _client.from('perfiles').delete().eq('id', id);
  }

  // ---------------- ADMIN: PEDIDOS DE TODOS LOS USUARIOS ----------------
  Future<List<Map<String, dynamic>>> getTodosLosPedidos() async {
    final data = await _client
        .from('pedidos')
        .select('*, perfiles(nombre, email), pedido_items(*)')
        .eq('estado', 'pagado')
        .not('stripe_payment_id', 'is', null)
        .order('fecha', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------- PEDIDOS (usuario) ----------------
  Future<void> crearPedido({
    required double total,
    required List<CartItemModel> items,
    required String stripePaymentId,
  }) async {
    if (stripePaymentId.trim().isEmpty) {
      throw StateError(
        'No se puede registrar un pedido sin confirmación de Stripe.',
      );
    }
    final userId = _client.auth.currentUser!.id;

    final pedido = await _client
        .from('pedidos')
        .insert({
          'usuario_id': userId,
          'total': total,
          'estado': 'pagado',
          'stripe_payment_id': stripePaymentId,
        })
        .select()
        .single();

    final pedidoId = pedido['id'];

    final itemsData = items
        .map(
          (i) => {
            'pedido_id': pedidoId,
            'producto_id': i.product.id,
            'nombre_producto': i.product.name,
            'talla': i.size,
            'cantidad': i.quantity,
            'precio_unitario': i.product.price,
          },
        )
        .toList();

    await _client.from('pedido_items').insert(itemsData);
  }

  Future<List<OrderModel>> getPedidosUsuario() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final userId = user.id;
    final pedidosData = await _client
        .from('pedidos')
        .select('*, pedido_items(*)')
        .eq('usuario_id', userId)
        .eq('estado', 'pagado')
        .not('stripe_payment_id', 'is', null)
        .order('fecha', ascending: false);

    final rawOrders = List<Map<String, dynamic>>.from(pedidosData);
    final productIds = rawOrders
        .expand(
          (order) =>
              List<Map<String, dynamic>>.from(order['pedido_items'] ?? []),
        )
        .map((item) => item['producto_id'])
        .whereType<String>()
        .toSet()
        .toList();
    final productImages = <String, String>{};
    if (productIds.isNotEmpty) {
      final products = await _client
          .from('productos')
          .select('id, imagen_url')
          .inFilter('id', productIds);
      for (final product in products as List) {
        productImages[product['id'] as String] =
            (product['imagen_url'] ?? '') as String;
      }
    }
    for (final order in rawOrders) {
      for (final item in List<Map<String, dynamic>>.from(
        order['pedido_items'] ?? [],
      )) {
        item['imagen_url'] = productImages[item['producto_id']] ?? '';
      }
    }
    final pedidos = rawOrders.map(OrderModel.fromJson).toList();

    final devolucionesData = await _client
        .from('devoluciones')
        .select()
        .eq('usuario_id', userId);

    for (final dev in (devolucionesData as List)) {
      final match = pedidos.where((p) => p.id == dev['pedido_id']);
      if (match.isNotEmpty) match.first.devolucionEstado = dev['estado'];
    }

    return pedidos;
  }

  // ---------------- DEVOLUCIONES (usuario) ----------------
  Future<String?> solicitarDevolucion(String pedidoId, String motivo) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 'Debes iniciar sesión para devolver un pedido';

      await _client.from('devoluciones').insert({
        'pedido_id': pedidoId,
        'usuario_id': user.id,
        'motivo': motivo,
      });
      return null;
    } catch (e) {
      return 'No se pudo registrar la devolución: $e';
    }
  }
}
