import 'package:flutter/material.dart';
import 'stock_management_page.dart';
import 'puzzle_list_page.dart';
import 'create_puzzle_page.dart';

void main() {
  runApp(const WoodyCraftAdmin());
}

class WoodyCraftAdmin extends StatelessWidget {
  const WoodyCraftAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodyCraft Admin',
      theme: ThemeData(primaryColor: Colors.brown),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PAGE D'ACCUEIL
// ════════════════════════════════════════════════════════════════════════════
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Logo / Titre ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1A17),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.extension_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WoodyCraft',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1A17),
                        ),
                      ),
                      Text(
                        'Panneau d\'administration',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'Que voulez-vous faire ?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1A17),
                ),
              ),

              const SizedBox(height: 16),

              // ── Bouton Gestion des stocks ─────────────────────────────────
              _NavCard(
                icon: Icons.inventory_2_rounded,
                title: 'Gestion des stocks',
                subtitle: 'Voir et ajuster les niveaux de stock',
                color: const Color(0xFF1C1A17),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockManagementPage()),
                ),
              ),

              const SizedBox(height: 12),

              // ── Bouton Liste des puzzles ───────────────────────────────────
              _NavCard(
                icon: Icons.extension_rounded,
                title: 'Liste des puzzles',
                subtitle: 'Consulter tous les puzzles',
                color: Colors.brown,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PuzzleListPage()),
                ),
              ),

              const SizedBox(height: 12),

              // ── Bouton Ajouter un puzzle ──────────────────────────────────
              _NavCard(
                icon: Icons.add_box_rounded,
                title: 'Ajouter un puzzle',
                subtitle: 'Créer un nouveau puzzle',
                color: const Color(0xFF5D8A5E),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreatePuzzlePage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Carte de navigation ──────────────────────────────────────────────────────
class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1C1A17),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
