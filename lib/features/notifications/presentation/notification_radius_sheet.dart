import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/push_notifications_providers.dart';

// Permette di scegliere il raggio (3-10 km) entro cui ricevere una push
// quando arrivano segnalazioni validate vicino alla posizione attuale
// dell'utente. Distinto dal raggio dei luoghi salvati, che è indipendente
// per ciascun luogo.
class NotificationRadiusSheet extends ConsumerStatefulWidget {
  const NotificationRadiusSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NotificationRadiusSheet(),
    );
  }

  @override
  ConsumerState<NotificationRadiusSheet> createState() =>
      _NotificationRadiusSheetState();
}

class _NotificationRadiusSheetState
    extends ConsumerState<NotificationRadiusSheet> {
  double _radiusKm = 5;
  String? _fcmToken;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await FirebaseMessaging.instance.getToken();
    _fcmToken = token;
    if (token != null) {
      final repository = ref.read(alertSubscriptionRepositoryProvider);
      final current = await repository.currentRadius(token);
      if (current != null) _radiusKm = current;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save(double value) async {
    setState(() => _radiusKm = value);
    final token = _fcmToken;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(alertSubscriptionRepositoryProvider)
          .updateRadius(fcmToken: token, radiusKm: value);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allerta di prossimità',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ricevi una notifica quando arrivano segnalazioni validate entro questa distanza dalla tua posizione attuale (aggiornata solo mentre l\'app è aperta).',
            style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.amberSignal),
              ),
            )
          else ...[
            Text(
              '${_radiusKm.round()} km',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Slider(
              value: _radiusKm,
              min: 3,
              max: 10,
              divisions: 7,
              activeColor: AppColors.amberSignal,
              inactiveColor: AppColors.darkBorder,
              label: '${_radiusKm.round()} km',
              onChanged: _isSaving ? null : _save,
            ),
          ],
        ],
      ),
    );
  }
}
