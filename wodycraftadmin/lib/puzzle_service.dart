import 'dart:convert';
import 'package:http/http.dart' as http;

// --- LES MODÈLES DE DONNÉES (Pour matcher ton API Laravel) ---

class Categorie {
  final int id;
  final String nom; // On garde 'nom' dans Flutter, mais on lit 'libelle' depuis l'API

  Categorie({required this.id, required this.nom});

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'],
      nom: json['libelle'] ?? 'Sans nom', // J'ai vu que ton API envoie 'libelle'
    );
  }
}

class Puzzle {
  final int id;
  final String nom;
  final String description;
  final String pathImage; // On récupère le chemin brut (ex: images/puzzles/rex.png)
  final double prix;
  final int stock;
  final int? categorieId;

  Puzzle({
    required this.id,
    required this.nom,
    required this.description,
    required this.pathImage,
    required this.prix,
    required this.stock,
    this.categorieId,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      // J'ai vu que ton API envoie 'path_image'
      pathImage: json['path_image']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      categorieId: int.tryParse(json['categorie_id'].toString()),
    );
  }

  // Petit helper pour construire l'URL complète de l'image pour l'afficher
  String get imageUrl => "http://groupe2.lycee.local/$pathImage";
}


// --- LE SERVICE (Pour appeler ton API) ---

class PuzzleService {
  final String baseUrl = "http://groupe2.lycee.local/api";

  // Récupérer tous les puzzles
  Future<List<Puzzle>> fetchPuzzles() async {
    final response = await http.get(Uri.parse('$baseUrl/puzzles'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Puzzle.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de récupération des puzzles: ${response.body}');
    }
  }

  // Récupérer toutes les catégories (J'ai vu que ton URL est /cat)
  Future<List<Categorie>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/cat'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Categorie.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de récupération des catégories: ${response.body}');
    }
  }

  // --- Les autres méthodes CRUD sont déjà prêtes mais on ne les utilise pas aujourd'hui ---
  
  Future<void> createPuzzle(String nom, String description, String image, double prix, int stock, int categorieId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/puzzles'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'path_image': image, // Ton backend attend 'path_image'
        'prix': prix,
        'stock': stock,
        'categorie_id': categorieId,
      }),
    );
    if (response.statusCode != 201) throw Exception('Échec création: ${response.body}');
  }

  Future<void> updatePuzzle(int id, String nom, String description, String image, double prix, int stock, int categorieId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/puzzles/$id'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'path_image': image,
        'prix': prix,
        'stock': stock,
        'categorie_id': categorieId,
      }),
    );
    if (response.statusCode != 200) throw Exception('Échec modification: ${response.body}');
  }

  Future<void> deletePuzzle(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/puzzles/$id'));
    if (response.statusCode != 200) throw Exception('Échec suppression: ${response.body}');
  }
}