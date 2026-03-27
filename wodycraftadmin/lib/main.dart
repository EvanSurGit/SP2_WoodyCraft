import 'package:flutter/material.dart';
import 'puzzle_list_page.dart';
import 'admin_orders_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodyCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'DM Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3D2E)),
        scaffoldBackgroundColor: const Color(0xFFF5F0EB),
      ),
      home: const HomePage(),
    );
  }
}

// ======================
// Page d'accueil avec navigation
// ======================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const PuzzleListPage(),
    const AdminOrdersPage(),
    const StocksPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, "Dashboard"),
                _buildNavItem(1, Icons.extension_outlined, Icons.extension, "Puzzles"),
                _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2, "Commandes"),
                _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart, "Stocks"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFFC8A882) : const Color(0xFF666666),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFFC8A882) : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================
// Page Dashboard (placeholder)
// ======================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Dashboard",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}

// ======================
// Page Stocks (placeholder)
// ======================
class StocksPage extends StatelessWidget {
  const StocksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F0EB),
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          "Stocks",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Stocks",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }
}