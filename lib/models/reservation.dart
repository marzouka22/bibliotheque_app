import 'package:cloud_firestore/cloud_firestore.dart';

enum StatutReservation { enAttente, confirmee, annulee, expiree, convertieEnEmprunt }

extension StatutReservationExt on StatutReservation {
  String get label {
    switch (this) {
      case StatutReservation.enAttente:
        return 'En attente';
      case StatutReservation.confirmee:
        return 'Confirmée';
      case StatutReservation.annulee:
        return 'Annulée';
      case StatutReservation.expiree:
        return 'Expirée';
      case StatutReservation.convertieEnEmprunt:
        return 'Empruntée';
    }
  }

  static StatutReservation fromString(String value) {
    switch (value) {
      case 'confirmee':
        return StatutReservation.confirmee;
      case 'annulee':
        return StatutReservation.annulee;
      case 'expiree':
        return StatutReservation.expiree;
      case 'convertieEnEmprunt':
        return StatutReservation.convertieEnEmprunt;
      default:
        return StatutReservation.enAttente;
    }
  }

  String get value => toString().split('.').last;
}

/// Modèle de données : Réservation
class Reservation {
  final String id;
  final String livreId;
  final String livretitre;
  final String livreAuteur;
  final String? livreCouvertureUrl;
  final String membreId;
  final String membreNom;
  final DateTime dateReservation;
  final DateTime? dateExpiration;
  final StatutReservation statut;
  final int positionFile; // Position dans la file d'attente
  final String? empruntId; // Renseigné si convertie en emprunt

  Reservation({
    required this.id,
    required this.livreId,
    required this.livretitre,
    required this.livreAuteur,
    this.livreCouvertureUrl,
    required this.membreId,
    required this.membreNom,
    required this.dateReservation,
    this.dateExpiration,
    this.statut = StatutReservation.enAttente,
    this.positionFile = 1,
    this.empruntId,
  });

  factory Reservation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reservation(
      id: doc.id,
      livreId: data['livreId'] ?? '',
      livretitre: data['livretitre'] ?? '',
      livreAuteur: data['livreAuteur'] ?? '',
      livreCouvertureUrl: data['livreCouvertureUrl'],
      membreId: data['membreId'] ?? '',
      membreNom: data['membreNom'] ?? '',
      dateReservation: (data['dateReservation'] as Timestamp).toDate(),
      dateExpiration: (data['dateExpiration'] as Timestamp?)?.toDate(),
      statut: StatutReservationExt.fromString(data['statut'] ?? 'enAttente'),
      positionFile: data['positionFile'] ?? 1,
      empruntId: data['empruntId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'livreId': livreId,
        'livretitre': livretitre,
        'livreAuteur': livreAuteur,
        'livreCouvertureUrl': livreCouvertureUrl,
        'membreId': membreId,
        'membreNom': membreNom,
        'dateReservation': Timestamp.fromDate(dateReservation),
        'dateExpiration':
            dateExpiration != null ? Timestamp.fromDate(dateExpiration!) : null,
        'statut': statut.value,
        'positionFile': positionFile,
        'empruntId': empruntId,
      };
}
