import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeEvenement { lecture, conference, atelier, exposition, club, autre }

extension TypeEvenementExt on TypeEvenement {
  String get label {
    switch (this) {
      case TypeEvenement.lecture: return 'Lecture';
      case TypeEvenement.conference: return 'Conférence';
      case TypeEvenement.atelier: return 'Atelier';
      case TypeEvenement.exposition: return 'Exposition';
      case TypeEvenement.club: return 'Club de lecture';
      case TypeEvenement.autre: return 'Autre';
    }
  }
  static TypeEvenement fromString(String value) {
    switch (value) {
      case 'conference': return TypeEvenement.conference;
      case 'atelier': return TypeEvenement.atelier;
      case 'exposition': return TypeEvenement.exposition;
      case 'club': return TypeEvenement.club;
      default: return TypeEvenement.lecture;
    }
  }
  String get value => toString().split('.').last;
}

class Evenement {
  final String id;
  final String titre;
  final String description;
  final TypeEvenement type;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String lieu;
  final int? capaciteMax;
  final int nbInscrits;
  final List<String> participantsIds;
  final String? imageUrl;
  final String organisateurId;
  final String organisateurNom;
  final bool estPublic;
  final bool estAnnule;
  final List<String> photos;
  final String? compteRendu;
  final DateTime dateCreation;

  Evenement({required this.id, required this.titre, required this.description,
    required this.type, required this.dateDebut, required this.dateFin,
    required this.lieu, this.capaciteMax, this.nbInscrits = 0,
    this.participantsIds = const [], this.imageUrl, required this.organisateurId,
    required this.organisateurNom, this.estPublic = true, this.estAnnule = false,
    this.photos = const [], this.compteRendu, required this.dateCreation});

  bool get placesDispo => capaciteMax == null || nbInscrits < capaciteMax!;
  int get placesRestantes => capaciteMax != null ? capaciteMax! - nbInscrits : -1;
  bool get estPasse => dateFin.isBefore(DateTime.now());
  bool get estAVenir => dateDebut.isAfter(DateTime.now());
  bool get estEnCours => dateDebut.isBefore(DateTime.now()) && dateFin.isAfter(DateTime.now());

  factory Evenement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Evenement(
      id: doc.id, titre: data['titre'] ?? '', description: data['description'] ?? '',
      type: TypeEvenementExt.fromString(data['type'] ?? 'lecture'),
      dateDebut: (data['dateDebut'] as Timestamp).toDate(),
      dateFin: (data['dateFin'] as Timestamp).toDate(),
      lieu: data['lieu'] ?? '', capaciteMax: data['capaciteMax'],
      nbInscrits: data['nbInscrits'] ?? 0,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      imageUrl: data['imageUrl'], organisateurId: data['organisateurId'] ?? '',
      organisateurNom: data['organisateurNom'] ?? '', estPublic: data['estPublic'] ?? true,
      estAnnule: data['estAnnule'] ?? false, photos: List<String>.from(data['photos'] ?? []),
      compteRendu: data['compteRendu'],
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'titre': titre, 'description': description, 'type': type.value,
    'dateDebut': Timestamp.fromDate(dateDebut), 'dateFin': Timestamp.fromDate(dateFin),
    'lieu': lieu, 'capaciteMax': capaciteMax, 'nbInscrits': nbInscrits,
    'participantsIds': participantsIds, 'imageUrl': imageUrl,
    'organisateurId': organisateurId, 'organisateurNom': organisateurNom,
    'estPublic': estPublic, 'estAnnule': estAnnule, 'photos': photos,
    'compteRendu': compteRendu, 'dateCreation': Timestamp.fromDate(dateCreation),
  };

  Evenement copyWith({String? titre, String? description, int? nbInscrits,
    List<String>? participantsIds, bool? estAnnule, String? compteRendu, List<String>? photos}) {
    return Evenement(id: id, titre: titre ?? this.titre, description: description ?? this.description,
      type: type, dateDebut: dateDebut, dateFin: dateFin, lieu: lieu, capaciteMax: capaciteMax,
      nbInscrits: nbInscrits ?? this.nbInscrits, participantsIds: participantsIds ?? this.participantsIds,
      imageUrl: imageUrl, organisateurId: organisateurId, organisateurNom: organisateurNom,
      estPublic: estPublic, estAnnule: estAnnule ?? this.estAnnule, photos: photos ?? this.photos,
      compteRendu: compteRendu ?? this.compteRendu, dateCreation: dateCreation);
  }
}
