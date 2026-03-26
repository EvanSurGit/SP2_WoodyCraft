import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'create_puzzle_page.dart';
import 'puzzle_list_page.dart';
import 'edit_puzzle_page.dart'; // <-- NOUVEL IMPORT OBLIGATOIRE ICI

// ─── Palette de couleurs centralisée ────────────────────────────────────────
class AppColors {
  static const background   = Color(0xFFF2EDE6); // beige chaud
  static const card         = Colors.white;
  static const navBar       = Color(0xFF1A1A1A); // barre nav sombre
  static const gold         = Color(0xFFC17D2E); // bouton FAB + chip actif
  static const goldLight    = Color(0xFFF5E6C8); // chip actif fond clair
  static const textPrimary  = Color(0xFF1A1A1A);
  static const textSecond   = Color(0xFF888888);
  static const textPrice    = Color(0xFFC17D2E);
  static const stockBg      = Color(0xFFFFFBF5);
  static const chipBorder   = Color(0xFFDDD5C8);
}

class CataloguePage extends StatefulWidget {
  const CataloguePage({super.key});

  @override
  _CataloguePageState createState() => _CataloguePageState();
}

class _CataloguePageState extends State<CataloguePage> {
  late Future<List<Puzzle>>    _futurePuzzles;
  late Future<List<Categorie>> _futureCategories;
  int _selectedCategoryId  = -1; // -1 = "Tous"
  int _selectedBottomIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futurePuzzles    = PuzzleService().fetchPuzzles();
    _futureCategories = PuzzleService().fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _futurePuzzles = PuzzleService().fetchPuzzles();
    });
  }

  // Filtre puzzles selon catégorie sélectionnée + recherche texte
  List<Puzzle> _filterPuzzles(List<Puzzle> all) {
    return all.where((p) {
      final matchCat    = _selectedCategoryId == -1 || p.categorieId == _selectedCategoryId;
      final matchSearch = _searchQuery.isEmpty ||
          p.nom.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ── Corps ──────────────────────────────────────────────────────────────
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'Catalogue',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ── Barre de recherche ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un puzzle…',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Chips catégories ───────────────────────────────────────────
            FutureBuilder<List<Categorie>>(
              future: _futureCategories,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                // On ajoute "Tous" en tête
                final chips = <_CategoryChip>[
                  const _CategoryChip(id: -1, label: 'Tous'),
                  ...categories.map((c) => _CategoryChip(id: c.id, label: c.nom)),
                ];
                return SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final chip  = chips[i];
                      final isSelected = chip.id == _selectedCategoryId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = chip.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.gold : AppColors.chipBorder,
                              width: 1.2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.gold.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Text(
                            chip.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Grille puzzles ─────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Puzzle>>(
                future: _futurePuzzles,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucun puzzle trouvé.'));
                  }

                  final filtered = _filterPuzzles(snapshot.data!);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Aucun résultat.', style: TextStyle(color: AppColors.textSecond)),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.95, 
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      // --- MAGIE DU CLIC ICI ---
                      return GestureDetector(
                        onTap: () async {
                          // Ouvre la page EditPuzzlePage avec le puzzle sélectionné
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPuzzlePage(puzzle: filtered[index]),
                            ),
                          );
                          // Rafraîchit la liste si une modif ou suppression a eu lieu
                          if (result == true) {
                            _refreshData();
                          }
                        },
                        child: _PuzzleCard(puzzle: filtered[index]),
                      );
                      // -------------------------
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB doré ──────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePuzzlePage()),
          );
          if (result == true) _refreshData();
        },
        backgroundColor: AppColors.gold,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ── Barre de navigation sombre ─────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedBottomIndex,
        onTap: (index) {
          if (index == 1) return; // déjà sur catalogue
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PuzzleListPage()),
            );
          }
          setState(() => _selectedBottomIndex = index);
        },
      ),
    );
  }
}

// ─── Chip catégorie (data class simple) ────────────────────────────────────
class _CategoryChip {
  final int    id;
  final String label;
  const _CategoryChip({required this.id, required this.label});
}

// ─── Carte puzzle ────────────────────────────────────────────────────────────
class _PuzzleCard extends StatelessWidget {
  final Puzzle puzzle;
  const _PuzzleCard({required this.puzzle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + badge stock (On utilise Expanded pour qu'il s'adapte au carré)
          Expanded(
            child: Stack(
              fit: StackFit.expand, // Force l'image à remplir l'Expanded
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: puzzle.pathImage.isEmpty
                      ? _placeholder()
                      : Image.network(
                          puzzle.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                ),
                // Badge "Stock: XX"
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                      ],
                    ),
                    child: Text(
                      'Stock: ${puzzle.stock}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: puzzle.stock <= 5
                            ? Colors.red.shade600
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Infos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puzzle.nom,
                  style: const TextStyle(
                    fontSize: 13, // Un poil plus petit
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1, // Une seule ligne pour éviter que ça casse le design
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${puzzle.prix.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 14, // Un poil plus petit
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrice,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8E0D5),
      child: const Center(
        child: Icon(Icons.extension_rounded, color: Color(0xFFBBAA96), size: 36),
      ),
    );
  }
}

// ─── Barre de navigation personnalisée ──────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

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
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? AppColors.gold : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? AppColors.gold : Colors.grey.shade600,
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