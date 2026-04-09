import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut de disponibilité d'un livre
enum StatutLivre { disponible, emprunte, reserve, indisponible }

extension StatutLivreExt on StatutLivre {
  String get label {
    switch (this) {
      case StatutLivre.disponible:
        return 'Disponible';
      case StatutLivre.emprunte:
        return 'Emprunté';
      case StatutLivre.reserve:
        return 'Réservé';
      case StatutLivre.indisponible:
        return 'Indisponible';
    }
  }

  static StatutLivre fromString(String value) {
    switch (value) {
      case 'emprunte':
        return StatutLivre.emprunte;
      case 'reserve':
        return StatutLivre.reserve;
      case 'indisponible':
        return StatutLivre.indisponible;
      default:
        return StatutLivre.disponible;
    }
  }

  String get value => toString().split('.').last;
}

/// Modèle d'avis sur un livre
class Avis {
  final String id;
  final String membreId;
  final String membreNom;
  final double note;
  final String? commentaire;
  final DateTime date;

  Avis({
    required this.id,
    required this.membreId,
    required this.membreNom,
    required this.note,
    this.commentaire,
    required this.date,
  });

  factory Avis.fromMap(Map<String, dynamic> data, String id) {
    return Avis(
      id: id,
      membreId: data['membreId'] ?? '',
      membreNom: data['membreNom'] ?? '',
      note: (data['note'] as num?)?.toDouble() ?? 0.0,
      commentaire: data['commentaire'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'membreId': membreId,
        'membreNom': membreNom,
        'note': note,
        'commentaire': commentaire,
        'date': Timestamp.fromDate(date),
      };
}

/// Modèle de données : Livre
class Livre {
  final String id;
  final String titre;
  final String auteur;
  final String? isbn;
  final String genre;
  final List<String> tags;
  final String? resume;
  final String? couvertureUrl;
  final int? anneePublication;
  final String? editeur;
  final int? nombrePages;
  final String? langue;
  final StatutLivre statut;
  final double notemoyenne;
  final int nbAvis;
  final int nbEmpruntsTotal;
  final DateTime dateAjout;
  final String? addedBy;
  final int exemplairesTotal;
  final int exemplairesDisponibles;

  Livre({
    required this.id,
    required this.titre,
    required this.auteur,
    this.isbn,
    required this.genre,
    this.tags = const [],
    this.resume,
    this.couvertureUrl,
    this.anneePublication,
    this.editeur,
    this.nombrePages,
    this.langue,
    this.statut = StatutLivre.disponible,
    this.notemoyenne = 0.0,
    this.nbAvis = 0,
    this.nbEmpruntsTotal = 0,
    required this.dateAjout,
    this.addedBy,
    this.exemplairesTotal = 1,
    this.exemplairesDisponibles = 1,
  });

  bool get estDisponible =>
      statut == StatutLivre.disponible && exemplairesDisponibles > 0;

  // ── Firestore → Livre ──
  factory Livre.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Livre(
      id: doc.id,
      titre: data['titre'] ?? '',
      auteur: data['auteur'] ?? '',
      isbn: data['isbn'],
      genre: data['genre'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      resume: data['resume'],
      couvertureUrl: data['couvertureUrl'],
      anneePublication: data['anneePublication'],
      editeur: data['editeur'],
      nombrePages: data['nombrePages'],
      langue: data['langue'],
      statut: StatutLivreExt.fromString(data['statut'] ?? 'disponible'),
      notemoyenne: (data['notemoyenne'] as num?)?.toDouble() ?? 0.0,
      nbAvis: data['nbAvis'] ?? 0,
      nbEmpruntsTotal: data['nbEmpruntsTotal'] ?? 0,
      dateAjout:
          (data['dateAjout'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: data['addedBy'],
      exemplairesTotal: data['exemplairesTotal'] ?? 1,
      exemplairesDisponibles: data['exemplairesDisponibles'] ?? 1,
    );
  }

  // ── Livre → Map Firestore ──
  Map<String, dynamic> toFirestore() => {
        'titre': titre,
        'auteur': auteur,
        'isbn': isbn,
        'genre': genre,
        'tags': tags,
        'resume': resume,
        'couvertureUrl': couvertureUrl,
        'anneePublication': anneePublication,
        'editeur': editeur,
        'nombrePages': nombrePages,
        'langue': langue,
        'statut': statut.value,
        'notemoyenne': notemoyenne,
        'nbAvis': nbAvis,
        'nbEmpruntsTotal': nbEmpruntsTotal,
        'dateAjout': Timestamp.fromDate(dateAjout),
        'addedBy': addedBy,
        'exemplairesTotal': exemplairesTotal,
        'exemplairesDisponibles': exemplairesDisponibles,
      };

  // ── copyWith ──
  Livre copyWith({
    String? titre,
    String? auteur,
    String? isbn,
    String? genre,
    List<String>? tags,
    String? resume,
    String? couvertureUrl,
    int? anneePublication,
    String? editeur,
    int? nombrePages,
    String? langue,
    StatutLivre? statut,
    double? notemoyenne,
    int? nbAvis,
    int? nbEmpruntsTotal,
    String? addedBy,
    int? exemplairesTotal,
    int? exemplairesDisponibles,
  }) {
    return Livre(
      id: id,
      titre: titre ?? this.titre,
      auteur: auteur ?? this.auteur,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      tags: tags ?? this.tags,
      resume: resume ?? this.resume,
      couvertureUrl: couvertureUrl ?? this.couvertureUrl,
      anneePublication: anneePublication ?? this.anneePublication,
      editeur: editeur ?? this.editeur,
      nombrePages: nombrePages ?? this.nombrePages,
      langue: langue ?? this.langue,
      statut: statut ?? this.statut,
      notemoyenne: notemoyenne ?? this.notemoyenne,
      nbAvis: nbAvis ?? this.nbAvis,
      nbEmpruntsTotal: nbEmpruntsTotal ?? this.nbEmpruntsTotal,
      dateAjout: dateAjout,
      addedBy: addedBy ?? this.addedBy,
      exemplairesTotal: exemplairesTotal ?? this.exemplairesTotal,
      exemplairesDisponibles:
          exemplairesDisponibles ?? this.exemplairesDisponibles,
    );
  }

  @override
  String toString() => 'Livre(id: $id, titre: $titre, auteur: $auteur)';
}
