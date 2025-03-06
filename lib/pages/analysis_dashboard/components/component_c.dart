import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';
import 'package:flutter/material.dart';

class ComponentC extends StatefulWidget {
  final void Function(Anagrafica?) onAnagraficaSelected;
  final String username;
  final String password;

  const ComponentC({
    Key? key,
    required this.onAnagraficaSelected,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  _ComponentCState createState() => _ComponentCState();
}

class _ComponentCState extends State<ComponentC> {
  final AnagraficaApi _api = AnagraficaApi();
  List<Anagrafica> _anagrafiche = [];
  Anagrafica? _selectedAnagrafica;
  String? _selectedAnagraficaString;
  String? _selectedZone;
  bool _isLoading = true;

  // Questa variabile servirà a disabilitare i controlli della telecamera quando è aperto un Dialog
  bool _isDialogOpen = false;

  // Lista appiattita delle parti del corpo
  final List<String> _bodyParts = [
    "Mento e baffi (Viso)",
    "Basette (Viso)",
    "Sopracciglia (Viso)",
    "Guance (Viso)",
    "Orecchie (Testa)",
    "Nuca (Collo)",
    "Collo (Collo)",
    "Seno (Torace)",
    "Ascelle (Torace)",
    "Spalle (Torace)",
    "Petto (Torace)",
    "Addome (Addome)",
    "Schiena (Dorso)",
    "Linea alba (Addome)",
    "Inguine (Pelvi)",
    "Braccia (Arti Superiori)",
    "Mani (Arti Superiori)",
    "Gambe (Arti Inferiori)",
    "Cosce (Arti Inferiori)",
    "Gambaletto (Arti Inferiori)",
    "Piedi (Arti Inferiori)",
    "Ano (Pelvi)",
  ];

  @override
  void initState() {
    super.initState();
    _selectedZone = _bodyParts[0]; // Valore predefinito
    _selectedAnagraficaString = "Seleziona";
    _fetchAnagrafiche();
  }

  Future<void> _fetchAnagrafiche() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final anagrafiche = await _api.getAnagrafiche(widget.username, widget.password);
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

  List<Map<String, String>> _generateKeyValuePairs(Anagrafica anagrafica) {
    return [
      {"Nome": anagrafica.nome},
      {"Cognome": anagrafica.cognome},
      {"Data di nascita": anagrafica.birthDate},
      {"Indirizzo": anagrafica.address},
      {"Peso": "${anagrafica.peso} kg"},
      {"Altezza": "${anagrafica.altezza} cm"},
      {"Genere": anagrafica.gender},
      {"Tipo di Pelle": anagrafica.skinTypes.join(', ')},
      {"Inestetismi": anagrafica.issues.join(', ')},
    ];
  }

  /// Mostra un dialogo di selezione con campo di ricerca.
  /// [title] è il titolo del dialogo,
  /// [items] è la lista di elementi selezionabili.
  /// Ritorna la stringa selezionata, oppure null se non si seleziona nulla.
  Future<String?> _showSelectionDialog({
    required String title,
    required List<String> items,
  }) async {
    // Manteniamo una lista locale per il filtraggio.
    List<String> filteredItems = List.from(items);

    // Dialog che ritorna la stringa selezionata.
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 300,
                height: 400, // Altezza fissa per il dialog, con scroll interno.
                child: Column(
                  children: [
                    // Campo di ricerca
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Cerca...',
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          query = value;
                          filteredItems = items
                              .where((item) =>
                                  item.toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).pop(item);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                child: Text(item),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Per l'anagrafica, prepariamo la lista di stringhe (nome cognome).
    final List<String> anagraficheItems =
        _anagrafiche.map((ana) => "${ana.nome} ${ana.cognome}").toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Se in caricamento, mostra il progress indicator, altrimenti mostra i pulsanti
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                // Bottone per selezionare un'anagrafica
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _isDialogOpen = true;
                      });
                      final selectedValue = await _showSelectionDialog(
                        title: "Seleziona un'anagrafica",
                        items: anagraficheItems,
                      );
                      setState(() {
                        _isDialogOpen = false;
                      });

                      if (selectedValue != null) {
                        Anagrafica? selected;
                        for (var ana in _anagrafiche) {
                          final fullName = "${ana.nome} ${ana.cognome}";
                          if (fullName == selectedValue) {
                            selected = ana;
                            break;
                          }
                        }
                        setState(() {
                          _selectedAnagraficaString = selectedValue;
                          _selectedAnagrafica = selected;
                        });
                        widget.onAnagraficaSelected(selected);
                      }
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedAnagraficaString ?? "Seleziona",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bottone per selezionare la parte del corpo
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        _isDialogOpen = true;
                      });
                      final selectedValue = await _showSelectionDialog(
                        title: "Seleziona la zona del corpo",
                        items: _bodyParts,
                      );
                      setState(() {
                        _isDialogOpen = false;
                      });

                      if (selectedValue != null) {
                        setState(() {
                          _selectedZone = selectedValue;
                        });
                      }
                    },
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 1.0),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedZone ?? _bodyParts[0],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                // Sezione per la visualizzazione dei dettagli dell'anagrafica
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0),
                    child: _selectedAnagrafica == null
                        ? const Center(
                            child: Text(
                              'Seleziona un\'anagrafica per visualizzare i dettagli',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _generateKeyValuePairs(_selectedAnagrafica!)
                                        .map(
                                          (pair) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "  ${pair.keys.first}: ",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  pair.values.first,
                                                  style:
                                                      const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Visualizzazione del modello 3D
                Expanded(
                  flex: 3,
                  child: ThreeDModelViewer(
                    // Per forzare la ricostruzione se cambia anagrafica o se il dialog è aperto/chiuso
                    key: ValueKey(
                        '${_selectedAnagrafica?.id}-${_isDialogOpen.toString()}'),
                    autoRotate: true,
                    modelUrl: _selectedAnagrafica != null &&
                            _selectedAnagrafica!.gender.toLowerCase() == "donna"
                        ? "https://www.goldbitweb.com/api1/models/femalebody_with_base_color.glb"
                        : "https://www.goldbitweb.com/api1/models/malebody_with_base_color.glb",
                    // Se il dialog è aperto, disabilitiamo i controlli della telecamera
                    cameraControls: !_isDialogOpen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
