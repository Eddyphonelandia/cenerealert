import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_flags.dart';

final hasGivenConsentProvider = FutureProvider<bool>((ref) {
  return LocalFlags.hasGivenConsent();
});

// Registra l'accettazione del consenso e aggiorna il provider così
// ConsentGate lascia passare subito al resto dell'app, senza richiedere
// un riavvio.
Future<void> acceptConsent(WidgetRef ref) async {
  await LocalFlags.setConsentGiven();
  ref.invalidate(hasGivenConsentProvider);
}
