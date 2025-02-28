import 'package:flutter/material.dart';
import 'package:app_analisi_cute/backend_sdk/patients.dart';
import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';

class AnagraficaView extends StatelessWidget {
  final Anagrafica anagrafica;

  const AnagraficaView({Key? key, required this.anagrafica}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // Sfondo bianco per l'intero dialog
      title: const Text(
        'Dettagli Anagrafica',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colonna sinistra: due riquadri impilati verticalmente
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(
                    child: _buildInfoBox(
                      context,
                      'Dettagli Personali',
                      [
                        _buildDetailRow('Nome', anagrafica.nome),
                        _buildDetailRow('Cognome', anagrafica.cognome),
                        _buildDetailRow('Data di Nascita', anagrafica.birthDate),
                        _buildDetailRow('Indirizzo', anagrafica.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildInfoBox(
                      context,
                      'Dati Fisici',
                      [
                        _buildDetailRow('Peso', '${anagrafica.peso} kg'),
                        _buildDetailRow('Altezza', '${anagrafica.altezza} cm'),
                        _buildDetailRow('Genere', anagrafica.gender),
                        _buildDetailRow('Tipo di Pelle', anagrafica.skinTypes.join(', ')),
                        _buildDetailRow('Inestetismi', anagrafica.issues.join(', ')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Colonna centrale: contenente il modello 3D
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Sfondo bianco
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ThreeDModelViewer(
                  autoRotate: true,
                  modelUrl: anagrafica.gender.toLowerCase() == "donna"
                      ? "https://www.goldbitweb.com/api1/models/femalebody_with_base_color.glb"
                      : "https://www.goldbitweb.com/api1/models/malebody_with_base_color.glb",
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Colonna destra: riquadro con la lista delle analisi
            if (anagrafica.analysisHistory != null &&
                anagrafica.analysisHistory!.isNotEmpty)
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Sfondo bianco per la scheda storica
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Storico delle Analisi:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              children: anagrafica.analysisHistory!.map((analysis) {
                                final timestamp = analysis['timestamp'] as String;
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: ListTile(
                                    title: Text('Analisi del $timestamp'),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => _AnalysisDetailPopup(
                                          analysis: analysis['result']
                                              as Map<String, dynamic>,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildInfoBox(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white, // Sfondo bianco
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
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

  const _AnalysisDetailPopup({Key? key, required this.analysis})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Crea le righe della tabella a partire dalle entry dell'analisi
    List<DataRow> rows = [];
    analysis.forEach((tipoAnalisi, details) {
      if (tipoAnalisi != 'bod_zone' && details is! String) {
        rows.add(
          DataRow(cells: [
            DataCell(Text(tipoAnalisi)),
            DataCell(Text(details['valore'].toString())),
            DataCell(Text(details['descrizione'])),
            DataCell(Text(details['valutazione_professionale'])),
            DataCell(Text(details['consigli'])),
          ]),
        );
      }
    });

    return AlertDialog(
      backgroundColor: Colors.white, // Sfondo bianco
      title: const Text(
        'Dettagli Analisi',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text(
                'Tipo Analisi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Punteggio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Descrizione',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Valutazione',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Consigli',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: rows,
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowHeight: 60,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    );
  }
}
