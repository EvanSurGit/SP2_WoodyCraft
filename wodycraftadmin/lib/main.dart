
import 'package:flutter/material.dart';
import 'dashboardadmin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Puzzles',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PuzzleListPage(),
        '/dashboard': (context) => AdminDashboard(),
      },
    );
  }
}

class PuzzleListPage extends StatelessWidget {
  const PuzzleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des Puzzles"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/dashboard');
            },
            child: const Text("Dashboard Admin"),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Contenu de la liste des puzzles ici",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
