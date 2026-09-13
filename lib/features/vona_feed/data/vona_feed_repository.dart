import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/vona_feed_entry.dart';

// Legge l'ultimo comunicato VONA/INGV in cache. Nessuna scrittura da
// qui: la tabella è popolata solo lato server dalla Edge Function di
// scraping "fetch-vona-feed".
class VonaFeedRepository {
  VonaFeedRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'vona_feed_cache';

  Future<VonaFeedEntry?> fetchLatest() async {
    final row = await _client
        .from(_table)
        .select()
        .order('received_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return row == null ? null : VonaFeedEntry.fromJson(row);
  }
}
