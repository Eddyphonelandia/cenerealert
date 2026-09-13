import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../reputation/application/reputation_providers.dart';

// Bottom sheet per collegare un'email all'account anonimo, così
// reputazione e luoghi salvati sopravvivono al cambio di dispositivo.
// Collegare l'email resta sempre facoltativo: l'app è completamente
// utilizzabile in modo anonimo, come deciso in fase di architettura.
class AccountLinkSheet extends ConsumerStatefulWidget {
  const AccountLinkSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AccountLinkSheet(),
    );
  }

  @override
  ConsumerState<AccountLinkSheet> createState() => _AccountLinkSheetState();
}

class _AccountLinkSheetState extends ConsumerState<AccountLinkSheet> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _feedback = 'Inserisci un indirizzo email valido.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedback = null;
    });

    try {
      await ref.read(authRepositoryProvider).linkEmail(email);
      setState(() {
        _feedback =
            'Controlla la tua casella email e apri il link per confermare.';
      });
    } catch (_) {
      setState(() {
        _feedback = 'Non è stato possibile collegare questa email. Riprova.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = ref.watch(isAnonymousProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAnonymous ? 'Non perdere i tuoi dati' : 'Account collegato',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            "Collegando un'email, la tua reputazione e i tuoi luoghi salvati restano disponibili anche se cambi telefono. Resta facoltativo.",
            style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          if (isAnonymous) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: 'nome@esempio.it',
                hintStyle: const TextStyle(color: AppColors.darkTextTertiary),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.amberSignal,
                  foregroundColor: AppColors.darkBackground,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Collega email'),
              ),
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.amberSignal),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 16),
          const _ReputationSummary(),
        ],
      ),
    );
  }
}

// Riepilogo di sola lettura, in linguaggio semplice e senza toni
// competitivi (niente "livelli" o badge): quante segnalazioni sono state
// inviate e quante confermate da altri, così l'utente capisce come
// funziona la reputazione senza che diventi un elemento da "ottimizzare".
class _ReputationSummary extends ConsumerWidget {
  const _ReputationSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reputation = ref.watch(myReputationProvider);

    return reputation.when(
      data: (data) {
        if (data == null || data.totalReports == 0) {
          return const Text(
            'Non hai ancora inviato segnalazioni.',
            style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
          );
        }

        final percentage = (data.score * 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le tue segnalazioni',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${data.confirmedReports} su ${data.totalReports} confermate da altri segnalatori ($percentage%).',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
