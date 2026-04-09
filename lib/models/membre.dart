import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un membre
enum StatutMembre { actif, suspendu, enAttente, inactif }

extension StatutMembreExt on StatutMembre {
  String get label {
    switch (this) {
      case StatutMembre.actif:
        return 'Actif';
      case StatutMembre.suspendu:
        return 'Suspendu';
      case StatutMembre.enAttente:
        return 'En attente';
      case StatutMembre.inactif:
        return 'Inactif';
    }
  }

  static StatutMembre fromString(String value) {
    switch (value) {
      case 'suspendu':
        return StatutMembre.suspendu;
      case 'enAttente':
        return StatutMembre.enAttente;
      case 'inactif':
        return StatutMembre.inactif;
      default:
        return StatutMembre.actif;
    }
  }

  String get value => toString().split('.').last;
}

/// Modèle de données : Membre
class Membre {
  final String uid;
  final String nom;
  final String email;
  final String? telephone;
  final String? avatarUrl;
  final DateTime dateAdhesion;
  final List<String> genresPreferes;
  final int nbEmpruntsEnCours;
  final int nbEmpruntsTotal;
  final StatutMembre statut;
  final String role; // 'visiteur', 'membre', 'admin'
  final List<String> wishlist; // IDs des livres souhaités
  final String? adresse;
  final DateTime? dateNaissance;
  final String? bio;
  final bool notificationsActives;
  final bool modeNuit;

  Membre({
    required this.uid,
    required this.nom,
    required this.email,
    this.telephone,
    this.avatarUrl,
    required this.dateAdhesion,
    this.genresPreferes = const [],
    this.nbEmpruntsEnCours = 0,
    this.nbEmpruntsTotal = 0,
    this.statut = StatutMembre.enAttente,
    this.role = 'membre',
    this.wishlist = const [],
    this.adresse,
    this.dateNaissance,
    this.bio,
    this.notificationsActives = true,
    this.modeNuit = false,
  });

  bool get estAdmin => role == 'admin';
  bool get estActif => statut == StatutMembre.actif;
  bool get peutEmprunter =>
      estActif && nbEmpruntsEnCours < 5; // max 5 emprunts

  // ── Firestore → Membre ──
  factory Membre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Membre(
      uid: doc.id,
      nom: data['nom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'],
      avatarUrl: data['avatarUrl'],
      dateAdhesion:
          (data['dateAdhesion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genresPreferes: List<String>.from(data['genresPreferes'] ?? []),
      nbEmpruntsEnCours: data['nbEmpruntsEnCours'] ?? 0,
      nbEmpruntsTotal: data['nbEmpruntsTotal'] ?? 0,
      statut: StatutMembreExt.fromString(data['statut'] ?? 'enAttente'),
      role: data['role'] ?? 'membre',
      wishlist: List<String>.from(data['wishlist'] ?? []),
      adresse: data['adresse'],
      dateNaissance: (data['dateNaissance'] as Timestamp?)?.toDate(),
      bio: data['bio'],
      notificationsActives: data['notificationsActives'] ?? true,
      modeNuit: data['modeNuit'] ?? false,
    );
  }

  // ── Membre → Map Firestore ──
  Map<String, dynamic> toFirestore() => {
        'nom': nom,
        'email': email,
        'telephone': telephone,
        'avatarUrl': avatarUrl,
        'dateAdhesion': Timestamp.fromDate(dateAdhesion),
        'genresPreferes': genresPreferes,
        'nbEmpruntsEnCours': nbEmpruntsEnCours,
        'nbEmpruntsTotal': nbEmpruntsTotal,
        'statut': statut.value,
        'role': role,
        'wishlist': wishlist,
        'adresse': adresse,
        'dateNaissance':
            dateNaissance != null ? Timestamp.fromDate(dateNaissance!) : null,
        'bio': bio,
        'notificationsActives': notificationsActives,
        'modeNuit': modeNuit,
      };

  // ── copyWith ──
  Membre copyWith({
    String? nom,
    String? telephone,
    String? avatarUrl,
    List<String>? genresPreferes,
    int? nbEmpruntsEnCours,
    int? nbEmpruntsTotal,
    StatutMembre? statut,
    String? role,
    List<String>? wishlist,
    String? adresse,
    String? bio,
    bool? notificationsActives,
    bool? modeNuit,
  }) {
    return Membre(
      uid: uid,
      nom: nom ?? this.nom,
      email: email,
      telephone: telephone ?? this.telephone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateAdhesion: dateAdhesion,
      genresPreferes: genresPreferes ?? this.genresPreferes,
      nbEmpruntsEnCours: nbEmpruntsEnCours ?? this.nbEmpruntsEnCours,
      nbEmpruntsTotal: nbEmpruntsTotal ?? this.nbEmpruntsTotal,
      statut: statut ?? this.statut,
      role: role ?? this.role,
      wishlist: wishlist ?? this.wishlist,
      adresse: adresse ?? this.adresse,
      dateNaissance: dateNaissance,
      bio: bio ?? this.bio,
      notificationsActives: notificationsActives ?? this.notificationsActives,
      modeNuit: modeNuit ?? this.modeNuit,
    );
  }

  @override
  String toString() => 'Membre(uid: $uid, nom: $nom, role: $role)';
}
