import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  final String currentUsername;
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
        title: const Text('Eliminar usuario'),
        content: const Text('¿Seguro que quieres eliminar este usuario? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuario eliminado correctamente.')));
    }
  }

  void _editUser(BuildContext context, String id, String username, String password, String rol) {
    final usernameController = TextEditingController(text: username);
    final passwordController = TextEditingController(text: password);
    String selectedRole = rol;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: const Text('Editar usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: const Icon(Icons.visibility),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Usuario')),
                DropdownMenuItem(value: 'admin', child: Text('Administrador')),
              ],
              onChanged: (value) {
                if (value != null) selectedRole = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(id).update({
                'username': usernameController.text.trim(),
                'password': passwordController.text.trim(),
                'rol': selectedRole,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Usuario actualizado')));
            },
            child: const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }

  void _showUserTrips(BuildContext context, String userId, String username) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text('Viajes de $username',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('users')
                      .doc(userId)
                      .collection('trips')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final trips = snapshot.data!.docs;
                    if (trips.isEmpty) {
                      return const Center(child: Text('No tiene viajes registrados.'));
                    }

                    return ListView.builder(
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        final data = trips[index].data() as Map<String, dynamic>;
                        final id = trips[index].id;
                        final fechaSalida = (data['fecha_salida'] as Timestamp).toDate();
                        final fechaVuelta = (data['fecha_vuelta'] as Timestamp).toDate();

                        final isDark = Theme.of(context).brightness == Brightness.dark;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text('${data['origen']} → ${data['destino']}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}\n'
                              'Vuelta: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () => _editTrip(context, userId, id, data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => _deleteTrip(userId, id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editTrip(BuildContext context, String userId, String tripId, Map<String, dynamic> data) async {
    final origenController = TextEditingController(text: data['origen']);
    final destinoController = TextEditingController(text: data['destino']);
    final notasController = TextEditingController(text: data['notas']);
    int personas = data['personas'];
    String transporte = data['transporte'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar viaje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: origenController, decoration: const InputDecoration(labelText: 'Origen')),
            TextField(controller: destinoController, decoration: const InputDecoration(labelText: 'Destino')),
            DropdownButtonFormField<String>(
              value: transporte,
              decoration: const InputDecoration(labelText: 'Transporte'),
              items: const [
                DropdownMenuItem(value: 'Avión ✈️', child: Text('Avión ✈️')),
                DropdownMenuItem(value: 'Tren 🚄', child: Text('Tren 🚄')),
                DropdownMenuItem(value: 'Coche 🚗', child: Text('Coche 🚗')),
                DropdownMenuItem(value: 'Barco 🚢', child: Text('Barco 🚢')),
                DropdownMenuItem(value: 'Autobús 🚌', child: Text('Autobús 🚌')),
              ],
              onChanged: (v) => transporte = v!,
            ),
            TextField(controller: notasController, decoration: const InputDecoration(labelText: 'Notas')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(userId).collection('trips').doc(tripId).update({
                'origen': origenController.text,
                'destino': destinoController.text,
                'transporte': transporte,
                'notas': notasController.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Viaje actualizado')));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _deleteTrip(String userId, String tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: const Text('¿Seguro que quieres eliminar este viaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('users').doc(userId).collection('trips').doc(tripId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Viaje eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((u) => u['username'] != widget.currentUsername).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final id = users[index].id;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: data['profileImage'] != null && data['profileImage'] != ''
                        ? NetworkImage(data['profileImage'])
                        : null,
                    child: data['profileImage'] == null || data['profileImage'] == ''
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(data['username'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Rol: ${data['rol']}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall!.color)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.travel_explore, color: Colors.blueAccent),
                        onPressed: () => _showUserTrips(context, id, data['username']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () =>
                            _editUser(context, id, data['username'], data['password'], data['rol']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteUser(id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
