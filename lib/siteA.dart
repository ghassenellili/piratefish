import 'package:flutter/material.dart';
import 'package:piratef/home.dart';
import 'package:fl_chart/fl_chart.dart'; // Pour les graphiques professionnels

class Sitea extends StatefulWidget {
  final String userEmail;
  
  const Sitea({super.key, required this.userEmail});

  @override
  State<Sitea> createState() => _SiteaState();
}

class _SiteaState extends State<Sitea> {
  // Données fictives pour Site A
  final Map<String, Map<String, dynamic>> siteSections = {
    "A1": {
      "status": "En marche",
      "volume": "500 L",
      "temperature": "25°C",
      "phLevel": "7.2",
      "oxygenLevel": "6.5 mg/L",
      "isActive": true,
    },
    "A2": {
      "status": "En maintenance",
      "volume": "350 L",
      "temperature": "23°C",
      "phLevel": "6.8",
      "oxygenLevel": "5.9 mg/L",
      "isActive": false,
    }
  };

  // Données pour les graphiques
  final List<FlSpot> temperatureData = [
    FlSpot(0, 22),
    FlSpot(1, 23),
    FlSpot(2, 25),
    FlSpot(3, 24.5),
    FlSpot(4, 25),
    FlSpot(5, 25.5),
    FlSpot(6, 25),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring - Site A', style: TextStyle(fontWeight: FontWeight.w600)),
       backgroundColor: const Color(0xFF2D5AF7),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home(userEmail: widget.userEmail)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Rafraîchir les données
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données actualisées')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Afficher les notifications
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(),
                const SizedBox(height: 20),
                ...siteSections.entries.map((entry) => _buildSiteSection(entry.key, entry.value)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Carte d'aperçu général
  Widget _buildOverviewCard() {
    int activeSections = siteSections.values.where((section) => section["isActive"] == true).length;
    int totalSections = siteSections.length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Vue d'ensemble",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$activeSections/$totalSections actifs",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildOverviewStat(Icons.thermostat, "Température", "24°C", Colors.orange),
                _buildOverviewStat(Icons.opacity, "pH moyen", "7.0", Colors.blue),
                _buildOverviewStat(Icons.bubble_chart, "O₂ moyen", "6.2 mg/L", Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Statistique pour la carte d'aperçu
  Widget _buildOverviewStat(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Section de site améliorée
  Widget _buildSiteSection(String siteName, Map<String, dynamic> siteData) {
    Color statusColor = siteData["isActive"] ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    String statusText = siteData["isActive"] ? "Actif" : "Inactif";

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                " $siteName",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Carte des informations
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Paramètres en temps réel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow("Volume", siteData["volume"], Icons.water_drop),
                  _buildInfoRow("Température", siteData["temperature"], Icons.thermostat),
                  _buildInfoRow("Niveau de pH", siteData["phLevel"], Icons.science),
                  _buildInfoRow("Niveau d'oxygène", siteData["oxygenLevel"], Icons.air),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Graphique
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Évolution sur 7 jours",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: "Température",
                        items: const [
                          DropdownMenuItem(value: "Température", child: Text("Température")),
                          DropdownMenuItem(value: "pH", child: Text("pH")),
                          DropdownMenuItem(value: "Oxygène", child: Text("Oxygène")),
                        ],
                        onChanged: (value) {
                          // Changer le graphique
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.only(right: 16.0, top: 16.0),
                    child: _buildLineChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Action pour démarrer/arrêter
                  },
                  icon: Icon(siteData["isActive"] ? Icons.stop : Icons.play_arrow),
                  label: Text(siteData["isActive"] ? "Arrêter" : "Démarrer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: siteData["isActive"] ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Action pour maintenance
                  },
                  icon: const Icon(Icons.build),
                  label: const Text("Maintenance"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39C12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ligne d'information améliorée
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF3498DB)),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Graphique linéaire
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                int index = value.toInt();
                if (index >= 0 && index < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[index], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 20,
        maxY: 28,
        lineBarsData: [
          LineChartBarData(
            spots: temperatureData,
            isCurved: true,
            color: const Color(0xFF3498DB),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3498DB).withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
