import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/saved_place.dart';

class SavedPlaceException implements Exception {
  SavedPlaceException(this.message);
  final String message;

  @override
  String toString() => message;
}

// CRUD sui luoghi salvati. La lettura passa dalla vista
// "saved_places_view" (lat/lon esplicite); scrittura, aggiornamento e
// cancellazione vanno sulla tabella base "saved_places", protetta da RLS:
// ogni utente vede e modifica solo le proprie righe.
class SavedPlacesRepository {
  SavedPlacesRepository(this._client);
  final SupabaseClient _client;

  static const _table = 'saved_places';
  static const _readView = 'saved_places_view';

  Future<List<SavedPlace>> fetchAll() async {
    try {
      final rows =
          await _client.from(_readView).select().order('label', ascending: true);

      return (rows as List)
          .map((row) => SavedPlace.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException {
      throw SavedPlaceException(
        'Non riesco a caricare i tuoi luoghi salvati. Riprova più tardi.',
      );
    }
  }

  Future<SavedPlace> create(SavedPlace place) async {
    try {
      final response = await _client
          .from(_table)
          .insert(place.toWritePayload())
          .select('id')
          .single();

      return place.copyWith(id: response['id'] as String);
    } on PostgrestException {
      throw SavedPlaceException(
        'Non è stato possibile salvare il luogo. Controlla il raggio (3-10 km) e riprova.',
      );
    }
  }

  Future<void> update(SavedPlace place) async {
    assert(place.id != null, 'Impossibile aggiornare un luogo senza id');
    try {
      await _client
          .from(_table)
          .update(place.toWritePayload())
          .eq('id', place.id!);
    } on PostgrestException {
      throw SavedPlaceException(
        'Non è stato possibile aggiornare il luogo. Riprova.',
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException {
      throw SavedPlaceException('Non è stato possibile rimuovere il luogo.');
    }
  }
}
