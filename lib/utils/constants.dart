import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  COULEURS PRINCIPALES (Palette Bleu/Jaune/Orange)
// ─────────────────────────────────────────────
class AppColors {
  // Primaire
  static const Color primary = Color(0xFF1A3C5E);       // Bleu bibliothèque
  static const Color primaryLight = Color(0xFF2D6A9F);
  static const Color primaryDark = Color(0xFF0D2137);

  // Secondaire
  static const Color secondary = Color(0xFFF5A623);     // Jaune/Ambre
  static const Color secondaryLight = Color(0xFFFFCB6B);
  static const Color secondaryDark = Color(0xFFC77D00);

  // Accent
  static const Color accent = Color(0xFFE8572A);        // Orange
  static const Color accentLight = Color(0xFFFF8C5A);

  // Neutres
  static const Color background = Color(0xFFF8F4EF);    // Beige clair
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0D6C8);

  // Texte
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textLight = Color(0xFFAFAFC0);

  // États
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Dark Mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2A2A2A);
}

// ─────────────────────────────────────────────
//  THÈME CLAIR
// ─────────────────────────────────────────────
ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: null,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      fontFamily: null, // Utilise la police système par défaut
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: null,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
        displayMedium: TextStyle(
            fontFamily: null,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
        headlineMedium: TextStyle(
            fontFamily: null,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
        titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight.withOpacity(0.1),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: AppColors.divider,
    );

// ─────────────────────────────────────────────
//  THÈME SOMBRE
// ─────────────────────────────────────────────
ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.secondaryLight,
        unselectedItemColor: Colors.grey,
      ),
    );

// ─────────────────────────────────────────────
//  CONSTANTES APPLICATION
// ─────────────────────────────────────────────
class AppConstants {
  // App Info
  static const String appName = 'BiblioApp';
  static const String appVersion = '1.0.0';

  // Emprunt
  static const int dureeEmpruntJours = 21;      // 3 semaines
  static const int maxEmpruntsSimultanes = 5;
  static const int delaiProlongationJours = 14;
  static const int nbRelancesMax = 3;

  // Catalogue
  static const int nbLivresParPage = 20;
  static const double noteMinimale = 1.0;
  static const double noteMaximale = 5.0;

  // Collections Firestore
  static const String colLivres = 'livres';
  static const String colMembres = 'membres';
  static const String colEmprunts = 'emprunts';
  static const String colReservations = 'reservations';
  static const String colEvenements = 'evenements';
  static const String colMessages = 'messages';
  static const String colConversations = 'conversations';
  static const String colAvis = 'avis';

  // Storage paths
  static const String storageCouverts = 'couvertures/';
  static const String storagePhotos = 'photos/';
  static const String storageAvatars = 'avatars/';

  // Genres littéraires
  static const List<String> genres = [
    'Roman',
    'Policier',
    'Science-Fiction',
    'Fantasy',
    'Biographie',
    'Histoire',
    'Sciences',
    'Poésie',
    'Théâtre',
    'Bande Dessinée',
    'Jeunesse',
    'Développement Personnel',
    'Cuisine',
    'Voyage',
    'Art',
    'Philosophie',
  ];

  // Statuts
  static const String statutDisponible = 'disponible';
  static const String statutEmprunte = 'emprunte';
  static const String statutReserve = 'reserve';
  static const String statutIndisponible = 'indisponible';

  // Rôles utilisateurs
  static const String roleVisiteur = 'visiteur';
  static const String roleMembre = 'membre';
  static const String roleAdmin = 'admin';
}

// ─────────────────────────────────────────────
//  ROUTES
// ─────────────────────────────────────────────
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String catalogue = '/catalogue';
  static const String livreDetail = '/livre-detail';
  static const String emprunts = '/emprunts';
  static const String evenements = '/evenements';
  static const String messagerie = '/messagerie';
  static const String profil = '/profil';
  static const String adminDashboard = '/admin';
  static const String adminCatalogue = '/admin/catalogue';
  static const String adminMembres = '/admin/membres';
  static const String adminEmprunts = '/admin/emprunts';
  static const String scanner = '/scanner';
}
