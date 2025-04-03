import 'package:flutter/material.dart';
import 'package:piratef/LoginScreen.dart';
import 'package:piratef/siteA.dart';
import 'package:piratef/siteb.dart';
import 'package:piratef/sitec.dart';

class Home extends StatefulWidget {
  final String userEmail;

  const Home({super.key, required this.userEmail});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'SmartAquaFarm', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          )
        ),
        backgroundColor: const Color(0xFF2D5AF7),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Action pour les notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Action pour l'aide
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // En-tête du Drawer avec logo et infos utilisateur
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF2D5AF7),
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF2D5AF7)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Compte utilisateur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userEmail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard, color: Color(0xFF2D5AF7)),
                    title: const Text('Tableau de Bord', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.analytics_outlined, color: Color(0xFF2D5AF7)),
                    title: const Text('Analyses', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Color(0xFF2D5AF7)),
                    title: const Text('Historique', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Color(0xFF2D5AF7)),
                    title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.support_agent, color: Color(0xFF2D5AF7)),
                    title: const Text('Support technique', style: TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Section déconnexion en bas du drawer
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la page
            const Text(
              'Tableau de bord',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Surveillez et gérez vos installations aquacoles',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
            
            // Indicateurs de performance
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Sites actifs', 
                    '2/3', 
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'Maintenance', 
                    '1', 
                    Icons.engineering,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    'Alertes', 
                    '0', 
                    Icons.warning_amber,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Titre de la section sites
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes installations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D5AF7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Liste des sites
            Expanded(
              child: ListView(
                children: [
                  _buildSiteCard(
                    'Site A', 
                    'En fonctionnement', 
                    'Dernière mise à jour: aujourd\'hui, 09:45',
                    Icons.check_circle,
                    Colors.green,
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Sitea(userEmail: widget.userEmail)),
                      );
                    },
                  ),
                  _buildSiteCard(
                    'Site B', 
                    'En maintenance', 
                    'Dernière mise à jour: hier, 15:30',
                    Icons.engineering,
                    Colors.orange,
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Siteb(userEmail: widget.userEmail)),
                      );
                    },
                  ),
                  _buildSiteCard(
                    'Site C', 
                    'En fonctionnement', 
                    'Dernière mise à jour: aujourd\'hui, 08:15',
                    Icons.check_circle,
                    Colors.green,
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => sitec(userEmail: widget.userEmail)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D5AF7),
        onPressed: () {
          // Action pour ajouter un nouveau site
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Widget pour les cartes de statut
  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Widget pour les cartes de site
  Widget _buildSiteCard(String title, String status, String lastUpdate, IconData icon, Color color, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastUpdate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF2D5AF7), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
