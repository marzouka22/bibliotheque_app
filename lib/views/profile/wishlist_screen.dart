import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/livre_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/livre_card.dart';
import '../catalogue/livre_detail_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final membre = context.watch<AuthController>().membre;
    final livreCtrl = context.watch<LivreController>();

    final wishlistLivres = livreCtrl.livres
        .where((l) => membre?.wishlist.contains(l.id) ?? false)
        .toList();

    return Scaffold(
      appBar: const CustomAppBar(titre: 'Ma liste de souhaits'),
      body: wishlistLivres.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.favorite_border,
              titre: 'Liste vide',
              sousTitre:
                  'Ajoutez des livres à votre liste de souhaits depuis le catalogue',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: wishlistLivres.length,
              itemBuilder: (_, i) => LivreCard(
                livre: wishlistLivres[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        LivreDetailScreen(livre: wishlistLivres[i]),
                  ),
                ),
              ),
            ),
    );
  }
}
