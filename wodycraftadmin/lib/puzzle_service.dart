import 'dart:convert';
import 'package:http/http.dart' as http;
// Import pour détecter la plateforme

class Puzzle {
  final int id;
  final String nom;
  final String description;
  final String image;
  final double prix;
  // --- NOUVEAUX CHAMPS ---
  final int stock;
  final int? categorieId;

  Puzzle({
    required this.id,
    required this.nom,
    required this.description,
    this.image = '',
    this.prix = 0.0,
    this.stock = 0, // par défaut 0
    this.categorieId,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      image: json['path_image']?.toString() ?? '', // on lit bien path_image
      prix: double.tryParse(json['prix'].toString().replaceAll(',', '.')) ?? 0.0,
      
      // --- ON LIT LE STOCK ET LA CATEGORIE ---
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      categorieId: json['categorie_id'] != null ? int.tryParse(json['categorie_id'].toString()) : null,
    );
  }
}

class PuzzleService {
  // Utilisez '10.0.2.2' pour l'émulateur Android, 'localhost' pour le Web/iOS
  final String apiUrl = "http://groupe2.lycee.local/api/puzzles";

  Future<List<Categorie>> fetchCategories() async {
    // On remplace /puzzles par /categories dans ton URL
    final String catUrl = apiUrl.replaceAll('/puzzles', '/cat'); 
    
    final response = await http.get(Uri.parse(catUrl));
    
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Categorie.fromJson(item)).toList();
    } else {
      throw Exception('Erreur de récupération des catégories');
    }
  }

  Future<List<Puzzle>> fetchPuzzles() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        // C'est toujours une bonne pratique de l'ajouter aussi pour la lecture
        headers: {'Accept': 'application/json'}, 
      );
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
      double prix, int stock, int categorieId) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Pour bien recevoir les erreurs Laravel
      },
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'path_image': image,
        'prix': prix,
        'stock': stock, // On envoie le stock
        'categorie_id': categorieId, // On envoie l'ID et non plus le texte
      }),
    );

    if (response.statusCode == 201) {
      return Puzzle.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Échec de la création: ${response.body}');
    }
  }

  // NOUVELLE MÉTHODE POUR MODIFIER UN PUZZLE
  Future<Puzzle> updatePuzzle(int id, String nom, String description, String image, double prix, int stock, int categorieId) async {
    // L'URL devient /api/puzzles/ID (ex: /api/puzzles/5)
    final response = await http.put(
      Uri.parse('$apiUrl/$id'), 
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nom': nom,
        'description': description,
        'path_image': image,
        'prix': prix,
        'stock': stock,
        'categorie_id': categorieId,
      }),
    );

    if (response.statusCode == 200) {
      // 200 signifie que Laravel a bien modifié l'élément
      return Puzzle.fromJson(jsonDecode(response.body));
    } else {
      print("Erreur modification: ${response.body}");
      throw Exception('Échec de la modification: ${response.body}');
    }
  }

  // NOUVELLE MÉTHODE POUR SUPPRIMER UN PUZZLE
  Future<void> deletePuzzle(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));

    if (response.statusCode != 200) {
      print("Erreur suppression: ${response.body}");
      throw Exception('Échec de la suppression');
    }
  }
}



// NOUVELLE CLASSE POUR LES CATEGORIES
class Categorie {
  final int id;
  final String nom; // Mets le vrai nom de la colonne de ta bdd (ex: nom, libelle...)

  Categorie({required this.id, required this.nom});

  factory Categorie.fromJson(Map<String, dynamic> json) {
    return Categorie(
      id: json['id'],
      nom: json['libelle']?.toString() ?? 'Sans nom', // Attention : si ta colonne s'appelle 'libelle', remplace 'nom' par 'libelle'
    );
  }
}