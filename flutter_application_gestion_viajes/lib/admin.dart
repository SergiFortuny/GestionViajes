import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';

class AdminDashboard extends StatefulWidget {
  final String currentUsername;
  const AdminDashboard({super.key, required this.currentUsername});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _viewUserTrips(String userId, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserTripsScreen(userId: userId, username: username),
      ),
    );
  }

  void _viewUserProfile(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(username: username)),
    );
  }

  Future<void> _deleteUser(String userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que quieres eliminar al usuario "$username"?\n\nEsta acción eliminará también todos sus viajes y no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Eliminar subcolección de viajes
      final trips = await _db.collection('users').doc(userId).collection('trips').get();
      for (var trip in trips.docs) {
        await _db.collection('users').doc(userId).collection('trips').doc(trip.id).delete();
      }

      // Eliminar usuario
      await _db.collection('users').doc(userId).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario "$username" eliminado correctamente'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where((u) {
            final data = u.data() as Map<String, dynamic>;
            return data['username'] != widget.currentUsername;
          });

          if (users.isEmpty) {
            return const Center(child: Text('No hay otros usuarios registrados.'));
          }

          final admins = users.where((u) => (u.data() as Map<String, dynamic>)['rol'] == 'admin');
          final normales = users.where((u) => (u.data() as Map<String, dynamic>)['rol'] == 'user');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (admins.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Text('🛡️ Administradores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text('👤 Usuarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...normales.map((u) => _buildUserCard(u)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(QueryDocumentSnapshot u) {
    final data = u.data() as Map<String, dynamic>;
    final userId = u.id;
    final rol = data['rol'] ?? 'user';
    final username = data['username'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (data['profileImage'] != null && data['profileImage'] != '')
              ? NetworkImage(data['profileImage'])
              : null,
          child: (data['profileImage'] == null || data['profileImage'] == '')
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(username),
        subtitle: Text('Rol: $rol'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_search, color: Colors.indigo),
              tooltip: 'Ver perfil',
              onPressed: () => _viewUserProfile(username),
            ),
            if (rol == 'user')
              IconButton(
                icon: const Icon(Icons.flight, color: Colors.green),
                tooltip: 'Ver viajes',
                onPressed: () => _viewUserTrips(userId, username),
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Eliminar usuario',
              onPressed: () => _deleteUser(userId, username),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTripsScreen extends StatefulWidget {
  final String userId;
  final String username;
  const UserTripsScreen({super.key, required this.userId, required this.username});

  @override
  State<UserTripsScreen> createState() => _UserTripsScreenState();
}

class _UserTripsScreenState extends State<UserTripsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _editTrip(String tripId, Map<String, dynamic> data) async {
    final origenController = TextEditingController(text: data['origen']);
    final destinoController = TextEditingController(text: data['destino']);
    final personasController = TextEditingController(text: data['personas'].toString());
    final transporteController = TextEditingController(text: data['transporte']);
    final notasController = TextEditingController(text: data['notas']);
    DateTime fechaSalida = (data['fecha_salida'] as Timestamp).toDate();
    DateTime fechaVuelta = (data['fecha_vuelta'] as Timestamp).toDate();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar viaje de ${widget.username}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: origenController, decoration: const InputDecoration(labelText: 'Origen')),
              TextField(controller: destinoController, decoration: const InputDecoration(labelText: 'Destino')),
              TextField(controller: personasController, decoration: const InputDecoration(labelText: 'Personas'), keyboardType: TextInputType.number),
              TextField(controller: transporteController, decoration: const InputDecoration(labelText: 'Transporte')),
              TextField(controller: notasController, decoration: const InputDecoration(labelText: 'Notas'), maxLines: 3),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text('Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}')),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final nuevaFecha = await showDatePicker(
                        context: context,
                        initialDate: fechaSalida,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (nuevaFecha != null) setState(() => fechaSalida = nuevaFecha);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('Regreso: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}')),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () async {
                      final nuevaFecha = await showDatePicker(
                        context: context,
                        initialDate: fechaVuelta,
                        firstDate: fechaSalida,
                        lastDate: DateTime(2100),
                      );
                      if (nuevaFecha != null) setState(() => fechaVuelta = nuevaFecha);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () async {
                await _db.collection('users').doc(widget.userId).collection('trips').doc(tripId).update({
                  'origen': origenController.text.trim(),
                  'destino': destinoController.text.trim(),
                  'personas': int.tryParse(personasController.text.trim()) ?? 1,
                  'transporte': transporteController.text.trim(),
                  'notas': notasController.text.trim(),
                  'fecha_salida': fechaSalida,
                  'fecha_vuelta': fechaVuelta,
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar cambios')),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(String tripId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: const Text('¿Seguro que deseas eliminar este viaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('users').doc(widget.userId).collection('trips').doc(tripId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Viajes de ${widget.username}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('users')
            .doc(widget.userId)
            .collection('trips')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final trips = snapshot.data!.docs;
          if (trips.isEmpty) return const Center(child: Text('Este usuario no tiene viajes.'));
          return ListView.builder(
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final data = trip.data() as Map<String, dynamic>;
              final fechaSalida = (data['fecha_salida'] as Timestamp).toDate();
              final fechaVuelta = (data['fecha_vuelta'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.flight_takeoff, color: Colors.blue),
                  title: Text('${data['origen']} → ${data['destino']}'),
                  subtitle: Text(
                    'Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}\n'
                    'Regreso: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}\n'
                    'Personas: ${data['personas']} - ${data['transporte']}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editTrip(trip.id, data)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTrip(trip.id)),
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
