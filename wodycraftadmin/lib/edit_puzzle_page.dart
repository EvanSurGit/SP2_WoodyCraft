import 'package:flutter/material.dart';
import 'puzzle_service.dart';

// --- Palette de couleurs (La même que ton catalogue) ---
class _C {
  static const background  = Color(0xFFF2EDE6);
  static const card        = Colors.white;
  static const gold        = Color(0xFFC17D2E);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF888888);
  static const danger      = Color(0xFFDC2626); // Rouge pour la suppression
}

class EditPuzzlePage extends StatefulWidget {
  final Puzzle puzzle;
  const EditPuzzlePage({super.key, required this.puzzle});

  @override
  _EditPuzzlePageState createState() => _EditPuzzlePageState();
}

class _EditPuzzlePageState extends State<EditPuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Variables du formulaire
  late String _nom;
  late String _description;
  late String _image;
  late double _prix;
  late int?   _categorieId;
  
  // On garde le stock en mémoire invisible pour ne pas casser l'API Laravel !
  late int    _stockInvisible; 
  
  bool _isLoading         = false;
  List<Categorie> _categories = [];
  bool _isLoadingCats     = true;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage avec les données actuelles
    _nom            = widget.puzzle.nom;
    _description    = widget.puzzle.description;
    _image          = widget.puzzle.pathImage;
    _prix           = widget.puzzle.prix;
    _categorieId    = widget.puzzle.categorieId;
    _stockInvisible = widget.puzzle.stock; // Conservé précieusement
    
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final cats = await PuzzleService().fetchCategories();
      setState(() { _categories = cats; _isLoadingCats = false; });
    } catch (e) {
      setState(() => _isLoadingCats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.background,
      
      // --- EN-TÊTE STYLISÉ (AppBar) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Modifier',
          style: TextStyle(color: _C.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // --- CORPS DE LA PAGE ---
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Image d'en-tête stylisée
                    Center(
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.puzzle.pathImage.isEmpty
                              ? Container(color: Colors.white, child: const Icon(Icons.extension_rounded, color: Color(0xFFD4C8B8), size: 60))
                              : Image.network(widget.puzzle.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.white, child: const Icon(Icons.broken_image, color: Colors.grey, size: 40))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Les champs du formulaire (Style Maquette)
                    _buildInputLabel('Nom du puzzle'),
                    _buildTextField(
                      initialValue: _nom,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                      onSaved: (v) => _nom = v!,
                    ),

                    _buildInputLabel('Prix (€)'),
                    _buildTextField(
                      initialValue: _prix.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                      onSaved: (v) => _prix = double.parse(v!),
                    ),

                    _buildInputLabel('Catégorie'),
                    _isLoadingCats 
                      ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: _C.gold))
                      : DropdownButtonFormField<int>(
                          value: _categories.any((c) => c.id == _categorieId) ? _categorieId : null,
                          dropdownColor: Colors.white,
                          decoration: _inputDecoration(),
                          items: _categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.nom))).toList(),
                          onChanged: (v) => setState(() => _categorieId = v),
                          onSaved: (v) => _categorieId = v,
                          validator: (v) => v == null ? 'Requis' : null,
                        ),
                    const SizedBox(height: 16),

                    _buildInputLabel('URL de l\'image (Chemin serveur)'),
                    _buildTextField(
                      initialValue: _image,
                      onSaved: (v) => _image = v ?? '',
                    ),

                    _buildInputLabel('Description'),
                    _buildTextField(
                      initialValue: _description,
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                      onSaved: (v) => _description = v!,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- BARRE DU BAS (Delete & Save) ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), // Padding bas pour les iPhones
            decoration: BoxDecoration(
              color: _C.background,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                // Bouton Poubelle (Rouge clair)
                InkWell(
                  onTap: _confirmDelete,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2), // Fond rouge ultra clair
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 26),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Bouton Sauvegarder (Doré)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Sauvegarder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers UI ---
  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 16),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _C.textPrimary)),
    );
  }

  Widget _buildTextField({String? initialValue, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator, void Function(String?)? onSaved}) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: _inputDecoration(),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _C.gold.withOpacity(0.5), width: 1.5)),
    );
  }

  // --- LOGIQUE ---
  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      // On envoie à Laravel (On utilise _stockInvisible !)
      PuzzleService()
          .updatePuzzle(widget.puzzle.id, _nom, _description, _image, _prix, _stockInvisible, _categorieId!)
          .then((_) => Navigator.pop(context, true))
          .catchError((error) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $error'), backgroundColor: _C.danger));
      });
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous vraiment supprimer "${widget.puzzle.nom}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler', style: TextStyle(color: _C.textSecond))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _C.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx); // Ferme la popup
              setState(() => _isLoading = true);
              try {
                await PuzzleService().deletePuzzle(widget.puzzle.id);
                if(mounted) Navigator.pop(context, true); // Ferme la page de modification et retourne au catalogue
              } catch(e) {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: _C.danger));
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}