import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/livre_controller.dart';
import 'controllers/emprunt_controller.dart';
import 'controllers/evenement_controller.dart';
import 'controllers/message_controller.dart';

// Vues
import 'views/home_screen.dart';
import 'views/profile_screen.dart';
import 'views/catalogue/catalogue_screen.dart';
import 'views/emprunts/emprunts_screen.dart';
import 'views/evenements/evenements_screen.dart';
import 'views/messagerie/messagerie_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/auth/login_screen.dart';
import 'firebase_options.dart';

// Utilitaires
import 'utils/constants.dart';

/// ──────────────────────────────────────────────
///  Point d'entrée de l'application
///  DEVMOB-ApcPedagogie-16 — Bibliothèque de Quartier
/// ──────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️  Initialisation Firebase — Voir firebase_options.dart après setup
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Localisation française pour les dates
  await initializeDateFormatting('fr_FR', null);

  runApp(const BiblioApp());
}

/// Application principale
class BiblioApp extends StatelessWidget {
  const BiblioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()..init()),
        ChangeNotifierProvider(create: (_) => LivreController()),
        ChangeNotifierProvider(create: (_) => EmpruntController()),
        ChangeNotifierProvider(create: (_) => EvenementController()),
        ChangeNotifierProvider(create: (_) => MessageController()),
      ],
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            // Thème clair / sombre automatique
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: auth.membre?.modeNuit == true
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: AppRoutes.home,
            routes: {
              AppRoutes.home: (_) => const MainNavigationScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.adminDashboard: (_) => const AdminDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}

/// ──────────────────────────────────────────────
///  Navigation principale — BottomNavigationBar
///  5 onglets : Accueil / Catalogue / Événements / Messages / Profil
/// ──────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // IndexedStack pour conserver l'état de chaque onglet
  final List<Widget> _screens = const [
    HomeScreen(),
    CatalogueScreen(),
    EvenementsScreen(),
    MessagerieScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Consumer<MessageController>(
        builder: (_, msgCtrl, __) {
          final nbNonLus =
              auth.uid != null ? msgCtrl.nbNonLusPour(auth.uid!) : 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              // ── Accueil ──
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              // ── Catalogue ──
              const BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Catalogue',
              ),
              // ── Événements ──
              const BottomNavigationBarItem(
                icon: Icon(Icons.event_outlined),
                activeIcon: Icon(Icons.event),
                label: 'Événements',
              ),
              // ── Messages (avec badge non-lus) ──
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: nbNonLus > 0,
                  label: Text('$nbNonLus'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  isLabelVisible: nbNonLus > 0,
                  label: Text('$nbNonLus'),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'Messages',
              ),
              // ── Profil ──
              BottomNavigationBarItem(
                icon: auth.estConnecte && auth.membre != null
                    ? CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.textLight.withOpacity(0.25),
                        child: Text(
                          auth.membre!.nom[0].toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : const Icon(Icons.person_outline),
                activeIcon: auth.estConnecte && auth.membre != null
                    ? CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          auth.membre!.nom[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}
