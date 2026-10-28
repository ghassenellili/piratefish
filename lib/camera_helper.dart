import 'package:flutter/material.dart';
import 'camera_web_view_stub.dart'
    if (dart.library.html) 'camera_web_view_web.dart';

Widget getPcCameraView({
  required double width,
  required double height,
  required VoidCallback onError,
  required VoidCallback onReady,
}) {
  return buildPcCameraView(
    width: width,
    height: height,
    onError: onError,
    onReady: onReady,
  );
}
