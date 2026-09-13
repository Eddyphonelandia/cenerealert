import 'package:supabase_flutter/supabase_flutter.dart';

// Incapsula il bootstrap dell'autenticazione anonima e il collegamento
// opzionale di un'email, così la reputazione e i luoghi salvati possono
// sopravvivere al cambio di dispositivo o alla disinstallazione dell'app
// (decisione presa in fase di architettura, confermata dall'utente).
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  // true se l'utente non ha ancora collegato un'identità permanente
  // (email/telefono). Il campo isAnonymous è esposto dagli oggetti User
  // nelle versioni di supabase_flutter che supportano l'accesso anonimo;
  // verifica contro la versione installata se l'analyzer non lo riconosce.
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Crea (se non esiste già) una sessione anonima. Va chiamato una sola
  // volta all'avvio dell'app, prima di mostrare qualunque schermata che
  // richieda un utente autenticato (es. l'invio di una segnalazione).
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentUser != null) return;
    await _client.auth.signInAnonymously();
  }

  // Collega un'email all'utente anonimo corrente. Supabase invia
  // un'email di conferma; l'account resta anonimo finché il link non
  // viene aperto, dopodiché diventa permanente mantenendo lo stesso
  // user_id — reputazione e luoghi salvati restano quindi validi.
  Future<void> linkEmail(String email) async {
    await _client.auth.updateUser(UserAttributes(email: email));
  }
}
