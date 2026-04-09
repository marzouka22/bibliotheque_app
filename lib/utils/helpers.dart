import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Helpers - Fonctions utilitaires globales
class Helpers {
  // ── Format de date ──
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
  }

  static String formatDateHeure(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(date);
  }

  static String formatHeure(DateTime date) {
    return DateFormat('HH:mm', 'fr_FR').format(date);
  }

  // ── Durée relative ──
  static String dateRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return 'il y a ${diff.inMinutes} min';
      return 'il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'hier';
    } else if (diff.inDays < 7) {
      return 'il y a ${diff.inDays} jours';
    } else if (diff.inDays < 30) {
      return 'il y a ${(diff.inDays / 7).floor()} semaine(s)';
    } else {
      return formatDate(date);
    }
  }

  // ── Jours restants ──
  static int joursRestants(DateTime dateRetour) {
    return dateRetour.difference(DateTime.now()).inDays;
  }

  static String joursRestantsLabel(DateTime dateRetour) {
    final jours = joursRestants(dateRetour);
    if (jours < 0) return 'En retard de ${jours.abs()} jour(s)';
    if (jours == 0) return 'Retour aujourd\'hui';
    return 'Retour dans $jours jour(s)';
  }

  // ── Couleur selon état ──
  static Color couleurEtat(String statut) {
    switch (statut) {
      case AppConstants.statutDisponible:
        return AppColors.success;
      case AppConstants.statutEmprunte:
        return AppColors.error;
      case AppConstants.statutReserve:
        return AppColors.warning;
      default:
        return AppColors.textLight;
    }
  }

  static Color couleurRetard(DateTime dateRetour) {
    final jours = joursRestants(dateRetour);
    if (jours < 0) return AppColors.error;
    if (jours <= 3) return AppColors.warning;
    return AppColors.success;
  }

  // ── Initiales ──
  static String initiales(String nom) {
    final parts = nom.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ── Snackbars ──
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Dialogue de confirmation ──
  static Future<bool> confirmer(
    BuildContext context, {
    required String titre,
    required String message,
    String boutonConfirmer = 'Confirmer',
    String boutonAnnuler = 'Annuler',
    Color? couleurConfirmer,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titre),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(boutonAnnuler),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: couleurConfirmer != null
                ? ElevatedButton.styleFrom(backgroundColor: couleurConfirmer)
                : null,
            child: Text(boutonConfirmer),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Calcul date de retour ──
  static DateTime calculerDateRetour({
    DateTime? dateEmprunt,
    int dureeJours = AppConstants.dureeEmpruntJours,
  }) {
    final debut = dateEmprunt ?? DateTime.now();
    return debut.add(Duration(days: dureeJours));
  }

  // ── Formatage nombre ──
  static String formatNombre(int nombre) {
    if (nombre >= 1000000) return '${(nombre / 1000000).toStringAsFixed(1)}M';
    if (nombre >= 1000) return '${(nombre / 1000).toStringAsFixed(1)}K';
    return nombre.toString();
  }

  // ── Génération UUID simple ──
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
