import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../report/application/report_providers.dart';
import '../data/saved_places_repository.dart';
import '../domain/saved_place.dart';

final savedPlacesRepositoryProvider = Provider<SavedPlacesRepository>((ref) {
  return SavedPlacesRepository(ref.watch(supabaseClientProvider));
});

// Numero massimo di luoghi salvati per utente. Soglia lato client per
// tenere sotto controllo il volume di controlli di prossimità lato
// server; andrà eventualmente specchiata anche in thresholds_config
// quando implementeremo le push di prossimità.
const maxSavedPlaces = 5;

// Elenco dei luoghi salvati dell'utente corrente. Le azioni aggiornano
// subito lo stato locale, senza bisogno di un refresh manuale dopo ogni
// operazione.
class SavedPlacesController extends AsyncNotifier<List<SavedPlace>> {
  @override
  Future<List<SavedPlace>> build() {
    return ref.read(savedPlacesRepositoryProvider).fetchAll();
  }

  Future<void> add(SavedPlace place) async {
    final created = await ref.read(savedPlacesRepositoryProvider).create(place);
    state = AsyncData([...state.valueOrNull ?? const [], created]);
  }

  Future<void> updatePlace(SavedPlace place) async {
    await ref.read(savedPlacesRepositoryProvider).update(place);
    final current = state.valueOrNull ?? const [];
    state = AsyncData([
      for (final existing in current)
        if (existing.id == place.id) place else existing,
    ]);
  }

  Future<void> remove(String id) async {
    await ref.read(savedPlacesRepositoryProvider).delete(id);
    final current = state.valueOrNull ?? const [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}

final savedPlacesControllerProvider =
    AsyncNotifierProvider<SavedPlacesController, List<SavedPlace>>(
  SavedPlacesController.new,
);
