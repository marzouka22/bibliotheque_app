import 'package:flutter/material.dart';
import '../models/evenement.dart';
import '../services/firestore_service.dart';

/// Controller pour les événements
class EvenementController extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Evenement> _evenements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Evenement> get evenements => _evenements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Evenement> get evenementsAVenir =>
      _evenements.where((e) => e.estAVenir && !e.estAnnule).toList();

  List<Evenement> get evenementsPasses =>
      _evenements.where((e) => e.estPasse).toList();

  List<Evenement> get evenementsEnCours =>
      _evenements.where((e) => e.estEnCours && !e.estAnnule).toList();

  // ── Écouter les événements ──
  void ecouterEvenements({bool aVenir = false}) {
    _firestore.getEvenementsStream(aVenir: aVenir).listen((evts) {
      _evenements = evts;
      notifyListeners();
    });
  }

  // ── Créer un événement ──
  Future<bool> creerEvenement(Evenement evenement) async {
    _setLoading(true);
    try {
      await _firestore.creerEvenement(evenement);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Modifier un événement ──
  Future<bool> modifierEvenement(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _firestore.modifierEvenement(id, data);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Annuler un événement ──
  Future<bool> annulerEvenement(String id) async {
    return modifierEvenement(id, {'estAnnule': true});
  }

  // ── S'inscrire ──
  Future<bool> sInscrire(String evenementId, String membreId) async {
    _setLoading(true);
    try {
      await _firestore.inscrireEvenement(evenementId, membreId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Se désinscrire ──
  Future<bool> seDesinscrire(String evenementId, String membreId) async {
    _setLoading(true);
    try {
      await _firestore.desinscrireEvenement(evenementId, membreId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool estInscrit(Evenement evenement, String membreId) {
    return evenement.participantsIds.contains(membreId);
  }

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

  // ── Événements du jour ──
  List<Evenement> evenementsDuJour(DateTime jour) {
    return _evenements.where((e) {
      return e.dateDebut.year == jour.year &&
          e.dateDebut.month == jour.month &&
          e.dateDebut.day == jour.day;
    }).toList();
  }

  // ── Prochain événement ──
  Evenement? get prochainEvenement {
    final aVenir = evenementsAVenir;
    if (aVenir.isEmpty) return null;
    aVenir.sort((a, b) => a.dateDebut.compareTo(b.dateDebut));
    return aVenir.first;
  }
