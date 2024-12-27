import 'dart:convert';
import 'package:http/http.dart' as http;

class Api4Sdk {
  final String baseUrl;
  final http.Client client;

  Api4Sdk({this.baseUrl = 'https://www.goldbitweb.com/api4', http.Client? client})
      : client = client ?? http.Client();

  // Modello per la registrazione di un utente
  Future<void> registerUser({
    required String username,
    required String password,
    Map<String, String>? metadata,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'metadata': metadata ?? {},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante la registrazione: ${response.body}');
    }
  }

  // Modello per eseguire il login
  Future<void> loginUser({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante il login: ${response.body}');
    }
  }

  // Modello per aggiornare un utente
  Future<void> updateUser({
    required String username,
    String? newPassword,
    Map<String, String>? metadata,
  }) async {
    final url = Uri.parse('$baseUrl/update/$username');
    final response = await client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        if (newPassword != null) 'password': newPassword,
        if (metadata != null) 'metadata': metadata,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'aggiornamento utente: ${response.body}');
    }
  }
}
