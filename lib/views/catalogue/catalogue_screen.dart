import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/livre_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/livre.dart';
import '../../utils/constants.dart';
import '../../widgets/livre_card.dart';
import '../../widgets/custom_appbar.dart';
// LoadingWidget et EmptyStateWidget sont définis dans custom_appbar.dart
import 'livre_detail_screen.dart';

/// Écran du catalogue de livres
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final _searchCtrl = TextEditingController();
  bool _modeGrille = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivreController>().ecouterLivres();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: Icon(_modeGrille ? Icons.list : Icons.grid_view),
            color: Colors.white,
            onPressed: () => setState(() => _modeGrille = !_modeGrille),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltres(),
          Expanded(child: _buildListeLivres()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => context.read<LivreController>().setRecherche(v),
        decoration: InputDecoration(
          hintText: 'Titre, auteur, ISBN...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<LivreController>().setRecherche('');
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFiltres() {
    return Consumer<LivreController>(
      builder: (_, ctrl, __) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Filtre "Tous"
              _filterChip(
                label: 'Tous',
                selected: ctrl.filtreGenre.isEmpty && ctrl.filtreStatut.isEmpty,
                onSelected: (_) => ctrl.clearFiltres(),
              ),
              const SizedBox(width: 8),
              // Filtre disponibilité
              _filterChip(
                label: '✅ Disponibles',
                selected: ctrl.filtreStatut == 'disponible',
                onSelected: (_) => ctrl.setFiltreStatut(
                    ctrl.filtreStatut == 'disponible' ? '' : 'disponible'),
              ),
              const SizedBox(width: 8),
              // Filtres genres
              ...AppConstants.genres.map((genre) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _filterChip(
                      label: genre,
                      selected: ctrl.filtreGenre == genre,
                      onSelected: (_) => ctrl.setFiltreGenre(
                          ctrl.filtreGenre == genre ? '' : genre),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildListeLivres() {
    return Consumer2<LivreController, AuthController>(
      builder: (_, livreCtrl, authCtrl, __) {
        if (livreCtrl.isLoading) {
          return const LoadingWidget(message: 'Chargement du catalogue...');
        }

        final livres = livreCtrl.livresFiltres;

        if (livres.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.menu_book,
            titre: 'Aucun livre trouvé',
            sousTitre: 'Essayez de modifier vos filtres de recherche',
            action: TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                livreCtrl.clearFiltres();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
            ),
          );
        }

        if (_modeGrille) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: livres.length,
            itemBuilder: (_, i) => LivreCard(
              livre: livres[i],
              onTap: () => _ouvrirDetail(livres[i]),
              modeGrille: true,
              isInWishlist: authCtrl.membre?.wishlist.contains(livres[i].id) ?? false,
              onWishlist: authCtrl.estConnecte
                  ? () => livreCtrl.toggleWishlist(
                      authCtrl.uid!, livres[i].id)
                  : null,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: livres.length,
          itemBuilder: (_, i) => LivreCard(
            livre: livres[i],
            onTap: () => _ouvrirDetail(livres[i]),
            isInWishlist: authCtrl.membre?.wishlist.contains(livres[i].id) ?? false,
            onWishlist: authCtrl.estConnecte
                ? () =>
                    livreCtrl.toggleWishlist(authCtrl.uid!, livres[i].id)
                : null,
          ),
        );
      },
    );
  }

  void _ouvrirDetail(Livre livre) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LivreDetailScreen(livre: livre)),
    );
  }
}
