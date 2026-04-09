import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/emprunt.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Widget d'affichage d'un emprunt en cours ou historique
class EmpruntItem extends StatelessWidget {
  final Emprunt emprunt;
  final VoidCallback? onRetourner;
  final VoidCallback? onProlonger;
  final bool isAdmin;

  const EmpruntItem({
    super.key,
    required this.emprunt,
    this.onRetourner,
    this.onProlonger,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnRetard = emprunt.estEnRetard;
    final isRetourne = emprunt.statut == StatutEmprunt.retourne;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couverture
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _couverture(),
            ),
            const SizedBox(width: 12),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre & Auteur
                  Text(
                    emprunt.livretitre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    emprunt.livreAuteur,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Dates
                  if (!isRetourne) ...[
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Emprunté le ${Helpers.formatDate(emprunt.dateEmprunt)}',
                    ),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.event_available_outlined,
                      'Retour le ${Helpers.formatDate(emprunt.dateRetourPrevue)}',
                      color: isEnRetard
                          ? AppColors.error
                          : Helpers.couleurRetard(emprunt.dateRetourPrevue),
                    ),
                    const SizedBox(height: 4),
                    _retardLabel(isEnRetard),
                  ] else ...[
                    _infoRow(
                      Icons.check_circle_outline,
                      'Retourné le ${Helpers.formatDate(emprunt.dateRetourEffective!)}',
                      color: AppColors.success,
                    ),
                  ],

                  // Membre (admin seulement)
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    _infoRow(Icons.person_outline, emprunt.membreNom),
                  ],

                  // Actions
                  if (!isRetourne && (onRetourner != null || onProlonger != null)) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (onProlonger != null &&
                            emprunt.nbProlongations == 0) ...[
                          OutlinedButton.icon(
                            onPressed: onProlonger,
                            icon: const Icon(Icons.update, size: 16),
                            label: const Text('Prolonger',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onRetourner != null)
                          ElevatedButton.icon(
                            onPressed: onRetourner,
                            icon: const Icon(Icons.assignment_return, size: 16),
                            label: const Text('Retourner',
                                style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEnRetard
                                  ? AppColors.error
                                  : AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Badge statut
            _badgeStatut(),
          ],
        ),
      ),
    );
  }

  Widget _couverture() {
    if (emprunt.livreCouvertureUrl != null &&
        emprunt.livreCouvertureUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: emprunt.livreCouvertureUrl!,
        width: 60,
        height: 85,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 60,
        height: 85,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.menu_book,
            color: AppColors.primaryLight, size: 28),
      );

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12, color: color ?? AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _retardLabel(bool isEnRetard) {
    if (isEnRetard) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '⚠️ En retard de ${emprunt.joursRetard} jour(s)',
          style: const TextStyle(
              color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Text(
      Helpers.joursRestantsLabel(emprunt.dateRetourPrevue),
      style: TextStyle(
          color: Helpers.couleurRetard(emprunt.dateRetourPrevue),
          fontSize: 12,
          fontWeight: FontWeight.w500),
    );
  }

  Widget _badgeStatut() {
    String label;
    Color color;
    switch (emprunt.statut) {
      case StatutEmprunt.enCours:
        label = 'En cours';
        color = AppColors.info;
        break;
      case StatutEmprunt.retourne:
        label = 'Retourné';
        color = AppColors.success;
        break;
      case StatutEmprunt.enRetard:
        label = 'Retard';
        color = AppColors.error;
        break;
      case StatutEmprunt.prolonge:
        label = 'Prolongé';
        color = AppColors.warning;
        break;
      default:
        label = '-';
        color = AppColors.textLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
