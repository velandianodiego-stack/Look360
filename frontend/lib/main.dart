import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/user/main_navigation.dart';
import 'screens/admin/admin_users_screen.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

const String supabaseUrl = 'https://dlaygjudeehcvlznhhxi.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRsYXlnanVkZWVoY3Zsem5oaHhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0NDQ0MTYsImV4cCI6MjEwNDAyMDQxNn0.NHnkG6uBbRqf8ZBIKvQ7TDTTJLfQPAXkcWJP2nrBYvI';
const String stripePublishableKey =
    'pk_test_51UHPL7HUnLVIdCeH8VbIzx1Suhgh7GjJrIxvpKopTt1GWUZroZwaZW0AtpDm7ypSRIvgpn5wlW8dCl7tWqjmMoGk00naEENnSP';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  if (!kIsWeb) {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..cargarSesion()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'ModaStyle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF171717),
            onPrimary: Colors.white,
            secondary: Color(0xFF555555),
            onSecondary: Colors.white,
            surface: Color(0xFFF5F5F3),
            onSurface: Color(0xFF171717),
            outline: Color(0xFFD6D6D2),
            outlineVariant: Color(0xFFE5E5E2),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F3),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF171717),
            foregroundColor: Colors.white,
            centerTitle: false,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD6D6D2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFD6D6D2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFF171717),
                width: 1.5,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE0E0DC)),
            ),
          ),
          navigationBarTheme: const NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: Color(0xFFE3E3DF),
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          tabBarTheme: const TabBarThemeData(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFBDBDBD),
          ),
        ),
        home: const RootDecider(),
      ),
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final isPasswordReset = Uri.base.path == '/reset-password';
    if (isPasswordReset) return const ResetPasswordScreen();

    if (auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.logueado) {
      return const LoginScreen();
    }
    if (auth.isAdmin) {
      return const AdminUsersScreen();
    }
    return const MainNavigation();
  }
}
