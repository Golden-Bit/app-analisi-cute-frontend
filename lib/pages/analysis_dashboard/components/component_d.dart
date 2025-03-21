import 'package:app_analisi_cute/pages/analysis_dashboard/components/sub_components/3dmodel_viewer.dart';
import 'package:flutter/material.dart';

class ComponentD extends StatelessWidget {
  final String modelSrc; // Path to the 3D model
  final Map<String, int> analysisData; // Analysis data for all types

  const ComponentD({Key? key, required this.modelSrc, required this.analysisData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Padding around the component
      child: Column(
        children: [
          // 3D Model Viewer at the top
          Expanded(
            flex: 3,
            child: ThreeDModelViewer(
              autoRotate: true,
              modelUrl: modelSrc,
            ), // Replace with the actual 3D model viewer
          ),
          const SizedBox(height: 12), // Spacing between sections
          // Unified analysis data table
          Expanded(
            flex: 2,
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Padding around the table
                  child: Table(
                    defaultColumnWidth: const FlexColumnWidth(1),
                    children: _generateTableRows(analysisData),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generate rows for the analysis data table
  List<TableRow> _generateTableRows(Map<String, int> data) {
    List<TableRow> rows = [];
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i += 3) {
      rows.add(
        TableRow(
          children: List.generate(3, (index) {
            if (i + index < keys.length) {
              final key = keys[i + index];
              final value = data[key] ?? 0; // Default to zero if not measured
return Padding(
  padding: const EdgeInsets.all(4.0),
  child: Container(
    height: 60, // Altezza fissa per tutte le celle (modifica questo valore se necessario)
    decoration: BoxDecoration(
      border: Border.all(
        color: _getColorForValue(key, value),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Titolo allineato in alto
        Align(
          alignment: Alignment.topCenter,
          child: Text(
            key,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        // Valore allineato in basso
        Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            (value/100).toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  ),
);


            } else {
              // Empty cells to balance the table
              return const SizedBox.shrink();
            }
          }),
        ),
      );
    }
    return rows;
  }

Color _getColorForValue(String key, int value) {
  if (key.toLowerCase() == "densità pilifera") {
    // Inversione: valori bassi -> verde, alti -> rosso
    if (value <= 40) {
      return Colors.green;
    } else if (value > 40 && value < 70) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  } else {
    // Logica standard per le altre analisi
    if (value <= 40) {
      return Colors.red;
    } else if (value > 40 && value < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
}
