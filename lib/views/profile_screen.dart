import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/membre.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_appbar.dart'; // inclut EmptyStateWidget
import 'auth/login_screen.dart';
import 'profile/edit_profil_screen.dart';
import 'profile/wishlist_screen.dart';
import 'emprunts/emprunts_screen.dart';

/// Écran de profil utilisateur
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.estConnecte) {
      return Scaffold(
        appBar: const CustomAppBar(titre: 'Mon Profil', showBack: false),
        body: EmptyStateWidget(
          icon: Icons.person_outline,
          titre: 'Non connecté',
          sousTitre: 'Connectez-vous pour accéder à votre profil',
          action: ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.login),
            label: const Text('Se connecter'),
          ),
        ),
      );
    }

    final membre = auth.membre!;

    return Scaffold(
      appBar: CustomAppBar(
        titre: 'Mon Profil',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editerProfil(context, auth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header profil
            _buildHeaderProfil(membre),
            const SizedBox(height: 8),
            // Stats
            _buildStats(membre),
            const Divider(height: 1),
            // Menu
            _buildMenu(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderProfil(Membre membre) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                backgroundImage: membre.avatarUrl != null
                    ? NetworkImage(membre.avatarUrl!) as ImageProvider
                    : null,
                child: membre.avatarUrl == null
                    ? Text(
                        Helpers.initiales(membre.nom),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary,
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            membre.nom,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            membre.email,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _badge(membre.role.toUpperCase(),
                  membre.estAdmin ? AppColors.secondary : Colors.white24),
              const SizedBox(width: 8),
              _badge(membre.statut.label,
                  membre.estActif ? AppColors.success : AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStats(Membre membre) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _statItem(
              '${membre.nbEmpruntsEnCours}', 'En cours', Icons.library_books),
          _dividerVertical(),
          _statItem('${membre.nbEmpruntsTotal}', 'Total emprunts',
              Icons.history),
          _dividerVertical(),
          _statItem('${membre.wishlist.length}', 'Wishlist',
              Icons.favorite_border),
          _dividerVertical(),
          _statItem(
              Helpers.formatDate(membre.dateAdhesion).split('/').last,
              'Membre depuis',
              Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _dividerVertical() {
    return Container(
        height: 50, width: 1, color: AppColors.divider);
  }

  Widget _buildMenu(BuildContext context, AuthController auth) {
    final membre = auth.membre!;
    return Column(
      children: [
        _menuSection('Mon compte', [
          _menuItem(Icons.person_outline, 'Informations personnelles', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditProfilScreen()));
          }),
          _menuItem(Icons.category_outlined, 'Genres préférés', () {
            _choisirGenres(context, auth);
          }),
          _menuItem(Icons.notifications_outlined, 'Notifications',
              () {}, trailing: Switch(
                value: membre.notificationsActives,
                onChanged: (val) => auth.updateProfil({'notificationsActives': val}),
                activeColor: AppColors.primary,
              )),
          _menuItem(Icons.dark_mode_outlined, 'Mode sombre', () {},
              trailing: Switch(
                value: membre.modeNuit,
                onChanged: (val) => auth.updateProfil({'modeNuit': val}),
                activeColor: AppColors.primary,
              )),
        ]),
        _menuSection('Bibliothèque', [
          _menuItem(
              Icons.favorite_border, 'Ma liste de souhaits', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()));
          }, badge: '${membre.wishlist.length}'),
          _menuItem(Icons.history, 'Historique des emprunts', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmpruntsScreen()));
          }),
          _menuItem(Icons.star_outline, 'Mes avis', () {
            Helpers.showInfo(context, 'Fonctionnalité bientôt disponible');
          }),
        ]),
        if (membre.estAdmin) ...[
          _menuSection('Administration', [
            _menuItem(Icons.admin_panel_settings_outlined, 'Tableau de bord admin', () {
              Navigator.pushNamed(context, AppRoutes.adminDashboard);
            }, color: AppColors.accent),
          ]),
        ],
        _menuSection('', [
          _menuItem(Icons.info_outline, 'À propos', () {}),
          _menuItem(Icons.help_outline, 'Aide & Support', () {}),
          _menuItem(
            Icons.logout,
            'Se déconnecter',
            () => _seDeconnecter(context, auth),
            color: AppColors.error,
          ),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _menuSection(String titre, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              titre.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  letterSpacing: 1.2),
            ),
          ),
        Container(
          color: Colors.white,
          child: Column(children: items),
        ),
        const Divider(height: 8),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
    String? badge,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color ?? AppColors.textPrimary, fontSize: 15)),
      trailing: trailing ??
          (badge != null
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11)))
              : const Icon(Icons.chevron_right,
                  color: AppColors.textLight)),
      onTap: onTap,
    );
  }

  Future<void> _seDeconnecter(
      BuildContext context, AuthController auth) async {
    final confirm = await Helpers.confirmer(
      context,
      titre: 'Se déconnecter',
      message: 'Voulez-vous vous déconnecter ?',
      boutonConfirmer: 'Déconnecter',
      couleurConfirmer: AppColors.error,
    );
    if (!confirm) return;
    await auth.deconnecter();
  }

  void _editerProfil(BuildContext context, AuthController auth) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EditProfilScreen()));
  }

  Future<void> _choisirGenres(
      BuildContext context, AuthController auth) async {
    final membre = auth.membre!;
    final selectionnes = List<String>.from(membre.genresPreferes);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Genres préférés',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Sélectionnez vos genres favoris',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.genres.map((g) {
                  final selected = selectionnes.contains(g);
                  return FilterChip(
                    label: Text(g),
                    selected: selected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    onSelected: (val) {
                      setModalState(() {
                        if (val) {
                          selectionnes.add(g);
                        } else {
                          selectionnes.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth
                        .updateProfil({'genresPreferes': selectionnes});
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted)
                      Helpers.showSuccess(
                          context, 'Genres mis à jour !');
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
