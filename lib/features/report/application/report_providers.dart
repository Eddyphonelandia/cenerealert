import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/report_repository.dart';
import '../domain/ash_intensity.dart';
import '../domain/report.dart';
import 'position_provider.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(supabaseClientProvider));
});

// Gestisce il ciclo di vita dell'invio di una segnalazione:
// idle -> loading -> data (successo) / error (fallimento).
class ReportSubmissionController extends AsyncNotifier<Report?> {
  @override
  Future<Report?> build() async => null;

  Future<void> submit(AshIntensity intensity) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final position = await ref.read(currentPositionProvider.future);
      final repository = ref.read(reportRepositoryProvider);
      return repository.submit(
        latitude: position.latitude,
        longitude: position.longitude,
        intensity: intensity,
      );
    });
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final reportSubmissionControllerProvider =
    AsyncNotifierProvider<ReportSubmissionController, Report?>(
  ReportSubmissionController.new,
);
