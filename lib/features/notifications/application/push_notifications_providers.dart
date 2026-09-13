import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../report/application/report_providers.dart';
import '../data/alert_subscription_repository.dart';

final alertSubscriptionRepositoryProvider =
    Provider<AlertSubscriptionRepository>((ref) {
  return AlertSubscriptionRepository(ref.watch(supabaseClientProvider));
});

// Registra il dispositivo per le allerte di prossimità e ne aggiorna
// periodicamente la posizione mentre l'app è in primo piano.
//
// Limite importante da tenere presente: questo aggiornamento avviene SOLO
// mentre l'app è aperta (ogni 5 minuti). Non c'è alcun aggiornamento in
// background: se l'utente chiude l'app, l'ultima posizione nota resta
// quella dell'ultimo utilizzo, e le allerte di prossimità legate alla
// posizione attuale (non ai luoghi salvati) smettono di essere accurate.
// Per lo scenario "eruzione notturna" del brief questo è un limite reale.
// Un aggiornamento in background richiederebbe il permesso di
// geolocalizzazione "sempre" (Always) su iOS, con un impatto sui consumi
// e sull'esperienza di consenso da valutare con attenzione prima di
// implementarlo — non l'ho aggiunto in questo sprint per non introdurre
// un permesso invasivo senza una decisione esplicita.
class PushNotificationsController {
  PushNotificationsController(this._ref);
  final Ref _ref;

  Timer? _positionTimer;
  String? _fcmToken;

  Future<void> bootstrap() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      _fcmToken = await messaging.getToken();
      final token = _fcmToken;
      if (token == null) return;

      final repository = _ref.read(alertSubscriptionRepositoryProvider);
      await repository.upsertToken(token);

      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        repository.upsertToken(newToken);
      });

      await _updatePositionOnce();
      _positionTimer?.cancel();
      _positionTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _updatePositionOnce(),
      );
    } catch (_) {
      // Se Firebase non è stato ancora inizializzato (es. durante i primi
      // test, con `Firebase.initializeApp()` commentato in main.dart) o
      // manca la configurazione nativa, le notifiche restano
      // semplicemente disattivate: il resto dell'app non deve bloccarsi
      // per questo.
    }
  }

  Future<void> _updatePositionOnce() async {
    final token = _fcmToken;
    if (token == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      await _ref.read(alertSubscriptionRepositoryProvider).updatePosition(
            fcmToken: token,
            latitude: position.latitude,
            longitude: position.longitude,
          );
    } catch (_) {
      // Silenzioso e non bloccante: l'aggiornamento posizione è un
      // "best effort" in background rispetto all'uso dell'app, non deve
      // mai interrompere l'utente con un errore.
    }
  }

  void dispose() {
    _positionTimer?.cancel();
  }
}

final pushNotificationsControllerProvider =
    Provider<PushNotificationsController>((ref) {
  final controller = PushNotificationsController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
