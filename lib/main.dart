import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:piratefish/SplashScreen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyApRbFEAUb9bBvC83o4-b_-H-AJgJtSIkU",
    authDomain: "piratefish-1ea25.firebaseapp.com",
    projectId: "piratefish-1ea25",
    storageBucket: "piratefish-1ea25.firebasestorage.app",
    messagingSenderId: "226030086996",
    appId: "1:226030086996:web:2ec584ffa79e3305cd76c1",
    measurementId: "G-0Q1152L4QV",
  );

  try {
    if (kIsWeb) {
      if (Firebase.apps.isNotEmpty) {
        final currentId = Firebase.app().options.projectId;
        debugPrint("Current Firebase projectId in memory: $currentId");
        if (currentId != firebaseOptions.projectId) {
          debugPrint("Switching from $currentId to ${firebaseOptions.projectId}...");
          await Firebase.app().delete();
          await Firebase.initializeApp(options: firebaseOptions);
        }
      } else {
        await Firebase.initializeApp(options: firebaseOptions);
      }
      debugPrint("Firebase successfully initialized with: ${Firebase.app().options.projectId}");
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint("Firebase init: $e");
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