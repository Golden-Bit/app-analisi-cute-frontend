import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:uuid/uuid.dart';

class NewAnagraficaPage extends StatefulWidget {
  final String username;
  final String password;

  const NewAnagraficaPage({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  _NewAnagraficaPageState createState() => _NewAnagraficaPageState();
}

class _NewAnagraficaPageState extends State<NewAnagraficaPage> {
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  String _gender = 'Donna'; // Default gender value

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
    for (var type in skinTypes) {
      selectedSkinTypes[type] = false;
    }
    for (var issue in issues) {
      selectedIssues[issue] = false;
    }
  }

  Future<void> _saveAnagrafica() async {
    final selectedSkinTypesList =
        selectedSkinTypes.entries.where((e) => e.value).map((e) => e.key).toList();
    final selectedIssuesList =
        selectedIssues.entries.where((e) => e.value).map((e) => e.key).toList();

    try {
      var uuid = Uuid();
      final newAnagrafica = Anagrafica(
        id: uuid.v4(),
        nome: _nomeController.text,
        cognome: _cognomeController.text,
        birthDate: _birthDateController.text,
        address: _addressController.text,
        peso: double.tryParse(_pesoController.text) ?? 0,
        altezza: double.tryParse(_altezzaController.text) ?? 0,
        gender: _gender,
        skinTypes: selectedSkinTypesList,
        issues: selectedIssuesList,
        analysisHistory: [],
      );

      // Call SDK to save the anagrafica
      await _api.createAnagrafica(widget.username, widget.password, newAnagrafica);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anagrafica salvata con successo!')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nuovo Paziente',
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
              onPressed: _saveAnagrafica,
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
            const SizedBox(height: 16),
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
