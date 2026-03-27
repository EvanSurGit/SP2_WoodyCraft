import 'dart:convert';
import 'dart:developer' as developer;
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

// ─── SEUILS D'ALERTE ─────────────────────────────────────────────────────────
class StockThresholds {
  static const int rupture = 0; // Rouge  : rupture de stock
  static const int faible = 5;  // Orange : stock faible
}

// ─── MODÈLE PUZZLE ───────────────────────────────────────────────────────────
class Puzzle {
  final int? id;
  final String nom;
  final String description;
  final String pathImage; // On récupère le chemin brut (ex: images/puzzles/rex.png)
  final double prix;
  final int stock;
  final int? categorieId;

  const Puzzle({
    this.id,
    required this.nom,
    required this.description,
    required this.pathImage,
    required this.prix,
    required this.stock,
    this.categorieId,
  });

  // Utilisé dans _updateLocal() de stock_management_page.dart
  Puzzle copyWith({
    int? id,
    String? nom,
    String? description,
    String? image,
    double? prix,
    int? stock,
  }) {
    return Puzzle(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      image: image ?? this.image,
      prix: prix ?? this.prix,
      stock: stock ?? this.stock,
    );
  }

  // Laravel renvoie "path_image" ou "image" selon l'endpoint
  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'],
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
// ─── MODÈLE PUZZLE ALERTE ────────────────────────────────────────────────────
// Modèle simplifié : on n'a besoin que de l'id, du nom et du stock pour les alertes
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

// ─── SERVICE API ─────────────────────────────────────────────────────────────
class PuzzleService {
  final String _base = 'http://groupe2.lycee.local/api';

  String get _puzzlesUrl => '$_base/puzzles';

  // ── GET /api/puzzles ──────────────────────────────────────────────────────
  Future<List<Puzzle>> fetchPuzzles() async {
    final res = await http.get(Uri.parse(_puzzlesUrl));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchPuzzles – Erreur ${res.statusCode}: ${res.body}');
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
  // ── GET /api/puzzles/alertes/stock-bas ────────────────────────────────────
  Future<List<PuzzleAlerte>> fetchStockBas() async {
    final res = await http.get(Uri.parse('$_puzzlesUrl/alertes/stock-bas'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => PuzzleAlerte.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchStockBas – Erreur ${res.statusCode}: ${res.body}');
  }

  // ── GET /api/puzzles/alertes/ruptures ─────────────────────────────────────
  Future<List<PuzzleAlerte>> fetchRuptures() async {
    final res = await http.get(Uri.parse('$_puzzlesUrl/alertes/ruptures'));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => PuzzleAlerte.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('fetchRuptures – Erreur ${res.statusCode}: ${res.body}');
  }

  // ── PATCH /api/puzzles/{id}/stock ─────────────────────────────────────────
  Future<Puzzle> updateStock(int id, int nouveauStock) async {
    final res = await http.patch(
      Uri.parse('$_puzzlesUrl/$id/stock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'stock': nouveauStock}),
    );
    if (res.statusCode == 200) {
      return Puzzle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    developer.log('updateStock erreur: ${res.body}', name: 'PuzzleService');
    throw Exception('updateStock – Erreur ${res.statusCode}: ${res.body}');
  }

  // ── POST /api/puzzles ─────────────────────────────────────────────────────
  Future<Puzzle> createPuzzle(
    String nom,
    String description,
    String image,
    double prix,
    String categorie,
  ) async {
    final res = await http.post(
      Uri.parse(_puzzlesUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'prix': prix,
        'categorie_id': 1,
        'stock': 10,
        'path_image': image.isEmpty ? null : image,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Puzzle.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    developer.log('createPuzzle erreur: ${res.body}', name: 'PuzzleService');
    throw Exception('createPuzzle – Erreur ${res.statusCode}: ${res.body}');
  }
}