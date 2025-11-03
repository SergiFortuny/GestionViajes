import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'admin.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? userId;
  String? userRole;
  String? profileImage;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: widget.username)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        userId = query.docs.first.id;
        userRole = data['rol'];
        profileImage = data['profileImage'];
        loading = false;
      });

      _db.collection('users').doc(userId).snapshots().listen((snapshot) {
        if (snapshot.exists) {
          final newData = snapshot.data()!;
          setState(() {
            profileImage = newData['profileImage'];
            userRole = newData['rol'];
          });
        }
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _addOrEditTrip({String? tripId, Map<String, dynamic>? existingData}) async {
    final origenController = TextEditingController(text: existingData?['origen'] ?? '');
    final destinoController = TextEditingController(text: existingData?['destino'] ?? '');
    final notasController = TextEditingController(text: existingData?['notas'] ?? '');
    final formKey = GlobalKey<FormState>();

    DateTime? fechaSalida = existingData != null ? (existingData['fecha_salida'] as Timestamp).toDate() : null;
    DateTime? fechaVuelta = existingData != null ? (existingData['fecha_vuelta'] as Timestamp).toDate() : null;
    int personas = existingData?['personas'] ?? 1;
    String transporte = existingData?['transporte'] ?? 'Avión ✈️';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(tripId == null ? '✈️ Nuevo viaje' : '✏️ Editar viaje'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: origenController,
                      decoration: const InputDecoration(labelText: 'Origen'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: destinoController,
                      decoration: const InputDecoration(labelText: 'Destino'),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Personas:', style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (personas > 1) {
                                  setStateDialog(() => personas--);
                                }
                              },
                            ),
                            Text('$personas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setStateDialog(() => personas++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: transporte,
                      decoration: const InputDecoration(labelText: 'Medio de transporte'),
                      items: const [
                        DropdownMenuItem(value: 'Avión ✈️', child: Text('Avión ✈️')),
                        DropdownMenuItem(value: 'Tren 🚄', child: Text('Tren 🚄')),
                        DropdownMenuItem(value: 'Coche 🚗', child: Text('Coche 🚗')),
                        DropdownMenuItem(value: 'Barco 🚢', child: Text('Barco 🚢')),
                        DropdownMenuItem(value: 'Autobús 🚌', child: Text('Autobús 🚌')),
                      ],
                      onChanged: (value) => setStateDialog(() => transporte = value!),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            fechaSalida == null
                                ? '📅 Fecha de salida'
                                : 'Salida: ${fechaSalida!.day}/${fechaSalida!.month}/${fechaSalida!.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: fechaSalida ?? DateTime.now(),
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
                        Expanded(
                          child: Text(
                            fechaVuelta == null
                                ? '📆 Fecha de regreso'
                                : 'Regreso: ${fechaVuelta!.day}/${fechaVuelta!.month}/${fechaVuelta!.year}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: () async {
                            final fecha = await showDatePicker(
                              context: context,
                              initialDate: fechaVuelta ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (fecha != null) setStateDialog(() => fechaVuelta = fecha);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: notasController,
                      decoration: const InputDecoration(labelText: 'Bloc de notas'),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (userId == null) return;

              final tripData = {
                'origen': origenController.text.trim(),
                'destino': destinoController.text.trim(),
                'personas': personas,
                'transporte': transporte,
                'fecha_salida': fechaSalida ?? DateTime.now(),
                'fecha_vuelta': fechaVuelta ?? DateTime.now(),
                'notas': notasController.text.trim(),
                'createdAt': existingData?['createdAt'] ?? DateTime.now(),
              };

              if (tripId == null) {
                await _db.collection('users').doc(userId).collection('trips').add(tripData);
              } else {
                await _db.collection('users').doc(userId).collection('trips').doc(tripId).update(tripData);
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTrip(String tripId) async {
    if (userId == null) return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Viajes')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(widget.username, style: const TextStyle(fontSize: 18)),
              accountEmail: Text(userRole == 'admin' ? 'Administrador' : 'Usuario'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                    ? NetworkImage(profileImage!)
                    : null,
                child: (profileImage == null || profileImage!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            if (userRole == 'user')
              ListTile(
                leading: const Icon(Icons.flight),
                title: const Text('Mis Viajes'),
                onTap: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => HomeScreen(username: widget.username)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ProfileScreen(username: widget.username)));
              },
            ),
            if (userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Panel de administración'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDashboard(currentUsername: widget.username),
                    ),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
            ),
          ],
        ),
      ),
      body: userRole == 'admin'
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '👑 Este usuario tiene permisos de administrador.\n\nPuede gestionar usuarios y sus viajes desde el panel de administración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .doc(userId)
                  .collection('trips')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final trips = snapshot.data!.docs;
                if (trips.isEmpty) return const Center(child: Text('No tienes viajes aún.'));
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
                            'Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}\nVuelta: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}\nPersonas: ${data['personas']} - ${data['transporte']}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _addOrEditTrip(tripId: trip.id, existingData: data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteTrip(trip.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton:
          userRole == 'user' ? FloatingActionButton(onPressed: _addOrEditTrip, child: const Icon(Icons.add)) : null,
    );
  }
}
