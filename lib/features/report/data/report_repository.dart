import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/ash_intensity.dart';
import '../domain/report.dart';

// Eccezione applicativa per errori di business (cooldown, ecc.) sollevati
// dai trigger Postgres e propagati come messaggio nell'eccezione Postgrest.
class ReportException implements Exception {
  ReportException(this.message, {this.isCooldown = false});
  final String message;
  final bool isCooldown;

  @override
  String toString() => message;
}

class ReportRepository {
  ReportRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'reports';

  // Invia una nuova segnalazione. Il trigger lato database si occupa di:
  // - verificare il cooldown dell'utente,
  // - assegnare la cella di griglia,
  // - aggiornare/creare il cluster corrispondente (senza generare
  //   allerte: quello avviene solo dopo la validazione col gate INGV,
  //   in uno sprint successivo).
  Future<Report> submit({
    required double latitude,
    required double longitude,
    required AshIntensity intensity,
  }) async {
    final report = Report(
      latitude: latitude,
      longitude: longitude,
      intensity: intensity,
    );

    try {
      final response = await _client
          .from(_table)
          .insert(report.toInsertPayload())
          .select('id, intensity, grid_cell, created_at')
          .single();

      return Report(
        id: response['id'] as String,
        latitude: latitude,
        longitude: longitude,
        intensity: ashIntensityFromDbValue(response['intensity'] as int),
        gridCell: response['grid_cell'] as String?,
        createdAt: DateTime.parse(response['created_at'] as String),
      );
    } on PostgrestException catch (e) {
      // Il trigger before_insert_report solleva un'eccezione con un
      // prefisso riconoscibile, così l'app distingue il cooldown da un
      // errore generico e mostra un messaggio calmo e specifico.
      if (e.message.contains('COOLDOWN_ATTIVO')) {
        throw ReportException(
          'Hai già inviato una segnalazione di recente. Riprova tra qualche minuto.',
          isCooldown: true,
        );
      }
      throw ReportException(
        'Non è stato possibile inviare la segnalazione. Controlla la connessione e riprova.',
      );
    }
  }
}
