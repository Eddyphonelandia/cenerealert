import 'package:supabase_flutter/supabase_flutter.dart';

import '../../report/domain/report.dart';

// Legge le segnalazioni aggregate/anonimizzate dalla vista pubblica
// "reports_public" (mai lo user_id, per GDPR/privacy by design).
class ReportsFeedRepository {
  ReportsFeedRepository(this._client);
  final SupabaseClient _client;

  static const _view = 'reports_public';
  static const _maxWindow = Duration(hours: 24);
  static const _maxRows = 3000;

  // Recupera tutte le segnalazioni entro la finestra massima (24h): i
  // filtri più stretti (1h/3h/6h) vengono applicati lato client, così
  // cambiare filtro è immediato e non richiede un nuovo giro di rete.
  Future<List<Report>> fetchRecent() async {
    final cutoff = DateTime.now().toUtc().subtract(_maxWindow);
    final rows = await _client
        .from(_view)
        .select()
        .gte('created_at', cutoff.toIso8601String())
        .order('created_at', ascending: false)
        .limit(_maxRows);

    return (rows as List)
        .map((row) => Report.fromPublicJson(row as Map<String, dynamic>))
        .toList();
  }
}
