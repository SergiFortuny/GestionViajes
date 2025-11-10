/// 📘 Pantalla de perfil - Corregido error "undefined LatLng"
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final imageController = TextEditingController();

  bool loading = true;
  bool _obscurePassword = true;
  bool _loadingLocation = false;
  String? userId;
  Map<String, dynamic>? userData;

  // 🔹 Mapa controller para controlar el mapa
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 Cargar datos del usuario desde Firebase
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
      emailController.text = userData!['email'] ?? '';
      phoneController.text = userData!['phone'] ?? '';
      imageController.text = userData!['profileImage'] ?? '';
      locationController.text = userData!['locationAddress'] ?? '';
    }
    setState(() => loading = false);
  }

  // 🔹 Geocoding inverso: convertir coordenadas a dirección
  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;
        return address ?? 'Ubicación seleccionada';
      }
    } catch (e) {
      print('Error en geocoding: $e');
    }
    
    return 'Ubicación seleccionada en el mapa';
  }

  // 🔹 Geocoding directo: convertir dirección a coordenadas
  Future<LatLng?> _getLatLngFromAddress(String address) async {
    if (address.isEmpty) return null;
    
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final firstResult = data[0];
          return LatLng(
            double.parse(firstResult['lat']),
            double.parse(firstResult['lon']),
          );
        }
      }
    } catch (e) {
      print('Error en geocoding directo: $e');
    }
    return null;
  }

  // 🔹 Validación de email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El email es obligatorio';
    final emailRegex = RegExp(r'^[\w-\.]+@[a-zA-Z]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Ingresa un email válido';
    return null;
  }

  // 🔹 Validación de teléfono
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'El teléfono es obligatorio';
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    if (!phoneRegex.hasMatch(value)) return 'Ingresa un teléfono válido';
    return null;
  }

  // 🔹 Validación de ubicación
  String? _validateLocation(String? value) {
    if (value == null || value.isEmpty) return 'La ubicación es obligatoria';
    return null;
  }

  // 🔹 Versión SIMPLIFICADA del mapa (alternativa)
  void _showSimpleLocationMap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Selecciona tu ubicación', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(40.4168, -3.7038), // ✅ Coordenadas fijas
              initialZoom: 12.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, latLng) async {
                // ✅ Obtener dirección directamente
                final address = await _getAddressFromLatLng(latLng);
                locationController.text = address;
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ubicación seleccionada ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.gestion_viajes',
              ),
              // ✅ Marcador fijo en el centro inicial
              MarkerLayer(
                markers: [
                  Marker(
                    point: const LatLng(40.4168, -3.7038),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  // 🔹 Buscar ubicación por dirección
  void _searchLocation() async {
    if (locationController.text.isEmpty) return;

    setState(() => _loadingLocation = true);

    try {
      final latLng = await _getLatLngFromAddress(locationController.text);
      if (latLng != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dirección válida ✅'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo encontrar la dirección ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar dirección: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  // 🔹 Guardar cambios en Firestore - SOLO TEXTO
  Future<void> _saveChanges() async {
    if (userId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final updateData = {
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'profileImage': imageController.text.trim(),
      'locationAddress': locationController.text.trim(),
      'updatedAt': DateTime.now(),
    };

    await _db.collection('users').doc(userId).update(updateData);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambios guardados correctamente 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil de usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: (imageController.text.isNotEmpty)
                    ? NetworkImage(imageController.text)
                    : null,
                child: (imageController.text.isEmpty)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              const SizedBox(height: 20),

              // Campos del formulario
              _buildTextField(imageController, 'URL de imagen de perfil', false),
              const SizedBox(height: 16),
              _buildTextField(emailController, 'Email', false, 
                  keyboardType: TextInputType.emailAddress, validator: _validateEmail),
              const SizedBox(height: 16),
              _buildTextField(phoneController, 'Teléfono', false, 
                  keyboardType: TextInputType.phone, validator: _validatePhone),
              const SizedBox(height: 16),
              _buildTextField(usernameController, 'Nombre de usuario', false, 
                  validator: (v) => v!.isEmpty ? 'Obligatorio' : null),
              const SizedBox(height: 16),
              
              // Campo de contraseña
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'La contraseña es obligatoria' : null,
              ),
              const SizedBox(height: 16),

              // 🔹 Campo de ubicación
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        hintText: 'Escribe tu dirección o usa el mapa',
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: _validateLocation,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _loadingLocation
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: _searchLocation,
                          tooltip: 'Validar dirección',
                        ),
                ],
              ),
              const SizedBox(height: 8),

              // 🔹 Botón para seleccionar en mapa (usa la versión simple)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showSimpleLocationMap, // ✅ Usar versión simple
                  icon: const Icon(Icons.map),
                  label: const Text('Seleccionar ubicación en el mapa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Botón para guardar
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método auxiliar para construir TextFields
  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    bool obscureText, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    imageController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
