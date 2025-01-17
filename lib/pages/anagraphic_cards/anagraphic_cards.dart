import 'package:app_analisi_cute/pages/edit_anagraphic/edit_anagraphic_page.dart';
import 'package:app_analisi_cute/pages/new_anagraphic/new_anagraphic.dart';
import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/anagraphic_cards/components/anagraphic_card_viewer.dart';

class HoverableCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Anagrafica anagrafica;
  final VoidCallback onRefresh;
  final String username;
  final String password;

  const HoverableCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.anagrafica,
    required this.onRefresh,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  Future<void> _deleteAnagrafica() async {
    try {
      final api = AnagraficaApi();
      await api.deleteAnagrafica(
        widget.username,
        widget.password,
        widget.anagrafica.id!,
      );
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anagrafica eliminata con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        child: ListTile(
          // Aggiunto comportamento per aprire la visualizzazione cliccando sulla scheda
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AnagraficaView(anagrafica: widget.anagrafica),
            );
          },
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
              } else if (value == 'Modifica') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAnagraficaPage(
                      username: widget.username,
                      password: widget.password,
                      anagrafica: widget.anagrafica,
                    ),
                  ),
                ).then((updatedAnagrafica) {
                  if (updatedAnagrafica != null) {
                    widget.onRefresh();
                  }
                });
              } else if (value == 'Elimina') {
                _deleteAnagrafica();
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
  final String username;
  final String password;

  const AnagrafichePage({Key? key, required this.username, required this.password})
      : super(key: key);

  @override
  State<AnagrafichePage> createState() => _AnagrafichePageState();
}

class _AnagrafichePageState extends State<AnagrafichePage> {
  final AnagraficaApi _api = AnagraficaApi();
  List<Anagrafica> _allAnagrafiche = [];
  List<Anagrafica> _filteredAnagrafiche = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAnagrafiche();
    _searchController.addListener(_filterAnagrafiche);
  }

  Future<void> _fetchAnagrafiche() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final anagrafiche = await _api.getAnagrafiche(widget.username, widget.password);
      setState(() {
        _allAnagrafiche = anagrafiche;
        _filteredAnagrafiche = anagrafiche;
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

  void _filterAnagrafiche() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnagrafiche = _allAnagrafiche.where((anagrafica) {
        final fullName = '${anagrafica.nome} ${anagrafica.cognome}'.toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  void _createNewAnagrafica() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewAnagraficaPage(username: widget.username, password: widget.password), 
      ),
    ).then((_) {
      _fetchAnagrafiche();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              onPressed: _createNewAnagrafica,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuova Anagrafica',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Container(
      color: Colors.white, // Sfondo bianco
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca anagrafica...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Logica per i filtri
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAnagrafiche.isEmpty
                    ? const Center(child: Text('Nessuna anagrafica trovata'))
                    : ListView.builder(
                        itemCount: _filteredAnagrafiche.length,
                        itemBuilder: (context, index) {
                          final anagrafica = _filteredAnagrafiche[index];
                          return HoverableCard(
                            title: '${anagrafica.nome} ${anagrafica.cognome}',
                            subtitle: 'ID: ${anagrafica.id}',
                            anagrafica: anagrafica,
                            onRefresh: _fetchAnagrafiche,
                            username: widget.username,
                            password: widget.password,
                          );
                        },
                      ),
          ),
        ],
      ),
    ));
  }
}
