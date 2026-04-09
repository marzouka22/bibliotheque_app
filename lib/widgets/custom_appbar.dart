import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// AppBar personnalisée réutilisable
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titre;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.titre,
    this.actions,
    this.leading,
    this.showBack = true,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        titre,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation,
      leading: leading ??
          (showBack && Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// AppBar de recherche
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const SearchAppBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      titleSpacing: 0,
      title: Container(
        height: 40,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon:
                const Icon(Icons.search, color: Colors.white, size: 20),
            suffixIcon: controller?.text.isNotEmpty == true
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        color: Colors.white, size: 18),
                    onPressed: () {
                      controller?.clear();
                      onClear?.call();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Section titre avec bouton "voir tout"
class SectionTitre extends StatelessWidget {
  final String titre;
  final String? boutonLabel;
  final VoidCallback? onBouton;

  const SectionTitre({
    super.key,
    required this.titre,
    this.boutonLabel,
    this.onBouton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 18,
                        ),
          ),
          if (boutonLabel != null && onBouton != null)
            TextButton(
              onPressed: onBouton,
              child: Text(boutonLabel!),
            ),
        ],
      ),
    );
  }
}

/// Widget de chargement
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Widget d'état vide
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String? sousTitre;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.titre,
    this.sousTitre,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              titre,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: 8),
              Text(
                sousTitre!,
                style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
