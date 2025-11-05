/// 📘 Descripción del archivo:
/// Pantalla de inicio de sesión (LoginScreen) para la aplicación "Gestión de Viajes".
///
/// 🔹 Funcionalidades principales:
/// - Permite iniciar sesión validando usuario y contraseña desde Firebase.
/// - Si los datos son correctos, redirige al `HomeScreen`.
/// - Botón para registrarse si no se tiene cuenta.
/// - Campo de contraseña con botón para mostrar/ocultar texto.
/// - Permite iniciar sesión presionando Enter en el campo contraseña.
///
/// 🔹 Aspectos visuales:
/// - Diseño JetBlack (modo oscuro moderno).
/// - Estilo Material Design 3 consistente con el resto de la aplicación.
/// - Colores unificados (azul Material y fondo negro).


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  Future<void> _login() async {
    setState(() => loading = true);

    final query = await _db
        .collection('users')
        .where('username', isEqualTo: usernameController.text.trim())
        .where('password', isEqualTo: passwordController.text.trim())
        .limit(1)
        .get();

    setState(() => loading = false);

    if (query.docs.isNotEmpty) {
      final username = query.docs.first['username'];
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(username: username)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario o contraseña incorrectos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flight_takeoff, color: Colors.blueAccent, size: 80),
              const SizedBox(height: 20),
              Text(
                "Gestión de Viajes",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              // 🔹 Campo de usuario
              TextField(
                controller: usernameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  prefixIcon: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black45),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Campo de contraseña
              TextField(
                controller: passwordController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                obscureText: !showPassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                  prefixIcon: Icon(Icons.lock, color: isDark ? Colors.white70 : Colors.black45),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white70 : Colors.black45,
                    ),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 🔹 Botón de inicio de sesión
              ElevatedButton(
                onPressed: loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Iniciar sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // 🔹 Botón para ir al registro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  "¿No tienes cuenta? Regístrate",
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
