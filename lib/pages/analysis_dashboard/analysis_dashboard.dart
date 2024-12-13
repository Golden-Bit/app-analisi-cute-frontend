import 'dart:convert';
import 'dart:typed_data';

import 'package:app_analisi_cute/backend_sdk/analyze.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:flutter/material.dart';
import 'components/sub_components/camera.dart';
import 'components/component_a.dart';
import 'components/component_c.dart';
import 'components/component_d.dart';
import 'components/component_b.dart';

class AnalysisDashboard extends StatefulWidget {
  const AnalysisDashboard({Key? key}) : super(key: key);

  @override
  _AnalysisDashboardState createState() => _AnalysisDashboardState();
}

class _AnalysisDashboardState extends State<AnalysisDashboard> {
  final AnalysisApi _api = AnalysisApi(); // API instance
  final Map<String, List<Uint8List>> _imagesByAnalysis = {}; // Map for images
  final Map<String, Map<String, dynamic>> _resultsByAnalysis = {}; // Results by type
  final Map<String, int> _analysisScores = {}; // Unified scores for ComponentD
  String _selectedAnalysis = "Idratazione"; // Current selected type
  bool _isAnalyzing = false; // Track if analysis is in progress
  String? _selectedPatientId; // ID del paziente selezionato

  void _onPatientSelected(Anagrafica? selectedPatient) {
    setState(() {
      _selectedPatientId = selectedPatient?.id; // Aggiorna lo stato con l'ID del paziente selezionato
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    const analysisTypes = [
      "Idratazione",
      "Strato lipidico",
      "Elasticità",
      "Cheratina",
      "Pelle sensibile",
      "Macchie cutanee",
      "Tonalità",
      "Densità pilifera",
      "Pori ostruiti",
    ];
    for (var type in analysisTypes) {
      _imagesByAnalysis[type] = [];
      _resultsByAnalysis[type] = {
        "valore": 0,
        "descrizione": "Nessun dato disponibile.",
        "valutazione_professionale": "Nessuna valutazione disponibile.",
        "consigli": "Nessun consiglio disponibile.",
      };
      _analysisScores[type] = 0; // Initialize scores with zero
    }
  }

  void _updateImages(String analysisType, List<Uint8List> images) {
    setState(() {
      _imagesByAnalysis[analysisType] = images;
    });
  }

  void _onAnalysisSelected(String analysisType) {
    setState(() {
      _selectedAnalysis = analysisType;
    });
  }

  Future<void> _performAnalysis() async {
  if (_selectedPatientId == null) { // Controlla se è stato selezionato un paziente
    // Mostra un messaggio se nessun paziente è selezionato
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleziona un paziente prima di avviare l\'analisi.')),
    );
    return; // Interrompe l'esecuzione se non c'è paziente selezionato
  }

  // Prepara tutte le immagini per l'analisi
  final allImages = _imagesByAnalysis.map((type, images) {
    final base64Images = images.map((image) => base64Encode(image)).toList();
    return MapEntry(type, base64Images);
  });

  setState(() {
    _isAnalyzing = true;
  });

  try {
    // Esegui la chiamata all'API con l'ID del paziente selezionato
    final response = await _api.analyzeSkin(
      patient_id: _selectedPatientId!, // Passa l'ID del paziente selezionato
      images: allImages.values.expand((list) => list).toList(), // Unisci tutte le immagini
    );

    // Aggiorna i risultati di tutte le analisi
    setState(() {
      for (var entry in response.entries) {
        final analysisType = entry.key;
        final result = entry.value as Map<String, dynamic>;
        _resultsByAnalysis[analysisType] = result;
        _analysisScores[analysisType] = result["valore"] ?? 0;
      }
      _isAnalyzing = false;
    });
  } catch (e) {
    setState(() {
      _isAnalyzing = false;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Errore"),
          content: Text("Si è verificato un errore: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
  @override
  Widget build(BuildContext context) {
    const double borderRadius = 2.0;
    const BoxShadow lightShadow = BoxShadow(
      color: Colors.grey,
      offset: Offset(0, 2),
      blurRadius: 2,
      spreadRadius: 0.5,
    );

    final analysisResult = _resultsByAnalysis[_selectedAnalysis]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        title: const Text(
          'Demo Camera e Galleria',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
    ),
  ),
  onPressed: _isAnalyzing
      ? null
      : _performAnalysis, // Chiamata alla funzione aggiornata
  child: const Text(
    'Avvia Analisi',
    style: TextStyle(color: Colors.white),
  ),
),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed: () {
                print('Genera Report premuto');
              },
              child: const Text(
                'Genera Report',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [lightShadow],
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 1,
                                child: ComponentA(
                                  heightFactor: 0.33,
                                  borderRadius: 2,
                                  onAnalysisSelected: _onAnalysisSelected,
                                ),
                              ),
                              const Divider(thickness: 1, color: Colors.grey, height: 1),
Expanded(
  flex: 1,
  child: ComponentC(
    //keyValuePairs: [
    //  {"Peso": "50 kg"},
    //  {"Altezza": "1.75 m"},
    //  {"Età": "30 anni"},
    //  {"BMI": "22.5"},
    //  {"Genere": "Maschio"},
    //],
    //modelSrc: 'http://127.0.0.1:8000/models/femalebody_with_base_color.glb',
    onAnagraficaSelected: _onPatientSelected, // Callback per aggiornare il paziente selezionato
  ),
),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
  flex: 2,
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: Colors.white,
    ),
    child: CameraGalleryWidget(
    onImagesUpdated: (List<Uint8List> images) {
    _updateImages(_selectedAnalysis, images);
  },
  initialImages: _imagesByAnalysis[_selectedAnalysis] ?? [],
),
  ),
),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [lightShadow],
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 1,
                                child: _isAnalyzing
                                    ? const Center(child: CircularProgressIndicator())
                                    : ComponentB(
                                        score: analysisResult["valore"] ?? 0,
                                        description: analysisResult["descrizione"] ??
                                            "Nessun dato disponibile.",
                                        professionalEvaluation:
                                            analysisResult["valutazione_professionale"] ??
                                                "Nessuna valutazione disponibile.",
                                        advice: analysisResult["consigli"] ??
                                            "Nessun consiglio disponibile.",
                                      ),
                              ),
                              const Divider(thickness: 1, color: Colors.grey, height: 1),
                              Expanded(
                                flex: 1,
                                child: ComponentD(
                                  modelSrc:
                                      'http://127.0.0.1:8000/models/Skin_with_base_color.glb',
                                  analysisData: _analysisScores,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
