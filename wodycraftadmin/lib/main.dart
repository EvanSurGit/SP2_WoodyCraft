import 'package:flutter/material.dart';
import 'puzzle_list_page.dart';
import 'admin_orders_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Puzzles',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(), // Nouvelle page d'accueil avec menu
    );
  }
}

// ======================
// Page d'accueil avec menu
// ======================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WoodyCraft'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PuzzleListPage()),
                );
              },
              child: Text("Voir les puzzles"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AdminOrdersPage()),
                );
              },
              child: Text("Admin - Commandes"),
            ),
          ],
        ),
      ),
    );
  }
}