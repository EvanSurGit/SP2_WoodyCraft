import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'create_puzzle_page.dart';
import 'bottom_nav_bar.dart';

class PuzzleListPage extends StatefulWidget {
  const PuzzleListPage({super.key});
  @override
  _PuzzleListPageState createState() => _PuzzleListPageState();
}

class _PuzzleListPageState extends State<PuzzleListPage> {
  late Future<List<Puzzle>> futurePuzzles;

  @override
  void initState() {
    super.initState();
    futurePuzzles = PuzzleService().fetchPuzzles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WoodyCraft Admin')),
      // ✅ Navbar partagée, currentIndex: 1 = onglet "Puzzles" actif
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      body: FutureBuilder<List<Puzzle>>(
        future: futurePuzzles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final puzzles = snapshot.data!;
            return ListView.builder(
              itemCount: puzzles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(puzzles[index].nom),
                  subtitle: Text(puzzles[index].description),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePuzzlePage()),
          );
          if (result == true) {
            setState(() {
              futurePuzzles = PuzzleService().fetchPuzzles();
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}