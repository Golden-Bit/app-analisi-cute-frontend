import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/anagraphic_cards/components/anagraphic_card_viewer.dart';

class HoverableCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Anagrafica anagrafica; // Oggetto completo dell'anagrafica

  const HoverableCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.anagrafica,
  }) : super(key: key);

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2), // Imposta il border radius a 2
        ),
        child: ListTile(
          title: Text(widget.title),
          subtitle: Text(widget.subtitle),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz,
              color: _isHovered ? Colors.black : Colors.grey[300],
            ),
            onSelected: (String value) {
              if (value == 'Visualizza') {
                showDialog(
                  context: context,
                  builder: (context) => AnagraficaView(anagrafica: widget.anagrafica),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Visualizza',
                child: Text('Visualizza'),
              ),
              const PopupMenuItem<String>(
                value: 'Modifica',
                child: Text('Modifica'),
              ),
              const PopupMenuItem<String>(
                value: 'Elimina',
                child: Text('Elimina'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnagrafichePage extends StatefulWidget {
  const AnagrafichePage({Key? key}) : super(key: key);

  @override
  State<AnagrafichePage> createState() => _AnagrafichePageState();
}

class _AnagrafichePageState extends State<AnagrafichePage> {
  final AnagraficaApi _api = AnagraficaApi();
  List<Anagrafica> _anagrafiche = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnagrafiche();
  }

  Future<void> _fetchAnagrafiche() async {
    try {
      final anagrafiche = await _api.getAnagrafiche();
      setState(() {
        _anagrafiche = anagrafiche;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento delle anagrafiche: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestione Anagrafiche',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
                elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Barra di ricerca con filtri
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Campo di testo per la ricerca
                // Campo di testo per la ricerca
Expanded(
  flex: 3,
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Cerca anagrafica...',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2), // Border radius ridotto a 2
      ),
      prefixIcon: const Icon(Icons.search),
    ),
  ),
),
                const SizedBox(width: 8),
                // Pulsante per i filtri
                // Pulsante per i filtri
ElevatedButton.icon(
  onPressed: () {
    // Per ora, non implementa alcuna logica
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2), // Border radius ridotto a 2
    ),
  ),
  icon: const Icon(Icons.filter_list, color: Colors.white),
  label: const Text(
    'Filtri',
    style: TextStyle(color: Colors.white),
  ),
),

              ],
            ),
          ),
          const SizedBox(width: 8),
          // Contenuto principale
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _anagrafiche.length,
                    itemBuilder: (context, index) {
                      final anagrafica = _anagrafiche[index];
                      return HoverableCard(
                        title: '${anagrafica.nome} ${anagrafica.cognome}',
                        subtitle: 'ID: ${anagrafica.id}',
                        anagrafica: anagrafica,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
