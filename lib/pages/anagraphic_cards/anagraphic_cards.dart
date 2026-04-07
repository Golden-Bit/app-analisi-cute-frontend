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
        color: Colors.white,
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
/// Apre un dialog con i controlli di filtro
Future<void> _openFilterDialog() async {
  // Stato locale dei filtri
  String nameContains = _searchController.text;
  bool onlyWithId = false;

  // Controller persistente per evitare perdite di focus e selection inversa
  final TextEditingController nameController =
      TextEditingController(text: nameContains)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: nameContains.length),
        );

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Filtri Anagrafiche'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filtro per nome
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nome contiene...',
                  ),
                  onChanged: (v) {
                    setDialogState(() => nameContains = v);
                    // Ricarica la selection per sicurezza
                    nameController.selection = TextSelection.fromPosition(
                      TextPosition(offset: nameController.text.length),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Filtro checkbox
                CheckboxListTile(
                  title: const Text('Mostra solo con ID non nullo'),
                  value: onlyWithId,
                  onChanged: (v) =>
                      setDialogState(() => onlyWithId = v!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Applica filtro definitivo
                  setState(() {
                    // (Opzionale) sincronizza anche la search bar principale
                    _searchController.text = nameContains;
                    _filteredAnagrafiche = _allAnagrafiche.where((a) {
                      final fullName =
                          '${a.nome} ${a.cognome}'.toLowerCase();
                      final matchesName =
                          fullName.contains(nameContains.toLowerCase());
                      final matchesId =
                          onlyWithId ? (a.id?.isNotEmpty ?? false) : true;
                      return matchesName && matchesId;
                    }).toList();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Applica'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _buildSubtitle(Anagrafica ana) {
  final hist = ana.analysisHistory;
  if (hist.isEmpty) return 'Nessuna analisi registrata';

  // numero totale
  final total = hist.length;

  // estrai la data più recente
  hist.sort((a, b) =>
      (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  final latest = hist.first['timestamp'] as String;      // "YYYY-MM-DD HH:MM:SS"
  final datePart = latest.split(' ').first;              // "YYYY-MM-DD"
  final ymd = datePart.split('-');                       // [Y, M, D]
  final formatted =
      '${ymd[2].padLeft(2, '0')}/${ymd[1].padLeft(2, '0')}/${ymd[0]}';

  return 'Ultima: $formatted — Analisi totali: $total';
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
                     onPressed: _openFilterDialog,
                  style: ElevatedButton.styleFrom(
                        //minimumSize: const Size.fromHeight(56), // forza altezza a 56px
                        //padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            subtitle: _buildSubtitle(anagrafica),
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
