import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../report/application/report_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

// Esegue il bootstrap della sessione anonima. L'app mostra la schermata
// principale solo dopo che questo provider si è risolto con successo
// (vedi AuthGate). Se fallisce (es. provider "Anonymous sign-ins" non
// abilitato nel progetto Supabase), l'errore viene mostrato con un retry.
final authBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.watch(authRepositoryProvider).ensureSignedIn();
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  // Si aggiorna reattivamente sia al bootstrap iniziale sia a eventuali
  // cambi di stato (es. dopo il collegamento di un'email).
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

final isAnonymousProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).isAnonymous;
});
