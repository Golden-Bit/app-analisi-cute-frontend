import 'package:app_analisi_cute/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:app_analisi_cute/pages/anagraphic_cards/anagraphic_cards.dart';
import '../analysis_dashboard/analysis_dashboard.dart';

class HomePage extends StatelessWidget {
  final String username;
  final String password;

  const HomePage({Key? key, required this.username, required this.password})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double cardSize = MediaQuery.of(context).size.width / 4;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.black),
        title: Stack(
          children: [
            // Titolo posizionato a sinistra
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  'Home',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Logo centrato
            Align(
              alignment: Alignment.center,
              child: Image.network(
                'https://static.wixstatic.com/media/63b1fb_f4b32483fdcb4f39a1e294a497dd452a~mv2.png',
                height: 40,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white, // Sfondo bianco
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                HomeCard(
                  title: 'Test Cutaneo',
                  icon: Icons.medical_services,
                  size: cardSize,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AnalysisDashboard(username: username, password: password),
                      ),
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
                      MaterialPageRoute(
                        builder: (context) =>
                            AnagrafichePage(username: username, password: password),
                      ),
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
                      MaterialPageRoute(
                        builder: (context) => ImpostazioniCentroPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double size;
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
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: size / 2.5, color: Colors.black),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size / 10,
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
