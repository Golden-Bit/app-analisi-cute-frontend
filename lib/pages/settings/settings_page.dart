import 'package:flutter/material.dart';

class ImpostazioniCentroPage extends StatefulWidget {
  const ImpostazioniCentroPage({Key? key}) : super(key: key);

  @override
  _ImpostazioniCentroPageState createState() => _ImpostazioniCentroPageState();
}

class _ImpostazioniCentroPageState extends State<ImpostazioniCentroPage> {
  // Controller con valori iniziali di fantasia
  final TextEditingController _nomeCentroController =
      TextEditingController(text: 'Centro Estetico Bellezza');
  final TextEditingController _indirizzoController =
      TextEditingController(text: 'Via Roma 123, Milano');
  final TextEditingController _numDipendentiController =
      TextEditingController(text: '15');
  final TextEditingController _telefonoController =
      TextEditingController(text: '+39 012 3456 7890');
  final TextEditingController _mailController =
      TextEditingController(text: 'info@centrobellezza.com');
  final TextEditingController _nomeResponsabileController =
      TextEditingController(text: 'Mario Rossi');
  final TextEditingController _orariAperturaController =
      TextEditingController(text: '09:00');
  final TextEditingController _orariChiusuraController =
      TextEditingController(text: '19:00');

  void _saveSettings() {
    // Logica per salvare le impostazioni
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impostazioni salvate con successo!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Impostazioni Centro',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.4),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'SALVA',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
              'Modifica Informazioni Centro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField('Nome del Centro', _nomeCentroController),
            _buildTextField('Indirizzo', _indirizzoController),
            _buildTextField('Numero Dipendenti', _numDipendentiController),
            _buildTextField('Telefono', _telefonoController),
            _buildTextField('Email', _mailController),
            _buildTextField('Nome e Cognome Responsabile', _nomeResponsabileController),
            _buildTextField('Orario Apertura', _orariAperturaController),
            _buildTextField('Orario Chiusura', _orariChiusuraController),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2), // Bordi con raggio 2
          ),
        ),
      ),
    );
  }
}
