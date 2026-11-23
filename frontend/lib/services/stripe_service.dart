import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class PendingWebPayment {
  final double total;
  final List<CartItemModel> items;
  final String paymentId;

  const PendingWebPayment({
    required this.total,
    required this.items,
    required this.paymentId,
  });
}

class StripeServerException implements Exception {
  final String message;

  const StripeServerException(this.message);

  @override
  String toString() => message;
}

class StripeService {
  StripeService._internal();
  static final StripeService instance = StripeService._internal();

  // Stripe exige un importe minimo equivalente a 50 centavos de USD.
  static const int _minimumCopAmount = 2000;

  static const String _functionUrl = 'https://dlaygjudeehcvlznhhxi.supabase.co/functions/v1/create-payment-intent';

  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsYXlnanVkZWVoY3Zsem5oaHhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NDQ0MTYsImV4cCI6MjEwNDAyMDQxNn0.NHnkG6uBbRqf8ZBIKvQ7TDTTJLfQPAXkcWJP2nrBYvI';

  Future<String?> pagar({required double total}) async {
    try {
      if (kIsWeb) {
        return await _abrirCheckoutWeb(total);
      }

      final amountInCop = total.round();
      if (amountInCop < _minimumCopAmount) {
        throw const StripeServerException(
          'El total es demasiado bajo para pagar con Stripe. Usa al menos '
          r'$2.000 COP o agrega mas productos.',
        );
      }

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({'amount': amountInCop}),
      );

      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = responseData?['error']?.toString() ??
            'Stripe rechazó el pago (HTTP ${response.statusCode}).';
        debugPrint('Error del servidor Stripe/Supabase: $message');
        throw StripeServerException(message);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String?;

      if (clientSecret == null || clientSecret.isEmpty) {
        debugPrint('No se recibió clientSecret: ${response.body}');
        return null;
      }

      final paymentIntentId = clientSecret.split('_secret_')[0];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ModaStyle',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      return paymentIntentId;
    } on StripeException catch (e) {
      debugPrint('Pago cancelado: ${e.error.localizedMessage}');
      return null;
    } catch (e) {
      debugPrint('Error de pago: $e');
      return null;
    }
  }

  Future<void> guardarPedidoPendiente({
    required double total,
    required List<CartItemModel> items,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('pending_order', jsonEncode({
      'total': total,
      'items': items.map((item) => {
        'id': item.product.id,
        'name': item.product.name,
        'description': item.product.description,
        'price': item.product.price,
        'imageUrl': item.product.imageUrl,
        'category': item.product.category,
        'sizes': item.product.sizes,
        'stock': item.product.stock,
        'size': item.size,
        'quantity': item.quantity,
      }).toList(),
    }));
  }

  Future<PendingWebPayment?> recuperarPagoWebConfirmado() async {
    if (!kIsWeb || Uri.base.queryParameters['payment'] != 'success') return null;
    final sessionId = Uri.base.queryParameters['session_id'];
    if (sessionId == null || sessionId.isEmpty) return null;

    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      },
      body: jsonEncode({'action': 'verify_checkout', 'sessionId': sessionId}),
    );
    if (response.statusCode != 200) return null;

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['paid'] != true || result['paymentId'] == null) return null;

    final preferences = await SharedPreferences.getInstance();
    final pendingJson = preferences.getString('pending_order');
    if (pendingJson == null) return null;
    final pending = jsonDecode(pendingJson) as Map<String, dynamic>;
    final rawItems = pending['items'] as List<dynamic>;
    final items = rawItems.map((raw) {
      final item = raw as Map<String, dynamic>;
      return CartItemModel(
        product: ProductModel(
          id: item['id'] as String,
          name: item['name'] as String,
          description: item['description'] as String,
          price: (item['price'] as num).toDouble(),
          imageUrl: item['imageUrl'] as String,
          category: item['category'] as String,
          sizes: List<String>.from(item['sizes'] as List<dynamic>),
          stock: item['stock'] as int,
        ),
        size: item['size'] as String,
        quantity: item['quantity'] as int,
      );
    }).toList();

    return PendingWebPayment(
      total: (pending['total'] as num).toDouble(),
      items: items,
      paymentId: result['paymentId'] as String,
    );
  }

  Future<void> limpiarPedidoPendiente() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('pending_order');
  }

  Future<String?> _abrirCheckoutWeb(double total) async {
    final amountInCop = total.round();
    if (amountInCop < _minimumCopAmount) {
      throw const StripeServerException(
        'El total es demasiado bajo para pagar con Stripe. Usa al menos '
        r'$2.000 COP o agrega mas productos.',
      );
    }

    final origin = Uri.base.origin;
    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
      },
      body: jsonEncode({
        'amount': amountInCop,
        'checkout': true,
        'successUrl': '$origin/?payment=success&session_id={CHECKOUT_SESSION_ID}',
        'cancelUrl': '$origin/?payment=cancelled',
      }),
    );

    if (response.statusCode != 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw StripeServerException(
        responseData?['error']?.toString() ??
            'Stripe rechazó el Checkout (HTTP ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final checkoutUrl = data['checkoutUrl'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw const StripeServerException('Stripe no devolvió la URL de Checkout.');
    }

    final launched = await launchUrl(Uri.parse(checkoutUrl), webOnlyWindowName: '_self');
    if (!launched) {
      throw const StripeServerException('No se pudo abrir la página de pago de Stripe.');
    }
    return null;
  }
}
