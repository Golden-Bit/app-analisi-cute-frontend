import 'dart:convert';
import 'package:http/http.dart' as http;

// Modello per l'anagrafica
class Anagrafica {
  String? id;
  String nome;
  String cognome;
  String birthDate;
  String address;
  double peso;
  double altezza;
  String gender;
  List<String> skinTypes;
  List<String> issues;
  List<Map<String, dynamic>> analysisHistory;

  Anagrafica({
    this.id,
    required this.nome,
    required this.cognome,
    required this.birthDate,
    required this.address,
    required this.peso,
    required this.altezza,
    required this.gender,
    required this.skinTypes,
    required this.issues,
    required this.analysisHistory,
  });

  // Metodo per creare un'istanza da JSON
  factory Anagrafica.fromJson(Map<String, dynamic> json) {
    return Anagrafica(
      id: json['id'],
      nome: json['nome'],
      cognome: json['cognome'],
      birthDate: json['birth_date'],
      address: json['address'],
      peso: (json['peso'] as num).toDouble(),
      altezza: (json['altezza'] as num).toDouble(),
      gender: json['gender'],
      skinTypes: List<String>.from(json['skin_types']),
      issues: List<String>.from(json['issues']),
      analysisHistory: List<Map<String, dynamic>>.from(json['analysis_history'])
    );
  }

  // Metodo per convertire un'istanza in JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'birth_date': birthDate,
      'address': address,
      'peso': peso,
      'altezza': altezza,
      'gender': gender,
      'skin_types': skinTypes,
      'issues': issues,
    };
  }
}

class AnagraficaApi {
  final String baseUrl;

  AnagraficaApi({this.baseUrl = "https://www.goldbitweb.com/api3"});

  // Recupera tutte le anagrafiche
  Future<List<Anagrafica>> getAnagrafiche() async {
    final url = Uri.parse('$baseUrl/anagrafiche');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Anagrafica.fromJson(json)).toList();
    } else {
      throw Exception('Errore durante il recupero delle anagrafiche: ${response.body}');
    }
  }

  // Crea una nuova anagrafica
  Future<Anagrafica> createAnagrafica(Anagrafica anagrafica) async {
    final url = Uri.parse('$baseUrl/create_anagrafiche');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(anagrafica.toJson()),
    );

    if (response.statusCode == 200) {
      return Anagrafica.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante la creazione dell\'anagrafica: ${response.body}');
    }
  }

  // Aggiorna un'anagrafica esistente
  Future<Anagrafica> updateAnagrafica(String id, Anagrafica anagrafica) async {
    final url = Uri.parse('$baseUrl/anagrafiche/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(anagrafica.toJson()),
    );

    if (response.statusCode == 200) {
      return Anagrafica.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante l\'aggiornamento dell\'anagrafica: ${response.body}');
    }
  }

  // Elimina un'anagrafica esistente
  Future<void> deleteAnagrafica(String id) async {
    final url = Uri.parse('$baseUrl/anagrafiche/$id');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'eliminazione dell\'anagrafica: ${response.body}');
    }
  }
}
