import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisApi {
  final String baseUrl =
      "https://www.goldbitweb.com/api2"; // URL base per l'API
  //final String baseUrl = "http://127.0.0.1:8001"; // URL base per l'API

  final http.Client client;

  AnalysisApi({http.Client? client}) : client = client ?? http.Client();

  // Metodo per analizzare la pelle
  Future<Map<String, dynamic>> analyzeSkin({
    required String username,
    required String password,
    required List<String> images,
    required String patientId,
  }) async {
    // Costruzione dell'URL con i parametri della query string
    final url = Uri.parse('$baseUrl/analyze_skin').replace(queryParameters: {
      'username': username,
      'password': password,
    });

    try {
      // Effettua una richiesta POST all'API
      final response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'patient_id': patientId,
          'images': images, // Lista delle immagini codificate in Base64
        }),
      );

      // Decodifica UTF-8 e restituisce il risultato come Map
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonResponse =
            json.decode(decodedBody) as Map<String, dynamic>;
        return jsonResponse['result'] as Map<String,
            dynamic>; // Restituisce i risultati sotto la chiave `result`
      } else {
        throw Exception(
          'Errore durante l\'analisi: ${response.statusCode}, ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Errore di comunicazione con il server: $e');
    }
  }

  // Endpoint admin per storico analisi utente con paginazione
  Future<Map<String, dynamic>> getAdminUserAnalysisHistory({
    required String targetUsername,
    required String adminUsername,
    required String adminPassword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final url =
        Uri.parse('$baseUrl/admin/users/$targetUsername/analysis_history')
            .replace(
      queryParameters: {
        'admin_username': adminUsername,
        'admin_password': adminPassword,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Errore durante il recupero dello storico analisi: ${response.statusCode}, ${response.body}',
      );
    }

    final decodedBody = utf8.decode(response.bodyBytes);
    final Map<String, dynamic> payload =
        json.decode(decodedBody) as Map<String, dynamic>;
    return Map<String, dynamic>.from(payload['data'] ?? {});
  }
}
