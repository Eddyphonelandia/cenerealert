import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/notifications/presentation/notifications_bootstrap.dart';
import 'features/onboarding/presentation/consent_gate.dart';
import 'features/report/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  // Richiede gli scaffold nativi (android/, ios/) generati con
  // `flutter create .` e i file di configurazione Firebase per
  // piattaforma (google-services.json / GoogleService-Info.plist) —
  // vedi README per i passaggi di setup, non ancora eseguibili in questo
  // ambiente di sviluppo.
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: CenereAlertApp()));
}

class CenereAlertApp extends StatelessWidget {
  const CenereAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CenereAlert',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Ordine dei gate: consenso GDPR (nessuna rete/permesso ancora) →
      // bootstrap della sessione anonima (bloccante) → registrazione
      // push in background (non bloccante) → schermata principale.
      home: const ConsentGate(
        child: AuthGate(
          child: NotificationsBootstrap(child: HomeScreen()),
        ),
      ),
    );
  }
}
