import 'dart:async';
import 'package:flutter/material.dart';
import 'package:piratef/LoginScreen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  _SplashscreenState createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255), // Couleur de fond unie
          // Ou utilisez un dégradé :
          /*gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.lightBlue,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),*/
        ),
        child: Center(
          child: SizedBox(
            width: 200, // Définit la largeur de l'image
            height: 200, // Définit la hauteur de l'image
            child: Image.asset(
              'images/logo.png',
              fit: BoxFit.contain, // Assure que l'image garde son aspect ratio tout en restant contenue dans les dimensions
            ),
          ),
        ),
      ),
    );
  }
}