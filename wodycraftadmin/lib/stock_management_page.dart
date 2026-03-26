import 'package:flutter/material.dart';            
import 'package:flutter/services.dart';
import 'puzzle_service.dart';
import 'bottom_nav_bar.dart';

// ════════════════════════════════════════════════════════════════════════════
//  PAGE GESTION DES STOCKS
//
//  Cette page communique avec 4 endpoints de l'API Laravel :
//    GET   /api/puzzles/stock              → récupère la liste complète des puzzles avec leur stock
//    GET   /api/puzzles/alertes/stock-bas  → récupère les puzzles avec un stock faible
//    GET   /api/puzzles/alertes/ruptures   → récupère les puzzles en rupture de stock
//    PATCH /api/puzzles/{id}/stock         → met à jour le stock d'un puzzle spécifique
// ════════════════════════════════════════════════════════════════════════════

// StatefulWidget = widget qui peut changer d'état (les données évoluent au fil du temps)
// C'est le bon choix ici car on charge des données depuis une API et on les met à jour
class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  // createState() crée l'objet qui va gérer l'état de cette page
  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

// _StockManagementPageState : la classe qui contient toute la logique et les données
// Le "with SingleTickerProviderStateMixin" est nécessaire pour faire fonctionner
// le TabController (les onglets Tous / Faibles / Ruptures)
class _StockManagementPageState extends State<StockManagementPage>
    with SingleTickerProviderStateMixin {

  // ── DONNÉES ──────────────────────────────────────────────────────────────
  // Liste de tous les puzzles reçus depuis l'API
  List<Puzzle> _allPuzzles = [];

  // Liste des puzzles affichés après application du filtre de recherche
  // Au départ, c'est une copie de _allPuzzles
  List<Puzzle> _filtered = [];

  // Liste des puzzles en rupture de stock (stock = 0), vient de l'API
  List<PuzzleAlerte> _ruptures = [];

  // Liste des puzzles avec un stock faible (mais pas encore à 0), vient de l'API
  List<PuzzleAlerte> _stockBas = [];

  // true pendant le chargement des données → affiche un spinner à l'écran
  bool _loading = true;

  // Contiendra le message d'erreur si l'API échoue, null si tout va bien
  String? _error;

  // true si l'utilisateur a fermé la bannière d'alertes (bouton croix)
  bool _alertDismissed = false;

  // Contrôleur du champ de recherche : permet de lire ce que l'utilisateur tape
  final _searchCtrl = TextEditingController();

  // ── ONGLETS ───────────────────────────────────────────────────────────────
  // Contrôleur des onglets (Tous / Faibles / Ruptures)
  // "late" signifie qu'on l'initialise juste après, dans initState()
  late TabController _tabCtrl;

  // Seuils importés depuis puzzle_service.dart (ex: rupture = 0, faible = 5)
  // Ces constantes sont définies dans un fichier partagé pour éviter de les dupliquer
  static const int _seuilRupture = StockThresholds.rupture;
  static const int _seuilFaible = StockThresholds.faible;

  // ── INITIALISATION ────────────────────────────────────────────────────────
  // initState() est appelé une seule fois quand la page s'affiche pour la première fois
  @override
  void initState() {
    super.initState(); // toujours appeler super en premier
    _tabCtrl = TabController(length: 3, vsync: this); // 3 onglets
    _load(); // charge les données depuis l'API au démarrage
    // Quand le texte de recherche change, on applique automatiquement le filtre
    _searchCtrl.addListener(_applyFilter);
  }

  // ── NETTOYAGE ─────────────────────────────────────────────────────────────
  // dispose() est appelé quand on quitte la page
  // IMPORTANT : il faut toujours libérer les controllers pour éviter les fuites mémoire
  @override
  void dispose() {
    _tabCtrl.dispose();    // libère le TabController
    _searchCtrl.dispose(); // libère le TextEditingController
    super.dispose();
  }

  // ── CHARGEMENT PARALLÈLE DES 3 ENDPOINTS ─────────────────────────────────
  // Cette méthode est "async" car elle fait des appels réseau qui prennent du temps
  // Elle appelle les 3 endpoints un par un et met à jour l'état quand c'est fini
  Future<void> _load() async {
    // On commence par montrer le spinner et réinitialiser les erreurs
    setState(() {
      _loading = true;
      _error = null;
      _alertDismissed = false; // on réaffiche la bannière d'alertes si nécessaire
    });

    try {
      // On crée une instance du service qui gère les appels API
      final service = PuzzleService();

      // On lance les 3 appels API séparément (on pourrait les lancer en parallèle
      // avec Future.wait, mais ici ils sont séquentiels pour simplicité)
      final puzzlesFuture = service.fetchPuzzles();    // liste complète
      final stockBasFuture = service.fetchStockBas();  // stocks faibles
      final rupturesFuture = service.fetchRuptures();  // ruptures

      // "await" attend que chaque Future soit terminé avant de passer à la ligne suivante
      final puzzles = await puzzlesFuture;
      final stockBas = await stockBasFuture;
      final ruptures = await rupturesFuture;

      // setState() met à jour l'affichage avec les nouvelles données
      setState(() {
        _allPuzzles = puzzles;
        _filtered = List.from(_allPuzzles); // copie de la liste complète pour le filtre
        _stockBas = stockBas;
        _ruptures = ruptures;
        _loading = false; // on cache le spinner
      });
    } catch (e) {
      // Si une erreur survient (réseau coupé, serveur down, etc.)
      // on stocke le message d'erreur pour l'afficher à l'écran
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── FILTRE DE RECHERCHE ───────────────────────────────────────────────────
  // Appelé automatiquement à chaque frappe dans le champ de recherche
  void _applyFilter() {
    // On met tout en minuscules pour que la recherche ne soit pas sensible à la casse
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          // Si le champ est vide → on affiche tout
          ? List.from(_allPuzzles)
          // Sinon → on garde seulement les puzzles dont le nom OU la référence contient le texte
          : _allPuzzles
                .where(
                  (p) =>
                      p.nom.toLowerCase().contains(q) ||
                      'wc-${p.id}'.toLowerCase().contains(q), // ex: "wc-001"
                )
                .toList();
    });
  }

  //evan
  // ── AJUSTER LE STOCK DE +1 OU -1 ─────────────────────────────────────────
  // delta = +1 pour augmenter, -1 pour diminuer
  Future<void> _adjust(Puzzle puzzle, int delta) async {
    // clamp(0, 9999) empêche le stock de dépasser les bornes (pas de stock négatif)
    final newStock = (puzzle.stock + delta).clamp(0, 9999);

    // Si le nouveau stock est identique (ex: on essaie de descendre en dessous de 0)
    // → on ne fait rien
    if (newStock == puzzle.stock) return;

    // Mise à jour optimiste : on modifie l'affichage AVANT la réponse de l'API
    // Cela donne l'impression que l'app est rapide
    _updateLocal(puzzle.id!, newStock);

    try {
      // On envoie le nouveau stock à l'API Laravel
      final updated = await PuzzleService().updateStock(puzzle.id!, newStock);
      // On met à jour avec la valeur confirmée par le serveur (au cas où elle diffère)
      _updateLocal(updated.id!, updated.stock);
      // On recharge les alertes pour refléter le nouveau stock
      await _refreshAlertes();
    } catch (_) {
      // Si l'API échoue : on annule la mise à jour locale (rollback)
      _updateLocal(puzzle.id!, puzzle.stock);
      // On affiche un message d'erreur en bas de l'écran (SnackBar = toast)
      if (mounted) { // "mounted" vérifie que la page est encore affichée
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de mise à jour du stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── SAISIE MANUELLE D'UN STOCK ────────────────────────────────────────────
  // Appelée quand l'utilisateur valide une valeur dans la boîte de dialogue
  Future<void> _setManual(Puzzle puzzle, int val) async {
    // Mise à jour optimiste (même logique que _adjust)
    _updateLocal(puzzle.id!, val);
    try {
      final updated = await PuzzleService().updateStock(puzzle.id!, val);
      _updateLocal(updated.id!, updated.stock);
      await _refreshAlertes();
    } catch (_) {
      // Rollback si l'API échoue
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

  // ── MISE À JOUR LOCALE SANS RECHARGER TOUTE LA LISTE ─────────────────────
  // On modifie seulement l'item concerné dans les deux listes (_allPuzzles et _filtered)
  // C'est bien plus performant que de tout recharger depuis l'API
  void _updateLocal(int id, int stock) {
    setState(() {
      // On parcourt les deux listes pour trouver et mettre à jour le bon puzzle
      for (final list in [_allPuzzles, _filtered]) {
        final idx = list.indexWhere((p) => p.id == id); // trouve l'index du puzzle
        if (idx != -1) {
          // copyWith() crée une copie du puzzle avec seulement le stock modifié
          // (les autres champs restent inchangés)
          list[idx] = list[idx].copyWith(stock: stock);
        }
      }
    });
  }

  // ── RAFRAÎCHIR UNIQUEMENT LES ALERTES ────────────────────────────────────
  // Après un changement de stock, on recharge juste les listes d'alertes
  // sans recharger tous les puzzles (plus léger)
  Future<void> _refreshAlertes() async {
    try {
      final service = PuzzleService();
      final stockBas = await service.fetchStockBas();
      final ruptures = await service.fetchRuptures();
      if (mounted) { // vérifie que la page est encore ouverte
        setState(() {
          _stockBas = stockBas;
          _ruptures = ruptures;
        });
      }
    } catch (_) {
      // On ignore silencieusement : la liste principale reste correcte
      // Une erreur sur les alertes ne doit pas planter la page
    }
  }

  // ── BOÎTE DE DIALOGUE SAISIE MANUELLE ────────────────────────────────────
  // S'ouvre quand on appuie longtemps sur une carte (ou sur le chiffre du stock)
  // L'utilisateur peut taper directement un nombre
  Future<void> _showEditDialog(Puzzle puzzle) async {
    // Pré-remplit le champ avec le stock actuel
    final ctrl = TextEditingController(text: puzzle.stock.toString());

    // showDialog affiche une popup et renvoie la valeur quand l'utilisateur valide
    // Le type <int> indique qu'on attend un entier en retour
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // Titre de la popup = nom du puzzle
        title: Text(
          puzzle.nom,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // la popup prend le minimum de hauteur nécessaire
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affiche le stock actuel pour référence
            Text(
              'Stock actuel : ${puzzle.stock}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Champ de saisie numérique
            TextField(
              controller: ctrl,
              autofocus: true, // le clavier s'ouvre automatiquement
              keyboardType: TextInputType.number,
              // inputFormatters bloque toute saisie autre que des chiffres
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
          // Bouton Annuler : ferme la popup sans renvoyer de valeur
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          // Bouton Valider : ferme la popup et renvoie la valeur saisie
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1A17),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // int.tryParse retourne null si la saisie n'est pas un nombre valide
              final v = int.tryParse(ctrl.text);
              if (v != null) Navigator.pop(ctx, v); // renvoie la valeur
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    // Si l'utilisateur a validé (val != null), on applique la nouvelle valeur
    if (val != null) await _setManual(puzzle, val);
  }

  // ── HELPERS (fonctions utilitaires) ──────────────────────────────────────

  // Calcule le stock total de tous les puzzles
  // fold() parcourt la liste et additionne les stocks : 0 + stock1 + stock2 + ...
  int get _totalStock => _allPuzzles.fold(0, (s, p) => s + p.stock);

  // Génère la référence affichée sous le nom du puzzle
  // ex: id = 3 → "Réf: WC-003" (padLeft complète avec des zéros à gauche)
  String _ref(Puzzle p) =>
      'Réf: WC-${p.id?.toString().padLeft(3, '0') ?? '???'}';

  // Retourne la couleur à utiliser pour afficher le stock selon son niveau
  //  - rouge  si rupture (stock ≤ seuil rupture)
  //  - orange si faible  (stock ≤ seuil faible)
  //  - noir   si normal
  Color _stockColor(int stock) {
    if (stock <= _seuilRupture) return const Color(0xFFD32F2F); // rouge
    if (stock <= _seuilFaible) return const Color(0xFFE65100);  // orange
    return const Color(0xFF1C1A17);                              // noir
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD - Construit l'interface de la page
  //  build() est appelé à chaque setState() pour reconstruire l'UI
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE8), // fond beige clair
      body: SafeArea(
        // SafeArea évite que le contenu soit caché derrière la barre de statut ou l'encoche
        child: Column(
          children: [
            _buildHeader(), // en-tête avec les compteurs

            // ── Bannière d'alertes ─────────────────────────────────────────
            // Affichée seulement si :
            //   - le chargement est terminé
            //   - l'utilisateur ne l'a pas fermée
            //   - il y a des alertes (ruptures ou stocks faibles)
            if (!_loading &&
                !_alertDismissed &&
                (_ruptures.isNotEmpty || _stockBas.isNotEmpty))
              _buildAlertBanner(),

            // ── Barre d'onglets ────────────────────────────────────────────
            _buildTabBar(), // Tous | Faibles | Ruptures

            // ── Contenu principal ──────────────────────────────────────────
            Expanded( // Expanded = prend tout l'espace vertical restant
              child: _loading
                  // Pendant le chargement → spinner au centre
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1C1A17),
                      ),
                    )
                  // Si erreur → page d'erreur avec bouton réessayer
                  : _error != null
                  ? _buildError()
                  // Sinon → les 3 onglets avec leur contenu
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildAllTab(), // Onglet "Tous" avec barre de recherche
                        _buildAlerteTab(
                          // Onglet "Faibles" : stocks faibles en orange
                          items: _stockBas,
                          couleur: const Color(0xFFE65100),
                          icone: Icons.warning_amber_rounded,
                          message: 'Aucun stock faible 👍',
                        ),
                        _buildAlerteTab(
                          // Onglet "Ruptures" : ruptures en rouge
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
      // Barre de navigation en bas de l'écran
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── EN-TÊTE ───────────────────────────────────────────────────────────────
  // Affiche le titre "Gestion Stocks" + 3 petits chips de compteurs
  // + bouton rafraîchir à droite
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
              // ── 3 compteurs affichés côte à côte ─────────────────────────
              Row(
                children: [
                  // Chip noir : stock total de tous les puzzles combinés
                  _headerChip(
                    label: 'Total: $_totalStock',
                    color: const Color(0xFF1C1A17),
                  ),
                  const SizedBox(width: 8),
                  // Chip orange : nombre de puzzles avec stock faible
                  _headerChip(
                    label:
                        '${_stockBas.length} faible${_stockBas.length > 1 ? 's' : ''}',
                    color: const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 8),
                  // Chip rouge : nombre de puzzles en rupture de stock
                  _headerChip(
                    label:
                        '${_ruptures.length} rupture${_ruptures.length > 1 ? 's' : ''}',
                    color: const Color(0xFFD32F2F),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(), // pousse le bouton refresh à l'extrême droite
          // Bouton pour recharger toutes les données depuis l'API
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1C1A17)),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
    );
  }

  // ── PETIT CHIP COLORÉ (compteur dans l'en-tête) ───────────────────────────
  // Reçoit un texte (label) et une couleur, affiche un badge arrondi
  Widget _headerChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Fond très transparent de la couleur (alpha 0.08 = 8% d'opacité)
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

  // ── BANNIÈRE D'ALERTES ────────────────────────────────────────────────────
  // S'affiche en haut de page si des puzzles ont un stock problématique
  // L'utilisateur peut la fermer avec le bouton croix (setState → _alertDismissed = true)
  Widget _buildAlertBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50], // fond rouge très pâle
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre de la bannière + bouton fermer ─────────────────────────
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.red, size: 18),
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
              // Bouton croix pour fermer la bannière
              GestureDetector(
                onTap: () => setState(() => _alertDismissed = true),
                child: const Icon(Icons.close, size: 16, color: Colors.red),
              ),
            ],
          ),

          // ── Liste des ruptures (si il y en a) ───────────────────────────
          // Le "..." devant la liste décompose les widgets dans le Column parent
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
            // map() transforme chaque alerte en widget Text
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

          // ── Liste des stocks faibles (si il y en a) ──────────────────────
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

  // ── BARRE D'ONGLETS (Tous / Faibles / Ruptures) ───────────────────────────
  // Les onglets "Faibles" et "Ruptures" affichent un badge rouge/orange
  // avec le nombre d'alertes quand il y en a
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: const Color(0xFF1C1A17),       // couleur onglet sélectionné
        unselectedLabelColor: Colors.grey,          // couleur onglets non sélectionnés
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        // Indicateur visuel de l'onglet actif (fond légèrement coloré)
        indicator: BoxDecoration(
          color: const Color(0xFF1C1A17).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: [
          const Tab(text: 'Tous'),
          // Onglet "Faibles" avec badge orange si des alertes existent
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
          // Onglet "Ruptures" avec badge rouge si des ruptures existent
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

  // ── BADGE NUMÉRIQUE SUR UN ONGLET ─────────────────────────────────────────
  // Petit cercle coloré avec un chiffre dedans (ex: 🔴 3)
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

  // ── ONGLET "TOUS" ─────────────────────────────────────────────────────────
  // Affiche la barre de recherche + la liste complète de tous les puzzles
  Widget _buildAllTab() {
    return Column(
      children: [
        // Barre de recherche (filtre par nom ou référence)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchCtrl, // lié au contrôleur qui déclenche _applyFilter
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
              // Trois états de bordure : normal, focus (cliqué), enabled (actif)
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
              // Aucun résultat → message vide
              ? Center(
                  child: Text(
                    'Aucun puzzle trouvé.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              // ListView.builder = liste performante : ne crée que les items visibles
              // (plus efficace que de construire toute la liste d'un coup)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildCard(_filtered[i]),
                ),
        ),
      ],
    );
  }

  // ── ONGLET ALERTES (réutilisé pour "Faibles" ET "Ruptures") ──────────────
  // Cette fonction est générique : elle affiche n'importe quelle liste d'alertes
  // selon les paramètres passés (couleur, icône, message si vide)
  Widget _buildAlerteTab({
    required List<PuzzleAlerte> items, // la liste à afficher
    required Color couleur,            // couleur du thème (orange ou rouge)
    required IconData icone,           // icône à afficher
    required String message,           // message si la liste est vide
  }) {
    // Si aucune alerte → affiche un état "tout va bien" avec une icône verte
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 52, color: Colors.green[400]),
            const SizedBox(height: 12),
            Text(
              message, // ex: "Aucune rupture de stock 👍"
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Sinon → liste des alertes
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i]; // l'alerte à cet index
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Barre colorée sur le bord gauche pour indiquer le niveau d'alerte
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
              // Icône de l'alerte (warning orange ou remove rouge)
              Icon(icone, color: couleur, size: 28),
              const SizedBox(width: 14),
              // Nom + référence du puzzle en alerte
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
              // Badge avec le stock actuel à droite (ex: "2" en rouge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  // ── CARTE PUZZLE (utilisée dans l'onglet "Tous") ──────────────────────────
  // Affiche une carte par puzzle avec :
  //   - une miniature (icône puzzle)
  //   - le nom et la référence
  //   - un label "Rupture" ou "Stock bas" si nécessaire
  //   - les boutons + et – pour ajuster le stock
  //   - un appui long → ouvre la saisie manuelle
  Widget _buildCard(Puzzle puzzle) {
    // Détermine l'état du stock pour appliquer le bon style visuel
    final isRupture = puzzle.stock <= _seuilRupture;                   // stock critique
    final isFaible = !isRupture && puzzle.stock <= _seuilFaible;       // stock faible (mais pas 0)
    final stockColor = _stockColor(puzzle.stock);                       // couleur du chiffre

    return GestureDetector(
      // Appui long → ouvre la boîte de dialogue de saisie manuelle
      onLongPress: () => _showEditDialog(puzzle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          // Barre colorée à gauche selon l'état du stock (rouge = rupture, orange = faible)
          border: isRupture
              ? const Border(
                  left: BorderSide(color: Color(0xFFD32F2F), width: 4),
                )
              : isFaible
              ? const Border(
                  left: BorderSide(color: Color(0xFFE65100), width: 4),
                )
              : null, // pas de barre si le stock est normal
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
              // ── Miniature du puzzle (icône dans un carré arrondi beige) ──
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

              // ── Infos du puzzle (nom, référence, label d'alerte) ──────────
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
                    // Référence au format WC-001
                    Text(
                      _ref(puzzle),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    // Label "Rupture de stock" en rouge (si applicable)
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
                    // Label "Stock bas" en orange (si applicable)
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

              // ── Contrôles +/– avec chiffre cliquable au centre ───────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton – (désactivé si stock = 0 pour ne pas passer en négatif)
                  _roundBtn(
                    icon: Icons.remove,
                    onTap: puzzle.stock > 0 ? () => _adjust(puzzle, -1) : null,
                  ),
                  const SizedBox(width: 6),
                  // Chiffre du stock (clic → ouvre la saisie manuelle)
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
                          color: stockColor, // rouge/orange/noir selon le niveau
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Bouton + (toujours actif, le stock ne peut pas dépasser 9999)
                  _roundBtn(icon: Icons.add, onTap: () => _adjust(puzzle, 1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BOUTON ROND +/– ───────────────────────────────────────────────────────
  // Widget réutilisable pour les boutons + et –
  // Si onTap est null → le bouton est visuellement désactivé (grisé)
  Widget _roundBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null; // le bouton est actif seulement si onTap est fourni
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          // Fond beige si actif, gris si désactivé
          color: enabled ? const Color(0xFFF2EDE8) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? const Color(0xFFD6C9BA) : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          // Icône noire si actif, grise si désactivé
          color: enabled ? const Color(0xFF1C1A17) : Colors.grey[400],
        ),
      ),
    );
  }

  // ── PAGE D'ERREUR ─────────────────────────────────────────────────────────
  // Affiché si le chargement de l'API échoue
  // Affiche l'icône cloud barré + le message d'erreur + bouton "Réessayer"
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
              _error!, // affiche le message d'erreur (ex: "Connection refused")
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Bouton qui relance _load() pour retenter l'appel API
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

  // ── BARRE DE NAVIGATION DU BAS ────────────────────────────────────────────
  // Barre commune à toutes les pages de l'app (Dashboard / Puzzles / Commandes / Stocks)
  // L'onglet "Stocks" (index 3) est mis en surbrillance car c'est la page actuelle
  Widget _buildBottomNav() {
    // Définition des 4 onglets de navigation
    const navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.extension_rounded, 'label': 'Puzzles'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Commandes'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Stocks'},
    ];

    return Container(
      color: const Color(0xFF1C1A17), // fond noir
      child: SafeArea(
        top: false, // SafeArea uniquement en bas (pour les iPhones avec barre home)
        child: SizedBox(
          height: 64,
          child: Row(
            // List.generate crée un widget pour chaque onglet
            children: List.generate(navItems.length, (i) {
              final selected = i == 3; // l'onglet "Stocks" est sélectionné
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque, // toute la zone est cliquable
                  onTap: () {
                    // Si on clique sur un autre onglet → on revient en arrière
                    // (la navigation vers les autres pages est gérée par le parent)
                    if (i != 3) Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        navItems[i]['icon'] as IconData,
                        // Blanc opaque si sélectionné, blanc transparent sinon
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
                              ? FontWeight.w600  // gras si sélectionné
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