import 'package:flutter/material.dart';
import 'puzzle_service.dart';

class CreatePuzzlePage extends StatefulWidget {
  const CreatePuzzlePage({super.key});

  @override
  _CreatePuzzlePageState createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  // Clé globale pour contrôler l'état du formulaire [cite: 258, 261]
  final _formKey = GlobalKey<FormState>();

  // Variables pour stocker les données saisies [cite: 261]
  String _nom = '';
  String _description = '';
  String _image = '';
  double _prix = 0.0;
  String _categorie = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un Puzzle'), // [cite: 38, 55]
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // [cite: 269, 276]
        child: Form(
          key: _formKey, // [cite: 277, 278]
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Champ Nom [cite: 39, 56, 281]
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom'; // [cite: 283, 284, 285]
                    }
                    return null;
                  },
                  onSaved: (value) => _nom = value!, // [cite: 295, 297]
                ),
                // Champ Description [cite: 40, 58]
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer une description'
                      : null,
                  onSaved: (value) => _description = value!,
                ),
                // Champ Image URL [cite: 41, 60]
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Image URL (optionnelle)',
                  ),
                  onSaved: (value) => _image = value ?? '',
                ),
                // Champ Prix [cite: 42, 62]
                TextFormField(
                  decoration: InputDecoration(labelText: 'Prix'),
                  keyboardType: TextInputType.number, // [cite: 349]
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer un prix'
                      : null,
                  onSaved: (value) =>
                      _prix = double.parse(value!), // [cite: 350]
                ),
                // Champ Catégorie [cite: 43, 64]
                TextFormField(
                  decoration: InputDecoration(labelText: 'Catégorie'),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Veuillez entrer une catégorie'
                      : null,
                  onSaved: (value) => _categorie = value!,
                ),
                SizedBox(height: 20), // [cite: 315]
                // Bouton Créer [cite: 65, 316, 344]
                ElevatedButton(
                  onPressed: () {
                    // Validation du formulaire [cite: 318, 351]
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save(); // [cite: 318, 352]

                      // Appel du service pour envoyer les données à Laravel [cite: 319, 353]
                      PuzzleService()
                          .createPuzzle(
                            _nom,
                            _description,
                            _image,
                            _prix,
                            _categorie,
                          )
                          .then((puzzle) {
                            // Succès: retour à la liste [cite: 338, 339, 354]
                            Navigator.pop(context, true);
                          })
                          .catchError((error) {
                            // Échec: notification d'erreur [cite: 340, 341, 342, 355]
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de la création'),
                              ),
                            );
                          });
                    }
                  },
                  child: Text('Créer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
