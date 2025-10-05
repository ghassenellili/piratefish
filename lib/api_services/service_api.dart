import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://172.20.10.2:5000/api'; 
  final Duration timeout = const Duration(seconds: 5);
  final int maxRetries = 3;

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup(
        Uri.parse(baseUrl).host,
      ).timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReadings() async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        if (!await checkConnection()) {
          throw Exception('Vérifiez votre connexion au réseau local');
        }

        // Try the new endpoint first
        final response = await http.get(
          Uri.parse('$baseUrl/sensor-data'),
          headers: {'Accept': 'application/json'},
        ).timeout(timeout);
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          return [
            {
              'day': 6,
              'temperature': data['temperature'] ?? 25.0,
              'ph': data['ph'] ?? 7.0,
              'oxygen': data['oxygen'] ?? 6.5,
              'timestamp': DateTime.now().toIso8601String(),
            }
          ];
        } else {
          // Fallback to the old endpoint
          final fallbackResponse = await http.get(
            Uri.parse('$baseUrl/readings/latest?site_id=1&section_name=A1'),
            headers: {'Accept': 'application/json'},
          ).timeout(timeout);
          
          if (fallbackResponse.statusCode == 200) {
            final data = json.decode(fallbackResponse.body);
            return [
              {
                'day': 6,
                'temperature': data['temperature'] ?? 25.0,
                'ph': data['ph'] ?? 7.0,
                'oxygen': data['oxygen'] ?? 6.5,
                'timestamp': DateTime.now().toIso8601String(),
              }
            ];
          }
          throw Exception('Erreur serveur: ${fallbackResponse.statusCode}');
        }
      } on SocketException catch (_) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Impossible de se connecter au serveur. Vérifiez que:\n'
              '1. Le serveur est en marche\n'
              '2. Vous êtes sur le même réseau WiFi\n'
              '3. L\'adresse IP du serveur est correcte');
        }
        await Future.delayed(Duration(seconds: attempts));
        continue;
      } on TimeoutException catch (_) {
        attempts++;
        if (attempts >= maxRetries) {
          throw Exception('Le serveur ne répond pas');
        }
        await Future.delayed(Duration(seconds: attempts));
        continue;
      } catch (e) {
        throw Exception('Erreur: $e');
      }
    }
    throw Exception('Échec de la connexion après $maxRetries tentatives');
  }
}
