import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Modèle Puzzle
class Puzzle {
  final int id;
  final String nom;
  final String description;
  final String image;
  final double prix;
  final String categorie;
  final int stock;

  Puzzle({
    required this.id,
    required this.nom,
    required this.description,
    this.image = '',
    this.prix = 0.0,
    this.categorie = '',
    this.stock = 0,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      categorie: json['categorie']?.toString() ?? '',
      stock: json['stock'] ?? 0,
    );
  }
}

// Service API Puzzle — toutes les requêtes incluent le token Bearer
class PuzzleService {
  static const String _baseUrl = 'http://groupe2.lycee.local/api';
  static const String _puzzlesUrl = '$_baseUrl/puzzles';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Récupère les headers avec le token d'authentification
  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Récupère la liste complète des puzzles
  Future<List<Puzzle>> fetchPuzzles() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse(_puzzlesUrl), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Puzzle.fromJson(item)).toList();
    } else {
      throw Exception('Erreur ${response.statusCode} : impossible de charger les puzzles');
    }
  }

  // Crée un nouveau puzzle
  Future<Puzzle> createPuzzle(
    String nom,
    String description,
    String image,
    double prix,
    String categorie,
  ) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(_puzzlesUrl),
      headers: headers,
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'image': image,
        'prix': prix,
        'categorie': categorie,
      }),
    );

    if (response.statusCode == 201) {
      return Puzzle.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur ${response.statusCode} : impossible de créer le puzzle');
    }
  }

  // Met à jour le stock d'un puzzle (PATCH /puzzles/{id}/stock)
  Future<void> updateStock(int id, int stock) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$_puzzlesUrl/$id/stock'),
      headers: headers,
      body: jsonEncode({'stock': stock}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode} : impossible de mettre à jour le stock');
    }
  }

  // Supprime un puzzle
  Future<void> deletePuzzle(int id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$_puzzlesUrl/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erreur ${response.statusCode} : impossible de supprimer le puzzle');
    }
  }
}