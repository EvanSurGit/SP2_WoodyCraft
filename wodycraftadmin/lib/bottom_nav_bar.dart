import 'package:flutter/material.dart';
import 'dashboardadmin.dart';
import 'catalogue_page.dart';
import 'stock_management_page.dart';
import 'admin_orders_page.dart'; // <-- 1. IMPORT DE LA NOUVELLE PAGE COMMANDES

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0: // Dashboard
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, __, ___) => AdminDashboard(), transitionDuration: Duration.zero),
        );
        break;
      case 1: // Puzzles (Catalogue)
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, __, ___) => const CataloguePage(), transitionDuration: Duration.zero),
        );
        break;
      case 2: // Commandes
        // --- 2. MAGIE : ON REDIRIGE VERS TA PAGE COMMANDES --- 👇
        Navigator.pushReplacement(
          context,
          // NB : Enlève le "const" si ta page a la même erreur que le dashboard !
          PageRouteBuilder(pageBuilder: (_, __, ___) => const AdminOrdersPage(), transitionDuration: Duration.zero),
        );
        break;
      case 3: // Stocks
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(pageBuilder: (_, __, ___) => const StockManagementPage(), transitionDuration: Duration.zero),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded,            label: 'Dashboard'),
      _NavItem(icon: Icons.extension_rounded,       label: 'Puzzles'),
      _NavItem(icon: Icons.receipt_long_rounded,    label: 'Commandes'),
      _NavItem(icon: Icons.inventory_2_rounded,     label: 'Stocks'),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item       = items[i];
          final isSelected = i == currentIndex;
          return GestureDetector(
            onTap: () => _onItemTapped(context, i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? const Color(0xFFC17D2E) : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? const Color(0xFFC17D2E) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}