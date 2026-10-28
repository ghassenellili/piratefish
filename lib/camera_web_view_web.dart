// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class PcCameraWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final VoidCallback? onReady;
  final Function(String)? onError;

  const PcCameraWidget({
    super.key,
    this.width,
    this.height,
    this.onReady,
    this.onError,
  });

  @override
  State<PcCameraWidget> createState() => _PcCameraWidgetState();
}

class _PcCameraWidgetState extends State<PcCameraWidget> {
  late String _viewId;
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _viewId = 'pc-webcam-${DateTime.now().millisecondsSinceEpoch}';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception("Périphérique média non supporté par ce navigateur.");
      }

      final stream = await mediaDevices.getUserMedia({'video': true, 'audio': false});
      _mediaStream = stream;

      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..srcObject = stream;

      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _videoElement!,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onReady?.call();
      }
    } catch (e) {
      debugPrint("PC Webcam error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().contains('NotAllowedError') || e.toString().contains('Permission')
              ? "Accès à la caméra refusé. Cliquez sur l'icône de caméra dans la barre d'adresse Chrome pour autoriser."
              : "Impossible d'accéder à la caméra du PC : $e";
        });
        widget.onError?.call(_errorMessage!);
      }
    }
  }

  @override
  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement?.srcObject = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF041426),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF00E5FF)),
              SizedBox(height: 12),
              Text(
                "Connexion à la caméra de votre PC...",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: const Color(0xFF061A33),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Color(0xFFFF5252), size: 40),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initCamera();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Autoriser et Réessayer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B0FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return HtmlElementView(viewType: _viewId);
  }
}

Widget buildPcCameraView({
  required double width,
  required double height,
  required VoidCallback onError,
  required VoidCallback onReady,
}) {
  return PcCameraWidget(
    width: width,
    height: height,
    onReady: onReady,
    onError: (_) => onError(),
  );
}
