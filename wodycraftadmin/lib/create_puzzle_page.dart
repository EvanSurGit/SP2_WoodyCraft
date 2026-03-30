import 'package:flutter/material.dart';
import 'puzzle_service.dart';
import 'main.dart' show AppColors;

// Formulaire de création d'un puzzle
class CreatePuzzlePage extends StatefulWidget {
  const CreatePuzzlePage({super.key});

  @override
  State<CreatePuzzlePage> createState() => _CreatePuzzlePageState();
}

class _CreatePuzzlePageState extends State<CreatePuzzlePage> {
  final _formKey = GlobalKey<FormState>();

  // Valeurs du formulaire
  String _nom         = '';
  String _description = '';
  String _image       = '';
  double _prix        = 0.0;
  String _categorie   = '';

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un Puzzle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(
                label: 'Nom',
                hint: 'Ex : Forêt enchantée',
                onSaved: (v) => _nom = v!,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Description',
                hint: 'Décrivez le puzzle...',
                maxLines: 3,
                onSaved: (v) => _description = v!,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Image URL',
                hint: 'https://exemple.com/image.jpg',
                keyboardType: TextInputType.url,
                onSaved: (v) => _image = v ?? '',
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Prix (€)',
                hint: '29.90',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onSaved: (v) => _prix = double.parse(v!),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Prix requis';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Catégorie',
                hint: 'Ex : Nature, Animaux...',
                onSaved: (v) => _categorie = v!,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 32),
              // Bouton de soumission
              SizedBox(
                height: 52,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text(
                          'Créer le Puzzle',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Champ de formulaire stylisé
  Widget _buildField({
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppColors.brownDark, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.brownDark.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  // Validation et envoi du formulaire
  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    PuzzleService()
        .createPuzzle(_nom, _description, _image, _prix, _categorie)
        .then((_) {
          if (!mounted) return;
          Navigator.pop(context, true);
        })
        .catchError((error) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }
}