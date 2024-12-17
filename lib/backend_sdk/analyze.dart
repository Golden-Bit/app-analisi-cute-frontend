import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisApi {
  final String baseUrl = "http://34.13.153.241:8001"; // Modificato per riflettere la porta corretta

  AnalysisApi();

  Future<Map<String, dynamic>> analyzeSkin({
    required List<String> images,
    required String patient_id,
  }) async {
    final url = Uri.parse('$baseUrl/analyze_skin'); // Endpoint aggiornato

    try {
      // Effettua una richiesta POST all'API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'patient_id': patient_id,
          'images': images, // Modello aggiornato per includere solo le immagini
        }),
      );

      // Decodifica UTF-8 e restituisce il risultato come Map
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse = json.decode(decodedBody) as Map<String, dynamic>;
        return jsonResponse['result'] as Map<String, dynamic>; // Restituisce il risultato dalla chiave `result`
      } else {
        throw Exception(
          'Error during analysis: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error communicating with the server: $e');
    }
  }
}
