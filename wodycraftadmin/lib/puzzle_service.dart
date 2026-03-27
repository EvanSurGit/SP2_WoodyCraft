import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

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
  final String image;
  final double prix;
  final int stock;

  const Puzzle({
    this.id,
    required this.nom,
    required this.description,
    required this.image,
    required this.prix,
    required this.stock,
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
      image: json['path_image']?.toString() ?? json['image']?.toString() ?? '',
      prix: double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }
}

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