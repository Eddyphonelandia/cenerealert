import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/consent_providers.dart';
import 'consent_screen.dart';

// Mostra la schermata di consenso finché l'utente non l'ha accettata
// almeno una volta; da lì in poi lascia passare direttamente al resto
// dell'app (il flag è persistito localmente, nessuna chiamata di rete).
class ConsentGate extends ConsumerWidget {
  const ConsentGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consent = ref.watch(hasGivenConsentProvider);

    return consent.when(
      data: (given) => given ? child : const ConsentScreen(),
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: SizedBox.shrink(),
      ),
      // In caso di errore di lettura del flag locale, mostriamo comunque
      // il consenso: meglio richiederlo di nuovo che darlo per scontato.
      error: (_, __) => const ConsentScreen(),
    );
  }
}
