import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';

class EditAnagraficaPage extends StatefulWidget {
  final Anagrafica anagrafica;

  const EditAnagraficaPage({Key? key, required this.anagrafica}) : super(key: key);

  @override
  _EditAnagraficaPageState createState() => _EditAnagraficaPageState();
}

class _EditAnagraficaPageState extends State<EditAnagraficaPage> {
  late TextEditingController _nomeController;
  late TextEditingController _cognomeController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  late TextEditingController _pesoController;
  late TextEditingController _altezzaController;
  String _gender = 'Donna';

  final List<String> skinTypes = [
    'Pelle secca',
    'Pelle grassa',
    'Pelle asfittica',
    'Pelle neutra',
    'Pelle mista grassa',
    'Pelle sensibile',
  ];

  final List<String> issues = [
    'Disidratata',
    'Discromie',
    'Acne attiva',
    'Pelle cadente',
    'Arrossata',
    'Impura',
    'Ruvida',
    'Colore della pelle non uniforme',
    'Pori dilatati',
    'Punti neri',
    'Rughe contorno occhi',
    'Rughe lineari',
    'Pallida',
    'Grassa',
    'Ruga sottile',
    'Sensitive',
  ];

  final Map<String, bool> selectedSkinTypes = {};
  final Map<String, bool> selectedIssues = {};

  final AnagraficaApi _api = AnagraficaApi(); // SDK instance

  @override
  void initState() {
    super.initState();
    // Popola i controller con i valori esistenti
    _nomeController = TextEditingController(text: widget.anagrafica.nome);
    _cognomeController = TextEditingController(text: widget.anagrafica.cognome);
    _birthDateController = TextEditingController(text: widget.anagrafica.birthDate);
    _addressController = TextEditingController(text: widget.anagrafica.address);
    _pesoController = TextEditingController(text: widget.anagrafica.peso.toString());
    _altezzaController = TextEditingController(text: widget.anagrafica.altezza.toString());
    _gender = widget.anagrafica.gender;

    // Popola i tipi di pelle e inestetismi esistenti
    for (var type in skinTypes) {
      selectedSkinTypes[type] = widget.anagrafica.skinTypes.contains(type);
    }
    for (var issue in issues) {
      selectedIssues[issue] = widget.anagrafica.issues.contains(issue);
    }
  }

  Future<void> _updateAnagrafica() async {
    final selectedSkinTypesList = selectedSkinTypes.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final selectedIssuesList = selectedIssues.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    try {
      final updatedAnagrafica = Anagrafica(
        id: widget.anagrafica.id,
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        birthDate: _birthDateController.text,
        address: _addressController.text,
        peso: double.tryParse(_pesoController.text) ?? 0,
        altezza: double.tryParse(_altezzaController.text) ?? 0,
        gender: _gender,
        skinTypes: selectedSkinTypesList,
        issues: selectedIssuesList,
        analysisHistory: widget.anagrafica.analysisHistory,
      );

      await _api.updateAnagrafica(widget.anagrafica.id!, updatedAnagrafica);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anagrafica aggiornata con successo!')),
      );

      Navigator.pop(context, updatedAnagrafica);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifica Paziente',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _updateAnagrafica,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: const Text(
                'Salva',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informazioni Personali:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cognomeController,
                    decoration: const InputDecoration(
                      labelText: 'Cognome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(
                      labelText: 'Data di nascita',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _birthDateController.text =
                            date.toLocal().toString().split(' ')[0];
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Indirizzo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Sesso',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Donna', child: Text('Donna')),
                DropdownMenuItem(value: 'Uomo', child: Text('Uomo')),
                DropdownMenuItem(value: 'Altro', child: Text('Altro')),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Dati Fisici:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesoController,
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _altezzaController,
                    decoration: const InputDecoration(
                      labelText: 'Altezza (cm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Tipo di Pelle:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: skinTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: selectedSkinTypes[type]!,
                  onSelected: (selected) {
                    setState(() {
                      selectedSkinTypes[type] = selected;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipologia di Inestetismo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: issues.map((issue) {
                return FilterChip(
                  label: Text(issue),
                  selected: selectedIssues[issue]!,
                  onSelected: (selected) {
                    setState(() {
                      selectedIssues[issue] = selected;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
