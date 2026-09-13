import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map/application/reports_feed_providers.dart';
import '../../report/application/position_provider.dart';
import '../../report/domain/ash_intensity.dart';

const _checklistRadiusKm = 5.0;
const _checklistWindow = Duration(hours: 3);

// Determina l'intensità "rilevata nella zona dell'utente" per la
// checklist contestuale: la più alta tra le segnalazioni recenti (ultime
// 3 ore, indipendentemente dal filtro temporale scelto sulla mappa) entro
// un raggio fisso di 5 km dalla posizione attuale. Scelta volutamente
// cautelativa: in presenza di segnalazioni miste nella stessa zona, la
// checklist mostra le precauzioni per l'intensità più alta, non una media.
final nearbyIntensityProvider =
    FutureProvider.autoDispose<AshIntensity?>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  final feed = await ref.watch(reportsFeedProvider.future);
  final cutoff = DateTime.now().toUtc().subtract(_checklistWindow);

  AshIntensity? highest;
  for (final report in feed) {
    final createdAt = report.createdAt;
    if (createdAt == null || createdAt.toUtc().isBefore(cutoff)) continue;

    final distanceKm = _distanceKm(
      position.latitude,
      position.longitude,
      report.latitude,
      report.longitude,
    );
    if (distanceKm > _checklistRadiusKm) continue;

    if (highest == null || report.intensity.dbValue > highest.dbValue) {
      highest = report.intensity;
    }
  }
  return highest;
});

// Formula di Haversine: sufficiente per le distanze di poche decine di
// km rilevanti qui, senza bisogno di una dipendenza aggiuntiva.
double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (pi / 180);
