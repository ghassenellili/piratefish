import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:piratefish/SplashScreen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyC0XWaT7W-snY9bHh3TcnODhjfLUwPaGeY",
          authDomain: "pfish-f02dd.firebaseapp.com",
          projectId: "pfish-f02dd",
          storageBucket: "pfish-f02dd.appspot.com",
          messagingSenderId: "374866452282",
          appId: "1:374866452282:web:0ab3de985a05c5db757a03",
          measurementId: "G-ZMYRBY5X22"
      ),
    );
  } else {
    await Firebase.initializeApp();
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