import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGu8asTgTjnf_MT0-tLavAcci_jfgb6WE",
      authDomain: "login-1841d.firebaseapp.com",
      projectId: "login-1841d",
      storageBucket: "login-1841d.firebasestorage.app",
      messagingSenderId: "172533303099",
      appId: "1:172533303099:web:d8d2cd8e24fabbcd09591e",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Viajes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
