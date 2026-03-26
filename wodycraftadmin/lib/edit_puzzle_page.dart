import 'package:flutter/material.dart';
import 'puzzle_service.dart';

class _C {
  static const background  = Color(0xFFF2EDE6);
  static const card        = Colors.white;
  static const gold        = Color(0xFFC17D2E);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF888888);
}

class EditPuzzlePage extends StatefulWidget {
  final Puzzle puzzle;
  const EditPuzzlePage({super.key, required this.puzzle});

  @override
  _EditPuzzlePageState createState() => _EditPuzzlePageState();
}

class _EditPuzzlePageState extends State<EditPuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  late String _nom;
  late String _description;
  late String _image;
  late double _prix;
  late int    _stock;
  late int?   _categorieId;
  bool _isLoading         = false;
  List<Categorie> _categories = [];
  bool _isLoadingCats     = true;

  @override
  void initState() {
    super.initState();
    _nom         = widget.puzzle.nom;
    _description = widget.puzzle.description;
    _image       = widget.puzzle.pathImage;
    _prix        = widget.puzzle.prix;
    _stock       = widget.puzzle.stock;
    _categorieId = widget.puzzle.categorieId;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    PuzzleService()
        .updatePuzzle(widget.puzzle.id, _nom, _description, _image, _prix, _stock, _categorieId!)
        .then((_) => Navigator.pop(context, true))
        .catchError((error) {
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
          'Modifier le Puzzle',
          style: TextStyle(color: _C.textPrimary, fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(children: [
                _buildField(label: 'Nom', initialValue: _nom,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _nom = v!,
                ),
                _divider(),
                _buildField(label: 'Description', initialValue: _description, maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _description = v!,
                ),
              ]),

              const SizedBox(height: 14),

              _buildCard(children: [
                _buildField(label: 'Image (path_image)', initialValue: _image,
                  onSaved: (v) => _image = v ?? '',
                ),
              ]),

              const SizedBox(height: 14),

              _buildCard(children: [
                _buildField(
                  label: 'Prix (€)', initialValue: _prix.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Prix requis' : null,
                  onSaved: (v) => _prix = double.parse(v!),
                ),
                _divider(),
                _buildField(
                  label: 'Stock', initialValue: _stock.toString(),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Stock requis' : null,
                  onSaved: (v) => _stock = int.parse(v!),
                ),
              ]),

              const SizedBox(height: 14),

              if (!_isLoadingCats)
                Container(
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      labelStyle: TextStyle(color: _C.textSecond, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    dropdownColor: Colors.white,
                    value: _categories.any((c) => c.id == _categorieId) ? _categorieId : null,
                    items: _categories.map((cat) => DropdownMenuItem<int>(
                      value: cat.id,
                      child: Text(cat.nom, style: const TextStyle(color: _C.textPrimary)),
                    )).toList(),
                    validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                    onChanged: (v) => setState(() => _categorieId = v),
                    onSaved: (v) => _categorieId = v,
                  ),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _C.gold))
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.gold,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Sauvegarder les modifications',
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
    String? initialValue,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        initialValue: initialValue,
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
