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
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _listenToUserChanges();
  }

  void _listenToUserChanges() {
    _db.collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          userData = snapshot.docs.first.data();
          loading = false;
        });
      }
    });
  }

  Future<void> _updateField(String field, String value) async {
    final query = await _db.collection('users').where('username', isEqualTo: widget.username).limit(1).get();
    if (query.docs.isNotEmpty) {
      await _db.collection('users').doc(query.docs.first.id).update({field: value});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field actualizado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: userData!['profileImage'] != null && userData!['profileImage'].isNotEmpty
                  ? NetworkImage(userData!['profileImage'])
                  : null,
              child: userData!['profileImage'] == null || userData!['profileImage'].isEmpty
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Enlace de imagen de perfil'),
              onSubmitted: (value) => _updateField('profileImage', value.trim()),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Nombre de usuario', hintText: userData!['username']),
              onSubmitted: (value) => _updateField('username', value.trim()),
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              onSubmitted: (value) => _updateField('password', value.trim()),
            ),
          ],
        ),
      ),
    );
  }
}
