import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// =====================
// MODELS
// =====================
class OrderDetail {
  final int id;
  final DateTime date_commande;
  final double total;
  final String status;
  final User user;
  final List<Puzzle> puzzles;

  OrderDetail({
    required this.id,
    required this.date_commande,
    required this.total,
    required this.status,
    required this.user,
    required this.puzzles,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] ?? 0,
      date_commande: DateTime.parse(json['date_commande']?.toString() ?? DateTime.now().toString()),
      total: double.parse(json['total']?.toString() ?? '0'),
      status: json['status'] ?? 'en_attente',
      user: User.fromJson(json['user'] ?? {}),
      puzzles: (json['puzzles'] as List?)?.map((e) => Puzzle.fromJson(e)).toList() ?? [],
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final int admin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.admin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      admin: json['admin'] ?? 0,
    );
  }

  // Générer les initiales
  String get initials {
    List<String> names = name.split(' ');
    String initials = names.map((n) => n.isNotEmpty ? n[0].toUpperCase() : '').join();
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  // Couleur basée sur les initiales
  Color get avatarColor {
    final colors = [
      Colors.purple,
      Colors.pink,
      Colors.orange,
      Colors.brown,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[name.hashCode % colors.length];
  }
}

class Puzzle {
  final int id;
  final String nom;
  final double prix;
  final int quantite;
  final String path_image;

  Puzzle({
    required this.id,
    required this.nom,
    required this.prix,
    required this.quantite,
    required this.path_image,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'N/A',
      prix: double.parse(json['prix']?.toString() ?? '0'),
      quantite: json['quantite'] ?? 0,
      path_image: json['path_image'] ?? '',
    );
  }
}

// =====================
// PAGE DÉTAIL COMMANDE
// =====================
class OrderDetailPage extends StatefulWidget {
  final int orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final String baseUrl = "http://localhost/SP2_Api/public/api/commandes";
  late Future<OrderDetail> futureOrderDetail;

  @override
  void initState() {
    super.initState();
    print("🔍 Chargement de la commande #${widget.orderId}");
    futureOrderDetail = fetchOrderDetail();
  }

  // =====================
  // FETCH ORDER DETAIL
  // =====================
  Future<OrderDetail> fetchOrderDetail() async {
    final url = "$baseUrl/${widget.orderId}";
    print("📡 URL appelée: $url");
    
    try {
      final response = await http.get(Uri.parse(url));
      
      print("📊 Status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Données reçues correctement");
        return OrderDetail.fromJson(data);
      } else {
        print("❌ Erreur HTTP: ${response.statusCode}");
        throw Exception("Erreur HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Exception: $e");
      throw Exception("Erreur: $e");
    }
  }

  // =====================
  // VALIDER
  // =====================
  Future<void> validerCommande() async {
    final response = await http.post(
      Uri.parse("$baseUrl/${widget.orderId}/valider"),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✓ Commande validée")),
      );
      setState(() {
        futureOrderDetail = fetchOrderDetail();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✗ Erreur validation")),
      );
    }
  }

  // =====================
  // EXPEDIER
  // =====================
  Future<void> expedierCommande() async {
    final response = await http.post(
      Uri.parse("$baseUrl/${widget.orderId}/expedier"),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✓ Commande expédiée")),
      );
      setState(() {
        futureOrderDetail = fetchOrderDetail();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✗ Erreur expédition")),
      );
    }
  }

  // =====================
  // DELETE
  // =====================
  Future<void> deleteOrder() async {
    final response = await http.delete(
      Uri.parse("$baseUrl/${widget.orderId}"),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✓ Commande supprimée")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✗ Erreur suppression")),
      );
    }
  }

  // =====================
  // CONFIRM DELETE
  // =====================
  Future<void> confirmDelete() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Êtes-vous sûr de vouloir supprimer cette commande ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      deleteOrder();
    }
  }

  // =====================
  // STATUS BADGE
  // =====================
  Widget statusBadge(String status) {
    Color badgeColor;
    String label;
    String icon;

    switch (status) {
      case "validee":
        badgeColor = const Color(0xFF4CAF50);
        label = "VALIDÉE";
        icon = "✓";
        break;
      case "expediee":
        badgeColor = const Color(0xFF2196F3);
        label = "EXPÉDIÉE";
        icon = "📦";
        break;
      default:
        badgeColor = const Color(0xFFFFA500);
        label = "EN ATTENTE";
        icon = "⏳";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Commande #${widget.orderId}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: confirmDelete,
          )
        ],
      ),
      body: FutureBuilder<OrderDetail>(
        future: futureOrderDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      "Erreur de chargement",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                      onPressed: () {
                        setState(() {
                          futureOrderDetail = fetchOrderDetail();
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          final order = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================
                // HEADER CARD
                // =====================
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "#WC-${order.id.toString().padLeft(4, '0')}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${order.date_commande.day}/${order.date_commande.month}/${order.date_commande.year}, ${order.date_commande.hour}:${order.date_commande.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            statusBadge(order.status),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Client Info
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: order.user.avatarColor,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Text(
                                  order.user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${order.puzzles.length} article${order.puzzles.length > 1 ? 's' : ''} • ${order.total.toStringAsFixed(2)} €",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =====================
                // PUZZLES LIST
                // =====================
                if (order.puzzles.isNotEmpty) ...[
                  const Text(
                    "Articles",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...order.puzzles.map((puzzle) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Image thumbnail
                            if (puzzle.path_image.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  "http://localhost/SP2_Api/public/${puzzle.path_image}",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    puzzle.nom,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Quantité: ${puzzle.quantite}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${puzzle.prix.toStringAsFixed(2)} €",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "x${puzzle.quantite}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // =====================
                // TOTAL CARD
                // =====================
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.grey[100],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          "${order.total.toStringAsFixed(2)} €",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =====================
                // ACTION BUTTONS
                // =====================
                Row(
                  children: [
                    // Supprimer button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[300],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: confirmDelete,
                        child: const Text(
                          "Supprimer",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Valider/Expédier button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: order.status == "en_attente"
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF8B6F47),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: order.status == "en_attente"
                            ? validerCommande
                            : order.status == "validee"
                                ? expedierCommande
                                : null,
                        child: Text(
                          order.status == "en_attente"
                              ? "Valider"
                              : order.status == "validee"
                                  ? "Expédier"
                                  : "Expédiée",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}