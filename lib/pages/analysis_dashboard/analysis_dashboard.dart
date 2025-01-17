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
import 'dart:html' as html; // Questo import funziona solo su Web
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';

class AnalysisDashboard extends StatefulWidget {
  final String username;
  final String password;

  const AnalysisDashboard({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

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
  final AnagraficaApi __api = AnagraficaApi(); // SDK API per le anagrafiche

  void _onPatientSelected(Anagrafica? selectedPatient) {
    setState(() {
      _selectedPatientId = selectedPatient?.id; // Aggiorna lo stato con l'ID del paziente selezionato
    });
  }


List<Anagrafica> _anagrafiche = []; // Lista di anagrafiche

  Future<void> _fetchAnagrafiche() async {
    setState(() {
      //_isLoading = true;
    });
    try {
      final anagrafiche = await __api.getAnagrafiche(widget.username, widget.password);
      setState(() {
        _anagrafiche = anagrafiche;
        //_isLoading = false;
      });
    } catch (e) {
      setState(() {
        //_isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento delle anagrafiche: $e')),
      );
    }
  }

Anagrafica? _getAnagraficaById(String patientId) {
  // Supponendo che _anagrafiche sia una lista di tutte le anagrafiche disponibili
  return _anagrafiche.firstWhere(
    (anagrafica) => anagrafica.id == patientId,
    orElse: () => null!,
  );
}

void _generateAndDownloadReport() async {
  if (_selectedPatientId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleziona un paziente prima di generare il report.')),
    );
    return;
  }

  // Recupera i dati dell'anagrafica e dei risultati
  final selectedAnagrafica = _getAnagraficaById(_selectedPatientId!);
  if (selectedAnagrafica == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Errore: impossibile trovare i dati del paziente.')),
    );
    return;
  }

  // Genera l'HTML dinamicamente
  final reportHtml = generateReportHtml(
    anagrafica: selectedAnagrafica,
    analysisResults: _resultsByAnalysis,
  );

  // Crea un blob HTML e consenti il download
  try {
    final blob = html.Blob([reportHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'report_${selectedAnagrafica.nome}_${selectedAnagrafica.cognome}.html'
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore durante la generazione del report: $e')),
    );
  }
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

    _fetchAnagrafiche();
    
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
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un paziente prima di avviare l\'analisi.')),
      );
      return;
    }

    final allImages = _imagesByAnalysis.map((type, images) {
      final base64Images = images.map((image) => base64Encode(image)).toList();
      return MapEntry(type, base64Images);
    });

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final response = await _api.analyzeSkin(
        username: widget.username,
        password: widget.password,
        patientId: _selectedPatientId!,
        //username: widget.username,
        //password: widget.password,
        images: allImages.values.expand((list) => list).toList(),
      );

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
              onPressed: _isAnalyzing ? null : _performAnalysis,
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
      // Qui viene richiamata la funzione per generare il report
      onPressed: _generateAndDownloadReport,
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
                                  onAnagraficaSelected: _onPatientSelected,
                                  username: widget.username,
                                  password: widget.password,
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
                                      'https://www.goldbitweb.com/api1/models/skin_with_base_color.glb',
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



String generateReportHtml({
  required Anagrafica anagrafica,
  required Map<String, Map<String, dynamic>> analysisResults,
}) {
  return '''
<!DOCTYPE html>
<html>
<head>
  <title>Report Analisi</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
    }
    .header {
      text-align: center;
      margin-bottom: 40px;
    }
    .section {
      margin-bottom: 20px;
    }
    .section-title {
      font-size: 20px;
      font-weight: bold;
      margin-bottom: 10px;
    }
    .table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    .table th, .table td {
      border: 1px solid #ddd;
      padding: 8px;
    }
    .table th {
      background-color: #f2f2f2;
      text-align: left;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>Report Analisi della Pelle</h1>
    <h3>Generato per: ${anagrafica.nome} ${anagrafica.cognome}</h3>
  </div>

  <div class="section">
    <div class="section-title">Informazioni Anagrafiche</div>
    <table class="table">
      <tr>
        <th>Nome</th>
        <td>${anagrafica.nome}</td>
      </tr>
      <tr>
        <th>Cognome</th>
        <td>${anagrafica.cognome}</td>
      </tr>
      <tr>
        <th>Data di Nascita</th>
        <td>${anagrafica.birthDate}</td>
      </tr>
      <tr>
        <th>Indirizzo</th>
        <td>${anagrafica.address}</td>
      </tr>
      <tr>
        <th>Peso</th>
        <td>${anagrafica.peso} kg</td>
      </tr>
      <tr>
        <th>Altezza</th>
        <td>${anagrafica.altezza} cm</td>
      </tr>
      <tr>
        <th>Genere</th>
        <td>${anagrafica.gender}</td>
      </tr>
      <tr>
        <th>Tipo di Pelle</th>
        <td>${anagrafica.skinTypes.join(', ')}</td>
      </tr>
      <tr>
        <th>Inestetismi</th>
        <td>${anagrafica.issues.join(', ')}</td>
      </tr>
    </table>
  </div>

  <div class="section">
    <div class="section-title">Risultati delle Analisi</div>
    <table class="table">
      <tr>
        <th>Tipo di Analisi</th>
        <th>Valore</th>
        <th>Descrizione</th>
        <th>Valutazione Professionale</th>
        <th>Consigli</th>
      </tr>
      ${analysisResults.entries.map((entry) {
        final type = entry.key;
        final result = entry.value;
        return '''
          <tr>
            <td>${type}</td>
            <td>${result['valore']}</td>
            <td>${result['descrizione']}</td>
            <td>${result['valutazione_professionale']}</td>
            <td>${result['consigli']}</td>
          </tr>
        ''';
      }).join()}
    </table>
  </div>
</body>
</html>
  ''';
}

