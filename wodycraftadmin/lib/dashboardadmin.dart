import 'package:flutter/material.dart';
import 'dashboard_service.dart';
import 'bottom_nav_bar.dart'; // ✅ Import de la navbar partagée

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService service = DashboardService();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF5F0E8);
  static const Color _dark = Color(0xFF2C1F14);
  static const Color _gold = Color(0xFFC8922A);
  static const Color _bar = Color(0xFFD4A96A);
  static const Color _cardBg = Colors.white;
  static const Color _redLight = Color(0xFFFFECEC);
  static const Color _redText = Color(0xFFD94040);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'expédié':
      case 'expedie':
      case 'livré':
      case 'livre':
        return const Color(0xFF4CAF50);
      case 'en_attente':
      case 'attente':
        return const Color(0xFFFFA500);
      case 'annulé':
      case 'annule':
        return const Color(0xFFD94040);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
        return 'Attente';
      case 'expédié':
      case 'expedie':
        return 'Expédié';
      case 'livré':
      case 'livre':
        return 'Livré';
      case 'annulé':
      case 'annule':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // ✅ Navbar partagée, currentIndex: 0 = onglet "Dashboard" actif
      // _buildBottomNav() supprimé et remplacé par AppBottomNavBar
      body: FutureBuilder(
        future: service.fetchDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erreur : ${snapshot.error}",
                style: const TextStyle(color: _redText),
              ),
            );
          }

          final data = snapshot.data as Map<String, dynamic>;

          final List stockFaibleList =
              (data['stock_faible_list'] as List?) ?? [];
          final int totalProduits = data['total_produits'] ?? 0;
          final List dernieresCommandes =
              (data['dernieres_commandes'] as List?) ?? [];
          final double ventes7Jours =
              double.tryParse(data['ventes_7_jours'].toString()) ?? 0.0;
          final int nombreClients = data['nombre_clients'] ?? 0;
          final int commandesEnAttente = dernieresCommandes
              .where((c) =>
                  (c['status'] ?? '').toString().toLowerCase() == 'en_attente')
              .length;

          return SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Bonjour,',
                          style:
                              TextStyle(fontSize: 14, color: Color(0xFF888888)),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Admin ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _dark,
                              ),
                            ),
                            Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle('APERÇU RAPIDE'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                label: 'Ventes (7j)',
                                value: '${ventes7Jours.toStringAsFixed(2)} €',
                                bold: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                label: 'Cmd. en attente',
                                value: commandesEnAttente.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                label: 'Puzzles',
                                value: totalProduits.toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                label: 'Clients',
                                value: nombreClients.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (stockFaibleList.isNotEmpty) ...[
                          _sectionTitle('ALERTES STOCKS'),
                          const SizedBox(height: 10),
                          _buildStockAlerts(stockFaibleList),
                          const SizedBox(height: 20),
                        ],
                        if (dernieresCommandes.isNotEmpty) ...[
                          _sectionTitle('DERNIÈRES COMMANDES'),
                          const SizedBox(height: 10),
                          ...dernieresCommandes.map(
                            (c) => _orderRow(c as Map<String, dynamic>),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () {},
            child: const Row(),
          ),
          const CircleAvatar(
            radius: 20,
            backgroundColor: _bar,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: _gold,
      ),
    );
  }

  // ── Stat card ──────────────────────────────────────────────────────────────
  Widget _statCard({
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stock alerts ───────────────────────────────────────────────────────────
  Widget _buildStockAlerts(List stockList) {
    if (stockList.length == 1) {
      final item = stockList[0] as Map<String, dynamic>;
      return _alertCard(
        title: item['nom'] ?? 'Produit',
        subtitle: (item['stock'] ?? 0) == 0
            ? 'Rupture de stock'
            : 'Reste : ${item['stock']} unité(s)',
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < stockList.length; i += 2) {
      final left = stockList[i] as Map<String, dynamic>;
      final right = (i + 1 < stockList.length)
          ? stockList[i + 1] as Map<String, dynamic>
          : null;

      rows.add(Row(
        children: [
          Expanded(
            child: _alertCard(
              title: left['nom'] ?? 'Produit',
              subtitle: (left['stock'] ?? 0) == 0
                  ? 'Rupture de stock'
                  : 'Reste : ${left['stock']} unité(s)',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: right != null
                ? _alertCard(
                    title: right['nom'] ?? 'Produit',
                    subtitle: (right['stock'] ?? 0) == 0
                        ? 'Rupture de stock'
                        : 'Reste : ${right['stock']} unité(s)',
                  )
                : const SizedBox(),
          ),
        ],
      ));
      if (i + 2 < stockList.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _alertCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _redLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: _redText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: _redText.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  // ── Order row ──────────────────────────────────────────────────────────────
  Widget _orderRow(Map<String, dynamic> commande) {
    final String status = commande['status'] ?? '';
    final String total =
        '${double.tryParse(commande['total'].toString())?.toStringAsFixed(2) ?? '0.00'} €';

    final List puzzles = (commande['puzzles'] as List?) ?? [];
    final String puzzleLabel = puzzles.isNotEmpty
        ? (puzzles[0]['nom'] ?? 'Commande')
        : 'Commande #${commande['id']}';

    final String dateLabel =
        _formatDate(commande['date_commande']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#WC-${commande['id']} · $puzzleLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateLabel • $total',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} heure(s)';
      return 'Il y a ${diff.inDays} jour(s)';
    } catch (_) {
      return raw;
    }
  }
}
