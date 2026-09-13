import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/push_notifications_providers.dart';

// Avvia la registrazione al servizio push in background, senza bloccare
// la UI: a differenza del bootstrap dell'autenticazione, un eventuale
// fallimento qui (permesso negato, rete assente, Firebase non
// configurato) non deve mai impedire l'uso del resto dell'app.
class NotificationsBootstrap extends ConsumerStatefulWidget {
  const NotificationsBootstrap({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NotificationsBootstrap> createState() =>
      _NotificationsBootstrapState();
}

class _NotificationsBootstrapState
    extends ConsumerState<NotificationsBootstrap> {
  @override
  void initState() {
    super.initState();
    // Fire-and-forget: eventuali errori sono già gestiti in silenzio
    // dentro PushNotificationsController.
    ref.read(pushNotificationsControllerProvider).bootstrap();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
