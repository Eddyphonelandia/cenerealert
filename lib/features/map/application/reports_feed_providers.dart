import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/application/report_providers.dart';
import '../../report/domain/report.dart';
import '../data/reports_feed_repository.dart';
import 'time_filter.dart';

final reportsFeedRepositoryProvider = Provider<ReportsFeedRepository>((ref) {
  return ReportsFeedRepository(ref.watch(supabaseClientProvider));
});

const _refreshInterval = Duration(seconds: 20);

// Nota sulla "vivacità" della mappa: la tabella "reports" ha una policy RLS
// che limita la lettura alle righe proprie dell'utente (vedi migration
// 0001), quindi un abbonamento Realtime diretto su quella tabella
// mostrerebbe a ciascun utente solo le proprie segnalazioni, non quelle
// altrui. Per l'MVP la heatmap pubblica viene quindi aggiornata con un
// refresh periodico della vista "reports_public"; un canale Realtime via
// Broadcast/pg_notify per gli aggiornamenti pubblici è un miglioramento
// naturale da valutare in uno sprint successivo, se il ritardo di ~20s
// risultasse troppo lento durante un evento in corso.
class ReportsFeedController extends AsyncNotifier<List<Report>> {
  Timer? _timer;

  @override
  Future<List<Report>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
    ref.onDispose(() => _timer?.cancel());
    return _fetch();
  }

  Future<List<Report>> _fetch() {
    return ref.read(reportsFeedRepositoryProvider).fetchRecent();
  }

  Future<void> refresh() async {
    final data = await _fetch();
    state = AsyncData(data);
  }
}

final reportsFeedProvider =
    AsyncNotifierProvider<ReportsFeedController, List<Report>>(
  ReportsFeedController.new,
);

final timeFilterProvider = StateProvider<TimeFilter>((ref) {
  return TimeFilter.sixHours;
});

// Combina il feed grezzo con il filtro temporale scelto dall'utente.
// Il peso di decadimento è già calcolato lato server (report_decay_weight),
// qui si applica solo il taglio della finestra temporale del filtro.
final filteredReportsProvider = Provider<List<Report>>((ref) {
  final filter = ref.watch(timeFilterProvider);
  final feed = ref.watch(reportsFeedProvider).valueOrNull ?? const [];
  final cutoff = DateTime.now().toUtc().subtract(filter.duration);

  return feed.where((report) {
    final createdAt = report.createdAt;
    return createdAt != null && createdAt.toUtc().isAfter(cutoff);
  }).toList();
});
