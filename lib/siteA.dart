import 'package:flutter/material.dart';
import 'package:piratef/home.dart';

class Sitea extends StatefulWidget {
  const Sitea({super.key});

  @override
  State<Sitea> createState() => _SiteaState();
}

class _SiteaState extends State<Sitea> {
  // Données fictives pour Site A
  final Map<String, String> siteInfo = {
    "status": "En marche",
    "volume": "500 L",
    "temperature": "25°C",
    "phLevel": "7.2",
    "oxygenLevel": "6.5 mg/L",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site A', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Icône de retour
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Home(userEmail: '')),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Première section (A1)
              _buildSiteSection("A1"),
              const SizedBox(height: 40), // Espace entre les sections
              // Deuxième section (A2)
              _buildSiteSection("A2"),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour construire une section du site
  Widget _buildSiteSection(String siteName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec le nom du site
        Text(
          siteName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        // Carte pour les informations générales
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informations Générales",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInfoRow("Statut", siteInfo["status"]!),
                _buildInfoRow("Volume", siteInfo["volume"]!),
                _buildInfoRow("Température", siteInfo["temperature"]!),
                _buildInfoRow("Niveau de pH", siteInfo["phLevel"]!),
                _buildInfoRow("Niveau d'oxygène", siteInfo["oxygenLevel"]!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Boutons d'action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                // Action pour démarrer/arrêter le site
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Démarrer"),
            ),
            ElevatedButton(
              onPressed: () {
                // Action pour mettre en maintenance
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Maintenance"),
            ),
            ElevatedButton(
              onPressed: () {
                // Action pour arrêter le site
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Arrêter"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Graphique (exemple)
        const Text(
          "Graphique de Performance",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              "Graphique ici",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // Fonction pour construire une ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}