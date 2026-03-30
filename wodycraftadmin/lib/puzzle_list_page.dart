import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'create_puzzle_page.dart';
import 'edit_puzzle_page.dart';
import 'bottom_nav_bar.dart';

// Palette de couleurs locale
class _C {
  static const background  = Color(0xFFF2EDE6);
  static const card        = Colors.white;
  static const gold        = Color(0xFFC17D2E);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF888888);
}

class PuzzleListPage extends StatefulWidget {
  const PuzzleListPage({super.key});
  
  @override
  State<PuzzleListPage> createState() => _PuzzleListPageState();
}

class _PuzzleListPageState extends State<PuzzleListPage> {
  late Future<List<Puzzle>> _futurePuzzles;

  @override
  void initState() {
    super.initState();
    _refreshPuzzles();
  }

  // Recharge la liste depuis l'API
  void _refreshPuzzles() {
    setState(() {
      _futurePuzzles = PuzzleService().fetchPuzzles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gestion du Catalogue',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _C.textPrimary, letterSpacing: -0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: _refreshPuzzles,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.refresh_rounded, color: _C.textPrimary, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Liste
            Expanded(
              child: FutureBuilder<List<Puzzle>>(
                future: _futurePuzzles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _C.gold));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucun puzzle trouvé.', style: TextStyle(color: _C.textSecond)));
                  }

                  final puzzles = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: puzzles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _PuzzleListTile(
                        puzzle: puzzles[index],
                        onEdit: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditPuzzlePage(puzzle: puzzles[index])),
                          );
                          if (result == true) _refreshPuzzles();
                        },
                        onDelete: () => _confirmDelete(puzzles[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _C.gold, // Un seul backgroundColor !
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un puzzle',
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePuzzlePage()),
          );
          if (result == true) _refreshPuzzles();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // On branche la fameuse barre de navigation
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
    );
  }

  void _confirmDelete(Puzzle puzzle) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.w800, color: _C.textPrimary)),
        content: Text('Voulez-vous vraiment supprimer "${puzzle.nom}" ?', style: const TextStyle(color: _C.textSecond)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: _C.textSecond)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PuzzleService().deletePuzzle(puzzle.id);
                _refreshPuzzles();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Puzzle supprimé !'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Tuile puzzle ─────────────────────────────────────────────────────────────
class _PuzzleListTile extends StatelessWidget {
  final Puzzle puzzle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PuzzleListTile({required this.puzzle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: puzzle.pathImage.isEmpty
                ? Container(width: 80, height: 80, color: const Color(0xFFE8E0D5),
                    child: const Center(child: Icon(Icons.extension_rounded, color: Color(0xFFBBAA96), size: 30)))
                : Image.network(puzzle.imageUrl, width: 80, height: 80, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: const Color(0xFFE8E0D5),
                      child: const Center(child: Icon(Icons.extension_rounded, color: Color(0xFFBBAA96), size: 30)))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(puzzle.nom,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _C.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(puzzle.description,
                    style: const TextStyle(fontSize: 12, color: _C.textSecond),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${puzzle.prix.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.gold)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EDE6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Stock: ${puzzle.stock}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textSecond)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: _C.gold, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red.shade400, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}