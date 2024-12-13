import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';

class AnagraficaView extends StatelessWidget {
  final Anagrafica anagrafica; // Oggetto anagrafica completo

  const AnagraficaView({Key? key, required this.anagrafica}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Dettagli Anagrafica',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8, // Imposta una larghezza personalizzata
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Nome', anagrafica.nome),
              _buildDetailRow('Cognome', anagrafica.cognome),
              _buildDetailRow('Data di Nascita', anagrafica.birthDate),
              _buildDetailRow('Indirizzo', anagrafica.address),
              _buildDetailRow('Peso', '${anagrafica.peso} kg'),
              _buildDetailRow('Altezza', '${anagrafica.altezza} cm'),
              _buildDetailRow('Genere', anagrafica.gender),
              _buildDetailRow('Tipo di Pelle', anagrafica.skinTypes.join(', ')),
              _buildDetailRow('Inestetismi', anagrafica.issues.join(', ')),
              const SizedBox(height: 16),
              if (anagrafica.analysisHistory != null &&
                  anagrafica.analysisHistory!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storico delle Analisi:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...anagrafica.analysisHistory!.map((analysis) {
                      final timestamp = analysis['timestamp'] as String;
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2), // Bordi con raggio 2
                        ),
                        child: ListTile(
                          title: Text('Analisi del $timestamp'),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => _AnalysisDetailPopup(
                                analysis: analysis['result'] as Map<String, dynamic>,
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // Margini personalizzati
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)), // Popup con raggio 2
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisDetailPopup extends StatelessWidget {
  final Map<String, dynamic> analysis;

  const _AnalysisDetailPopup({Key? key, required this.analysis}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Dettagli Analisi',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // Imposta una larghezza personalizzata
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(2),
            },
            border: TableBorder.all(color: Colors.grey, width: 1),
            children: analysis.entries.map((entry) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry.value.toString()),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // Margini personalizzati
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)), // Popup con raggio 2
    );
  }
}
