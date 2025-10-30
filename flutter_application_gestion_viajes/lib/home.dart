import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'admin.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userRole;
  bool isLoading = true;
  String? userPhoto;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        userRole = data['rol'];
        userPhoto = data['profileImage'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bienvenido ${widget.username}')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: userPhoto != null
                        ? NetworkImage(userPhoto!)
                        : const AssetImage('assets/default_user.png')
                              as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.username,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    userRole ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(username: widget.username),
                  ),
                );
              },
            ),

            if (userRole == 'admin') ...[
  const Divider(),
  ListTile(
    leading: const Icon(Icons.admin_panel_settings),
    title: const Text('Gestión de Usuarios'),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboard(
            currentUsername: widget.username, // 👈 importante
          ),
        ),
      );
    },
  ),
],


            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
            
            
          ],
        ),
      ),
      body: Center(
        child: Text(
          userRole == 'admin'
              ? 'Panel de administración — Bienvenido, ${widget.username}'
              : 'Pantalla principal de gestión de viajes',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
