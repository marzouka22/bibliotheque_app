import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/livre.dart';
import '../models/membre.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/evenement.dart';
import '../models/message.dart';
import '../utils/constants.dart';

/// Service principal Firestore — CRUD pour toutes les collections
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ══════════════════════════════════
  //  LIVRES
  // ══════════════════════════════════

  CollectionReference get _livres => _db.collection(AppConstants.colLivres);

  Stream<List<Livre>> getLivresStream({
    String? genre,
    String? statut,
    String? recherche,
  }) {
    Query query = _livres.orderBy('dateAjout', descending: true);

    if (genre != null && genre.isNotEmpty) {
      query = query.where('genre', isEqualTo: genre);
    }
    if (statut != null && statut.isNotEmpty) {
      query = query.where('statut', isEqualTo: statut);
    }

    return query.snapshots().map((snap) {
      List<Livre> livres =
          snap.docs.map((doc) => Livre.fromFirestore(doc)).toList();

      // Filtrage local pour la recherche textuelle
      if (recherche != null && recherche.isNotEmpty) {
        final q = recherche.toLowerCase();
        livres = livres
            .where((l) =>
                l.titre.toLowerCase().contains(q) ||
                l.auteur.toLowerCase().contains(q) ||
                (l.isbn?.contains(q) ?? false))
            .toList();
      }
      return livres;
    });
  }

  Future<Livre?> getLivre(String id) async {
    final doc = await _livres.doc(id).get();
    if (doc.exists) return Livre.fromFirestore(doc);
    return null;
  }

  Future<String> ajouterLivre(Livre livre) async {
    final ref = await _livres.add(livre.toFirestore());
    return ref.id;
  }

  Future<void> modifierLivre(String id, Map<String, dynamic> data) async {
    await _livres.doc(id).update(data);
  }

  Future<void> supprimerLivre(String id) async {
    await _livres.doc(id).delete();
  }

  Stream<List<Avis>> getAvisLivre(String livreId) {
    return _db
        .collection(AppConstants.colLivres)
        .doc(livreId)
        .collection(AppConstants.colAvis)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Avis.fromFirestore(d)).toList());
  }

  Future<void> ajouterAvis(String livreId, Avis avis) async {
    final batch = _db.batch();

    // Ajout de l'avis
    final avisRef = _db
        .collection(AppConstants.colLivres)
        .doc(livreId)
        .collection(AppConstants.colAvis)
        .doc();
    batch.set(avisRef, avis.toFirestore());

    // Recalcul de la note moyenne
    final existingAvis = await _db
        .collection(AppConstants.colLivres)
        .doc(livreId)
        .collection(AppConstants.colAvis)
        .get();

    final totalNote = existingAvis.docs.fold<double>(
        0.0, (sum, d) => sum + (d.data()['note'] ?? 0.0).toDouble());
    final nbAvis = existingAvis.docs.length + 1;
    final nouvelleMoyenne = (totalNote + avis.note) / nbAvis;

    batch.update(_livres.doc(livreId), {
      'notemoyenne': nouvelleMoyenne,
      'nbAvis': nbAvis,
    });

    await batch.commit();
  }

  // ══════════════════════════════════
  //  MEMBRES
  // ══════════════════════════════════

  CollectionReference get _membres => _db.collection(AppConstants.colMembres);

  Stream<List<Membre>> getMembresStream({String? statut}) {
    Query query = _membres.orderBy('dateAdhesion', descending: true);
    if (statut != null) query = query.where('statut', isEqualTo: statut);
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => Membre.fromFirestore(d)).toList());
  }

  Future<void> updateStatutMembre(String uid, String statut) async {
    await _membres.doc(uid).update({'statut': statut});
  }

  Future<void> updateRoleMembre(String uid, String role) async {
    await _membres.doc(uid).update({'role': role});
  }

  // ══════════════════════════════════
  //  EMPRUNTS
  // ══════════════════════════════════

  CollectionReference get _emprunts => _db.collection(AppConstants.colEmprunts);

  Stream<List<Emprunt>> getEmpruntsStream({String? membreId, String? statut}) {
    Query query = _emprunts.orderBy('dateEmprunt', descending: true);
    if (membreId != null) query = query.where('membreId', isEqualTo: membreId);
    if (statut != null) query = query.where('statut', isEqualTo: statut);
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => Emprunt.fromFirestore(d)).toList());
  }

  Future<String> creerEmprunt(Emprunt emprunt) async {
    final batch = _db.batch();

    // Créer l'emprunt
    final empruntRef = _emprunts.doc();
    batch.set(empruntRef, emprunt.toFirestore());

    // Mettre à jour le statut du livre
    batch.update(_livres.doc(emprunt.livreId), {
      'statut': 'emprunte',
      'exemplairesDisponibles': FieldValue.increment(-1),
      'nbEmpruntsTotal': FieldValue.increment(1),
    });

    // Mettre à jour le compteur du membre
    batch.update(_membres.doc(emprunt.membreId), {
      'nbEmpruntsEnCours': FieldValue.increment(1),
      'nbEmpruntsTotal': FieldValue.increment(1),
    });

    await batch.commit();
    return empruntRef.id;
  }

  Future<void> retournerLivre(String empruntId, String livreId, String membreId) async {
    final batch = _db.batch();

    batch.update(_emprunts.doc(empruntId), {
      'statut': 'retourne',
      'dateRetourEffective': Timestamp.now(),
    });

    batch.update(_livres.doc(livreId), {
      'statut': 'disponible',
      'exemplairesDisponibles': FieldValue.increment(1),
    });

    batch.update(_membres.doc(membreId), {
      'nbEmpruntsEnCours': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  Future<void> prolongerEmprunt(String empruntId, DateTime nouvelleDate) async {
    await _emprunts.doc(empruntId).update({
      'dateRetourPrevue': Timestamp.fromDate(nouvelleDate),
      'statut': 'prolonge',
      'nbProlongations': FieldValue.increment(1),
    });
  }

  // ══════════════════════════════════
  //  RÉSERVATIONS
  // ══════════════════════════════════

  CollectionReference get _reservations =>
      _db.collection(AppConstants.colReservations);

  Stream<List<Reservation>> getReservationsStream({String? membreId, String? livreId}) {
    Query query = _reservations.orderBy('dateReservation', descending: false);
    if (membreId != null) query = query.where('membreId', isEqualTo: membreId);
    if (livreId != null) query = query.where('livreId', isEqualTo: livreId);
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => Reservation.fromFirestore(d)).toList());
  }

  Future<String> creerReservation(Reservation reservation) async {
    // Calcul de la position dans la file
    final existantes = await _reservations
        .where('livreId', isEqualTo: reservation.livreId)
        .where('statut', isEqualTo: 'enAttente')
        .get();

    final position = existantes.docs.length + 1;
    final ref = await _reservations.add({
      ...reservation.toFirestore(),
      'positionFile': position,
    });

    // Mettre à jour le statut du livre
    await _livres.doc(reservation.livreId).update({'statut': 'reserve'});

    return ref.id;
  }

  Future<void> annulerReservation(String reservationId, String livreId) async {
    await _reservations.doc(reservationId).update({'statut': 'annulee'});
    // Vérifier s'il reste des réservations actives
    final remaining = await _reservations
        .where('livreId', isEqualTo: livreId)
        .where('statut', isEqualTo: 'enAttente')
        .get();
    if (remaining.docs.isEmpty) {
      await _livres.doc(livreId).update({'statut': 'disponible'});
    }
  }

  // ══════════════════════════════════
  //  ÉVÉNEMENTS
  // ══════════════════════════════════

  CollectionReference get _evenements =>
      _db.collection(AppConstants.colEvenements);

  Stream<List<Evenement>> getEvenementsStream({bool aVenir = false}) {
    Query query = _evenements.orderBy('dateDebut', descending: false);
    if (aVenir) {
      query = query.where('dateDebut',
          isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()));
    }
    return query.snapshots().map(
        (snap) => snap.docs.map((d) => Evenement.fromFirestore(d)).toList());
  }

  Future<String> creerEvenement(Evenement evenement) async {
    final ref = await _evenements.add(evenement.toFirestore());
    return ref.id;
  }

  Future<void> modifierEvenement(String id, Map<String, dynamic> data) async {
    await _evenements.doc(id).update(data);
  }

  Future<void> inscrireEvenement(String evenementId, String membreId) async {
    await _evenements.doc(evenementId).update({
      'participantsIds': FieldValue.arrayUnion([membreId]),
      'nbInscrits': FieldValue.increment(1),
    });
  }

  Future<void> desinscrireEvenement(String evenementId, String membreId) async {
    await _evenements.doc(evenementId).update({
      'participantsIds': FieldValue.arrayRemove([membreId]),
      'nbInscrits': FieldValue.increment(-1),
    });
  }

  // ══════════════════════════════════
  //  MESSAGERIE
  // ══════════════════════════════════

  CollectionReference get _conversations =>
      _db.collection(AppConstants.colConversations);

  Stream<List<Conversation>> getConversationsStream(String uid) {
    return _conversations
        .where('participantsIds', arrayContains: uid)
        .orderBy('dateDernierMessage', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Conversation.fromFirestore(d)).toList());
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('dateEnvoi', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromFirestore(d)).toList());
  }

  Future<String> creerConversation(Conversation conversation) async {
    final ref = await _conversations.add(conversation.toFirestore());
    return ref.id;
  }

  Future<void> envoyerMessage(String conversationId, Message message) async {
    final batch = _db.batch();

    final msgRef = _conversations.doc(conversationId).collection('messages').doc();
    batch.set(msgRef, message.toFirestore());

    batch.update(_conversations.doc(conversationId), {
      'dernierMessage': message.contenu,
      'dateDernierMessage': Timestamp.fromDate(message.dateEnvoi),
      'dernierExpedId': message.expediteurId,
    });

    await batch.commit();
  }

  // ══════════════════════════════════
  //  STATISTIQUES ADMIN
  // ══════════════════════════════════

  Future<Map<String, int>> getStatsGlobales() async {
    final results = await Future.wait([
      _livres.count().get(),
      _membres.where('statut', isEqualTo: 'actif').count().get(),
      _emprunts.where('statut', isEqualTo: 'enCours').count().get(),
      _emprunts.where('statut', isEqualTo: 'enRetard').count().get(),
      _reservations.where('statut', isEqualTo: 'enAttente').count().get(),
    ]);

    return {
      'totalLivres': results[0].count ?? 0,
      'membresActifs': results[1].count ?? 0,
      'empruntsEnCours': results[2].count ?? 0,
      'empruntsEnRetard': results[3].count ?? 0,
      'reservationsEnAttente': results[4].count ?? 0,
    };
  }

  // ── Wishlist ──
  Future<void> ajouterWishlist(String uid, String livreId) async {
    await _membres.doc(uid).update({
      'wishlist': FieldValue.arrayUnion([livreId]),
    });
  }

  Future<void> retirerWishlist(String uid, String livreId) async {
    await _membres.doc(uid).update({
      'wishlist': FieldValue.arrayRemove([livreId]),
    });
  }
}
