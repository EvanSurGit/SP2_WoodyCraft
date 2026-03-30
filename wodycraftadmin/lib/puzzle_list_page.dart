import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'create_puzzle_page.dart';
import 'main.dart' show AppColors;

// Page catalogue — intégrée dans AppShell (pas de BottomNav locale)
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
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _refreshPuzzles,
          ),
        ],
      ),
      body: FutureBuilder<List<Puzzle>>(
        future: _futurePuzzles,
        builder: (context, snapshot) {
          // Chargement en cours
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          // Erreur réseau ou API
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Erreur : ${snapshot.error}',
                    style: const TextStyle(color: AppColors.brownDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshPuzzles,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Liste vide
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aucun puzzle trouvé.',
                style: TextStyle(color: AppColors.brownDark),
              ),
            );
          }

          // Affichage de la liste
          final puzzles = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: puzzles.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.divider,
              indent: 72,
            ),
            itemBuilder: (context, index) => _PuzzleTile(puzzle: puzzles[index]),
          );
        },
      ),
      // Bouton ajout puzzle
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        tooltip: 'Ajouter un puzzle',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePuzzlePage()),
          );
          // Rafraîchit si un puzzle a été créé
          if (result == true) _refreshPuzzles();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Tuile puzzle ─────────────────────────────────────────────────────────────
class _PuzzleTile extends StatelessWidget {
  final Puzzle puzzle;
  const _PuzzleTile({required this.puzzle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.gold.withOpacity(0.15),
        child: Text(
          puzzle.nom.isNotEmpty ? puzzle.nom[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        puzzle.nom,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.brownDark,
        ),
      ),
      subtitle: Text(
        puzzle.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.brownDark.withOpacity(0.6),
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${puzzle.prix.toStringAsFixed(2)} €',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (puzzle.stock == 0)
            const Text(
              'Rupture',
              style: TextStyle(color: Colors.red, fontSize: 11),
            )
          else
            Text(
              'Stock : ${puzzle.stock}',
              style: TextStyle(
                color: AppColors.brownDark.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}