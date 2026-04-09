import 'package:flutter/material.dart';
import '../models/emprunt.dart';
import '../models/reservation.dart';
import '../models/livre.dart';
import '../models/membre.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Controller pour les emprunts et réservations
class EmpruntController extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Emprunt> _emprunts = [];
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Emprunt> get emprunts => _emprunts;
  List<Reservation> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Emprunt> get empruntsEnCours =>
      _emprunts.where((e) => e.statut == StatutEmprunt.enCours).toList();

  List<Emprunt> get empruntsEnRetard =>
      _emprunts.where((e) => e.estEnRetard).toList();

  List<Emprunt> get historique =>
      _emprunts.where((e) => e.statut == StatutEmprunt.retourne).toList();

  // ── Écouter les emprunts d'un membre ──
  void ecouterEmprunts(String membreId) {
    _firestore.getEmpruntsStream(membreId: membreId).listen((emprunts) {
      _emprunts = emprunts;
      notifyListeners();
    });
  }

  // ── Écouter tous les emprunts (admin) ──
  void ecouterTousEmprunts() {
    _firestore.getEmpruntsStream().listen((emprunts) {
      _emprunts = emprunts;
      notifyListeners();
    });
  }

  // ── Écouter les réservations ──
  void ecouterReservations(String membreId) {
    _firestore.getReservationsStream(membreId: membreId).listen((res) {
      _reservations = res;
      notifyListeners();
    });
  }

  // ── Créer un emprunt ──
  Future<bool> creerEmprunt({
    required Livre livre,
    required Membre membre,
    String? validePar,
  }) async {
    if (!membre.peutEmprunter) {
      _setError('Vous avez atteint le maximum d\'emprunts autorisés (${AppConstants.maxEmpruntsSimultanes}).');
      return false;
    }
    if (!livre.estDisponible) {
      _setError('Ce livre n\'est pas disponible actuellement.');
      return false;
    }

    _setLoading(true);
    try {
      final now = DateTime.now();
      final emprunt = Emprunt(
        id: '',
        livreId: livre.id,
        livretitre: livre.titre,
        livreAuteur: livre.auteur,
        livreCouvertureUrl: livre.couvertureUrl,
        membreId: membre.uid,
        membreNom: membre.nom,
        dateEmprunt: now,
        dateRetourPrevue: Helpers.calculerDateRetour(dateEmprunt: now),
        statut: StatutEmprunt.enCours,
        validePar: validePar,
      );

      await _firestore.creerEmprunt(emprunt);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Retourner un livre ──
  Future<bool> retournerLivre(Emprunt emprunt) async {
    _setLoading(true);
    try {
      await _firestore.retournerLivre(
        emprunt.id,
        emprunt.livreId,
        emprunt.membreId,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Prolonger un emprunt ──
  Future<bool> prolongerEmprunt(Emprunt emprunt) async {
    if (emprunt.nbProlongations >= 1) {
      _setError('La prolongation maximale a déjà été accordée.');
      return false;
    }
    _setLoading(true);
    try {
      final nouvelleDate = emprunt.dateRetourPrevue
          .add(const Duration(days: AppConstants.delaiProlongationJours));
      await _firestore.prolongerEmprunt(emprunt.id, nouvelleDate);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Réserver un livre ──
  Future<bool> reserverLivre({
    required Livre livre,
    required Membre membre,
  }) async {
    _setLoading(true);
    try {
      final reservation = Reservation(
        id: '',
        livreId: livre.id,
        livretitre: livre.titre,
        livreAuteur: livre.auteur,
        livreCouvertureUrl: livre.couvertureUrl,
        membreId: membre.uid,
        membreNom: membre.nom,
        dateReservation: DateTime.now(),
        dateExpiration: DateTime.now().add(const Duration(days: 7)),
        statut: StatutReservation.enAttente,
      );

      await _firestore.creerReservation(reservation);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Annuler une réservation ──
  Future<bool> annulerReservation(Reservation reservation) async {
    _setLoading(true);
    try {
      await _firestore.annulerReservation(reservation.id, reservation.livreId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Privé ──
  void _setLoading(bool val) {
    _isLoading = val;
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
