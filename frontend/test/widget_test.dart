// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/cart_provider.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/screens/auth/register_screen.dart';
import 'package:frontend/screens/user/cart_screen.dart';

void main() {
  testWidgets('registro exige nombre, celular, correo y contraseña', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );

    expect(find.text('Número de celular'), findsOneWidget);
    await tester.tap(find.text('Registrarme'));
    await tester.pump();
    expect(find.text('Ingresa un número de celular válido'), findsOneWidget);
  });

  testWidgets('carrito muestra el producto añadido', (WidgetTester tester) async {
    final product = ProductModel(
      id: 'product-1',
      name: 'Producto de prueba',
      description: 'Descripción',
      price: 120000,
      imageUrl: '',
      category: 'Prueba',
      sizes: const ['M'],
      stock: 5,
    );
    final cart = CartProvider()..addItem(product, 'M');

    await tester.pumpWidget(
      ChangeNotifierProvider<CartProvider>.value(
        value: cart,
        child: const MaterialApp(home: CartScreen()),
      ),
    );

    expect(find.text('Producto de prueba'), findsOneWidget);
    expect(find.text('Talla: M'), findsOneWidget);
  });
}
