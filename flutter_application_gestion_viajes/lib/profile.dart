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
  bool _obscurePassword = true; // 👁️ controla si se ve o no la contraseña
  String? userId;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

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
            TextField(
              controller: imageController,
              decoration: const InputDecoration(
                labelText: 'URL de imagen de perfil',
                hintText: 'Pega aquí un enlace directo a tu foto',
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
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
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
