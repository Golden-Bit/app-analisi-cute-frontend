import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';
import 'package:flutter/material.dart';

class ComponentC extends StatefulWidget {
  final void Function(Anagrafica?) onAnagraficaSelected; // Callback per la selezione dell'anagrafica

  const ComponentC({
    Key? key,
    required this.onAnagraficaSelected,
  }) : super(key: key);

  @override
  _ComponentCState createState() => _ComponentCState();
}

class _ComponentCState extends State<ComponentC> {
  final AnagraficaApi _api = AnagraficaApi(); // SDK API per le anagrafiche
  List<Anagrafica> _anagrafiche = []; // Lista delle anagrafiche
  Anagrafica? _selectedAnagrafica; // Anagrafica selezionata
  bool _isLoading = true; // Stato di caricamento

  @override
  void initState() {
    super.initState();
    _fetchAnagrafiche(); // Carica le anagrafiche all'inizializzazione
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
          // Dropdown per la selezione dell'anagrafica
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Align(
                  alignment: Alignment.center, // Centra il menu dropdown
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5, // Larghezza dimezzata
                    child: DropdownButton<Anagrafica>(
                      value: _selectedAnagrafica,
                      hint: const Text('Seleziona un\'anagrafica'),
                      isExpanded: true, // Occupa tutta la larghezza del contenitore padre
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
                        widget.onAnagraficaSelected(selected); // Notifica il cambiamento al parent
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Spaziatura tra dropdown e contenuto principale
              ],
            ),
          Expanded(
            child: Row(
              children: [
                // Colonna per le coppie chiave-valore
                Expanded(
                  flex: 3, // Modifica la larghezza per occupare il 25% in più dello spazio iniziale
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0.0), // Padding dal margine sinistro
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
                              borderRadius: BorderRadius.circular(2), // Border radius ridotto a 2
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: _generateKeyValuePairs(_selectedAnagrafica!)
                                        .map((pair) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0), // Spaziatura tra le coppie
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
                const SizedBox(width: 12), // Spaziatura tra le colonne
                // Modello 3D
                Expanded(
                  flex: 3, // Mantiene la larghezza del modello 3D invariata
                  child: ThreeDModelViewer(
                    key: ValueKey(_selectedAnagrafica?.id), // Forza il rebuilding
                    src: _selectedAnagrafica != null &&
                            _selectedAnagrafica!.gender.toLowerCase() == "donna"
                        ? "http://127.0.0.1:8000/models/femalebody_with_base_color.glb"
                        : "http://127.0.0.1:8000/models/malebody_with_base_color.glb",
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
