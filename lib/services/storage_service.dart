import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

/// Service Firebase Storage — upload/suppression d'images
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Upload couverture livre ──
  Future<String> uploadCouverture(String livreId, File file) async {
    return _uploadFile(
      path: '${AppConstants.storageCouverts}$livreId.jpg',
      file: file,
    );
  }

  // ── Upload avatar membre ──
  Future<String> uploadAvatar(String uid, File file) async {
    return _uploadFile(
      path: '${AppConstants.storageAvatars}$uid.jpg',
      file: file,
    );
  }

  // ── Upload photo événement ──
  Future<String> uploadPhotoEvenement(String evenementId, File file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _uploadFile(
      path: '${AppConstants.storagePhotos}evenements/$evenementId/$timestamp.jpg',
      file: file,
    );
  }

  // ── Upload générique ──
  Future<String> _uploadFile({
    required String path,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Erreur upload : ${e.message}');
    }
  }

  // ── Suppression ──
  Future<void> supprimerFichier(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore si le fichier n'existe pas
    }
  }

  // ── Progression d'upload ──
  Stream<TaskSnapshot> uploadAvecProgression(
      String path, File file) {
    final ref = _storage.ref().child(path);
    final task = ref.putFile(file);
    return task.snapshotEvents;
  }
}
