import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/livre.dart';
import '../utils/constants.dart';

/// Carte d'affichage d'un livre (liste ou grille)
class LivreCard extends StatelessWidget {
  final Livre livre;
  final VoidCallback onTap;
  final VoidCallback? onWishlist;
  final bool isInWishlist;
  final bool modeGrille;

  const LivreCard({
    super.key,
    required this.livre,
    required this.onTap,
    this.onWishlist,
    this.isInWishlist = false,
    this.modeGrille = false,
  });

  @override
  Widget build(BuildContext context) {
    return modeGrille ? _buildGrille(context) : _buildListe(context);
  }

  Widget _buildListe(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Couverture
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _couverture(width: 65, height: 95),
              ),
              const SizedBox(width: 14),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      livre.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      livre.auteur,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(child: _badgeGenre()),
                        const SizedBox(width: 6),
                        Flexible(child: _badgeStatut()),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _noteWidget(),
                  ],
                ),
              ),
              // Wishlist
              if (onWishlist != null)
                IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : AppColors.textLight,
                    size: 22,
                  ),
                  onPressed: onWishlist,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrille(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couverture — prend l'espace restant
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _couverture(width: double.infinity, height: double.infinity),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _badgeStatutSmall(),
                  ),
                  if (onWishlist != null)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onWishlist,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white70,
                          child: Icon(
                            isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isInWishlist ? Colors.red : Colors.grey,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Infos — hauteur fixe
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    livre.titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    livre.auteur,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  _noteWidget(small: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _couverture({required double width, required double height}) {
    if (livre.couvertureUrl != null && livre.couvertureUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: livre.couvertureUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholderCouverture(width, height),
        errorWidget: (_, __, ___) => _placeholderCouverture(width, height),
      );
    }
    return _placeholderCouverture(width, height);
  }

  Widget _placeholderCouverture(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: AppColors.primaryLight.withOpacity(0.15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book,
              color: AppColors.primaryLight.withOpacity(0.5), size: 32),
          const SizedBox(height: 4),
          Text(
            livre.genre,
            style: TextStyle(
                color: AppColors.primaryLight.withOpacity(0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _badgeGenre() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        livre.genre,
        style: const TextStyle(
            color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _badgeStatut() {
    Color color;
    switch (livre.statut) {
      case StatutLivre.disponible:
        color = AppColors.success;
        break;
      case StatutLivre.emprunte:
        color = AppColors.error;
        break;
      case StatutLivre.reserve:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        livre.statut.label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _badgeStatutSmall() {
    Color color;
    switch (livre.statut) {
      case StatutLivre.disponible:
        color = AppColors.success;
        break;
      case StatutLivre.emprunte:
        color = AppColors.error;
        break;
      case StatutLivre.reserve:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
      child: Text(
        livre.statut.label,
        style:
            const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _noteWidget({bool small = false}) {
    if (livre.notemoyenne == 0) {
      return Text(
        'Pas encore noté',
        style: TextStyle(
            color: AppColors.textLight, fontSize: small ? 10 : 12),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: AppColors.secondary, size: small ? 12 : 14),
        const SizedBox(width: 2),
        Text(
          livre.notemoyenne.toStringAsFixed(1),
          style: TextStyle(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
        ),
        Text(
          ' (${livre.nbAvis})',
          style: TextStyle(
              fontSize: small ? 10 : 11, color: AppColors.textLight),
        ),
      ],
    );
  }
}
