import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:piratef/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  try {
    await Firebase.initializeApp(); // Initialize Firebase
  } catch (e) {
    // Handle Firebase initialization error
    print('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Splashscreen(),
    );
  }
}