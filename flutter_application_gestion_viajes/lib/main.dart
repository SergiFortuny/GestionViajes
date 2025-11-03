import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';
import 'theme_manager.dart';

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

class ViajesApp extends StatefulWidget {
  const ViajesApp({super.key});

  @override
  State<ViajesApp> createState() => _ViajesAppState();
}

class _ViajesAppState extends State<ViajesApp> {
  final ThemeManager _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _themeManager.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // 🎨 Paleta unificada
    const primaryBlue = Color(0xFF2196F3);
    const backgroundDark = Color(0xFF121212);
    const surfaceDark = Color(0xFF1E1E1E);
    const textLight = Color(0xFFE0E0E0);
    const textMuted = Color(0xFFB0B0B0);

    final lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: Color(0xFF64B5F6),
        background: Colors.white,
        surface: Color(0xFFF5F5F5),
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF8F8F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: Color(0xFF64B5F6),
        background: backgroundDark,
        surface: surfaceDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textLight,
        elevation: 1,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textLight),
        bodySmall: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestión de Viajes',
      themeMode: _themeManager.mode,
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
