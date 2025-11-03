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
        content: const Text('¿Seguro que quieres eliminar este usuario? Se borrarán también sus viajes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Eliminar usuario y subcolección de viajes
      final trips = await _db.collection('users').doc(id).collection('trips').get();
      for (var doc in trips.docs) {
        await doc.reference.delete();
      }
      await _db.collection('users').doc(id).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Usuario eliminado correctamente')));
    }
  }

  void _editUser(BuildContext context, String id, String username, String password, String rol) {
    final usernameController = TextEditingController(text: username);
    final passwordController = TextEditingController(text: password);
    String selectedRole = rol;
    bool _obscurePassword = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Editar usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              const SizedBox(height: 10),
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
                      setStateDialog(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('Usuario')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (value) => setStateDialog(() => selectedRole = value!),
                decoration: const InputDecoration(labelText: 'Rol'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario actualizado correctamente ✅')));
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewUserTrips(String userId, String username) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 500,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Viajes de $username'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close))
              ],
            ),
            body: StreamBuilder<QuerySnapshot>(
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
                  return const Center(child: Text('Este usuario no tiene viajes.'));
                }

                return ListView.builder(
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final data = trip.data() as Map<String, dynamic>;
                    final fechaSalida = (data['fecha_salida'] as Timestamp).toDate();
                    final fechaVuelta = (data['fecha_vuelta'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTrip(userId, trip.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteTrip(userId, trip.id),
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
        ),
      ),
    );
  }

  void _editTrip(String userId, String tripId, Map<String, dynamic> existingData) async {
    final origenController = TextEditingController(text: existingData['origen']);
    final destinoController = TextEditingController(text: existingData['destino']);
    final notasController = TextEditingController(text: existingData['notas']);
    DateTime fechaSalida = (existingData['fecha_salida'] as Timestamp).toDate();
    DateTime fechaVuelta = (existingData['fecha_vuelta'] as Timestamp).toDate();
    int personas = existingData['personas'];
    String transporte = existingData['transporte'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar viaje'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: origenController,
                  decoration: const InputDecoration(labelText: 'Origen'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: destinoController,
                  decoration: const InputDecoration(labelText: 'Destino'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Personas:'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (personas > 1) setStateDialog(() => personas--);
                          },
                        ),
                        Text('$personas', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setStateDialog(() => personas++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                  onChanged: (value) => setStateDialog(() => transporte = value!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text('Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}')),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaSalida,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) setStateDialog(() => fechaSalida = fecha);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('Regreso: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}')),
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaVuelta,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) setStateDialog(() => fechaVuelta = fecha);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notasController,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(userId).collection('trips').doc(tripId).update({
                'origen': origenController.text.trim(),
                'destino': destinoController.text.trim(),
                'personas': personas,
                'transporte': transporte,
                'fecha_salida': fechaSalida,
                'fecha_vuelta': fechaVuelta,
                'notas': notasController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Viaje actualizado correctamente ✅')));
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
          .showSnackBar(const SnackBar(content: Text('Viaje eliminado correctamente')));
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
          final users = snapshot.data!.docs.where((u) => u['username'] != widget.currentUsername).toList();

          if (users.isEmpty) return const Center(child: Text('No hay otros usuarios registrados.'));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['profileImage'] != null && data['profileImage'].isNotEmpty
                        ? NetworkImage(data['profileImage'])
                        : null,
                    child: (data['profileImage'] == null || data['profileImage'].isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(data['username']),
                  subtitle: Text('Rol: ${data['rol']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          tooltip: 'Ver viajes',
                          onPressed: () => _viewUserTrips(user.id, data['username'])),
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          tooltip: 'Editar usuario',
                          onPressed: () =>
                              _editUser(context, user.id, data['username'], data['password'], data['rol'])),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Eliminar usuario',
                          onPressed: () => _deleteUser(user.id)),
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
