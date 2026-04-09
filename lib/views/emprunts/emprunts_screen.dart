import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/emprunt_controller.dart';
import '../../models/emprunt.dart';
import '../../models/reservation.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_appbar.dart'; // inclut LoadingWidget, EmptyStateWidget
import '../../widgets/emprunt_item.dart';

/// Écran de gestion des emprunts du membre
class EmpruntsScreen extends StatefulWidget {
  const EmpruntsScreen({super.key});

  @override
  State<EmpruntsScreen> createState() => _EmpruntsScreenState();
}

class _EmpruntsScreenState extends State<EmpruntsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        context.read<EmpruntController>().ecouterEmprunts(uid);
        context.read<EmpruntController>().ecouterReservations(uid);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.estConnecte) {
      return Scaffold(
        appBar: const CustomAppBar(titre: 'Mes Emprunts', showBack: false),
        body: EmptyStateWidget(
          icon: Icons.lock_outline,
          titre: 'Connexion requise',
          sousTitre: 'Connectez-vous pour consulter vos emprunts',
          action: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        titre: 'Mes Emprunts',
        showBack: false,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'En cours'),
            Tab(text: 'Réservations'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _EmpruntsEnCours(),
          _Reservations(),
          _Historique(),
        ],
      ),
    );
  }
}

class _EmpruntsEnCours extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EmpruntController>(
      builder: (_, ctrl, __) {
        if (ctrl.isLoading) {
          return const LoadingWidget(message: 'Chargement...');
        }
        final emprunts = ctrl.empruntsEnCours;
        if (emprunts.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.library_books_outlined,
            titre: 'Aucun emprunt en cours',
            sousTitre: 'Parcourez le catalogue pour emprunter un livre',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: emprunts.length,
          itemBuilder: (_, i) => EmpruntItem(
            emprunt: emprunts[i],
            onRetourner: () => _retourner(context, emprunts[i]),
            onProlonger: () => _prolonger(context, emprunts[i]),
          ),
        );
      },
    );
  }

  Future<void> _retourner(BuildContext context, Emprunt emprunt) async {
    final confirm = await Helpers.confirmer(
      context,
      titre: 'Confirmer le retour',
      message: 'Retourner "${emprunt.livretitre}" ?',
      boutonConfirmer: 'Retourner',
    );
    if (!confirm) return;
    final ctrl = context.read<EmpruntController>();
    final ok = await ctrl.retournerLivre(emprunt);
    if (context.mounted) {
      ok
          ? Helpers.showSuccess(context, 'Livre retourné avec succès !')
          : Helpers.showError(context, ctrl.errorMessage ?? 'Erreur');
    }
  }

  Future<void> _prolonger(BuildContext context, Emprunt emprunt) async {
    final confirm = await Helpers.confirmer(
      context,
      titre: 'Prolonger l\'emprunt',
      message:
          'Prolonger de ${AppConstants.delaiProlongationJours} jours supplémentaires ?',
      boutonConfirmer: 'Prolonger',
    );
    if (!confirm) return;
    final ctrl = context.read<EmpruntController>();
    final ok = await ctrl.prolongerEmprunt(emprunt);
    if (context.mounted) {
      ok
          ? Helpers.showSuccess(context, 'Emprunt prolongé !')
          : Helpers.showError(context, ctrl.errorMessage ?? 'Erreur');
    }
  }
}

class _Reservations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EmpruntController>(
      builder: (_, ctrl, __) {
        final reservations = ctrl.reservations
            .where((r) => r.statut == StatutReservation.enAttente)
            .toList();

        if (reservations.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.bookmark_border,
            titre: 'Aucune réservation',
            sousTitre:
                'Réservez un livre indisponible pour être notifié quand il revient',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reservations.length,
          itemBuilder: (_, i) {
            final r = reservations[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.warning,
                  child: Icon(Icons.bookmark, color: Colors.white),
                ),
                title: Text(r.livretitre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.livreAuteur),
                    Text(
                      'Position ${r.positionFile} dans la file',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 12),
                    ),
                    Text(
                      'Réservé le ${Helpers.formatDate(r.dateReservation)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final ok =
                        await ctrl.annulerReservation(r);
                    if (context.mounted) {
                      ok
                          ? Helpers.showSuccess(
                              context, 'Réservation annulée')
                          : Helpers.showError(
                              context, ctrl.errorMessage ?? 'Erreur');
                    }
                  },
                  child: const Text('Annuler',
                      style: TextStyle(color: AppColors.error)),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class _Historique extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EmpruntController>(
      builder: (_, ctrl, __) {
        final historique = ctrl.historique;
        if (historique.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.history,
            titre: 'Aucun historique',
            sousTitre: 'Vos livres retournés apparaîtront ici',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: historique.length,
          itemBuilder: (_, i) => EmpruntItem(emprunt: historique[i]),
        );
      },
    );
  }
}
