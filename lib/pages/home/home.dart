import 'package:app_analisi_cute/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:app_analisi_cute/pages/anagraphic_cards/anagraphic_cards.dart';
import '../analysis_dashboard/analysis_dashboard.dart';


class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardSize = MediaQuery.of(context).size.width / 4; // Aumenta il riquadro

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9, // Limita la larghezza del contenitore
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spaziatura uniforme
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
              HomeCard(
                title: 'Impostazioni',
                icon: Icons.settings,
                size: cardSize,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImpostazioniCentroPage()),
                  );
                },
              ),
            ],
          ),
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
          width: size, // Dimensione del riquadro aumentata
          height: size,
          padding: const EdgeInsets.all(8), // Ridotto il padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: size / 2.5, color: Colors.black), // Icona ingrandita
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size / 10, // Font proporzionato al riquadro
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
