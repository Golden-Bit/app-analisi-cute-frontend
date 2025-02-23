import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';
import 'package:flutter/material.dart';

/// CustomDropdown: dropdown personalizzato con campo di ricerca
class CustomDropdown extends StatefulWidget {
  final List<String> items;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDropdownOpen;
  final VoidCallback? onDropdownClose;

  const CustomDropdown({
    Key? key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.onDropdownOpen,
    this.onDropdownClose,
  }) : super(key: key);

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  final FocusNode _searchFocusNode = FocusNode();

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    // Lista locale per il filtraggio
    List<String> localFilteredItems = List.from(widget.items);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerSignal: (event) {},
          child: StatefulBuilder(
            builder: (context, setStateOverlay) {
              return Stack(
                children: [
                  // Schermata trasparente per chiudere il dropdown
                  GestureDetector(
                    onTap: _closeDropdown,
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                  Positioned(
                    width: 300,
                    left: offset.dx,
                    top: offset.dy + renderBox.size.height,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(4),
                      child: CompositedTransformFollower(
                        offset: Offset(0, renderBox.size.height),
                        link: _layerLink,
                        showWhenUnlinked: false,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: Colors.white,
                          ),
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Campo di ricerca
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  focusNode: _searchFocusNode,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Cerca...',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                  ),
                                  onChanged: (query) {
                                    setStateOverlay(() {
                                      localFilteredItems = widget.items
                                          .where((item) => item
                                              .toLowerCase()
                                              .contains(query.toLowerCase()))
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  children: localFilteredItems.map((item) {
                                    return _buildHoverableListTile(
                                      title: item,
                                      onTap: () {
                                        widget.onChanged(item);
                                        _closeDropdown();
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    Overlay.of(context)!.insert(_overlayEntry!);

    setState(() {
      _isDropdownOpen = true;
    });
    if (widget.onDropdownOpen != null) {
      widget.onDropdownOpen!();
    }

    // Richiede immediatamente il focus sul campo di ricerca
    Future.delayed(Duration.zero, () {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    setState(() {
      _isDropdownOpen = false;
    });
    if (widget.onDropdownClose != null) {
      widget.onDropdownClose!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          height: 45,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
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
    );
  }

  /// Costruisce una ListTile che cambia colore in base all'hover
  Widget _buildHoverableListTile({
    required String title,
    required VoidCallback onTap,
    double horizontalPadding = 8.0,
    double verticalPadding = 6.0,
  }) {
    Color backgroundColor = Colors.white;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) {
            setState(() {
              backgroundColor = Colors.grey[200]!;
            });
          },
          onExit: (_) {
            setState(() {
              backgroundColor = Colors.white;
            });
          },
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: backgroundColor,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ComponentC: widget principale per la visualizzazione dei dettagli dell'anagrafica e del modello 3D
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
  bool _bodyDropdownOpen = false; // Flag per controllare lo stato del dropdown delle parti del corpo

  // Lista appiattita delle parti del corpo (con eventuali sottocategorie del viso)
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
    _selectedAnagraficaString = "Seleziona un'anagrafica";
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

  @override
  Widget build(BuildContext context) {
    // Per il dropdown delle anagrafiche, creiamo la lista delle stringhe
    final List<String> anagraficheItems =
        _anagrafiche.map((ana) => "${ana.nome} ${ana.cognome}").toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Se l'app è in caricamento mostra il progress indicator,
          // altrimenti mostra i due dropdown (anagrafica e parte del corpo)
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                // CustomDropdown per la selezione dell'anagrafica
                Expanded(
                  child: CustomDropdown(
                    items: anagraficheItems,
                    value: _selectedAnagraficaString ?? "Seleziona un'anagrafica",
                    onChanged: (val) {
                      Anagrafica? selected;
                      for (var ana in _anagrafiche) {
                        if ("${ana.nome} ${ana.cognome}" == val) {
                          selected = ana;
                          break;
                        }
                      }
                      setState(() {
                        _selectedAnagraficaString = val;
                        _selectedAnagrafica = selected;
                      });
                      widget.onAnagraficaSelected(selected);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // CustomDropdown per la selezione della parte del corpo,
                // con callback per aggiornare lo stato (_bodyDropdownOpen)
                Expanded(
                  child: CustomDropdown(
                    items: _bodyParts,
                    value: _selectedZone ?? _bodyParts[0],
                    onChanged: (zone) {
                      setState(() {
                        _selectedZone = zone;
                      });
                    },
                    onDropdownOpen: () {
                      setState(() {
                        _bodyDropdownOpen = true;
                      });
                    },
                    onDropdownClose: () {
                      setState(() {
                        _bodyDropdownOpen = false;
                      });
                    },
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
                                        .map((pair) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Visualizzazione del modello 3D, in cui i controlli della telecamera sono disabilitati se il dropdown delle parti del corpo è aperto
                Expanded(
                  flex: 3,
                  child: ThreeDModelViewer(
                    key: ValueKey('${_selectedAnagrafica?.id}-${_bodyDropdownOpen}'),
                    autoRotate: true,
                    modelUrl: _selectedAnagrafica != null &&
                            _selectedAnagrafica!.gender.toLowerCase() == "donna"
                        ? "https://www.goldbitweb.com/api1/models/femalebody_with_base_color.glb"
                        : "https://www.goldbitweb.com/api1/models/malebody_with_base_color.glb",
                    // Se il dropdown è aperto, disabilitiamo i controlli della telecamera
                    cameraControls: !_bodyDropdownOpen,
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
