import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/consent_providers.dart';

// Schermata di consenso mostrata al primo avvio, prima di qualunque
// richiesta di permesso di sistema (posizione, notifiche). Spiega cosa
// viene raccolto e perché in linguaggio semplice: consenso granulare e
// informato richiesto dal GDPR, non un "accetta tutto" preselezionato.
class ConsentScreen extends ConsumerWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Prima di iniziare',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const _ConsentPoint(
                text:
                    'La posizione viene usata solo per collocare le tue segnalazioni sulla mappa e per avvisarti quando la cenere si avvicina. Non viene mai usata per pubblicità o tracciamento.',
              ),
              const _ConsentPoint(
                text:
                    'Le segnalazioni pubbliche sono aggregate e anonime: nessun altro utente vede chi le ha inviate.',
              ),
              const _ConsentPoint(
                text:
                    "CenereAlert è un servizio informativo collaborativo. Non sostituisce la Protezione Civile né l'INGV.",
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amberSignal,
                    foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => acceptConsent(ref),
                  child: const Text('Ho capito, continua'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentPoint extends StatelessWidget {
  const _ConsentPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 6, color: AppColors.amberSignal),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.darkTextSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
