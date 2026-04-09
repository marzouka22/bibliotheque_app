import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Service de notifications (FCM + locales)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // ── Initialisation ──
  Future<void> initialiser() async {
    // Permissions FCM
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configuration notifications locales
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotifTapped,
    );

    // Écoute des messages FCM en foreground
    FirebaseMessaging.onMessage.listen(_onMessageForeground);

    // Token FCM
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
  }

  // ── Gestion des messages reçus en foreground ──
  void _onMessageForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      afficherNotifLocale(
        titre: notification.title ?? 'BiblioApp',
        corps: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // ── Notification tap ──
  void _onNotifTapped(NotificationResponse response) {
    debugPrint('Notification tappée: ${response.payload}');
    // Navigation gérée par le controller
  }

  // ── Afficher une notif locale ──
  Future<void> afficherNotifLocale({
    required String titre,
    required String corps,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bibliotheque_channel',
      'Notifications BiblioApp',
      channelDescription: 'Notifications de la bibliothèque',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotif.show(id, titre, corps, details, payload: payload);
  }

  // ── Notif de rappel de retour ──
  Future<void> notifRappelRetour({
    required String titre,
    required DateTime dateRetour,
  }) async {
    final jours = dateRetour.difference(DateTime.now()).inDays;
    String message;
    if (jours <= 0) {
      message = 'Le retour de "$titre" est prévu aujourd\'hui !';
    } else if (jours == 1) {
      message = 'Pensez à retourner "$titre" demain.';
    } else {
      message = 'Il vous reste $jours jours pour retourner "$titre".';
    }

    await afficherNotifLocale(
      titre: '📚 Rappel de retour',
      corps: message,
      payload: 'emprunt',
    );
  }

  // ── Notif réservation disponible ──
  Future<void> notifReservationDisponible(String titrelivre) async {
    await afficherNotifLocale(
      titre: '✅ Réservation disponible',
      corps: 'Le livre "$titrelivre" est maintenant disponible pour vous.',
      payload: 'reservation',
    );
  }

  // ── Notif événement ──
  Future<void> notifEvenement(String titreEvenement, DateTime date) async {
    await afficherNotifLocale(
      titre: '📅 Événement à venir',
      corps: 'L\'événement "$titreEvenement" a lieu bientôt.',
      payload: 'evenement',
    );
  }

  // ── S'abonner à un topic FCM ──
  Future<void> abonnerTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> desabonnerTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  // ── Récupérer le token FCM ──
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
