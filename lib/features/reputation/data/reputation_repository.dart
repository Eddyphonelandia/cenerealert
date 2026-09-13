import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_reputation.dart';

// Legge la reputazione dell'utente corrente. La RLS definita nello
// sprint 1 permette a ciascun utente di leggere solo la propria riga di
// user_reputation; non esiste (né dovrebbe esistere) un modo per il
// client di scriverla direttamente.
class ReputationRepository {
  ReputationRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'user_reputation';

  Future<UserReputation?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return row == null ? null : UserReputation.fromJson(row);
  }
}
