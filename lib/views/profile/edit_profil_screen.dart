import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nomCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _adresseCtrl;
  late final TextEditingController _bioCtrl;

  @override
  void initState() {
    super.initState();
    final membre = context.read<AuthController>().membre!;
    _nomCtrl       = TextEditingController(text: membre.nom);
    _telephoneCtrl = TextEditingController(text: membre.telephone ?? '');
    _adresseCtrl   = TextEditingController(text: membre.adresse ?? '');
    _bioCtrl       = TextEditingController(text: membre.bio ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    try {
      await auth.updateProfil({
        'nom':       _nomCtrl.text.trim(),
        'telephone': _telephoneCtrl.text.trim(),
        'adresse':   _adresseCtrl.text.trim(),
        'bio':       _bioCtrl.text.trim(),
      });
      if (mounted) {
        Helpers.showSuccess(context, 'Profil mis à jour !');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                )
              : TextButton.icon(
                  onPressed: _sauvegarder,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Enregistrer',
                      style: TextStyle(color: Colors.white)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _champ(
              ctrl: _nomCtrl,
              label: 'Nom complet *',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Le nom est requis' : null,
            ),
            _champ(
              ctrl: _telephoneCtrl,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _champ(
              ctrl: _adresseCtrl,
              label: 'Adresse',
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio / À propos de moi',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 64),
                      child: Icon(Icons.notes_outlined),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sauvegarder,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer les modifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champ({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: AppColors.primary),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
