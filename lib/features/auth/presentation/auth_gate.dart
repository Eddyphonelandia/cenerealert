import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';

// Attende il bootstrap della sessione anonima prima di mostrare il resto
// dell'app. In caso di errore (es. provider "Anonymous sign-ins" non
// abilitato nel progetto Supabase) mostra un messaggio calmo con un
// pulsante di retry, mai un crash silenzioso o una schermata bianca.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(authBootstrapProvider);

    return bootstrap.when(
      data: (_) => child,
      loading: () => const _AuthLoading(),
      error: (error, _) => _AuthError(
        onRetry: () => ref.invalidate(authBootstrapProvider),
      ),
    );
  }
}

class _AuthLoading extends StatelessWidget {
  const _AuthLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.amberSignal),
      ),
    );
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Non riesco ad avviare una sessione. Controlla la connessione e riprova.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.darkTextPrimary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.amberSignal,
                  side: const BorderSide(color: AppColors.amberSignal),
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
