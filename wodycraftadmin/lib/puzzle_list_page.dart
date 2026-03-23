import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'create_puzzle_page.dart';
import 'edit_puzzle_page.dart'; 

class PuzzleListPage extends StatefulWidget {
  const PuzzleListPage({super.key});

  @override
  _PuzzleListPageState createState() => _PuzzleListPageState();
}

class _PuzzleListPageState extends State<PuzzleListPage> {
  late Future<List<Puzzle>> futurePuzzles;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _refreshPuzzles();
  }

  void _refreshPuzzles() {
    setState(() {
      futurePuzzles = PuzzleService().fetchPuzzles();
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
                  
                  // --- LA ZONE DES BOUTONS (Prix + Stylo + Poubelle) ---
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Très important pour l'affichage
                    children: [
                      Text(
                        '${puzzle.prix.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // 1. Bouton Modifier (Stylo bleu)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPuzzlePage(puzzle: puzzle),
                            ),
                          );
                          if (result == true) {
                            _refreshPuzzles(); 
                          }
                        },
                      ),
                      // 2. Bouton Supprimer (Poubelle rouge)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Ouvre la popup de confirmation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer ?'),
                              content: Text('Voulez-vous vraiment supprimer le puzzle "${puzzle.nom}" ?'),
                              actions: [
                                // Bouton "Non"
                                TextButton(
                                  onPressed: () => Navigator.pop(context), 
                                  child: const Text('Non'),
                                ),
                                // Bouton "Oui"
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context); // On ferme d'abord la popup
                                    try {
                                      // On appelle l'API pour détruire
                                      await PuzzleService().deletePuzzle(puzzle.id);
                                      _refreshPuzzles(); // On recharge la liste si succès
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Puzzle supprimé avec succès !'), 
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      // Si erreur (ex: puzzle déjà supprimé, erreur serveur)
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur: $e'), 
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Oui, supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // -------------------------------
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
            MaterialPageRoute(builder: (context) => const CreatePuzzlePage()),
          );
          if (result == true) {
            _refreshPuzzles();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}