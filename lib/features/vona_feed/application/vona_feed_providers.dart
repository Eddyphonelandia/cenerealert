import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/application/report_providers.dart';
import '../data/vona_feed_repository.dart';
import '../domain/vona_feed_entry.dart';

final vonaFeedRepositoryProvider = Provider<VonaFeedRepository>((ref) {
  return VonaFeedRepository(ref.watch(supabaseClientProvider));
});

const _refreshInterval = Duration(minutes: 2);

// Aggiorna periodicamente l'ultimo comunicato VONA mostrato in home. Un
// intervallo di 2 minuti è più che sufficiente: la Edge Function che
// alimenta la cache gira ogni 5-10 minuti (vedi README), quindi un
// refresh più frequente non troverebbe comunque nulla di nuovo.
class VonaFeedController extends AsyncNotifier<VonaFeedEntry?> {
  Timer? _timer;

  @override
  Future<VonaFeedEntry?> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => refresh());
    ref.onDispose(() => _timer?.cancel());
    return ref.read(vonaFeedRepositoryProvider).fetchLatest();
  }

  Future<void> refresh() async {
    final data = await ref.read(vonaFeedRepositoryProvider).fetchLatest();
    state = AsyncData(data);
  }
}

final vonaFeedProvider =
    AsyncNotifierProvider<VonaFeedController, VonaFeedEntry?>(
  VonaFeedController.new,
);
