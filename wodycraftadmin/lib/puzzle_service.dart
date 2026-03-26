import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

// ─── SEUILS D'ALERTE ─────────────────────────────────────────────────────────
class StockThresholds {
  static const int rupture = 0; // Rouge  : rupture de stock
  static const int faible = 5; // Orange : stock faible
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
  // evan
  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      // Laravel renvoie "path_image" dans stockAll() / index()
      image: json['path_image'] ?? json['image'] ?? '',
      prix: double.parse(json['prix'].toString()),
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }

  Puzzle copyWith({int? stock}) => Puzzle(
    id: id,
    nom: nom,
    description: description,
    image: image,
    prix: prix,
    stock: stock ?? this.stock,
  );
}

// ─── MODÈLE ALERTE (stockBas / ruptures) ─────────────────────────────────────
// Laravel renvoie uniquement {id, nom, stock} pour ces endpoints
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
      nom: json['nom'] ?? '',
      stock: int.tryParse(json['stock'].toString()) ?? 0,
    );
  }
}

// ─── SERVICE API ─────────────────────────────────────────────────────────────
class PuzzleService {
  final String _base = 'http://localhost/SP2_Api/public/api';

  String get _puzzlesUrl => '$_base/puzzles';

  // ── GET /api/puzzles ─────────────────────────────────────────────────────
  // → controller : index()
  //  FIX Null check on null value : on utilise index() qui inclut le champ 'id'
  //    (stockAll() ne retourne pas 'id', ce qui causait puzzle.id! == null)
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
  // → controller : stockBas()
  // Retourne les puzzles avec 0 < stock < 5
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
  // → controller : ruptures()
  // Retourne les puzzles avec stock == 0
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
  // → controller : updateStock()
  // Met à jour uniquement le stock d'un puzzle
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
  // → controller : store()
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
