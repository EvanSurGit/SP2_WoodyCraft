import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

// ─── LES MODÈLES DE DONNÉES ────────────────────────────────────────────────

class Categorie {
  final int id;
  final String nom; 

  Categorie({required this.id, required this.nom});

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'],
      nom: json['libelle'] ?? 'Sans nom', 
    );
  }
}

class StockThresholds {
  static const int rupture = 0; // Rouge  : rupture de stock
  static const int faible = 5;  // Orange : stock faible
}

class Puzzle {
  final int id;
  final String nom;
  final String description;
  final String pathImage; 
  final double prix;
  final int stock;
  final int? categorieId;

  const Puzzle({
    required this.id,
    required this.nom,
    required this.description,
    required this.pathImage,
    required this.prix,
    required this.stock,
    this.categorieId,
  });

  // Utilisé pour la gestion des stocks (mise à jour optimiste)
  Puzzle copyWith({
    int? id,
    String? nom,
    String? description,
    String? image,
    double? prix,
    int? stock,
    int? categorieId,
  }) {
    return Puzzle(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      pathImage: image ?? this.pathImage,
      prix: prix ?? this.prix,
      stock: stock ?? this.stock,
      categorieId: categorieId ?? this.categorieId,
    );
  }

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pathImage: json['path_image']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      categorieId: int.tryParse(json['categorie_id'].toString()),
    );
  }

  String get imageUrl => "http://groupe2.lycee.local/$pathImage";
}

class PuzzleAlerte {
  final int id;
  final String nom;
  final int stock;

  const PuzzleAlerte({
    required this.id,
    required this.nom,
    required this.stock,
  });

  factory PuzzleAlerte.fromJson(Map<String, dynamic> json) {
    return PuzzleAlerte(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }
}

// ─── LE SERVICE (API) ──────────────────────────────────────────────────────

class PuzzleService {
  final String baseUrl = "http://groupe2.lycee.local/api";

  // 1. Récupérer tous les puzzles
  Future<List<Puzzle>> fetchPuzzles() async {
    final response = await http.get(Uri.parse('$baseUrl/puzzles'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Puzzle.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de récupération des puzzles: ${response.body}');
    }
  }

  // 2. Récupérer toutes les catégories
  Future<List<Categorie>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/cat'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Categorie.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de récupération des catégories: ${response.body}');
    }
  }

  // 3. Créer un puzzle
  Future<void> createPuzzle(String nom, String description, String image, double prix, int stock, int categorieId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/puzzles'),
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
    if (response.statusCode != 201 && response.statusCode != 200) throw Exception('Échec création: ${response.body}');
  }

  // 4. Modifier un puzzle
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

  // 5. Supprimer un puzzle
  Future<void> deletePuzzle(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/puzzles/$id'));
    if (response.statusCode != 200) throw Exception('Échec suppression: ${response.body}');
  }

  // 6. Alertes : Stock bas
  Future<List<PuzzleAlerte>> fetchStockBas() async {
    final res = await http.get(Uri.parse('$baseUrl/puzzles/alertes/stock-bas'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => PuzzleAlerte.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchStockBas – Erreur ${res.statusCode}: ${res.body}');
  }

  // 7. Alertes : Ruptures
  Future<List<PuzzleAlerte>> fetchRuptures() async {
    final res = await http.get(Uri.parse('$baseUrl/puzzles/alertes/ruptures'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => PuzzleAlerte.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchRuptures – Erreur ${res.statusCode}: ${res.body}');
  }

  // 8. Modifier UNIQUEMENT le stock
  Future<Puzzle> updateStock(int id, int nouveauStock) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/puzzles/$id/stock'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'stock': nouveauStock}),
    );
    if (res.statusCode == 200) {
      return Puzzle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    developer.log('updateStock erreur: ${res.body}', name: 'PuzzleService');
    throw Exception('updateStock – Erreur ${res.statusCode}: ${res.body}');
  }
}