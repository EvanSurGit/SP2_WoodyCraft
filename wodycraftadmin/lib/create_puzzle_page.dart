import 'package:flutter/material.dart';
import 'puzzle_service.dart';

class CreatePuzzlePage extends StatefulWidget {
  @override
  _CreatePuzzlePageState createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  final _formKey = GlobalKey<FormState>();
  String _nom = '';
  String _description = '';
  String _image = '';
  double _prix = 0.0;
  String _categorie = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un Puzzle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _nom = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _description = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Image URL'),
                  onSaved: (v) => _image = v ?? '',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Prix requis';
                    if (double.tryParse(v) == null) return 'Nombre invalide';
                    return null;
                  },
                  onSaved: (v) => _prix = double.parse(v!),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Catégorie'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                  onSaved: (v) => _categorie = v!,
                ),
                SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(200, 50),
                        ),
                        onPressed: _submitForm,
                        child: Text('Créer le Puzzle'),
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
          .createPuzzle(_nom, _description, _image, _prix, _categorie)
          .then((_) => Navigator.pop(context, true))
          .catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }
}
