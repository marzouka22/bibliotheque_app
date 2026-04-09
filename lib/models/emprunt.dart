import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un emprunt
enum StatutEmprunt { enCours, retourne, enRetard, prolonge, annule }

extension StatutEmpruntExt on StatutEmprunt {
  String get label {
    switch (this) {
      case StatutEmprunt.enCours:
        return 'En cours';
      case StatutEmprunt.retourne:
        return 'Retourné';
      case StatutEmprunt.enRetard:
        return 'En retard';
      case StatutEmprunt.prolonge:
        return 'Prolongé';
      case StatutEmprunt.annule:
        return 'Annulé';
    }
  }

  static StatutEmprunt fromString(String value) {
    switch (value) {
      case 'retourne':
        return StatutEmprunt.retourne;
      case 'enRetard':
        return StatutEmprunt.enRetard;
      case 'prolonge':
        return StatutEmprunt.prolonge;
      case 'annule':
        return StatutEmprunt.annule;
      default:
        return StatutEmprunt.enCours;
    }
  }

  String get value => toString().split('.').last;
}

/// Modèle de données : Emprunt
class Emprunt {
  final String id;
  final String livreId;
  final String livretitre;
  final String livreAuteur;
  final String? livreCouvertureUrl;
  final String membreId;
  final String membreNom;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevue;
  final DateTime? dateRetourEffective;
  final StatutEmprunt statut;
  final bool prolongationAccordee;
  final int nbProlongations;
  final String? noteAdmin; // note/remarque de l'admin
  final String? validePar; // uid admin qui a validé

  Emprunt({
    required this.id,
    required this.livreId,
    required this.livretitre,
    required this.livreAuteur,
    this.livreCouvertureUrl,
    required this.membreId,
    required this.membreNom,
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourEffective,
    this.statut = StatutEmprunt.enCours,
    this.prolongationAccordee = false,
    this.nbProlongations = 0,
    this.noteAdmin,
    this.validePar,
  });

  bool get estEnRetard =>
      statut == StatutEmprunt.enCours &&
      DateTime.now().isAfter(dateRetourPrevue);

  int get joursRetard =>
      estEnRetard ? DateTime.now().difference(dateRetourPrevue).inDays : 0;

  int get joursRestants => dateRetourPrevue.difference(DateTime.now()).inDays;

  // ── Firestore → Emprunt ──
  factory Emprunt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Emprunt(
      id: doc.id,
      livreId: data['livreId'] ?? '',
      livretitre: data['livretitre'] ?? '',
      livreAuteur: data['livreAuteur'] ?? '',
      livreCouvertureUrl: data['livreCouvertureUrl'],
      membreId: data['membreId'] ?? '',
      membreNom: data['membreNom'] ?? '',
      dateEmprunt: (data['dateEmprunt'] as Timestamp).toDate(),
      dateRetourPrevue: (data['dateRetourPrevue'] as Timestamp).toDate(),
      dateRetourEffective:
          (data['dateRetourEffective'] as Timestamp?)?.toDate(),
      statut: StatutEmpruntExt.fromString(data['statut'] ?? 'enCours'),
      prolongationAccordee: data['prolongationAccordee'] ?? false,
      nbProlongations: data['nbProlongations'] ?? 0,
      noteAdmin: data['noteAdmin'],
      validePar: data['validePar'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'livreId': livreId,
        'livretitre': livretitre,
        'livreAuteur': livreAuteur,
        'livreCouvertureUrl': livreCouvertureUrl,
        'membreId': membreId,
        'membreNom': membreNom,
        'dateEmprunt': Timestamp.fromDate(dateEmprunt),
        'dateRetourPrevue': Timestamp.fromDate(dateRetourPrevue),
        'dateRetourEffective': dateRetourEffective != null
            ? Timestamp.fromDate(dateRetourEffective!)
            : null,
        'statut': statut.value,
        'prolongationAccordee': prolongationAccordee,
        'nbProlongations': nbProlongations,
        'noteAdmin': noteAdmin,
        'validePar': validePar,
      };

  Emprunt copyWith({
    StatutEmprunt? statut,
    DateTime? dateRetourEffective,
    DateTime? dateRetourPrevue,
    bool? prolongationAccordee,
    int? nbProlongations,
    String? noteAdmin,
  }) {
    return Emprunt(
      id: id,
      livreId: livreId,
      livretitre: livretitre,
      livreAuteur: livreAuteur,
      livreCouvertureUrl: livreCouvertureUrl,
      membreId: membreId,
      membreNom: membreNom,
      dateEmprunt: dateEmprunt,
      dateRetourPrevue: dateRetourPrevue ?? this.dateRetourPrevue,
      dateRetourEffective: dateRetourEffective ?? this.dateRetourEffective,
      statut: statut ?? this.statut,
      prolongationAccordee: prolongationAccordee ?? this.prolongationAccordee,
      nbProlongations: nbProlongations ?? this.nbProlongations,
      noteAdmin: noteAdmin ?? this.noteAdmin,
      validePar: validePar,
    );
  }
}
