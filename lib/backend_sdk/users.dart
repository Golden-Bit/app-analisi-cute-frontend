import 'dart:convert';
import 'package:http/http.dart' as http;

class Api4Sdk {
  final String baseUrl;
  final http.Client client;

  // Puoi passare l'URL base in fase di inizializzazione oppure utilizzare quello di default.
  Api4Sdk({this.baseUrl = 'https://www.goldbitweb.com/api4', http.Client? client})
      : client = client ?? http.Client();
  //Api4Sdk({this.baseUrl = 'http://127.0.0.1:8003', http.Client? client})
   //   : client = client ?? http.Client();

  // -----------------------------
  // Endpoint: Registrazione utente
  // -----------------------------
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

  // -----------------------------
  // Endpoint: Login utente
  // -----------------------------
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

  // -----------------------------
  // Endpoint: Aggiornamento utente
  // -----------------------------
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
// -----------------------------
// Endpoint: Visualizzazione dei dati personali dell'utente
// -----------------------------
Future<Map<String, dynamic>> getOwnData({
  required String username,
  required String password,
}) async {
  final url = Uri.parse('$baseUrl/me?username=$username&password=$password');
  final response = await client.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['data'];
  } else {
    throw Exception('Errore durante il recupero dei dati personali: ${response.body}');
  }
}
  // -----------------------------
  // Endpoint Admin: Cambio password arbitrario di un utente
  // -----------------------------
  Future<void> adminChangePassword({
    required String targetUsername,
    required String adminUsername,
    required String adminPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/admin/change_password/$targetUsername');
    final response = await client.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'admin_username': adminUsername,
        'admin_password': adminPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante il cambio password admin: ${response.body}');
    }
  }

  // -----------------------------
  // Endpoint Admin: Visualizzazione di tutti gli account
  // -----------------------------
  Future<List<dynamic>> getAllAccounts({
    required String adminUsername,
    required String adminPassword,
  }) async {
    final url = Uri.parse('$baseUrl/admin/accounts?admin_username=$adminUsername&admin_password=$adminPassword');
    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Errore durante il recupero degli account: ${response.body}');
    }
    final data = json.decode(response.body);
    return data['accounts'];
  }

  // -----------------------------
  // Endpoint Admin: Eliminazione di un utente
  // -----------------------------
  Future<void> adminDeleteUser({
    required String targetUsername,
    required String adminUsername,
    required String adminPassword,
  }) async {
    final url = Uri.parse('$baseUrl/admin/delete/$targetUsername?admin_username=$adminUsername&admin_password=$adminPassword');
    final response = await client.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'eliminazione dell\'utente: ${response.body}');
    }
  }
}
