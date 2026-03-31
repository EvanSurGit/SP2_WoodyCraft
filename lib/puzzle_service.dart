import 'dart:convert';
import 'package:http/http.dart' as http;
// Import pour détecter la plateforme

class Puzzle {
  final int id;
  final String nom;
  final String description;
  final String image;
  final double prix;
  final String categorie;

  Puzzle({
    required this.id,
    required this.nom,
    required this.description,
    this.image = '',
    this.prix = 0.0,
    this.categorie = '',
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      // Gestion robuste du type double
      prix:
          double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      categorie: json['categorie']?.toString() ?? '',
    );
  }
}

class PuzzleService {
  // Utilisez '10.0.2.2' pour l'émulateur Android, 'localhost' pour le Web/iOS
  final String apiUrl = "http://localhost/SP2_Api/public/api/puzzles";

  Future<List<Puzzle>> fetchPuzzles() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Puzzle.fromJson(item)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Impossible de contacter l\'API: $e');
    }
  }

  Future<Puzzle> createPuzzle(String nom, String description, String image,
      double prix, String categorie) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Échec de la création: ${response.body}');
    }
  }
}