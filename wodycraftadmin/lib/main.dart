import 'package:flutter/material.dart';
import 'dashboardadmin.dart';
import 'puzzle_list_page.dart';
import 'stock_management_page.dart';

void main() {
  runApp(const WoodyCraftAdmin());
}

class WoodyCraftAdmin extends StatelessWidget {
  const WoodyCraftAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WoodyCraft Admin',
      theme: ThemeData(primaryColor: Colors.brown),
      //  La page de démarrage est maintenant AdminDashboard
      home: AdminDashboard(),
      routes: {
        '/dashboard': (context) => AdminDashboard(),
        '/puzzles': (context) => const PuzzleListPage(),
        '/stocks': (context) => const StockManagementPage(),
      },
    );
  }
}
