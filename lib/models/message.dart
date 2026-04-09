import 'package:cloud_firestore/cloud_firestore.dart';

enum TypeMessage { texte, image, fichier, systeme }

/// Modèle : Message individuel
class Message {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String expediteurNom;
  final String? expediteurAvatar;
  final String contenu;
  final TypeMessage type;
  final DateTime dateEnvoi;
  final bool lu;
  final List<String> luPar;
  final String? reponseAMessageId;

  Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.expediteurNom,
    this.expediteurAvatar,
    required this.contenu,
    this.type = TypeMessage.texte,
    required this.dateEnvoi,
    this.lu = false,
    this.luPar = const [],
    this.reponseAMessageId,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    TypeMessage typeMsg;
    switch (data['type']) {
      case 'image':
        typeMsg = TypeMessage.image;
        break;
      case 'fichier':
        typeMsg = TypeMessage.fichier;
        break;
      case 'systeme':
        typeMsg = TypeMessage.systeme;
        break;
      default:
        typeMsg = TypeMessage.texte;
    }
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      expediteurId: data['expediteurId'] ?? '',
      expediteurNom: data['expediteurNom'] ?? '',
      expediteurAvatar: data['expediteurAvatar'],
      contenu: data['contenu'] ?? '',
      type: typeMsg,
      dateEnvoi: (data['dateEnvoi'] as Timestamp).toDate(),
      lu: data['lu'] ?? false,
      luPar: List<String>.from(data['luPar'] ?? []),
      reponseAMessageId: data['reponseAMessageId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'conversationId': conversationId,
        'expediteurId': expediteurId,
        'expediteurNom': expediteurNom,
        'expediteurAvatar': expediteurAvatar,
        'contenu': contenu,
        'type': type.toString().split('.').last,
        'dateEnvoi': Timestamp.fromDate(dateEnvoi),
        'lu': lu,
        'luPar': luPar,
        'reponseAMessageId': reponseAMessageId,
      };
}

/// Modèle : Conversation
class Conversation {
  final String id;
  final List<String> participantsIds;
  final List<String> participantsNoms;
  final String? titre; // null = conversation directe
  final bool estGroupe;
  final String? dernierMessage;
  final DateTime? dateDernierMessage;
  final String? dernierExpedId;
  final Map<String, int> nbNonLus; // uid → count
  final DateTime dateCreation;
  final String? avatarUrl;

  Conversation({
    required this.id,
    required this.participantsIds,
    required this.participantsNoms,
    this.titre,
    this.estGroupe = false,
    this.dernierMessage,
    this.dateDernierMessage,
    this.dernierExpedId,
    this.nbNonLus = const {},
    required this.dateCreation,
    this.avatarUrl,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      participantsNoms: List<String>.from(data['participantsNoms'] ?? []),
      titre: data['titre'],
      estGroupe: data['estGroupe'] ?? false,
      dernierMessage: data['dernierMessage'],
      dateDernierMessage:
          (data['dateDernierMessage'] as Timestamp?)?.toDate(),
      dernierExpedId: data['dernierExpedId'],
      nbNonLus: Map<String, int>.from(data['nbNonLus'] ?? {}),
      dateCreation:
          (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participantsIds': participantsIds,
        'participantsNoms': participantsNoms,
        'titre': titre,
        'estGroupe': estGroupe,
        'dernierMessage': dernierMessage,
        'dateDernierMessage': dateDernierMessage != null
            ? Timestamp.fromDate(dateDernierMessage!)
            : null,
        'dernierExpedId': dernierExpedId,
        'nbNonLus': nbNonLus,
        'dateCreation': Timestamp.fromDate(dateCreation),
        'avatarUrl': avatarUrl,
      };

  /// Nom affiché pour l'autre participant (conversation directe)
  String nomAutreParticipant(String monUid) {
    final index = participantsIds.indexOf(monUid);
    if (index == -1) return titre ?? 'Conversation';
    final autreIndex = index == 0 ? 1 : 0;
    if (autreIndex < participantsNoms.length) {
      return participantsNoms[autreIndex];
    }
    return titre ?? 'Conversation';
  }

  int nbNonLusPour(String uid) => nbNonLus[uid] ?? 0;
}
