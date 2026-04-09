import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../models/emprunt.dart';
import '../../models/membre.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_appbar.dart'; // inclut LoadingWidget, EmptyStateWidget, SectionTitre
import '../../widgets/emprunt_item.dart';
import '../../widgets/livre_card.dart';
import 'ajouter_livre_screen.dart';

/// Tableau de bord administrateur
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, int> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _chargerStats();
    context.read<EmpruntController>().ecouterTousEmprunts();
  }

  Future<void> _chargerStats() async {
    final stats =
        await FirestoreService().getStatsGlobales();
    setState(() {
      _stats = stats;
      _loadingStats = false;
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titre: 'Administration',
        showBack: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tableau de bord'),
            Tab(text: 'Emprunts'),
            Tab(text: 'Membres'),
            Tab(text: 'Catalogue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDashboard(),
          _buildGestionEmprunts(),
          _buildGestionMembres(),
          _buildGestionCatalogue(),
        ],
      ),
    );
  }

  // ── TABLEAU DE BORD ──
  Widget _buildDashboard() {
    if (_loadingStats) return const LoadingWidget(message: 'Chargement des statistiques...');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitre(titre: 'Vue d\'ensemble'),
          // Métriques
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _statCard(
                label: 'Livres',
                value: '${_stats['totalLivres'] ?? 0}',
                icon: Icons.menu_book,
                color: AppColors.primary,
              ),
              _statCard(
                label: 'Membres actifs',
                value: '${_stats['membresActifs'] ?? 0}',
                icon: Icons.people,
                color: AppColors.success,
              ),
              _statCard(
                label: 'Emprunts en cours',
                value: '${_stats['empruntsEnCours'] ?? 0}',
                icon: Icons.library_books,
                color: AppColors.info,
              ),
              _statCard(
                label: 'En retard',
                value: '${_stats['empruntsEnRetard'] ?? 0}',
                icon: Icons.warning_amber,
                color: AppColors.error,
              ),
              _statCard(
                label: 'Réservations',
                value: '${_stats['reservationsEnAttente'] ?? 0}',
                icon: Icons.bookmark,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions rapides
          const SectionTitre(titre: 'Actions rapides'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _actionButton(
                label: 'Ajouter un livre',
                icon: Icons.add_circle_outline,
                onTap: () => _tabCtrl.animateTo(3),
              ),
              _actionButton(
                label: 'Valider emprunts',
                icon: Icons.assignment_turned_in_outlined,
                onTap: () => _tabCtrl.animateTo(1),
              ),
              _actionButton(
                label: 'Gérer membres',
                icon: Icons.manage_accounts_outlined,
                onTap: () => _tabCtrl.animateTo(2),
              ),
              _actionButton(
                label: 'Actualiser stats',
                icon: Icons.refresh,
                onTap: _chargerStats,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── GESTION EMPRUNTS ──
  Widget _buildGestionEmprunts() {
    return Consumer<EmpruntController>(
      builder: (_, ctrl, __) {
        final emprunts = ctrl.emprunts;
        if (emprunts.isEmpty) {
          return const EmptyStateWidget(
              icon: Icons.library_books,
              titre: 'Aucun emprunt');
        }
        return ListView.builder(
          itemCount: emprunts.length,
          itemBuilder: (_, i) => EmpruntItem(
            emprunt: emprunts[i],
            isAdmin: true,
            onRetourner: emprunts[i].statut == StatutEmprunt.enCours
                ? () async {
                    final ok =
                        await ctrl.retournerLivre(emprunts[i]);
                    if (context.mounted) {
                      ok
                          ? Helpers.showSuccess(context, 'Retour enregistré')
                          : Helpers.showError(
                              context, ctrl.errorMessage ?? 'Erreur');
                    }
                  }
                : null,
          ),
        );
      },
    );
  }

  // ── GESTION MEMBRES ──
  Widget _buildGestionMembres() {
    return StreamBuilder<List<Membre>>(
      stream: FirestoreService().getMembresStream(),
      builder: (_, snap) {
        if (!snap.hasData) return const LoadingWidget();
        final membres = snap.data!;

        return ListView.builder(
          itemCount: membres.length,
          itemBuilder: (_, i) {
            final m = membres[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(Helpers.initiales(m.nom),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                title: Text(m.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.email),
                    Text(
                      'Rôle : ${m.role} | ${m.statut.label}',
                      style: TextStyle(
                          color: m.estActif
                              ? AppColors.success
                              : AppColors.error,
                          fontSize: 12),
                    ),
                    Text(
                      'Emprunts : ${m.nbEmpruntsEnCours} en cours / ${m.nbEmpruntsTotal} total',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _actionMembre(action, m),
                  itemBuilder: (_) => [
                    if (m.statut == StatutMembre.enAttente)
                      const PopupMenuItem(
                          value: 'activer', child: Text('✅ Activer')),
                    if (m.statut == StatutMembre.actif)
                      const PopupMenuItem(
                          value: 'suspendre', child: Text('⛔ Suspendre')),
                    if (m.role != 'admin')
                      const PopupMenuItem(
                          value: 'promouvoir',
                          child: Text('⭐ Promouvoir admin')),
                    if (m.role == 'admin')
                      const PopupMenuItem(
                          value: 'retirer_admin',
                          child: Text('🔽 Retirer admin')),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _actionMembre(String action, Membre m) async {
    final fs = FirestoreService();
    switch (action) {
      case 'activer':
        await fs.updateStatutMembre(m.uid, 'actif');
        if (mounted) Helpers.showSuccess(context, '${m.nom} activé');
        break;
      case 'suspendre':
        await fs.updateStatutMembre(m.uid, 'suspendu');
        if (mounted) Helpers.showInfo(context, '${m.nom} suspendu');
        break;
      case 'promouvoir':
        await fs.updateRoleMembre(m.uid, 'admin');
        if (mounted) Helpers.showSuccess(context, '${m.nom} promu admin');
        break;
      case 'retirer_admin':
        await fs.updateRoleMembre(m.uid, 'membre');
        if (mounted) Helpers.showInfo(context, 'Droits admin retirés');
        break;
    }
  }

  // ── GESTION CATALOGUE ──
  Widget _buildGestionCatalogue() {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AjouterLivreScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un livre'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: ctrl.livres.length,
              itemBuilder: (_, i) => LivreCard(
                livre: ctrl.livres[i],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AjouterLivreScreen(livre: ctrl.livres[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
