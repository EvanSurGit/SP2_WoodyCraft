import 'package:flutter/material.dart';
import 'puzzle_service.dart';

class CreatePuzzlePage extends StatefulWidget {
  const CreatePuzzlePage({super.key});
  //    State<CreatePuzzlePage> au lieu de _CreatePuzzlePageState
  @override
  State<CreatePuzzlePage> createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  String _nom = '';
  String _description = '';
  String _image = '';
  double _prix = 0.0;
  String _categorie = '';

  //    logique async extraite dans _submit() avec guard `if (!mounted) return`
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await PuzzleService().createPuzzle(
        _nom,
        _description,
        _image,
        _prix,
        _categorie,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la création'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Puzzle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // ── Nom ──────────────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer un nom'
                      : null,
                  onSaved: (value) => _nom = value!,
                ),

                // ── Description ───────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer une description'
                      : null,
                  onSaved: (value) => _description = value!,
                ),

                // ── Image URL ─────────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optionnelle)',
                  ),
                  onSaved: (value) => _image = value ?? '',
                ),

                // ── Prix ──────────────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer un prix'
                      : null,
                  onSaved: (value) => _prix = double.parse(value!),
                ),

                // ── Catégorie ─────────────────────────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer une catégorie'
                      : null,
                  onSaved: (value) => _categorie = value!,
                ),

                const SizedBox(height: 20),

                // ── Bouton Créer ──────────────────────────────────────────────
                ElevatedButton(
                  onPressed: _submit, // méthode async séparée
                  child: const Text('Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
