import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Recupera la posizione corrente dell'utente con un limite di tempo stretto,
// per rispettare il requisito "invio in meno di 3 secondi". Se il GPS non
// risponde in tempo, si ricade sull'ultima posizione nota.
final currentPositionProvider =
    FutureProvider.autoDispose<Position>((ref) async {
  final permission = await _ensurePermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw StateError(
      'Permesso di geolocalizzazione negato. Attivalo dalle impostazioni per poter segnalare.',
    );
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 2),
      ),
    );
  } on TimeoutException {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return lastKnown;
    }
    rethrow;
  }
});

Future<LocationPermission> _ensurePermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission;
}
