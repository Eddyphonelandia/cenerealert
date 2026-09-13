import 'package:supabase_flutter/supabase_flutter.dart';

// Mantiene aggiornata la sottoscrizione dell'utente alle allerte di
// prossimità: token FCM, ultima posizione nota (solo mentre l'app è in
// primo piano — vedi il limite descritto in PushNotificationsController)
// e raggio di notifica scelto (3-10 km).
class AlertSubscriptionRepository {
  AlertSubscriptionRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'device_alert_subscriptions';

  Future<void> upsertToken(String fcmToken) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from(_table).upsert(
      {'user_id': userId, 'fcm_token': fcmToken},
      onConflict: 'user_id,fcm_token',
    );
  }

  Future<void> updatePosition({
    required String fcmToken,
    required double latitude,
    required double longitude,
  }) async {
    await _client.from(_table).update({
      'last_known_position': 'SRID=4326;POINT($longitude $latitude)',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('fcm_token', fcmToken);
  }

  Future<void> updateRadius({
    required String fcmToken,
    required double radiusKm,
  }) async {
    await _client
        .from(_table)
        .update({'notify_radius_km': radiusKm})
        .eq('fcm_token', fcmToken);
  }

  Future<double?> currentRadius(String fcmToken) async {
    final row = await _client
        .from(_table)
        .select('notify_radius_km')
        .eq('fcm_token', fcmToken)
        .maybeSingle();
    return row == null ? null : (row['notify_radius_km'] as num).toDouble();
  }
}
