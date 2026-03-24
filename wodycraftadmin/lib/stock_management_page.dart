import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'puzzle_service.dart';

// ════════════════════════════════════════════════════════════════════════════
//  PAGE GESTION DES STOCKS
//  Utilise 3 endpoints Laravel :
//    GET  /api/puzzles/stock              → liste complète (stockAll)
//    GET  /api/puzzles/alertes/stock-bas  → stocks faibles (stockBas)
//    GET  /api/puzzles/alertes/ruptures   → ruptures (ruptures)
//    PATCH /api/puzzles/{id}/stock        → modifier stock (updateStock)
// ════════════════════════════════════════════════════════════════════════════
class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage>
    with SingleTickerProviderStateMixin {
  // ── Données ───────────────────────────────────────────────────────────────
  List<Puzzle> _allPuzzles = [];
  List<Puzzle> _filtered = [];
  List<PuzzleAlerte> _ruptures = [];
  List<PuzzleAlerte> _stockBas = [];

  bool _loading = true;
  String? _error;
  bool _alertDismissed = false;

  final _searchCtrl = TextEditingController();

  // ── Onglets ───────────────────────────────────────────────────────────────
  late TabController _tabCtrl;

  static const int _seuilRupture = StockThresholds.rupture;
  static const int _seuilFaible = StockThresholds.faible;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Chargement parallèle des 3 endpoints ──────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _alertDismissed = false;
    });
    try {
      // ✅ FIX unnecessary_cast : futures typés séparément évite les casts
      final service = PuzzleService();
      final puzzlesFuture = service.fetchPuzzles();
      final stockBasFuture = service.fetchStockBas();
      final rupturesFuture = service.fetchRuptures();

      final puzzles = await puzzlesFuture;
      final stockBas = await stockBasFuture;
      final ruptures = await rupturesFuture;

      setState(() {
        _allPuzzles = puzzles;
        _filtered = List.from(_allPuzzles);
        _stockBas = stockBas;
        _ruptures = ruptures;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Filtre recherche ──────────────────────────────────────────────────────
  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_allPuzzles)
          : _allPuzzles
                .where(
                  (p) =>
                      p.nom.toLowerCase().contains(q) ||
                      'wc-${p.id}'.toLowerCase().contains(q),
                )
                .toList();
    });
  }

  // ── Ajuster stock (+1 / -1) ───────────────────────────────────────────────
  Future<void> _adjust(Puzzle puzzle, int delta) async {
    final newStock = (puzzle.stock + delta).clamp(0, 9999);
    if (newStock == puzzle.stock) return;

    _updateLocal(puzzle.id!, newStock); // optimiste

    try {
      final updated = await PuzzleService().updateStock(puzzle.id!, newStock);
      _updateLocal(updated.id!, updated.stock);
      await _refreshAlertes(); // recalcule les alertes depuis l'API
    } catch (_) {
      _updateLocal(puzzle.id!, puzzle.stock); // rollback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de mise à jour du stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Saisie manuelle ───────────────────────────────────────────────────────
  Future<void> _setManual(Puzzle puzzle, int val) async {
    _updateLocal(puzzle.id!, val);
    try {
      final updated = await PuzzleService().updateStock(puzzle.id!, val);
      _updateLocal(updated.id!, updated.stock);
      await _refreshAlertes();
    } catch (_) {
      _updateLocal(puzzle.id!, puzzle.stock);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de mise à jour du stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Mise à jour locale (sans recharger toute la liste) ────────────────────
  void _updateLocal(int id, int stock) {
    setState(() {
      for (final list in [_allPuzzles, _filtered]) {
        final idx = list.indexWhere((p) => p.id == id);
        if (idx != -1) list[idx] = list[idx].copyWith(stock: stock);
      }
    });
  }

  // ── Rafraîchit uniquement les alertes depuis l'API ────────────────────────
  Future<void> _refreshAlertes() async {
    try {
      // ✅ FIX unnecessary_cast : futures typés séparément
      final service = PuzzleService();
      final stockBas = await service.fetchStockBas();
      final ruptures = await service.fetchRuptures();
      if (mounted) {
        setState(() {
          _stockBas = stockBas;
          _ruptures = ruptures;
        });
      }
    } catch (_) {
      // Silencieux : la liste principale reste correcte
    }
  }

  // ── Dialog saisie manuelle ────────────────────────────────────────────────
  Future<void> _showEditDialog(Puzzle puzzle) async {
    final ctrl = TextEditingController(text: puzzle.stock.toString());
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          puzzle.nom,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock actuel : ${puzzle.stock}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nouveau stock',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1A17),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (val != null) await _setManual(puzzle, val);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int get _totalStock => _allPuzzles.fold(0, (s, p) => s + p.stock);

  String _ref(Puzzle p) =>
      'Réf: WC-${p.id?.toString().padLeft(3, '0') ?? '???'}';

  Color _stockColor(int stock) {
    if (stock <= _seuilRupture) return const Color(0xFFD32F2F);
    if (stock <= _seuilFaible) return const Color(0xFFE65100);
    return const Color(0xFF1C1A17);
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // ── Bannière alertes ───────────────────────────────────────────────
            if (!_loading &&
                !_alertDismissed &&
                (_ruptures.isNotEmpty || _stockBas.isNotEmpty))
              _buildAlertBanner(),
            // ── Onglets ────────────────────────────────────────────────────────
            _buildTabBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1C1A17),
                      ),
                    )
                  : _error != null
                  ? _buildError()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildAllTab(), // Tous
                        _buildAlerteTab(
                          // Stock bas
                          items: _stockBas,
                          couleur: const Color(0xFFE65100),
                          icone: Icons.warning_amber_rounded,
                          message: 'Aucun stock faible 👍',
                        ),
                        _buildAlerteTab(
                          // Ruptures
                          items: _ruptures,
                          couleur: const Color(0xFFD32F2F),
                          icone: Icons.remove_circle,
                          message: 'Aucune rupture de stock 👍',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── En-tête ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestion Stocks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1A17),
                ),
              ),
              const SizedBox(height: 6),
              // ── 3 compteurs en ligne ──────────────────────────────────────────
              Row(
                children: [
                  _headerChip(
                    label: 'Total: $_totalStock',
                    color: const Color(0xFF1C1A17),
                  ),
                  const SizedBox(width: 8),
                  _headerChip(
                    label:
                        '${_stockBas.length} faible${_stockBas.length > 1 ? 's' : ''}',
                    color: const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 8),
                  _headerChip(
                    label:
                        '${_ruptures.length} rupture${_ruptures.length > 1 ? 's' : ''}',
                    color: const Color(0xFFD32F2F),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1C1A17)),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }

  Widget _headerChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Bannière alerte (depuis API stock-bas + ruptures) ─────────────────────
  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active,
                color: Colors.red,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Alertes de stock',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _alertDismissed = true),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ],
          ),
          if (_ruptures.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '🔴 Ruptures :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFFD32F2F),
              ),
            ),
            const SizedBox(height: 2),
            ..._ruptures.map(
              (a) => Padding(
                padding: const EdgeInsets.only(left: 10, top: 2),
                child: Text(
                  '• ${a.nom}  (stock : ${a.stock})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
          if (_stockBas.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '🟠 Stocks faibles :',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 2),
            ..._stockBas.map(
              (a) => Padding(
                padding: const EdgeInsets.only(left: 10, top: 2),
                child: Text(
                  '• ${a.nom}  (stock : ${a.stock})',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── TabBar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: const Color(0xFF1C1A17),
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicator: BoxDecoration(
          color: const Color(0xFF1C1A17).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: [
          const Tab(text: 'Tous'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Faibles'),
                if (_stockBas.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _tabBadge(_stockBas.length, const Color(0xFFE65100)),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Ruptures'),
                if (_ruptures.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _tabBadge(_ruptures.length, const Color(0xFFD32F2F)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Onglet "Tous" ─────────────────────────────────────────────────────────
  Widget _buildAllTab() {
    return Column(
      children: [
        // Barre de recherche
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher un nom ou une référence...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1C1A17),
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'Aucun puzzle trouvé.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildCard(_filtered[i]),
                ),
        ),
      ],
    );
  }

  // ── Onglet alertes (stock-bas ou ruptures) ────────────────────────────────
  Widget _buildAlerteTab({
    required List<PuzzleAlerte> items,
    required Color couleur,
    required IconData icone,
    required String message,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 52,
              color: Colors.green[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: couleur, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icone, color: couleur, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1C1A17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Réf: WC-${a.id.toString().padLeft(3, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Badge stock
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: couleur.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${a.stock}',
                  style: TextStyle(
                    color: couleur,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Carte puzzle (onglet Tous) ────────────────────────────────────────────
  Widget _buildCard(Puzzle puzzle) {
    final isRupture = puzzle.stock <= _seuilRupture;
    final isFaible = !isRupture && puzzle.stock <= _seuilFaible;
    final stockColor = _stockColor(puzzle.stock);

    return GestureDetector(
      onLongPress: () => _showEditDialog(puzzle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isRupture
              ? const Border(
                  left: BorderSide(color: Color(0xFFD32F2F), width: 4),
                )
              : isFaible
              ? const Border(
                  left: BorderSide(color: Color(0xFFE65100), width: 4),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Miniature
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFF0E8DC),
                  child: const Icon(
                    Icons.extension,
                    color: Color(0xFFB8956A),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1C1A17),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ref(puzzle),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (isRupture) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Rupture de stock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ] else if (isFaible) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Stock bas',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Contrôles +/–
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _roundBtn(
                    icon: Icons.remove,
                    onTap: puzzle.stock > 0 ? () => _adjust(puzzle, -1) : null,
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showEditDialog(puzzle),
                    child: SizedBox(
                      width: 36,
                      child: Text(
                        '${puzzle.stock}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stockColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _roundBtn(icon: Icons.add, onTap: () => _adjust(puzzle, 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bouton rond +/– ──────────────────────────────────────────────────────
  Widget _roundBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF2EDE8) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFD6C9BA) : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF1C1A17) : Colors.grey[400],
        ),
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1A17),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre de navigation ───────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.extension_rounded, 'label': 'Puzzles'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Commandes'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Stocks'},
    ];

    return Container(
      color: const Color(0xFF1C1A17),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(navItems.length, (i) {
              final selected = i == 3;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i != 3) Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        navItems[i]['icon'] as IconData,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        navItems[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
