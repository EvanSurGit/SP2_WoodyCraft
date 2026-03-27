import 'package:flutter/material.dart';
import 'dashboardadmin.dart';
import 'puzzle_list_page.dart';
import 'stock_management_page.dart';

// ════════════════════════════════════════════════════════════════════════════
//  WIDGET NAVBAR PARTAGÉE
//
//  Utilisé dans toutes les pages de l'app.
//  Paramètre "currentIndex" : indique quel onglet est actif (surligné en or)
//    0 = Dashboard
//    1 = Puzzles
//    2 = Commandes
//    3 = Stocks
// ════════════════════════════════════════════════════════════════════════════
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  static const Color _dark = Color(0xFF1C1A17);
  static const Color _gold = Color(0xFFC8922A);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Dashboard'},
      {'icon': Icons.extension_outlined, 'label': 'Puzzles'},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Commandes'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Stocks'},
    ];

    return Container(
      decoration: const BoxDecoration(color: _dark),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => _onTap(context, i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      color: selected ? _gold : Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? _gold : Colors.white54,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PuzzleListPage()),
          (route) => false,
        );
        break;
      case 2:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page Commandes à venir...')),
        );
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StockManagementPage()),
          (route) => false,
        );
        break;
    }
  }
}
