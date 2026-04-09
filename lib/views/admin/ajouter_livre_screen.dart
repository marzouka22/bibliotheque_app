import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Écran d'ajout / modification d'un livre (Admin)
class AjouterLivreScreen extends StatefulWidget {
  final Livre? livre; // null = ajout, non-null = modification

  const AjouterLivreScreen({super.key, this.livre});

  @override
  State<AjouterLivreScreen> createState() => _AjouterLivreScreenState();
}

class _AjouterLivreScreenState extends State<AjouterLivreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs
  late final TextEditingController _titreCtrl;
  late final TextEditingController _auteurCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _resumeCtrl;
  late final TextEditingController _editeurCtrl;
  late final TextEditingController _anneeCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _langueCtrl;
  late final TextEditingController _couvertureCtrl;
  late final TextEditingController _exemplairesCtrl;

  String _genreSelectionne = AppConstants.genres.first;
  StatutLivre _statut = StatutLivre.disponible;

  @override
  void initState() {
    super.initState();
    final l = widget.livre;
    _titreCtrl      = TextEditingController(text: l?.titre ?? '');
    _auteurCtrl     = TextEditingController(text: l?.auteur ?? '');
    _isbnCtrl       = TextEditingController(text: l?.isbn ?? '');
    _resumeCtrl     = TextEditingController(text: l?.resume ?? '');
    _editeurCtrl    = TextEditingController(text: l?.editeur ?? '');
    _anneeCtrl      = TextEditingController(text: l?.anneePublication?.toString() ?? '');
    _pagesCtrl      = TextEditingController(text: l?.nombrePages?.toString() ?? '');
    _langueCtrl     = TextEditingController(text: l?.langue ?? 'Français');
    _couvertureCtrl = TextEditingController(text: l?.couvertureUrl ?? '');
    _exemplairesCtrl = TextEditingController(
        text: l?.exemplairesTotal.toString() ?? '1');

    if (l != null) {
      _genreSelectionne = l.genre;
      _statut = l.statut;
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _auteurCtrl.dispose();
    _isbnCtrl.dispose();
    _resumeCtrl.dispose();
    _editeurCtrl.dispose();
    _anneeCtrl.dispose();
    _pagesCtrl.dispose();
    _langueCtrl.dispose();
    _couvertureCtrl.dispose();
    _exemplairesCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final ctrl = context.read<LivreController>();
    final exemplaires = int.tryParse(_exemplairesCtrl.text) ?? 1;

    final livre = Livre(
      id: widget.livre?.id ?? '',
      titre: _titreCtrl.text.trim(),
      auteur: _auteurCtrl.text.trim(),
      isbn: _isbnCtrl.text.trim().isEmpty ? null : _isbnCtrl.text.trim(),
      genre: _genreSelectionne,
      tags: [],
      resume: _resumeCtrl.text.trim().isEmpty ? null : _resumeCtrl.text.trim(),
      couvertureUrl: _couvertureCtrl.text.trim().isEmpty
          ? null
          : _couvertureCtrl.text.trim(),
      anneePublication: int.tryParse(_anneeCtrl.text),
      editeur: _editeurCtrl.text.trim().isEmpty ? null : _editeurCtrl.text.trim(),
      nombrePages: int.tryParse(_pagesCtrl.text),
      langue: _langueCtrl.text.trim().isEmpty ? 'Français' : _langueCtrl.text.trim(),
      statut: _statut,
      notemoyenne: widget.livre?.notemoyenne ?? 0.0,
      nbAvis: widget.livre?.nbAvis ?? 0,
      nbEmpruntsTotal: widget.livre?.nbEmpruntsTotal ?? 0,
      dateAjout: widget.livre?.dateAjout ?? DateTime.now(),
      exemplairesTotal: exemplaires,
      exemplairesDisponibles: exemplaires,
    );

    try {
      if (widget.livre == null) {
        await ctrl.ajouterLivre(livre);
        if (mounted) Helpers.showSuccess(context, 'Livre ajouté avec succès !');
      } else {
        await ctrl.modifierLivre(widget.livre!.id, livre.toFirestore());
        if (mounted) Helpers.showSuccess(context, 'Livre modifié avec succès !');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estModif = widget.livre != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(estModif ? 'Modifier le livre' : 'Ajouter un livre'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton.icon(
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
            // ── Section Informations principales ──
            _sectionTitre('Informations principales'),
            _champ(
              ctrl: _titreCtrl,
              label: 'Titre *',
              icon: Icons.book_outlined,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Le titre est requis' : null,
            ),
            _champ(
              ctrl: _auteurCtrl,
              label: 'Auteur *',
              icon: Icons.person_outline,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? "L'auteur est requis" : null,
            ),
            _champ(
              ctrl: _isbnCtrl,
              label: 'ISBN',
              icon: Icons.qr_code,
              keyboardType: TextInputType.number,
            ),

            // ── Genre ──
            const SizedBox(height: 8),
            _sectionTitre('Genre & Statut'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  value: _genreSelectionne,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: InputBorder.none,
                  ),
                  items: AppConstants.genres
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _genreSelectionne = v ?? _genreSelectionne),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<StatutLivre>(
                  value: _statut,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    prefixIcon: Icon(Icons.info_outline),
                    border: InputBorder.none,
                  ),
                  items: StatutLivre.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _statut = v ?? _statut),
                ),
              ),
            ),

            // ── Exemplaires ──
            const SizedBox(height: 8),
            _champ(
              ctrl: _exemplairesCtrl,
              label: 'Nombre d\'exemplaires *',
              icon: Icons.library_books_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (int.tryParse(v) == null || int.parse(v) < 1)
                  return 'Minimum 1 exemplaire';
                return null;
              },
            ),

            // ── Détails ──
            const SizedBox(height: 8),
            _sectionTitre('Détails'),
            _champ(
              ctrl: _editeurCtrl,
              label: 'Éditeur',
              icon: Icons.business_outlined,
            ),
            _champ(
              ctrl: _anneeCtrl,
              label: 'Année de publication',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
            ),
            _champ(
              ctrl: _pagesCtrl,
              label: 'Nombre de pages',
              icon: Icons.menu_book_outlined,
              keyboardType: TextInputType.number,
            ),
            _champ(
              ctrl: _langueCtrl,
              label: 'Langue',
              icon: Icons.language,
            ),

            // ── Résumé ──
            const SizedBox(height: 8),
            _sectionTitre('Résumé'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: _resumeCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Résumé du livre',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.notes_outlined),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // ── Couverture ──
            const SizedBox(height: 8),
            _sectionTitre('Couverture'),
            _champ(
              ctrl: _couvertureCtrl,
              label: 'URL de la couverture',
              icon: Icons.image_outlined,
              keyboardType: TextInputType.url,
            ),
            if (_couvertureCtrl.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _couvertureCtrl.text,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image, size: 60, color: AppColors.textLight),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // ── Bouton Enregistrer ──
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sauvegarder,
              icon: const Icon(Icons.save_outlined),
              label: Text(estModif ? 'Modifier le livre' : 'Ajouter le livre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitre(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        titre.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
          letterSpacing: 1.2,
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
