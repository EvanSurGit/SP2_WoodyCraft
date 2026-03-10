import 'package:flutter/material.dart';
import 'puzzle_service.dart'; //
import 'create_puzzle_page.dart'; //

class PuzzleListPage extends StatefulWidget {
  const PuzzleListPage({super.key});

  @override
  _PuzzleListPageState createState() => _PuzzleListPageState();
}

class _PuzzleListPageState extends State<PuzzleListPage> {
  late Future<List<Puzzle>> futurePuzzles; //
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _refreshPuzzles(); //
  }

  void _refreshPuzzles() {
    setState(() {
      futurePuzzles = PuzzleService().fetchPuzzles(); //
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPuzzles,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Commandes',
          ),
        ],
      ),
      body: FutureBuilder<List<Puzzle>>(
        future: futurePuzzles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun puzzle trouvé.'));
          } else {
            final puzzles = snapshot.data!;
            return ListView.separated(
              itemCount: puzzles.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final puzzle = puzzles[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(puzzle.nom[0])),
                  title: Text(
                    puzzle.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(puzzle.description),
                  trailing: Text(
                    '${puzzle.prix.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePuzzlePage()),
          );
          if (result == true) {
            _refreshPuzzles(); //
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
