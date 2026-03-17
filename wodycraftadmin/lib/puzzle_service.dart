import 'dart:convert';
import 'package:http/http.dart' as http;

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
<<<<<<< HEAD
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      prix: (json['prix'] is int)
          ? (json['prix'] as int).toDouble()
          : (json['prix']?.toDouble() ?? 0.0),
      categorie: json['categorie'] ?? '',
=======
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      // Gestion robuste du type double
      prix:
          double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      categorie: json['categorie']?.toString() ?? '',
>>>>>>> 4b43d1046d4bbb01c7e4912ab4698270264a2ba1
    );
  }
}

class PuzzleService {
<<<<<<< HEAD
  // Utilisation de 10.0.2.2 pour l'émulateur Android, localhost pour le web
  final String apiUrl = "http://localhost/woodycraft/public/api/puzzles";
=======
  // Utilisez '10.0.2.2' pour l'émulateur Android, 'localhost' pour le Web/iOS
  final String apiUrl = "http://groupe2.lycee.local/api/puzzles";
>>>>>>> 4b43d1046d4bbb01c7e4912ab4698270264a2ba1

  Future<List<Puzzle>> fetchPuzzles() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Puzzle.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load puzzles');
    }
  }

  Future<Puzzle> createPuzzle(
    String nom,
    String description,
    String image,
    double prix,
    String categorie,
  ) async {
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
      throw Exception('Failed to create puzzle');
    }
  }
}
