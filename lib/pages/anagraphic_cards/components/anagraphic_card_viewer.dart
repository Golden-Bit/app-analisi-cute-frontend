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
        child: Column(
          children: [
            // Colonna superiore: due blocchi di testo + Modello 3D con stessa altezza
            Expanded(
              flex: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBox(
                    context, // Passa il contesto corrente
                    'Dettagli Personali',
                    [
                      _buildDetailRow('Nome', anagrafica.nome),
                      _buildDetailRow('Cognome', anagrafica.cognome),
                      _buildDetailRow('Data di Nascita', anagrafica.birthDate),
                      _buildDetailRow('Indirizzo', anagrafica.address),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _buildInfoBox(
                    context, // Passa il contesto corrente
                    'Dati Fisici',
                    [
                      _buildDetailRow('Peso', '${anagrafica.peso} kg'),
                      _buildDetailRow('Altezza', '${anagrafica.altezza} cm'),
                      _buildDetailRow('Genere', anagrafica.gender),
                      _buildDetailRow('Tipo di Pelle', anagrafica.skinTypes.join(', ')),
                      _buildDetailRow('Inestetismi', anagrafica.issues.join(', ')),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Modello 3D
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.35,
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Colonna inferiore: Storico delle analisi con altezza aumentata
            if (anagrafica.analysisHistory != null &&
                anagrafica.analysisHistory!.isNotEmpty)
              Expanded(
                flex: 6,
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
                                  //color: Colors.white, // Sfondo bianco per ogni card
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

  Widget _buildInfoBox(BuildContext context, String title, List<Widget> children) {
    return Expanded(
      flex: 2,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.35,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white, // Sfondo bianco
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(2),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
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
    // Crea le righe della tabella a partire dalle entry dell'analisi (analysis['result'])
    List<DataRow> rows = [];
    analysis.forEach((tipoAnalisi, details) {
      rows.add(
        DataRow(cells: [
          DataCell(Text(tipoAnalisi)),
          DataCell(Text(details['valore'].toString())),
          DataCell(Text(details['descrizione'])),
          DataCell(Text(details['valutazione_professionale'])),
          DataCell(Text(details['consigli'])),
        ]),
      );
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

