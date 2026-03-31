import 'package:flutter/material.dart';
import 'puzzle_service.dart';

// Couleurs partagées (même palette que catalogue_page.dart)
class _C {
  static const background  = Color(0xFFF2EDE6);
  static const card        = Colors.white;
  static const gold        = Color(0xFFC17D2E);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF888888);
}

class CreatePuzzlePage extends StatefulWidget {
  const CreatePuzzlePage({super.key});
  
  @override
  State<CreatePuzzlePage> createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Variables qui vont stocker les données du formulaire
  String  _nom         = '';
  String  _description = '';
  String  _image       = '';
  double  _prix        = 0.0;
  int     _stock       = 0;
  int?    _categorieId;
  
  bool    _isLoading          = false;
  List<Categorie> _categories = [];
  bool    _isLoadingCats      = true;

  @override
  void initState() {
    super.initState();
    _loadCategories(); // On charge les catégories au démarrage
  }

  void _loadCategories() async {
    try {
      final cats = await PuzzleService().fetchCategories();
      if (mounted) {
        setState(() { 
          _categories = cats; 
          _isLoadingCats = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCats = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur catégories : $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  // --- LA SEULE ET UNIQUE FONCTION DE SOUMISSION ---
  void _submitForm() {
    // 1. On vérifie que tous les champs obligatoires sont remplis
    if (!_formKey.currentState!.validate()) return;
    
    // 2. On sauvegarde les valeurs dans nos variables (_nom, _prix, etc.)
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);

    // 3. On envoie tout au service (qui va appeler Laravel)
    PuzzleService()
        .createPuzzle(_nom, _description, _image, _prix, _stock, _categorieId!)
        .then((_) {
          if (!mounted) return;
          // Si succès, on ferme la page et on renvoie "true" pour dire au catalogue de se rafraîchir
          Navigator.pop(context, true);
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $error'), backgroundColor: Colors.red),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.textPrimary, size: 18),
          ),
        ),
        title: const Text(
          'Ajouter un Puzzle',
          style: TextStyle(
            color: _C.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(children: [
                _buildField(
                  label: 'Nom du puzzle', 
                  hint: 'Ex: Loup Arctique',
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _nom = v!,
                ),
                _divider(),
                _buildField(
                  label: 'Description', 
                  hint: 'Décris le puzzle…',
                  maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _description = v!,
                ),
              ]),

              const SizedBox(height: 14),

              _buildCard(children: [
                _buildField(
                  label: 'Image',
                  hint: 'nom_fichier.png  (images/puzzles/ sera ajouté)',
                  onSaved: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      _image = v.startsWith('images/puzzles/') ? v : 'images/puzzles/$v';
                    } else {
                      _image = '';
                    }
                  },
                ),
              ]),

              const SizedBox(height: 14),

              _buildCard(children: [
                _buildField(
                  label: 'Prix (€)',
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Prix requis';
                    if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Nombre invalide';
                    return null;
                  },
                  onSaved: (v) => _prix = double.parse(v!.replaceAll(',', '.')),
                ),
                _divider(),
                _buildField(
                  label: 'Stock initial',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Stock requis';
                    if (int.tryParse(v) == null) return 'Entier requis';
                    return null;
                  },
                  onSaved: (v) => _stock = int.parse(v!),
                ),
              ]),

              const SizedBox(height: 14),

              // --- SÉLECTEUR DE CATÉGORIE ---
              Container(
                decoration: BoxDecoration(
                  color: _C.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _isLoadingCats
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(color: _C.gold)),
                      )
                    : DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          labelStyle: TextStyle(color: _C.textSecond, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        dropdownColor: Colors.white,
                        value: _categorieId,
                        items: _categories.map((cat) => DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.nom, style: const TextStyle(color: _C.textPrimary)),
                        )).toList(),
                        onChanged: (v) => setState(() => _categorieId = v),
                        validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                        onSaved: (v) => _categorieId = v,
                      ),
              ),

              const SizedBox(height: 32),

              // --- BOUTON DE SOUMISSION ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _C.gold))
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.gold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Créer le Puzzle',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 1, color: Color(0xFFF0EAE2), indent: 16, endIndent: 16);

  Widget _buildField({
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
        style: const TextStyle(fontSize: 15, color: _C.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _C.textSecond, fontSize: 13),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCCC4BA), fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}