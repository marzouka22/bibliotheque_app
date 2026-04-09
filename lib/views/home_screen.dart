import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/auth_controller.dart';
import '../controllers/livre_controller.dart';
import '../controllers/evenement_controller.dart';
import '../models/livre.dart';
import '../models/evenement.dart';
import '../models/membre.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/custom_appbar.dart'; // inclut SectionTitre
import '../widgets/livre_card.dart';
import 'catalogue/catalogue_screen.dart';
import 'catalogue/livre_detail_screen.dart';

/// Écran d'accueil — Recommandations + Nouveautés
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivreController>().ecouterLivres();
      context.read<EvenementController>().ecouterEvenements(aVenir: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(auth),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auth.estConnecte && auth.membre?.statut == StatutMembre.enAttente)
                  _buildBanniereValidation(),
                _buildSection_Disponibles(),
                _buildSectionEvenements(),
                _buildSectionNouveautes(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AuthController auth) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                auth.estConnecte
                    ? 'Bonjour, ${auth.membre?.nom.split(' ').first ?? ''} 👋'
                    : 'Bienvenue à la bibliothèque 📚',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.estConnecte
                    ? '${auth.membre?.nbEmpruntsEnCours ?? 0} emprunt(s) en cours'
                    : 'Découvrez notre catalogue',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatalogueScreen()),
          ),
        ),
        if (auth.estConnecte)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
      ],
    );
  }

  Widget _buildBanniereValidation() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Votre compte est en attente de validation par un administrateur.',
              style: TextStyle(
                  color: AppColors.warning, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection_Disponibles() {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) {
        final dispos = ctrl.livres
            .where((l) => l.estDisponible)
            .take(10)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitre(
              titre: '✅ Disponibles maintenant',
              boutonLabel: 'Voir tout',
              onBouton: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CatalogueScreen())),
            ),
            if (dispos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Aucun livre disponible pour le moment.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              SizedBox(
                height: 230,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: dispos.length,
                  itemBuilder: (_, i) => SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: LivreCard(
                        livre: dispos[i],
                        modeGrille: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  LivreDetailScreen(livre: dispos[i])),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSectionEvenements() {
    return Consumer<EvenementController>(
      builder: (_, ctrl, __) {
        final evts = ctrl.evenementsAVenir.take(3).toList();
        if (evts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitre(titre: '📅 Prochains événements'),
            ...evts.map((e) => _evenementMini(e)),
          ],
        );
      },
    );
  }

  Widget _evenementMini(Evenement evenement) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary.withOpacity(0.15),
          child: Icon(_typeIcon(evenement.type), color: AppColors.secondary),
        ),
        title: Text(evenement.titre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          '${Helpers.formatDate(evenement.dateDebut)} • ${evenement.lieu}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: evenement.placesDispo
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            evenement.placesDispo ? 'Places dispo' : 'Complet',
            style: TextStyle(
                fontSize: 10,
                color: evenement.placesDispo
                    ? AppColors.success
                    : AppColors.error,
                fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () => Navigator.pushNamed(context, AppRoutes.evenements),
      ),
    );
  }

  Widget _buildSectionNouveautes() {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) {
        final nouveautes = ctrl.livres.take(6).toList();
        if (nouveautes.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitre(
              titre: '🆕 Dernières acquisitions',
              boutonLabel: 'Tout voir',
              onBouton: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CatalogueScreen())),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nouveautes.length,
              itemBuilder: (_, i) => LivreCard(
                livre: nouveautes[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          LivreDetailScreen(livre: nouveautes[i])),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _typeIcon(TypeEvenement type) {
    switch (type) {
      case TypeEvenement.lecture:
        return Icons.menu_book;
      case TypeEvenement.conference:
        return Icons.mic;
      case TypeEvenement.atelier:
        return Icons.handyman;
      default:
        return Icons.event;
    }
  }
}
