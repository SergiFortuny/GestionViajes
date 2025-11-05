/// 📘 Descripción del archivo:
/// Pantalla de registro (RegisterScreen) para la aplicación "Gestión de Viajes".
///
/// 🔹 Funcionalidades principales:
/// - Permite registrar nuevos usuarios en Firebase Firestore.
/// - Comprueba si el usuario ya existe antes de crear uno nuevo.
/// - Asigna por defecto el rol `user` y una imagen de perfil predeterminada.
/// - Muestra un diálogo de confirmación tras el registro exitoso.
///
/// 🔹 Aspectos visuales:
/// - Diseño JetBlack (modo oscuro moderno, consistente con toda la app).
/// - Colores unificados (fondo negro, azul principal Material Design 3).
/// - Botón para mostrar/ocultar la contraseña.
/// - Transiciones y campos con bordes suaves.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  Future<void> _register() async {
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rellena todos los campos')));
      return;
    }

    setState(() => loading = true);

    final existing = await _db
        .collection('users')
        .where('username', isEqualTo: usernameController.text.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('El usuario ya existe')));
      return;
    }

    await _db.collection('users').add({
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'rol': 'user',
      'profileImage': 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
    });

    setState(() => loading = false);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF0D0D0D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '✅ Registro exitoso',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Tu cuenta se ha creado correctamente.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Volver al login', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
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
              const Icon(Icons.person_add, color: Colors.blueAccent, size: 80),
              const SizedBox(height: 20),
              Text(
                "Crear Cuenta",
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
                onSubmitted: (_) => _register(),
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

              // 🔹 Botón de registro
              ElevatedButton(
                onPressed: loading ? null : _register,
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
                    : const Text('Registrarse', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),

              // 🔹 Enlace para ir al login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  "¿Ya tienes cuenta? Inicia sesión",
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
