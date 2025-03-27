import 'package:flutter/material.dart';
import 'package:piratef/LoginScreen.dart';
import 'package:piratef/siteA.dart';
import 'package:piratef/siteb.dart';
import 'package:piratef/sitec.dart';

class Home extends StatefulWidget {
  final String userEmail; // Ajoutez un champ pour l'email

  const Home({super.key, required this.userEmail}); // Constructeur

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartAquaFarm', style: TextStyle(color: Colors.white)),
        backgroundColor:  const Color(0xFF2D5AF7), // Couleur de l'app bar
        elevation: 0, // Supprime l'ombre de l'app bar
      ),
      // Ajout du Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero, // Supprime le padding par défaut
          children: [
            // En-tête du Drawer (avec image de fond et informations utilisateur)
            DrawerHeader(
              decoration: const BoxDecoration(
               color: const Color(0xFF2D5AF7) // Couleur de fond de l'en-tête
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Email de l'utilisateur (affiché dynamiquement)
                  Text(
                    widget.userEmail, // Utilisez l'email passé au constructeur
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Options du Drawer
            ListTile(
              leading: const Icon(Icons.dashboard,color: const Color(0xFF2D5AF7)), // Icône
              title: const Text('Tableau de Bord'),
              onTap: () {
                // Naviguer vers la page du tableau de bord
                Navigator.pop(context); // Ferme le Drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: const Color(0xFF2D5AF7)), // Icône
              title: const Text('Paramètres'),
              onTap: () {
                // Naviguer vers la page des paramètres
                Navigator.pop(context); // Ferme le Drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: const Color(0xFF2D5AF7)), // Icône
              title: const Text('Aide'),
              onTap: () {
                // Naviguer vers la page d'aide
                Navigator.pop(context); // Ferme le Drawer
              },
            ),
            const Divider(), // Séparateur
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red), // Icône
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Déconnexion et retour à la page de connexion
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Boutons pour les fonctionnalités principales
           
              
            const SizedBox(height: 40),
            // Cartes pour les sites
            Expanded(
              child: ListView(
                children: [
                  // Carte pour Site A
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Site A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Description du Site A'),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: const Color(0xFF2D5AF7)),
                        onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Sitea()),
                    );
                  },
                      ),
                    ),
                  ),
                  // Carte pour Site B
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Site B', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Description du Site B'),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward, color:  Color(0xFF2D5AF7)),
                        onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const siteb()),
                    );
                  },
                      ),
                    ),
                  ),
                  // Carte pour Site C
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: const Text('Site C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Description du Site C'),
                      trailing: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: const Color(0xFF2D5AF7)),
                        onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const sitec()),
                    );
                  },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}