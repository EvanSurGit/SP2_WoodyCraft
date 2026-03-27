import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// =====================
// COULEURS
// =====================
const Color kBg = Color(0xFFF5F0EB);
const Color kCardBg = Colors.white;
const Color kBrown = Color(0xFF5C3D2E);
const Color kGreen = Color(0xFF2D6A4F);
const Color kBlue = Color(0xFF1565C0);
const Color kOrange = Color(0xFFE07B00);
const Color kCancelBg = Color(0xFFFFF0F0);
const Color kCancelText = Color(0xFFC0392B);
const Color kNavBg = Color(0xFF1A1A1A);
const Color kNavActive = Color(0xFFC8A882);

// =====================
// MODEL
// =====================
class Order {
  final int id;
  final int userId;
  final DateTime dateCommande;
  final double total;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String modePaiement;
  final String userName;
  final int articleCount;

  Order({
    required this.id,
    required this.userId,
    required this.dateCommande,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.modePaiement,
    required this.userName,
    required this.articleCount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      dateCommande: DateTime.parse(json['date_commande']),
      total: double.parse(json['total'].toString()),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      modePaiement: json['mode_paiement'] ?? 'cb',
      userName: (json['user'] != null && json['user']['name'] != null)
          ? json['user']['name']
          : 'Client inconnu',
      articleCount: json['puzzles'] != null
        ? (json['puzzles'] as List).fold(
          0,
          (sum, item) => sum + ((item['pivot']?['quantite'] ?? 0) as int),
          )
        : 0,
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
  final String baseUrl = "http://groupe2.lycee.local/api/commandes";
  late Future<List<Order>> futureOrders;
  
  int _selectedTab = 0;
  int _selectedNav = 2;

  final List<Map<String, String>> _tabs = [
    {'label': 'Toutes'},
    {'label': 'À préparer'},
    {'label': 'Payées'},
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  void loadOrders() {
    futureOrders = fetchOrders();
  }

  Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse("$baseUrl/en-attente"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception("Erreur chargement");
    }
  }

  Future<void> validerCommande(int id) async {
    final response = await http.post(Uri.parse("$baseUrl/$id/valider"));
    if (response.statusCode == 200) refresh();
  }

  Future<void> expedierCommande(int id) async {
    final response = await http.post(Uri.parse("$baseUrl/$id/expedier"));
    if (response.statusCode == 200) refresh();
  }

  Future<void> deleteOrder(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) refresh();
  }

  Future<void> refresh() async {
    setState(() => loadOrders());
  }

  Future<void> confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirmation"),
        content: const Text("Supprimer cette commande ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: kCancelText),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) deleteOrder(id);
  }

  // ---- Helpers ----

  String formatStatus(String status) {
    switch (status) {
      case "en_attente":
        return "EN ATTENTE";
      case "payee":
        return "PAYÉ";
      case "expediee":
        return "EXPÉDIÉE";
      default:
        return status.toUpperCase();
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "payee":
        return kBlue;
      case "expediee":
        return kGreen;
      default:
        return kOrange;
    }
  }

  Color statusBgColor(String status) {
    switch (status) {
      case "payee":
        return kBlue.withOpacity(0.10);
      case "expediee":
        return kGreen.withOpacity(0.10);
      default:
        return kOrange.withOpacity(0.12);
    }
  }

  IconData getPaymentIcon(String mode) {
    switch (mode) {
      case "cheque":
        return Icons.receipt_long;
      case "cb":
        return Icons.credit_card;
      case "paypal":
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String getPaymentLabel(String mode) {
    switch (mode) {
      case "cheque":
        return "Chèque";
      case "cb":
        return "CB";
      case "paypal":
        return "PayPal";
      default:
        return mode.toUpperCase();
    }
  }

  Color avatarColor(String initials) {
    final colors = [
      const Color(0xFF5B8DEF),
      const Color(0xFFF4A0A0),
      const Color(0xFF6FCF97),
      const Color(0xFFF6AB47),
      const Color(0xFFBB86FC),
    ];
    int idx = (initials.isNotEmpty ? initials.codeUnitAt(0) : 0) % colors.length;
    return colors[idx];
  }

  String getInitials(String name) {
    if (name.trim().isEmpty) return '?';

    final parts = name.trim().split(' ');

    if (parts.length >= 2 &&
        parts[0].isNotEmpty &&
        parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }

    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }

    return name.substring(0, 1).toUpperCase();
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(orderDay).inDays;

    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return "Aujourd'hui, $time";
    if (diff == 1) return "Hier, $time";
    return "${date.day}/${date.month}/${date.year}, $time";
  }

  // =====================
  // WIDGETS
  // =====================

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusBgColor(status),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: statusColor(status).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Text(
        formatStatus(status),
        style: TextStyle(
          color: statusColor(status),
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = getInitials(name);
    final color = avatarColor(initials);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.75)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String mode) {
    return Row(
      children: [
        Icon(getPaymentIcon(mode), size: 13, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          getPaymentLabel(mode),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Order order) {
    // Expédiée : bouton "Détails de la livraison"
    if (order.status == 'expediee') {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF0EDE9),
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Détails de la livraison",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      );
    }

    // En attente + chèque → Supprimer / Valider
    if (order.modePaiement == "cheque" && order.status == "en_attente") {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => confirmDelete(order.id),
              style: TextButton.styleFrom(
                backgroundColor: kCancelBg,
                foregroundColor: kCancelText,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Supprimer",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextButton(
              onPressed: () => validerCommande(order.id),
              style: TextButton.styleFrom(
                backgroundColor: kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Valider",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Payée → Annuler / Expédier
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => confirmDelete(order.id),
            style: TextButton.styleFrom(
              backgroundColor: kCancelBg,
              foregroundColor: kCancelText,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Annuler",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextButton(
            onPressed: () => expedierCommande(order.id),
            style: TextButton.styleFrom(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Expédier",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : ID + badge statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "#WoodyCraft-${order.id}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.3,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(order.dateCommande),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(order.status),
              ],
            ),

            const SizedBox(height: 14),

            // Ligne client
            Row(
              children: [
                _buildAvatar(order.userName),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName.isNotEmpty
                          ? order.userName
                          : "Client :${order.userId}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${order.articleCount} article${order.articleCount > 1 ? 's' : ''} • ${order.total.toStringAsFixed(2)} €",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPaymentRow(order.modePaiement),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0EDE9)),
            const SizedBox(height: 12),

            // Boutons d'action
            _buildActions(order),
          ],
        ),
      ),
    );
  }

  // =====================
  // BUILD
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,

      // ---- AppBar ----
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "Commandes",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Onglets ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = _selectedTab == i;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: isActive ? kBrown : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isActive
                                ? kBrown
                                : const Color(0xFFDDDDDD),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _tabs[i]['label']!,
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF333333),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ---- Liste commandes ----
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: futureOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Erreur : ${snapshot.error}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      "Aucune commande",
                      style: TextStyle(color: Colors.grey[500], fontSize: 15),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: refresh,
                  color: kBrown,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(orders[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedNav == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedNav = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? kNavActive : const Color(0xFF666666),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? kNavActive : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
