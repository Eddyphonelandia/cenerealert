import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/application/report_providers.dart';
import '../data/reputation_repository.dart';
import '../domain/user_reputation.dart';

final reputationRepositoryProvider = Provider<ReputationRepository>((ref) {
  return ReputationRepository(ref.watch(supabaseClientProvider));
});

final myReputationProvider =
    FutureProvider.autoDispose<UserReputation?>((ref) {
  return ref.watch(reputationRepositoryProvider).fetchMine();
});
