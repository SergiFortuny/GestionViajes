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
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      _userId = snapshot.docs.first.id;
      _usernameController.text = data['username'] ?? '';
      _passwordController.text = data['password'] ?? '';
      _imageController.text = data['profileImage'] ?? '';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;

    await _db.collection('users').doc(_userId).update({
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'profileImage': _imageController.text.trim(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: _imageController.text.isNotEmpty
                      ? NetworkImage(_imageController.text)
                      : const NetworkImage('https://i.imgur.com/4ZQZ4Y0.png'),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Introduce un nombre' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Introduce una contraseña' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                    labelText: 'URL de imagen de perfil',
                    hintText: 'https://...'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
