import 'package:flutter/material.dart';
import '../models/membre.dart';
import '../services/auth_service.dart';

/// Controller d'authentification (Provider)
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Membre? _membre;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ──
  Membre? get membre => _membre;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get estConnecte => _membre != null;
  bool get estAdmin => _membre?.estAdmin ?? false;
  String? get uid => _authService.currentUid;

  // ── Initialisation (écoute état auth) ──
  void init() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _chargerProfil(user.uid);
      } else {
        _membre = null;
        notifyListeners();
      }
    });
  }

  Future<void> _chargerProfil(String uid) async {
    _authService.membreStream(uid).listen((membre) {
      _membre = membre;
      notifyListeners();
    });
  }

  // ── Inscription ──
  Future<bool> inscrire({
    required String email,
    required String password,
    required String nom,
    String? telephone,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.inscrire(
        email: email,
        password: password,
        nom: nom,
        telephone: telephone,
      );
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Connexion ──
  Future<bool> connecter({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.connecter(email: email, password: password);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Déconnexion ──
  Future<void> deconnecter() async {
    await _authService.deconnecter();
    _membre = null;
    notifyListeners();
  }

  // ── Reset password ──
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Mise à jour profil ──
  Future<bool> updateProfil(Map<String, dynamic> data) async {
    if (uid == null) return false;
    _setLoading(true);
    try {
      await _authService.updateProfil(uid!, data);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Helpers privés ──
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}

  // ── Vérifier si admin ──
  bool get estAdmin => _membre?.estAdmin ?? false;

  // ── Vérifier si membre actif ──
  bool get peutEmprunter => _membre?.peutEmprunter ?? false;
