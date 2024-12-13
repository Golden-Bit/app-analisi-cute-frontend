import 'package:app_analisi_cute/pages/anagraphic_cards/anagraphic_cards.dart';
import 'package:flutter/material.dart';
import '../analysis_dashboard/analysis_dashboard.dart'; // Import della dashboard di analisi

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardSize = MediaQuery.of(context).size.width / 12; // Dimensione delle schede

    return Scaffold(
     appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black), // Testo nero
        ),
        backgroundColor: Colors.white, // Sfondo bianco
        elevation: 4, // Ombra leggera
        shadowColor: Colors.grey.withOpacity(0.4), // Colore dell'ombra
        iconTheme: const IconThemeData(color: Colors.black), // Icone nere
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Centra il gruppo di schede
          children: [
            HomeCard(
              title: 'Test Cutaneo',
              icon: Icons.medical_services,
              size: cardSize,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalysisDashboard()),
                );
              },
            ),
            const SizedBox(width: 12), // Distanza fissa tra le schede
HomeCard(
  title: 'Anagrafiche',
  icon: Icons.account_circle,
  size: cardSize,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnagrafichePage()),
    );
  },
),
            const SizedBox(width: 12), // Distanza fissa tra le schede
            HomeCard(
              title: 'Impostazioni',
              icon: Icons.settings,
              size: cardSize,
              onTap: () {
                // Navigazione da implementare
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double size; // Dimensione quadrata
  final VoidCallback onTap;

  const HomeCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.size,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4), // Padding interno
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: size / 3, color: Colors.black), // Icona proporzionata
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size / 8, // Font proporzionato alla scheda
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
