import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'services/user_session.dart';
import 'services/cart_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true; // ✅ accept all
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ chỉ bật khi debug
  if (!kReleaseMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  await UserSession.load();
  await CartService().loadCart(); // ✅ Load giỏ hàng từ storage
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserSession.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
