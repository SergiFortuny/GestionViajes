/// 📘 Descripción del archivo:
/// Pantalla de perfil de usuario (ProfileScreen) para la aplicación "Gestión de Viajes".
///
/// 🔹 Funcionalidades principales:
/// - Permite visualizar y modificar los datos del usuario actual.
/// - Se conecta a Firebase Firestore para leer y actualizar los campos:
///   → Nombre de usuario  
///   → Contraseña  
///   → Imagen de perfil (mediante URL)
/// - Actualiza los datos directamente en la base de datos.
/// - Muestra notificaciones de confirmación tras guardar los cambios.
///
/// 🔹 Aspectos visuales:
/// - Estilo JetBlack (modo oscuro por defecto, coherente con toda la app).
/// - Bordes suaves, tipografía clara y uso de Material Design 3.
/// - Botón para mostrar/ocultar la contraseña.


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final imageController = TextEditingController();

  bool loading = true;
  bool _obscurePassword = true; // 👁️ Mostrar u ocultar contraseña
  String? userId;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 Cargar datos del usuario desde Firebase
  Future<void> _loadUserData() async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      userId = doc.id;
      userData = doc.data();
      usernameController.text = userData!['username'];
      passwordController.text = userData!['password'];
      imageController.text = userData!['profileImage'] ?? '';
    }
    setState(() => loading = false);
  }

  // 🔹 Guardar cambios en Firestore
  Future<void> _saveChanges() async {
    if (userId == null) return;

    await _db.collection('users').doc(userId).update({
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'profileImage': imageController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados correctamente 🎉'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: (imageController.text.isNotEmpty)
                    ? NetworkImage(imageController.text)
                    : null,
                child: (imageController.text.isEmpty)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Campo de URL de imagen
            TextField(
              controller: imageController,
              decoration: InputDecoration(
                labelText: 'URL de imagen de perfil',
                hintText: 'Pega aquí un enlace directo a tu foto',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),

            // 🔹 Campo de nombre de usuario
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),

            // 🔹 Campo de contraseña
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 30),

            // 🔹 Botón para guardar los cambios
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
