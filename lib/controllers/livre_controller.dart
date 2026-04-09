import 'dart:io';
import 'package:flutter/material.dart';
import '../models/livre.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Controller pour le catalogue de livres
class LivreController extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  List<Livre> _livres = [];
  List<Livre> _wishlist = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filtres
  String _filtreGenre = '';
  String _filtreStatut = '';
  String _recherche = '';

  // ── Getters ──
  List<Livre> get livres => _livres;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filtreGenre => _filtreGenre;
  String get filtreStatut => _filtreStatut;
  String get recherche => _recherche;

  List<Livre> get livresFiltres {
    var result = List<Livre>.from(_livres);

    if (_filtreGenre.isNotEmpty) {
      result = result.where((l) => l.genre == _filtreGenre).toList();
    }
    if (_filtreStatut.isNotEmpty) {
      result = result
          .where((l) => l.statut.toString().split('.').last == _filtreStatut)
          .toList();
    }
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      result = result
          .where((l) =>
              l.titre.toLowerCase().contains(q) ||
              l.auteur.toLowerCase().contains(q) ||
              (l.isbn?.contains(q) ?? false) ||
              l.genre.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  // ── Stream livres ──
  void ecouterLivres() {
    _firestore
        .getLivresStream(
          genre: _filtreGenre.isEmpty ? null : _filtreGenre,
          statut: _filtreStatut.isEmpty ? null : _filtreStatut,
          recherche: _recherche.isEmpty ? null : _recherche,
        )
        .listen((livres) {
      _livres = livres;
      notifyListeners();
    });
  }

  // ── Ajouter un livre ──
  Future<bool> ajouterLivre(Livre livre, {File? couverture}) async {
    _setLoading(true);
    try {
      String id = await _firestore.ajouterLivre(livre);

      if (couverture != null) {
        final url = await _storage.uploadCouverture(id, couverture);
        await _firestore.modifierLivre(id, {'couvertureUrl': url});
      }
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Modifier un livre ──
  Future<bool> modifierLivre(String id, Map<String, dynamic> data,
      {File? nouvelleCouverture}) async {
    _setLoading(true);
    try {
      if (nouvelleCouverture != null) {
        final url = await _storage.uploadCouverture(id, nouvelleCouverture);
        data['couvertureUrl'] = url;
      }
      await _firestore.modifierLivre(id, data);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Supprimer un livre ──
  Future<bool> supprimerLivre(String id) async {
    _setLoading(true);
    try {
      await _firestore.supprimerLivre(id);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Ajouter un avis ──
  Future<bool> ajouterAvis(String livreId, Avis avis) async {
    try {
      await _firestore.ajouterAvis(livreId, avis);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Filtres ──
  void setFiltreGenre(String genre) {
    _filtreGenre = genre;
    notifyListeners();
  }

  void setFiltreStatut(String statut) {
    _filtreStatut = statut;
    notifyListeners();
  }

  void setRecherche(String query) {
    _recherche = query;
    notifyListeners();
  }

  void clearFiltres() {
    _filtreGenre = '';
    _filtreStatut = '';
    _recherche = '';
    notifyListeners();
  }

  // ── Wishlist ──
  Future<void> toggleWishlist(String uid, String livreId) async {
    try {
      if (estDansWishlist(uid, livreId)) {
        await _firestore.retirerWishlist(uid, livreId);
      } else {
        await _firestore.ajouterWishlist(uid, livreId);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  bool estDansWishlist(String uid, String livreId) {
    // Vérifié via le profil membre
    return false;
  }

  // ── Privé ──
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

  // ── Wishlist locale ──
  List<String> get wishlistIds => _wishlist.map((l) => l.id).toList();

  bool estEnWishlist(String livreId, List<String> wishlist) {
    return wishlist.contains(livreId);
  }
