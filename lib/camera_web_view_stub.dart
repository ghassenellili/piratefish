import 'package:flutter/material.dart';

Widget buildPcCameraView({
  required double width,
  required double height,
  required VoidCallback onError,
  required VoidCallback onReady,
}) {
  return Container(
    color: const Color(0xFF061A33),
    child: const Center(
      child: Text(
        "Caméra PC disponible sur navigateur Chrome",
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
