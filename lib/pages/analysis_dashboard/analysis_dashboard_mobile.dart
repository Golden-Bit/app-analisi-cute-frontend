import 'dart:convert';
import 'dart:typed_data';
import 'dart:async' show unawaited; 
import 'package:app_analisi_cute/backend_sdk/analyze.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/camera_android.dart';
import 'package:flutter/material.dart';
//import 'components/sub_components/camera_web_.dart';
import 'components/component_a.dart';
import 'components/component_c.dart';
import 'components/component_d.dart';
import 'components/component_b.dart';
//import 'dart:html' as html; // Questo import funziona solo su Web
import 'dart:developer' as dev;   // per log più potenti di print
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator; // solo per lo spinner piccolo
import 'dart:io';             // ✔️  per File e Directory
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';  // o share_plus
import 'dart:math' as math;   // <-- per calcolare il minimo globale
import 'package:http/http.dart' as http; 

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

  String? _logoBase64;   
  final AnalysisApi _api = AnalysisApi(); // API instance
// subito dopo _analysisScoresByZone
final Set<String> _analysisInProgressPerZone = {}; // zone attualmente in analisi
final Set<String> _failedAutomaticZones = {};     // zone fallite
bool _showAutomaticSummary = false;               // mostra la card finale?
  // Le mappe per i risultati e i punteggi rimangono indicizzate per zona e per tipo di analisi
  Map<String, Map<String, Map<String, dynamic>>> _resultsByZone = {};
// dopo
Map<String, Map<String, double>> _analysisScoresByZone = {};

  // Ora le immagini sono gestite separatamente per zona (condivise tra i diversi tipi di analisi della stessa zona)
  Map<String, List<String>> _imagesByZone = {};

  // Tipo di analisi corrente (es. "Idratazione", "Strato lipidico", ecc.)
  String _selectedAnalysis = "Idratazione";
  // Zona corrente selezionata; di default la prima nell'elenco
  String _selectedZone = "Mento e baffi (Viso)";

  bool _isAnalyzing = false; // Stato dell'analisi manuale
  String? _selectedPatientId; // ID del paziente selezionato
  final AnagraficaApi __api = AnagraficaApi(); // API per le anagrafiche

  List<Anagrafica> _anagrafiche = []; // Lista delle anagrafiche

  // Variabili per l'analisi automatica
  bool _isAutomaticAnalysisActive = false;
  List<String> _automaticZones = [];
  int _currentAutomaticZoneIndex = 0;
  List<String> _completedAutomaticZones = [];

  // GlobalKey per poter aggiornare la zona in ComponentC
  final GlobalKey<ComponentCState> _componentCKey = GlobalKey<ComponentCState>();
/// Ricalcola i valori di “Densità pilifera” affinché il minimo misurato
/// fra tutte le zone diventi 0 sulla scala 0-100.
/// Chiama SEMPRE questa funzione ogni volta che arrivano nuovi risultati.
void _normalizeHairDensityScores() {
  final measured = _rawHairDensityByZone.values.where((v) => v > 0).toList();
  if (measured.isEmpty) return;

  final int minRaw = measured.reduce(math.min);

  _rawHairDensityByZone.forEach((zone, raw) {
    if (raw == 0) return; // mai misurata

    final double norm01 = (minRaw == 100)
        ? 0.0
        : ((raw - minRaw) / (100 - minRaw)).clamp(0.0, 1.0);

    _analysisScoresByZone[zone]?['Densità pilifera'] = norm01;
    _resultsByZone[zone]?['Densità pilifera']?['valore'] = norm01;
  });
}



  // Elenco di tutte le zone (da usare anche in ComponentC)
  final List<String> _allZones = [
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
// nuovo membro di stato
Map<String, int> _rawHairDensityByZone = {};   // ⚠️ solo il dato grezzo

  // Elenco dei tipi di analisi (uguale a quello usato in ComponentA)
  final List<String> _analysisTypes = [
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

  void _onPatientSelected(Anagrafica? selectedPatient) {
    setState(() {
      _selectedPatientId = selectedPatient?.id;
    });
  }
Future<void> _performAnalysisForZone(String zone) async {
  // debug
  print('[AA] ➡️ Richiesta analisi per "$zone"');

  // Non avviare se già in coda o senza foto
  final images = _imagesByZone[zone] ?? [];
  if (_analysisInProgressPerZone.contains(zone) || images.isEmpty) {
    print('[AA] ⏩ Skip "$zone": già in corso o senza immagini');
    return;
  }

  _analysisInProgressPerZone.add(zone);
  print('[AA] 🏃‍♂️ Parte analisi "$zone" con ${images.length} immagini');

  try {
    final response = await _api.analyzeSkin(
      username: widget.username,
      password: widget.password,
      patientId: _selectedPatientId!,
      images: images,
    );

    print('[AA] ✅ Risposta "$zone": ${response.keys.toList()}');

    if (!mounted) return; // widget distrutto

setState(() {
  response.forEach((analysisType, value) {
    if (value is Map<String, dynamic>) {
   // ① DUPLICA l’oggetto e riscrivi il campo 'valore' in scala 0-1
   _resultsByZone[zone]![analysisType] = {
     ...value,
     'valore': ((value['valore'] ?? 0) / 100).clamp(0.0, 1.0),
   };
   // ② punteggio per la UI in scala 0-1
   _analysisScoresByZone[zone]![analysisType] =
       ((value['valore'] ?? 0) / 100).clamp(0.0, 1.0);

      // ➕ aggiungi anche nel flusso automatico
  if (analysisType == 'Densità pilifera') {
  _rawHairDensityByZone[zone] = value['valore'] ?? 0;
    }
    }
  });
  _normalizeHairDensityScores();           // <-- stesso setState
});

  } catch (e, st) {
      _failedAutomaticZones.add(zone);   
    print('[AA] ❌ Errore "$zone": $e');
  } finally {
    _analysisInProgressPerZone.remove(zone);
    print('[AA] 🔚 Fine analisi "$zone"');
      if (!_isAutomaticAnalysisActive &&
      _analysisInProgressPerZone.isEmpty &&
      mounted) {
    setState(() {});      // forza rebuild del riepilogo quando l’ultima Future termina
  }
  }
}


  Future<void> _fetchAnagrafiche() async {
    try {
      final anagrafiche = await __api.getAnagrafiche(widget.username, widget.password);
      setState(() {
        _anagrafiche = anagrafiche;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il caricamento delle anagrafiche: $e')),
      );
    }
  }

  Anagrafica? _getAnagraficaById(String patientId) {
    // Restituisce la prima anagrafica che corrisponde all'ID oppure null se non trovata
    return _anagrafiche.firstWhere(
      (anagrafica) => anagrafica.id == patientId,
      orElse: () => null!,
    );
  }
Future<File> _saveHtml(String htmlSource, String filename) async {
  // 1. cartella Documents privata dell’app (nessun permesso extra) :contentReference[oaicite:4]{index=4}
  final dir  = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');

  // 2. scrive il file (overwrite se esiste già)
  return file.writeAsString(htmlSource, flush: true);
}
  void _generateAndDownloadReport() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un paziente prima di generare il report.')),
      );
      return;
    }

    final selectedAnagrafica = _getAnagraficaById(_selectedPatientId!);
    if (selectedAnagrafica == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore: impossibile trovare i dati del paziente.')),
      );
      return;
    }

    // Recupera i dati relativi alla zona corrente
    final analysisResultsForZone = _resultsByZone[_selectedZone]!;
    final imagesForZone = _imagesByZone[_selectedZone]!;

  try {
    final reportHtml = generateReportHtml(
      anagrafica: selectedAnagrafica,
      zone: _selectedZone,
      analysisResults: analysisResultsForZone,
      images: imagesForZone,
      logoBase64: _logoBase64,
    );
  final file = await _saveHtml(
      reportHtml,
      'report_${selectedAnagrafica.nome}_${selectedAnagrafica.cognome}_$_selectedZone.html');
  await OpenFile.open(file.path);        // lancia l’app associata :contentReference[oaicite:5]{index=5}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la generazione del report: $e')),
      );
    }
  }

  Future<void> _performAnalysis() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona un paziente prima di avviare l\'analisi.')),
      );
      return;
    }

    // Prepara le immagini per la zona corrente (le immagini sono ora gestite direttamente come lista)
    final allImages = _imagesByZone[_selectedZone] ?? [];

    setState(() {
      _isAnalyzing = true;
    });

    try {
      print("🔄 Inizio analisi per paziente $_selectedPatientId con ${allImages.length} immagini per la zona $_selectedZone.");

      final response = await _api.analyzeSkin(
        username: widget.username,
        password: widget.password,
        patientId: _selectedPatientId!,
        images: allImages, // Le immagini sono già in Base64
      );

      print("✅ Analisi completata. Risultati ricevuti: ${response.keys.toList()}");

setState(() {
  // 1️⃣ aggiorna mappe UI e salva SEMPRE il valore grezzo
  response.forEach((analysisType, value) {
    if (analysisType == 'bod_zone' && value is String) {
      // gestione opzionale della chiave bod_zone …
    } else if (value is Map<String, dynamic>) {
      // aggiorna risultato e punteggio mostrati a video
   // ① duplichiamo e riscriviamo 'valore' in 0-1
   _resultsByZone[_selectedZone]![analysisType] = {
     ...value,
     'valore': ((value['valore'] ?? 0) / 100).clamp(0.0, 1.0),
   };
   // ② punteggio UI in 0-1
   _analysisScoresByZone[_selectedZone]![analysisType] =
       ((value['valore'] ?? 0) / 100).clamp(0.0, 1.0);
      // ➕  se è “Densità pilifera” memorizza il dato GREZZO per la normalizzazione
      if (analysisType == 'Densità pilifera') {
        _rawHairDensityByZone[_selectedZone] = value['valore'] ?? 0;
      }
    }
  });

  _isAnalyzing = false;          // fine loading spinner

  // 2️⃣ ricalcola subito tutti i valori normalizzati
  _normalizeHairDensityScores();
});

    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      print("❌ Errore durante l'analisi: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
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
  // >>> NEW >>>----------------------------------------------------------------
  //  Set temporaneo delle zone selezionate nel dialog prima di avviare
  //  l’analisi automatica.
  // ---------------------------------------------------------------------------
  Set<String> _tmpSelectedZones = {};

  // >>> NEW >>>----------------------------------------------------------------
  //  Funzione helper che restituisce le zone di default in base al genere
  // ---------------------------------------------------------------------------
  List<String> _defaultZonesForGender(String gender) {
    if (gender.toLowerCase() == 'donna') {
      return [
        "Basette (Viso)",
        "Petto (Torace)",
        "Braccia (Arti Superiori)",
        "Addome (Addome)",
        "Schiena (Dorso)",
        "Inguine (Pelvi)",
        "Gambe (Arti Inferiori)",
      ];
    }
    return [
      "Basette (Viso)",
      "Petto (Torace)",
      "Braccia (Arti Superiori)",
      "Addome (Addome)",
      "Schiena (Dorso)",
      "Gambe (Arti Inferiori)",
    ];
  }

  // >>> NEW >>>----------------------------------------------------------------
  //  Dialogo modale per scegliere dinamicamente le zone da includere
  // ---------------------------------------------------------------------------
Future<void> _openZoneSelectionDialog() async {
  if (_selectedPatientId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleziona un paziente prima di avviare l\'analisi automatica.'),
      ),
    );
    return;
  }

  // pre-selezione in base al genere del paziente
  final defaultZones = _defaultZonesForGender(
    _getAnagraficaById(_selectedPatientId!)?.gender ?? '',
  );
  _tmpSelectedZones = {...defaultZones};

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            scrollable: true,
            title: const Text('Seleziona le zone da analizzare'),
            // ----------> START: contenuto dialog
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              // ListView.separated = spaziatura verticale “naturale”
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,  // ⬅︎ spaziatura orizzontale
                  vertical: 4,    // ⬅︎ spaziatura verticale in cima e fondo
                ),
                itemCount: _allZones.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 8), // ⬅︎ spaziatura verticale fra card
                itemBuilder: (_, idx) {
                  final zone = _allZones[idx];
                  final selected = _tmpSelectedZones.contains(zone);

                  return Card(
                    // ⬇︎ angoli arrotondati raggio 2
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    color: Colors.white,
                    margin: EdgeInsets.zero, // margine gestito da ListView padding
                    child: CheckboxListTile(
                      value: selected,
                      title: Text(zone),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, // ⬅︎ spaziatura interna orizzontale
                        vertical: 2,   // ⬅︎ spaziatura interna verticale
                      ),
                      onChanged: (checked) {
                        setStateSB(() {
                          if (checked == true) {
                            _tmpSelectedZones.add(zone);
                          } else {
                            _tmpSelectedZones.remove(zone);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            // ----------> END   contenuto dialog
            actions: [
              TextButton(
                child: const Text('Annulla'),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                child: const Text('Avvia'),
                onPressed: _tmpSelectedZones.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _startAutomaticAnalysis(_tmpSelectedZones.toList());
                      },
              ),
            ],
          );
        },
      );
    },
  );
}


/// Pulisce TUTTO lo stato di un’eventuale analisi precedente e
/// ricrea i placeholder di default per tutte le zone e i tipi di analisi.
void _resetAutomaticAnalysisState() {
  // 1️⃣ Svuota le immagini mantenendo le chiavi delle zone
  _imagesByZone.updateAll((_, __) => []);

  // 2️⃣ Ricrea placeholder per risultati e punteggi
  for (final zone in _allZones) {
    _resultsByZone[zone] = {};
    _analysisScoresByZone[zone] = {};

    for (final type in _analysisTypes) {
      _resultsByZone[zone]![type] = {
        'valore': 0.0,
        'descrizione': 'Nessun dato disponibile.',
        'valutazione_professionale': 'Nessuna valutazione disponibile.',
        'consigli': 'Nessun consiglio disponibile.',
      };
      _analysisScoresByZone[zone]![type] = 0.0;
    }
  }

  // 3️⃣ Svuota set e flag di stato
  _analysisInProgressPerZone.clear();
  _failedAutomaticZones.clear();
  _completedAutomaticZones.clear();
  _rawHairDensityByZone.clear();
  _showAutomaticSummary = false;
}


  // Avvio della modalità di analisi automatica
/// Avvia l’analisi automatica con l’elenco di zone scelto nel dialog.
/// [chosenZones] dev’essere NON vuota e provenire da _openZoneSelectionDialog().
void _startAutomaticAnalysis(List<String> chosenZones) {
  // 1️⃣ Controlli preliminari
  if (_selectedPatientId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Seleziona un paziente prima di avviare l\'analisi automatica.',
        ),
      ),
    );
    return;
  }

  if (chosenZones.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Seleziona almeno una zona da analizzare.'),
      ),
    );
    return;
  }

  // 2️⃣ Reset completo di qualsiasi sessione precedente
  _resetAutomaticAnalysisState();

  // 3️⃣ Setup dello stato per la nuova analisi
  setState(() {
    _automaticZones            = List<String>.from(chosenZones);
    _isAutomaticAnalysisActive = true;
    _completedAutomaticZones   = [];
    _currentAutomaticZoneIndex = 0;
    _selectedZone              = _automaticZones.first;
  });

  // 4️⃣ Aggiorna immediatamente la UI di ComponentC (se già montato)
  _componentCKey.currentState?.updateZone(_selectedZone);

  // 5️⃣ Lancia l’analisi della prima zona in background
  unawaited(_performAnalysisForZone(_selectedZone));
}


  // Metodo richiamato al click su "Prossimo" nella modalità automatica
void _onAutomaticAnalysisNext() {
  final zoneLeaving = _automaticZones[_currentAutomaticZoneIndex];

  // 1️⃣ lancia la richiesta NON bloccante
  unawaited(_performAnalysisForZone(zoneLeaving));

  // 2️⃣ passa subito alla UI della prossima zona
  setState(() {
    _completedAutomaticZones.add(zoneLeaving);
    _currentAutomaticZoneIndex++;

    if (_currentAutomaticZoneIndex < _automaticZones.length) {
      _selectedZone = _automaticZones[_currentAutomaticZoneIndex];
      _componentCKey.currentState?.updateZone(_selectedZone);
      dev.log('[AA] ➡️ Passo a "$_selectedZone" (idx $_currentAutomaticZoneIndex)',
          name: 'AUTOMATIC_ANALYSIS');
    } else {
  _isAutomaticAnalysisActive = false;
  _showAutomaticSummary   = true;                 // ⬅️ mostra card finale
  dev.log('[AA] 🏁 Finiti gli step automatici → riepilogo', name: 'AUTOMATIC_ANALYSIS');
}
  });
}

Future<void> _downloadLogo() async {
  const logoUrl =
      'https://static.wixstatic.com/media/63b1fb_f4b32483fdcb4f39a1e294a497dd452a~mv2.png';

  try {
    final bytes = await http.readBytes(Uri.parse(logoUrl));     // bodyBytes
    setState(() => _logoBase64 = base64Encode(bytes));          // dart:convert
  } catch (_) {
    _logoBase64 = null;   // fallback: nessun logo
  }
}

  @override
  void initState() {
    super.initState();
    _fetchAnagrafiche();
    _downloadLogo();    
    // Inizializza le mappe per ciascuna zona con i dati di default per ogni tipo di analisi
    for (var zone in _allZones) {
      // Inizializza le immagini come lista vuota per ogni zona
      _imagesByZone[zone] = [];
      _resultsByZone[zone] = {};
      _analysisScoresByZone[zone] = {};
      for (var type in _analysisTypes) {
        _resultsByZone[zone]![type] = {
          "valore": 0,
          "descrizione": "Nessun dato disponibile.",
          "valutazione_professionale": "Nessuna valutazione disponibile.",
          "consigli": "Nessun consiglio disponibile.",
        };
        _analysisScoresByZone[zone]![type] = 0.0;
      }
    }
  }

  // Aggiorna le immagini per la zona corrente (le immagini sono condivise per tutti i tipi di analisi nella stessa zona)
  void _updateImages(String analysisType, List<String> imagesBase64) {
    setState(() {
      _imagesByZone[_selectedZone] = imagesBase64;
    });
  }

  void _onAnalysisSelected(String analysisType) {
    setState(() {
      _selectedAnalysis = analysisType;
    });
  }
void _generateAndDownloadExtendedReport() async {
  if (_selectedPatientId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seleziona un paziente prima di generare il report.')),
    );
    return;
  }

  final selectedAnagrafica = _getAnagraficaById(_selectedPatientId!);
  if (selectedAnagrafica == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Errore: impossibile trovare i dati del paziente.')),
    );
    return;
  }

  // Utilizza tutte le zone (o eventualmente solo quelle effettivamente analizzate)
  final reportHtml = generateExtendedReportHtml(
    anagrafica: selectedAnagrafica,
    allResults: _resultsByZone,
    allImages: _imagesByZone,
    logoBase64: _logoBase64,
  );

  try {
  final file = await _saveHtml(
      reportHtml,
      'report_esteso_${selectedAnagrafica.nome}_${selectedAnagrafica.cognome}.html');
  await OpenFile.open(file.path);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore durante la generazione del report: $e')),
    );
  }
}
// Card che guida lo scatto foto per la zona corrente
Widget _buildStepCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Colors.black, width: 1),
      ),
      elevation: 4,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentAutomaticZoneIndex + 1}/${_automaticZones.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text(
                  'Effettua le fotografie della zona: '
                  '${_automaticZones[_currentAutomaticZoneIndex]}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildOutlinedButton('Annulla', () {
                  setState(() {
                    _isAutomaticAnalysisActive = false;
                  });
                }),
                const SizedBox(width: 8),
                _buildOutlinedButton('Prossimo', _onAutomaticAnalysisNext),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Card di riepilogo analisi automatiche
Widget _buildSummaryCard() {
  final bool allDone   = _analysisInProgressPerZone.isEmpty;
  final bool allOK     = _failedAutomaticZones.isEmpty;
  final Color headerBg = allDone
      ? (allOK ? Colors.green[100]! : Colors.red[100]!)
      : Colors.transparent;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    child: Card(
                            color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: allDone
              ? (allOK ? Colors.green : Colors.red)
              : Colors.grey,
          width: 2,
        ),
      ),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Header stato
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4.0),
              color: headerBg,
              child: Text(
                allDone
                    ? (allOK
                        ? '✅ Tutte le analisi completate con successo'
                        : '⚠️ Analisi completate – alcune con errore')
                    : '⏳ Analisi in corso…',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            // Lista stato per zona
            SizedBox(
              height: 75,
              child: ListView.builder(
                itemCount: _automaticZones.length,
                itemBuilder: (context, i) {
                  final z = _automaticZones[i];
                  Widget icon;
                  if (_analysisInProgressPerZone.contains(z)) {
                    icon = const CupertinoActivityIndicator();
                  } else if (_failedAutomaticZones.contains(z)) {
                    icon = const Icon(Icons.error, color: Colors.red);
                  } else if (_completedAutomaticZones.contains(z)) {
                    icon = const Icon(Icons.check, color: Colors.green);
                  } else {
                    icon = const Icon(Icons.circle_outlined,
                        color: Colors.grey);
                  }
                  return ListTile(
                    dense: true,
                    leading: icon,
                    title: Text(z, style: const TextStyle(fontSize: 14)),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (allDone)                           // mostra scarica solo a fine lavori
                  _buildOutlinedButton('Scarica Report', () {
                    _generateAndDownloadExtendedReport();
                    setState(() => _showAutomaticSummary = false);
                  }),
                const SizedBox(width: 8),
                _buildOutlinedButton('Chiudi', () {
                  setState(() => _showAutomaticSummary = false);
                }),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// comodità: bottone bianco con bordo nero
Widget _buildOutlinedButton(String label, VoidCallback onPressed) {
  return ElevatedButton(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
      foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
      side: MaterialStateProperty.all(
          const BorderSide(color: Colors.black)),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      )),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
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

    // Recupera i dati relativi alla zona corrente e al tipo di analisi selezionato
    final currentResults = _resultsByZone[_selectedZone]!;
    final analysisResult = currentResults[_selectedAnalysis]!;
    final currentScores = _analysisScoresByZone[_selectedZone]!;

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

          // Pulsante per avviare l'Analisi Automatica
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              onPressed:  _isAnalyzing || _isAutomaticAnalysisActive
                  ? null
                  : _openZoneSelectionDialog,
              child: const Text(
                'Analisi Automatica',
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
    onPressed: _generateAndDownloadExtendedReport,
    child: const Text(
      'Genera Report Esteso',
      style: TextStyle(color: Colors.white),
    ),
  ),
),
          // Pulsante per l'Analisi manuale
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
          // Pulsante per generare il Report
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                      // Colonna sinistra: ComponentA e ComponentC
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
                                  key: _componentCKey,
                                  onAnagraficaSelected: _onPatientSelected,
                                  // Callback per aggiornare la zona corrente
                                  onZoneSelected: (zone) {
                                    setState(() {
                                      _selectedZone = zone;
                                         // pulisco eventuali immagini “residue” prima del rebuild
   _imagesByZone[zone] = List<String>.from(_imagesByZone[zone] ?? []);
                                    });
                                  },
                                  username: widget.username,
                                  password: widget.password,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Colonna centrale: Camera Gallery e messaggi per l'analisi automatica
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            color: Colors.white,
                          ),
                          child: Column(
                            children: [
                              // Blocca relativo alla modalità automatica
  // ───────── BLOCCO UI AUTOMATIC ANALYSIS / SUMMARY ─────────
  if (_isAutomaticAnalysisActive &&
      _currentAutomaticZoneIndex < _automaticZones.length)
    _buildStepCard(),          // <-- niente spread, singolo widget

  if (_showAutomaticSummary)
    _buildSummaryCard(),       // <-- idem
  // ───────── FINE BLOCCO UI ─────────────────────────────────

                              // Widget della Camera Gallery
                              Expanded(
                                child: CameraGalleryMobileWidget(
                                  key: ValueKey(_selectedZone),  
                                  onImagesUpdated: (List<String> imagesBase64) {
                                    _updateImages(_selectedAnalysis, imagesBase64);
                                  },
                                  // Le immagini vengono lette direttamente dalla lista associata alla zona corrente
                                  initialImages: _imagesByZone[_selectedZone] ?? [],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Colonna destra: ComponentB e ComponentD
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
                                        score: analysisResult["valore"] / 1.0 ?? 0.0,
                                        description: analysisResult["descrizione"] ?? "Nessun dato disponibile.",
                                        professionalEvaluation: analysisResult["valutazione_professionale"] ?? "Nessuna valutazione disponibile.",
                                        advice: analysisResult["consigli"] ?? "Nessun consiglio disponibile.",
                                      ),
                              ),
                              const Divider(thickness: 1, color: Colors.grey, height: 1),
                              Expanded(
                                flex: 1,
                                child: ComponentD(
                                  modelSrc: 'https://www.goldbitweb.com/api1/models/skin_with_base_color.glb',
                                  analysisData: currentScores,
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
  required String zone,
  required Map<String, Map<String, dynamic>> analysisResults,
  required List<String> images,
  required String? logoBase64,  
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
    .image-box {
      width: 100%;
      border: 1px solid #ddd;
      padding: 10px;
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
    }
    .image-box img {
      max-width: 200px;
      margin: 5px;
    }
  </style>
</head>
<body>
  <!-- ---------- HEADER con logo ---------- -->
  <div class="header">
        ${logoBase64 != null
            ? '<img src="data:image/png;base64,$logoBase64" '
              'style="max-width:140px;margin:0 auto 10px;display:block;" />'
            : ''}
    <h1>Report Analisi della Pelle</h1>
    <h3>${anagrafica.nome} ${anagrafica.cognome}</h3>
    <h4>Zona del corpo: $zone</h4>
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

  <div class="section">
    <div class="section-title">Immagini</div>
    ${images.isNotEmpty 
      ? '''
      <div class="image-box">
        ${images.map((imgBase64) => '<img src="$imgBase64" />').join()}
      </div>
      '''
      : '<p>Nessuna immagine catturata</p>'}
  </div>
    <!-- ---------- FOOTER con logo ---------- -->
  <div class="footer" style="margin-top:40px;">
            ${logoBase64 != null
            ? '<img src="data:image/png;base64,$logoBase64" '
              'style="max-width:140px;margin:0 auto 10px;display:block;" />'
            : ''}
  </div>
</body>
</html>
  ''';
}

String generateExtendedReportHtml({
  required Anagrafica anagrafica,
  required Map<String, Map<String, Map<String, dynamic>>> allResults,
  required Map<String, List<String>> allImages,
  required String? logoBase64,
}) {
  StringBuffer htmlBuffer = StringBuffer();

  htmlBuffer.write('''
<!DOCTYPE html>
<html>
<head>
  <title>Report Analisi Esteso</title>
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
      margin-bottom: 40px;
      border-bottom: 1px solid #ddd;
      padding-bottom: 20px;
    }
    .section-title {
      font-size: 22px;
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
    .image-box {
      width: 100%;
      border: 1px solid #ddd;
      padding: 10px;
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
    }
    .image-box img {
      max-width: 200px;
      margin: 5px;
    }
  </style>
</head>
<body>
            ${logoBase64 != null
            ? '<img src="data:image/png;base64,$logoBase64" '
              'style="max-width:140px;margin:0 auto 10px;display:block;" />'
            : ''}
  <div class="header">
    <h1>Report Analisi Esteso</h1>
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
''');

  // Cicla su ogni zona analizzata
  allResults.forEach((zone, analysisResults) {
    // Filtra i risultati validi (non di default)
    final validRows = analysisResults.entries.where((entry) {
      final result = entry.value;
      bool isDefault = result['valore'] == 0 &&
                       result['descrizione'] == "Nessun dato disponibile." &&
                       result['valutazione_professionale'] == "Nessuna valutazione disponibile." &&
                       result['consigli'] == "Nessun consiglio disponibile.";
      return !isDefault;
    }).toList();

    // Recupera le immagini per la zona (eventualmente vuote)
    final images = allImages[zone] ?? [];

    // Se non ci sono risultati validi e non sono presenti immagini, salta la zona
    if (validRows.isEmpty && images.isEmpty) {
      return;
    }

    htmlBuffer.write('''
  <div class="section">
    <div class="section-title">Zona: $zone</div>
    <div>
''');

    // Se ci sono risultati validi, scrivi la tabella
    if (validRows.isNotEmpty) {
      htmlBuffer.write('''
      <table class="table">
        <tr>
          <th>Tipo di Analisi</th>
          <th>Valore</th>
          <th>Descrizione</th>
          <th>Valutazione Professionale</th>
          <th>Consigli</th>
        </tr>
      ''');
      validRows.forEach((entry) {
        final type = entry.key;
        final result = entry.value;
        htmlBuffer.write('''
        <tr>
          <td>$type</td>
          <td>${result['valore']}</td>
          <td>${result['descrizione']}</td>
          <td>${result['valutazione_professionale']}</td>
          <td>${result['consigli']}</td>
        </tr>
        ''');
      });
      htmlBuffer.write('''
      </table>
      ''');
    }
    
    // Se sono presenti immagini, mostra il riquadro immagini
    if (images.isNotEmpty) {
      htmlBuffer.write('''
      <div class="image-box">
        ${images.map((img) => '<img src="$img" />').join()}
      </div>
      ''');
    }
    
    htmlBuffer.write('''
    </div>
  </div>
    ''');
  });

  htmlBuffer.write('''
  <!-- ---------- FOOTER con logo ---------- -->
  <div class="footer" style="margin-top:40px;">
            ${logoBase64 != null
            ? '<img src="data:image/png;base64,$logoBase64" '
              'style="max-width:140px;margin:0 auto 10px;display:block;" />'
            : ''}
  </div>
</body>
</html>
  ''');

  return htmlBuffer.toString();
}
