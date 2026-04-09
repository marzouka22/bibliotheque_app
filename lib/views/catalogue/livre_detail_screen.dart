import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/livre.dart';
import '../../models/membre.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_appbar.dart';

/// Écran de détail d'un livre
class LivreDetailScreen extends StatefulWidget {
  final Livre livre;

  const LivreDetailScreen({super.key, required this.livre});

  @override
  State<LivreDetailScreen> createState() => _LivreDetailScreenState();
}

class _LivreDetailScreenState extends State<LivreDetailScreen> {
  double _maNote = 0;
  final _avisCtrl = TextEditingController();

  @override
  void dispose() {
    _avisCtrl.dispose();
    super.dispose();
  }

  Future<void> _emprunter() async {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();

    if (!auth.estConnecte) {
      Helpers.showInfo(context, 'Connectez-vous pour emprunter un livre.');
      return;
    }

    if (auth.membre?.statut != StatutMembre.actif) {
      Helpers.showError(
          context, 'Votre compte doit être validé pour emprunter.');
      return;
    }

    final confirm = await Helpers.confirmer(
      context,
      titre: 'Emprunter ce livre',
      message:
          'Vous avez ${AppConstants.dureeEmpruntJours} jours pour retourner "${widget.livre.titre}".',
      boutonConfirmer: 'Emprunter',
    );

    if (!confirm) return;

    final ok = await empruntCtrl.creerEmprunt(
      livre: widget.livre,
      membre: auth.membre!,
    );

    if (mounted) {
      if (ok) {
        Helpers.showSuccess(context, 'Emprunt enregistré ! Bonne lecture.');
        Navigator.pop(context);
      } else {
        Helpers.showError(
            context, empruntCtrl.errorMessage ?? 'Erreur lors de l\'emprunt.');
      }
    }
  }

  Future<void> _reserver() async {
    final auth = context.read<AuthController>();
    final empruntCtrl = context.read<EmpruntController>();

    if (!auth.estConnecte) {
      Helpers.showInfo(context, 'Connectez-vous pour réserver.');
      return;
    }

    final ok = await empruntCtrl.reserverLivre(
      livre: widget.livre,
      membre: auth.membre!,
    );

    if (mounted) {
      if (ok) {
        Helpers.showSuccess(context,
            'Réservation effectuée. Vous serez notifié quand le livre sera disponible.');
      } else {
        Helpers.showError(context, empruntCtrl.errorMessage ?? 'Erreur');
      }
    }
  }

  Future<void> _soumettreAvis() async {
    if (_maNote == 0) {
      Helpers.showInfo(context, 'Veuillez attribuer une note.');
      return;
    }
    final auth = context.read<AuthController>();
    if (!auth.estConnecte) return;

    final avis = Avis(
      id: '',
      livreId: widget.livre.id,
      membreId: auth.uid!,
      membreNom: auth.membre?.nom ?? 'Anonyme',
      note: _maNote,
      commentaire:
          _avisCtrl.text.trim().isNotEmpty ? _avisCtrl.text.trim() : null,
      date: DateTime.now(),
    );

    final ok = await context.read<LivreController>().ajouterAvis(widget.livre.id, avis);
    if (mounted && ok) {
      _avisCtrl.clear();
      setState(() => _maNote = 0);
      Helpers.showSuccess(context, 'Avis soumis, merci !');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfosLivre(),
                const Divider(height: 1),
                if (widget.livre.resume != null) _buildResume(),
                const Divider(height: 1),
                _buildActions(auth),
                const Divider(height: 1),
                _buildSectionAvis(auth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.livre.couvertureUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.livre.couvertureUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.primaryLight),
                errorWidget: (_, __, ___) => _couverturePlaceholder(),
              )
            : _couverturePlaceholder(),
      ),
      actions: [
        Consumer<AuthController>(
          builder: (_, auth, __) => IconButton(
            icon: Icon(
              auth.membre?.wishlist.contains(widget.livre.id) == true
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            onPressed: auth.estConnecte
                ? () => context
                    .read<LivreController>()
                    .toggleWishlist(auth.uid!, widget.livre.id)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _couverturePlaceholder() {
    return Container(
      color: AppColors.primaryDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, color: Colors.white54, size: 80),
            const SizedBox(height: 8),
            Text(widget.livre.genre,
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosLivre() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.livre.titre,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(widget.livre.auteur,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _infoBadge(Icons.category_outlined, widget.livre.genre,
                  AppColors.primary),
              _infoBadge(
                Icons.circle,
                widget.livre.statut.label,
                Helpers.couleurEtat(widget.livre.statut.toString().split('.').last),
              ),
              if (widget.livre.anneePublication != null)
                _infoBadge(Icons.calendar_today_outlined,
                    '${widget.livre.anneePublication}', AppColors.textSecondary),
              if (widget.livre.nombrePages != null)
                _infoBadge(Icons.menu_book_outlined,
                    '${widget.livre.nombrePages} pages', AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          // Note
          Row(
            children: [
              RatingBarIndicator(
                rating: widget.livre.notemoyenne,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppColors.secondary),
                itemCount: 5,
                itemSize: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.livre.notemoyenne.toStringAsFixed(1)} (${widget.livre.nbAvis} avis)',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          if (widget.livre.editeur != null) ...[
            const SizedBox(height: 8),
            Text('Éditeur : ${widget.livre.editeur}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
          if (widget.livre.isbn != null) ...[
            const SizedBox(height: 4),
            Text('ISBN : ${widget.livre.isbn}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
          // Exemplaires
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.library_books_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${widget.livre.exemplairesDisponibles}/${widget.livre.exemplairesTotal} exemplaire(s) disponible(s)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildResume() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Résumé',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.livre.resume!,
              style: const TextStyle(height: 1.6, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActions(AuthController auth) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.livre.estDisponible) ...[
            ElevatedButton.icon(
              onPressed: _emprunter,
              icon: const Icon(Icons.library_add),
              label: const Text('Emprunter ce livre'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: auth.estConnecte ? _reserver : null,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Réserver (indisponible)'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 8),
            Text(
              'Livre ${widget.livre.statut.label.toLowerCase()}. Réservez pour être notifié.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionAvis(AuthController auth) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Avis des lecteurs',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Formulaire avis (membres connectés uniquement)
          if (auth.estConnecte) ...[
            const Text('Votre avis :',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: _maNote,
              minRating: 1,
              itemBuilder: (_, __) =>
                  const Icon(Icons.star, color: AppColors.secondary),
              onRatingUpdate: (r) => setState(() => _maNote = r),
              itemSize: 32,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _avisCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Partagez votre avis sur ce livre (optionnel)...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _soumettreAvis,
              icon: const Icon(Icons.rate_review),
              label: const Text('Soumettre mon avis'),
            ),
            const Divider(height: 32),
          ],

          // Liste des avis
          StreamBuilder<List<Avis>>(
            stream: FirestoreService().getAvisLivre(widget.livre.id),
            builder: (_, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Text(
                  'Soyez le premier à laisser un avis !',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return Column(
                children: snap.data!
                    .map((avis) => _avisItem(avis))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _avisItem(Avis avis) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              Helpers.initiales(avis.membreNom),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(avis.membreNom,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Text(Helpers.dateRelative(avis.date),
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                RatingBarIndicator(
                  rating: avis.note,
                  itemBuilder: (_, __) =>
                      const Icon(Icons.star, color: AppColors.secondary),
                  itemCount: 5,
                  itemSize: 14,
                ),
                if (avis.commentaire != null) ...[
                  const SizedBox(height: 4),
                  Text(avis.commentaire!,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
