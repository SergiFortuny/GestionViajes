import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  final String currentUsername; // nombre del usuario actual
  const AdminDashboard({super.key, required this.currentUsername});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Seguro que quieres eliminar este usuario? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('users').doc(id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado')),
        );
      }
    }
  }

  void _editUser(BuildContext context, String id, String username,
      String password, String rol, String profileImage) {
    final usernameController = TextEditingController(text: username);
    final passwordController = TextEditingController(text: password);
    final imageController = TextEditingController(text: profileImage);
    String selectedRol = rol;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Editar usuario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre de usuario'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: false, // contraseña visible
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRol,
                items: const [
                  DropdownMenuItem(
                      value: 'user', child: Text('Usuario normal')),
                  DropdownMenuItem(
                      value: 'admin', child: Text('Administrador')),
                ],
                decoration: const InputDecoration(labelText: 'Rol'),
                onChanged: (value) {
                  if (value != null) selectedRol = value;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen de perfil',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(id).update({
                'username': usernameController.text.trim(),
                'password': passwordController.text.trim(),
                'rol': selectedRol,
                'profileImage': imageController.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuario actualizado')),
                );
              }
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<QueryDocumentSnapshot> users, String titulo) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...users.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: data['profileImage'] != null
                    ? NetworkImage(data['profileImage'])
                    : null,
                child: data['profileImage'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(data['username']),
              subtitle: Text('Rol: ${data['rol']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _editUser(
                        context,
                        id,
                        data['username'],
                        data['password'],
                        data['rol'],
                        data['profileImage'] ?? ''),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteUser(id),
                  ),
                ],
              ),
            ),
          );
        }),
        const Divider(thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allUsers = snapshot.data!.docs;

          // Filtramos el usuario actual
          final filteredUsers = allUsers.where((u) {
            final data = u.data() as Map<String, dynamic>;
            return data['username'] != widget.currentUsername;
          }).toList();

          // Dividimos por rol
          final admins =
              filteredUsers.where((u) => (u['rol'] ?? '') == 'admin').toList();
          final users =
              filteredUsers.where((u) => (u['rol'] ?? '') == 'user').toList();

          return ListView(
            children: [
              _buildUserList(admins, '👑 Administradores'),
              _buildUserList(users, '👤 Usuarios'),
            ],
          );
        },
      ),
    );
  }
}
