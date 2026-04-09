import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/membre.dart';
import '../utils/constants.dart';

/// Service d'authentification Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Utilisateur courant ──
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Inscription ──
  Future<UserCredential> inscrire({
    required String email,
    required String password,
    required String nom,
    String? telephone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Mise à jour du displayName
      await credential.user?.updateDisplayName(nom.trim());

      // Création du profil Firestore
      final membre = Membre(
        uid: credential.user!.uid,
        nom: nom.trim(),
        email: email.trim(),
        telephone: telephone?.trim(),
        dateAdhesion: DateTime.now(),
        statut: StatutMembre.enAttente,
        role: AppConstants.roleMembre,
      );

      await _firestore
          .collection(AppConstants.colMembres)
          .doc(credential.user!.uid)
          .set(membre.toFirestore());

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Connexion ──
  Future<UserCredential> connecter({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Déconnexion ──
  Future<void> deconnecter() async {
    await _auth.signOut();
  }

  // ── Réinitialisation mot de passe ──
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Récupérer le profil Firestore ──
  Future<Membre?> getMembre(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colMembres)
          .doc(uid)
          .get();
      if (doc.exists) return Membre.fromFirestore(doc);
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Stream profil ──
  Stream<Membre?> membreStream(String uid) {
    return _firestore
        .collection(AppConstants.colMembres)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? Membre.fromFirestore(doc) : null);
  }

  // ── Mise à jour profil ──
  Future<void> updateProfil(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.colMembres)
        .doc(uid)
        .update(data);
    if (data.containsKey('nom')) {
      await _auth.currentUser?.updateDisplayName(data['nom']);
    }
  }

  // ── Vérification email ──
  Future<void> envoyerVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // ── Gestion des erreurs Firebase Auth ──
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Aucun compte trouvé avec cet email.');
      case 'wrong-password':
        return Exception('Mot de passe incorrect.');
      case 'email-already-in-use':
        return Exception('Cet email est déjà utilisé.');
      case 'weak-password':
        return Exception('Le mot de passe est trop faible (minimum 6 caractères).');
      case 'invalid-email':
        return Exception('Format d\'email invalide.');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé.');
      case 'too-many-requests':
        return Exception('Trop de tentatives. Réessayez plus tard.');
      case 'network-request-failed':
        return Exception('Erreur réseau. Vérifiez votre connexion.');
      default:
        return Exception('Erreur d\'authentification : ${e.message}');
    }
  }
}
