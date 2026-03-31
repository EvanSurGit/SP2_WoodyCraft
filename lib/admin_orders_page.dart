import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'order_detail_page.dart';

// =====================
// MODEL
// =====================
class Order {
  final int id;
  final int user_id;
  final DateTime date_commande;
  final double total;
  final String status;
  final DateTime created_at;
  final DateTime updated_at;

  Order({
    required this.id,
    required this.user_id,
    required this.date_commande,
    required this.total,
    required this.status,
    required this.created_at,
    required this.updated_at,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      user_id: json['user_id'],
      date_commande: DateTime.parse(json['date_commande']),
      total: double.parse(json['total'].toString()),
      status: json['status'],
      created_at: DateTime.parse(json['created_at']),
      updated_at: DateTime.parse(json['updated_at']),
    );
  }
}

// =====================
// PAGE ADMIN
// =====================
class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {

  // ⚠️ BASE URL
  final String baseUrl = "http://localhost/SP2_Api/public/api/commandes";

  late Future<List<Order>> futureOrders;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() {
    futureOrders = fetchOrders();
  }

  // =====================
  // GET commandes
  // =====================
  Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse("$baseUrl/en-attente"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      print(response.body);
      throw Exception("Erreur chargement");
    }
  }

  // =====================
  // VALIDER
  // =====================
  Future<void> validerCommande(int id) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$id/valider"),
    );

    if (response.statusCode == 200) {
      refresh();
    } else {
      print("ERREUR VALIDER: ${response.body}");
    }
  }

  // =====================
  // EXPEDIER
  // =====================
  Future<void> expedierCommande(int id) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$id/expedier"),
    );

    if (response.statusCode == 200) {
      refresh();
    } else {
      print("ERREUR EXPEDIER: ${response.body}");
    }
  }

  // =====================
  // DELETE
  // =====================
  Future<void> deleteOrder(int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
    );

    if (response.statusCode == 200) {
      refresh();
    } else {
      print("ERREUR DELETE: ${response.body}");
    }
  }

  // =====================
  // REFRESH
  // =====================
  Future<void> refresh() async {
    setState(() {
      loadOrders();
    });
  }

  // =====================
  // CONFIRM DELETE
  // =====================
  Future<void> confirmDelete(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Supprimer cette commande ?"),
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
      deleteOrder(id);
    }
  }

  // =====================
  // NAVIGATE TO DETAIL
  // =====================
  void navigateToDetail(int orderId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailPage(orderId: orderId),
      ),
    );
    
    // Refresh list if order was deleted
    if (result == true) {
      refresh();
    }
  }

  // =====================
  // COLOR STATUS
  // =====================
  Color statusColor(String status) {
    switch (status) {
      case "validee":
        return Colors.green;
      case "expediee":
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // =====================
  // ACTION BUTTONS
  // =====================
  Widget buildActions(Order order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => validerCommande(order.id),
        ),
        IconButton(
          icon: const Icon(Icons.local_shipping, color: Colors.blue),
          onPressed: () => expedierCommande(order.id),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => confirmDelete(order.id),
        ),
      ],
    );
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes en attente"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          )
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: futureOrders,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Erreur chargement"));
          }

          final orders = snapshot.data!;
          final pending = orders.where((o) => o.status == "en_attente").toList();

          if (pending.isEmpty) {
            return const Center(child: Text("Aucune commande en attente"));
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: pending.length,
              itemBuilder: (context, index) {

                final order = pending[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    // ✅ CLIC POUR OUVRIR LE DETAIL
                    onTap: () => navigateToDetail(order.id),
                    
                    title: Text("Commande #${order.id}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total: ${order.total} €"),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor(order.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    trailing: buildActions(order),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}