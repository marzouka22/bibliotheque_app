/// Validators - Validation des formulaires
class Validators {
  // ── Email ──
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  // ── Mot de passe ──
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Au moins 6 caractères';
    }
    return null;
  }

  // ── Confirmation de mot de passe ──
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Veuillez confirmer le mot de passe';
      }
      if (value != password) {
        return 'Les mots de passe ne correspondent pas';
      }
      return null;
    };
  }

  // ── Champ requis ──
  static String? required(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  // ── Nom ──
  static String? nom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom est requis';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  // ── Téléphone ──
  static String? telephone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    final phoneRegex = RegExp(r'^[+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  // ── ISBN ──
  static String? isbn(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optionnel
    final clean = value.replaceAll(RegExp(r'[-\s]'), '');
    if (clean.length != 10 && clean.length != 13) {
      return 'ISBN invalide (10 ou 13 chiffres)';
    }
    return null;
  }

  // ── Année ──
  static String? annee(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final year = int.tryParse(value.trim());
    if (year == null) return 'Année invalide';
    if (year < 1000 || year > DateTime.now().year + 1) return 'Année hors limites';
    return null;
  }

  // ── URL ──
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final urlRegex = RegExp(
        r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');
    if (!urlRegex.hasMatch(value.trim())) return 'URL invalide';
    return null;
  }

  // ── Minimum de caractères ──
  static String? Function(String?) minLength(int min, {String? message}) {
    return (String? value) {
      if (value == null || value.trim().length < min) {
        return message ?? 'Minimum $min caractères requis';
      }
      return null;
    };
  }
}
