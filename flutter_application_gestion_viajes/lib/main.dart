/// 📘 Descripción del archivo:
/// Archivo principal `main.dart` de la aplicación "Gestión de Viajes".
///
/// 🔹 Funcionalidades principales:
/// - Inicializa la aplicación Flutter y configura el tema global.
/// - Define el estilo visual JetBlack (modo oscuro permanente).
/// - Establece el punto de entrada (`LoginScreen`) y las rutas base.
///
/// 🔹 Aspectos visuales:
/// - Paleta JetBlack unificada para toda la app.
/// - Uso de Material 3 con esquinas redondeadas y fondos oscuros.
/// - Colores coherentes en AppBar, Drawer, Inputs y botones.


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGu8asTgTjnf_MT0-tLavAcci_jfgb6WE",
      authDomain: "login-1841d.firebaseapp.com",
      projectId: "login-1841d",
      storageBucket: "login-1841d.firebasestorage.app",
      messagingSenderId: "172533303099",
      appId: "1:172533303099:web:d8d2cd8e24fabbcd09591e",
    ),
  );

  runApp(const ViajesApp());
}

class ViajesApp extends StatelessWidget {
  const ViajesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Viajes',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // 🌙 JetBlack activo por defecto
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
