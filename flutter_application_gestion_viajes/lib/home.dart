/// 📘 Descripción del archivo:
/// Pantalla principal (HomeScreen) de la aplicación "Gestión de Viajes".
///
/// 🔹 Funcionalidades principales:
/// - Los usuarios pueden:
///   → Ver, añadir, editar y eliminar sus viajes.  
///   → Gestionar detalles (origen, destino, fechas, transporte, notas).
/// - Los administradores pueden:
///   → Acceder al panel de administración desde el menú lateral.
/// - Drawer con acceso al perfil, panel admin y cierre de sesión.
/// - Sincronización en tiempo real con Firebase.
///
/// 🔹 Estilo visual:
/// - Tema JetBlack constante (oscuro por defecto, sin alternar).  
/// - Bordes definidos, sombras suaves y transiciones fluidas.

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

      // 🔁 Escucha en tiempo real de cambios del usuario
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

  /// ✏️ Añadir o editar viaje
  Future<void> _addOrEditTrip({String? tripId, Map<String, dynamic>? existingData}) async {
    final origenController = TextEditingController(text: existingData?['origen'] ?? '');
    final destinoController = TextEditingController(text: existingData?['destino'] ?? '');
    final notasController = TextEditingController(text: existingData?['notas'] ?? '');
    final formKey = GlobalKey<FormState>();

    DateTime? fechaSalida =
        existingData != null ? (existingData['fecha_salida'] as Timestamp).toDate() : null;
    DateTime? fechaVuelta =
        existingData != null ? (existingData['fecha_vuelta'] as Timestamp).toDate() : null;
    int personas = existingData?['personas'] ?? 1;
    String transporte = existingData?['transporte'] ?? 'Avión ✈️';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(tripId == null ? '✈️ Nuevo viaje' : '✏️ Editar viaje',
            style: const TextStyle(color: Colors.white)),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Origen'),
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: destinoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Destino'),
                      validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Personas:', style: TextStyle(color: Colors.white)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                              onPressed: () {
                                if (personas > 1) setStateDialog(() => personas--);
                              },
                            ),
                            Text('$personas',
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                              onPressed: () => setStateDialog(() => personas++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: transporte,
                      dropdownColor: Colors.grey[850],
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Medio de transporte'),
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
                            fechaSalida != null
                                ? '📅 Salida: ${fechaSalida?.day}/${fechaSalida?.month}/${fechaSalida?.year}'
                                : '📅 Fecha de salida',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today, color: Colors.white),
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
                            fechaVuelta != null
                                ? '📆 Regreso: ${fechaVuelta?.day}/${fechaVuelta?.month}/${fechaVuelta?.year}'
                                : '📆 Fecha de regreso',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Bloc de notas'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  Future<void> _deleteTrip(String tripId) async {
    if (userId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Eliminar viaje', style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que quieres eliminar este viaje?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        title: const Text('Gestión de Viajes'),
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey[900],
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
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
                leading: const Icon(Icons.flight, color: Colors.white),
                title: const Text('Mis Viajes', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => HomeScreen(username: widget.username))),
              ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Perfil', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ProfileScreen(username: widget.username))),
            ),
            if (userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
                title: const Text('Panel de administración', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminDashboard(currentUsername: widget.username),
                  ),
                ),
              ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
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
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
                if (trips.isEmpty) {
                  return const Center(
                      child: Text('No tienes viajes aún.', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final data = trip.data() as Map<String, dynamic>;
                    final fechaSalida = (data['fecha_salida'] as Timestamp).toDate();
                    final fechaVuelta = (data['fecha_vuelta'] as Timestamp).toDate();

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade800),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading:
                            const Icon(Icons.flight_takeoff, color: Colors.blueAccent, size: 28),
                        title: Text('${data['origen']} → ${data['destino']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Salida: ${fechaSalida.day}/${fechaSalida.month}/${fechaSalida.year}\n'
                          'Vuelta: ${fechaVuelta.day}/${fechaVuelta.month}/${fechaVuelta.year}\n'
                          'Personas: ${data['personas']} - ${data['transporte']}',
                          style: const TextStyle(color: Colors.white70, height: 1.3),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
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
      floatingActionButton: userRole == 'user'
          ? FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: _addOrEditTrip,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
