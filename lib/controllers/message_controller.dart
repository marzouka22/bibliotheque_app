import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';

/// Controller pour la messagerie
class MessageController extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Conversation> _conversations = [];
  List<Message> _messagesActuels = [];
  bool _isLoading = false;
  String? _conversationActiveId;

  List<Conversation> get conversations => _conversations;
  List<Message> get messagesActuels => _messagesActuels;
  bool get isLoading => _isLoading;
  String? get conversationActiveId => _conversationActiveId;

  int get totalNonLus {
    return _conversations.fold(0, (sum, conv) {
      return sum; // sera mis à jour avec l'uid
    });
  }

  int nbNonLusPour(String uid) {
    return _conversations.fold(
        0, (sum, conv) => sum + conv.nbNonLusPour(uid));
  }

  // ── Écouter les conversations ──
  void ecouterConversations(String uid) {
    _firestore.getConversationsStream(uid).listen((convs) {
      _conversations = convs;
      notifyListeners();
    });
  }

  // ── Écouter les messages d'une conversation ──
  void ecouterMessages(String conversationId) {
    _conversationActiveId = conversationId;
    _firestore.getMessagesStream(conversationId).listen((msgs) {
      _messagesActuels = msgs;
      notifyListeners();
    });
  }

  // ── Créer ou récupérer une conversation directe ──
  Future<String?> ouvrirConversationAvec({
    required String monUid,
    required String monNom,
    required String autreUid,
    required String autreNom,
  }) async {
    // Vérifier si la conversation existe déjà
    final existing = _conversations.where((c) =>
        !c.estGroupe &&
        c.participantsIds.contains(monUid) &&
        c.participantsIds.contains(autreUid));

    if (existing.isNotEmpty) {
      return existing.first.id;
    }

    // Créer une nouvelle conversation
    try {
      final conv = Conversation(
        id: '',
        participantsIds: [monUid, autreUid],
        participantsNoms: [monNom, autreNom],
        estGroupe: false,
        dateCreation: DateTime.now(),
      );
      return await _firestore.creerConversation(conv);
    } catch (e) {
      return null;
    }
  }

  // ── Envoyer un message ──
  Future<bool> envoyerMessage({
    required String conversationId,
    required String expediteurId,
    required String expediteurNom,
    required String contenu,
    String? expediteurAvatar,
  }) async {
    if (contenu.trim().isEmpty) return false;
    try {
      final message = Message(
        id: '',
        conversationId: conversationId,
        expediteurId: expediteurId,
        expediteurNom: expediteurNom,
        expediteurAvatar: expediteurAvatar,
        contenu: contenu.trim(),
        dateEnvoi: DateTime.now(),
      );
      await _firestore.envoyerMessage(conversationId, message);
      return true;
    } catch (e) {
      return false;
    }
  }

  void clearMessages() {
    _messagesActuels = [];
    _conversationActiveId = null;
    notifyListeners();
  }
}
