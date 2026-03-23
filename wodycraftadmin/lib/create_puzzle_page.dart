import 'package:flutter/material.dart';
import 'puzzle_service.dart';

class CreatePuzzlePage extends StatefulWidget {
  const CreatePuzzlePage({super.key});

  @override
  _CreatePuzzlePageState createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  String _nom = '';
  String _description = '';
  String _image = '';
  double _prix = 0.0;
  int _stock = 0;
  int? _categorieId;
  bool _isLoading = false;

  // --- NOUVELLES VARIABLES POUR LA VRAIE LISTE ---
  List<Categorie> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Charge les catégories dès l'ouverture de la page
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
      print("Erreur lors du chargement des catégories: $e");
      // Affiche une petite erreur en bas si la récupération rate
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur catégories: $e'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Puzzle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _nom = v!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _description = v!,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'image (ex: mamouth.png)',
                    hintText: 'Le chemin images/puzzles/ sera ajouté automatiquement',
                  ),
                  onSaved: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      _image = v.startsWith('images/puzzles/') ? v : 'images/puzzles/$v';
                    } else {
                      _image = '';
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Prix requis';
                    if (double.tryParse(v) == null) return 'Nombre invalide';
                    return null;
                  },
                  onSaved: (v) => _prix = double.parse(v!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité en Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Stock requis';
                    if (int.tryParse(v) == null) return 'Nombre entier invalide';
                    return null;
                  },
                  onSaved: (v) => _stock = int.parse(v!),
                ),
                const SizedBox(height: 15),
                // --- VRAIE LISTE DÉROULANTE (Base de données) ---
                _isLoadingCategories
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(), // Tourne pendant la récupération API
                      )
                    : DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Catégorie'),
                        value: _categorieId,
                        items: _categories.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Text(cat.nom), // Affiche le nom de la catégorie (ex: 'Dinosaures')
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categorieId = value;
                          });
                        },
                        validator: (v) => v == null ? 'Veuillez choisir une catégorie' : null,
                        onSaved: (v) => _categorieId = v,
                      ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                        onPressed: _submitForm,
                        child: const Text('Créer le Puzzle'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      PuzzleService()
          .createPuzzle(_nom, _description, _image, _prix, _stock, _categorieId!)
          .then((_) => Navigator.pop(context, true))
          .catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error'), backgroundColor: Colors.red),
        );
      });
    }
  }
}