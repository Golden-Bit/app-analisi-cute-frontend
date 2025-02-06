import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';
import 'package:flutter/material.dart';

class ComponentC extends StatefulWidget {
  final void Function(Anagrafica?) onAnagraficaSelected; // Callback per la selezione dell'anagrafica
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
  final AnagraficaApi _api = AnagraficaApi(); // SDK API per le anagrafiche
  List<Anagrafica> _anagrafiche = []; // Lista delle anagrafiche
  Anagrafica? _selectedAnagrafica; // Anagrafica selezionata
  String? _selectedZone; // Zona del corpo selezionata
  bool _isLoading = true; // Stato di caricamento

  @override
  void initState() {
    super.initState();
    _fetchAnagrafiche(); // Carica le anagrafiche all'inizializzazione
    _selectedZone = "Viso"; // Zona predefinita
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
    return Padding(
      padding: const EdgeInsets.all(8.0), // Outer padding for the entire component
      child: Column(
        children: [
          // Dropdowns per la selezione dell'anagrafica e della zona del corpo
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                // Dropdown per la selezione dell'anagrafica
                Expanded(
                  child: DropdownButton<Anagrafica>(
                    value: _selectedAnagrafica,
                    hint: const Text('Seleziona un\'anagrafica'),
                    isExpanded: true,
                    items: _anagrafiche.map((anagrafica) {
                      return DropdownMenuItem<Anagrafica>(
                        value: anagrafica,
                        child: Text('${anagrafica.nome} ${anagrafica.cognome}'),
                      );
                    }).toList(),
                    onChanged: (selected) {
                      setState(() {
                        _selectedAnagrafica = selected;
                      });
                      widget.onAnagraficaSelected(selected);
                    },
                  ),
                ),
                const SizedBox(width: 12), // Spazio tra i dropdown
                // Dropdown per la selezione della zona del corpo
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedZone,
                    hint: const Text('Seleziona Zona del Corpo'),
                    isExpanded: true,
                    items: ['Viso', 'Collo', 'Spalle', 'Braccia', 'Gambe', 'Torso']
                        .map((zone) => DropdownMenuItem<String>(
                              value: zone,
                              child: Text(zone),
                            ))
                        .toList(),
                    onChanged: (zone) {
                      setState(() {
                        _selectedZone = zone;
                      });
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12), // Spaziatura tra dropdown e contenuto principale
          Expanded(
            child: Row(
              children: [
                // Colonna per le coppie chiave-valore
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
                // Modello 3D
                Expanded(
                  flex: 3,
                  child: ThreeDModelViewer(
                    key: ValueKey(_selectedAnagrafica?.id),
                    autoRotate: true,
                    modelUrl: _selectedAnagrafica != null &&
                            _selectedAnagrafica!.gender.toLowerCase() == "donna"
                        ? "https://www.goldbitweb.com/api1/models/femalebody_with_base_color.glb"
                        : "https://www.goldbitweb.com/api1/models/malebody_with_base_color.glb",
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
