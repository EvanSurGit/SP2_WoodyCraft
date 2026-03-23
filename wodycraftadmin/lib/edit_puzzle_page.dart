import 'package:flutter/material.dart';
import 'puzzle_service.dart';

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
  late int _stock;
  late int? _categorieId;
  
  bool _isLoading = false;
  List<Categorie> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    // On récupère les VRAIES données du puzzle
    _nom = widget.puzzle.nom;
    _description = widget.puzzle.description;
    _image = widget.puzzle.image;
    _prix = widget.puzzle.prix;
    _stock = widget.puzzle.stock; // Plus de "10" en dur, on lit le vrai stock !
    _categorieId = widget.puzzle.categorieId; 
    
    _loadCategories();
  }

  void _loadCategories() async {
    try {
      final categories = await PuzzleService().fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le Puzzle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: _nom,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _nom = v!,
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _description = v!,
                ),
                TextFormField(
                  initialValue: _image,
                  decoration: const InputDecoration(labelText: 'Image (path_image)'),
                  onSaved: (v) => _image = v ?? '',
                ),
                TextFormField(
                  initialValue: _prix.toString(),
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => (v == null || v.isEmpty) ? 'Prix requis' : null,
                  onSaved: (v) => _prix = double.parse(v!),
                ),
                TextFormField(
                  initialValue: _stock.toString(),
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Stock requis' : null,
                  onSaved: (v) => _stock = int.parse(v!),
                ),
                if (!_isLoadingCategories)
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    // Vérifie que l'ID existe bien dans la liste, sinon met null
                    value: _categories.any((c) => c.id == _categorieId) ? _categorieId : null,
                    items: _categories.map((cat) {
                      return DropdownMenuItem<int>(
                        value: cat.id,
                        child: Text(cat.nom),
                      );
                    }).toList(),
                    validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                    onChanged: (v) => setState(() => _categorieId = v),
                    onSaved: (v) => _categorieId = v,
                  ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                        onPressed: _submit,
                        child: const Text('Sauvegarder les modifications'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    // 1. On vérifie que le formulaire est bien rempli (ça manquait !)
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      // 2. On envoie la modification à l'API
      PuzzleService()
          .updatePuzzle(widget.puzzle.id, _nom, _description, _image, _prix, _stock, _categorieId!)
          .then((_) {
            // Si c'est un succès, on ferme la page et on dit "true" pour rafraîchir
            Navigator.pop(context, true);
          })
          .catchError((error) {
            // 3. SI IL Y A UNE ERREUR, ON L'AFFICHE EN ROUGE MAINTENANT !
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
            );
      });
    }
  }
}