import 'package:shared_preferences/shared_preferences.dart';

// Wrapper minimale su SharedPreferences per i flag locali dell'app.
// Nessun dato personale qui dentro: solo la preferenza "consenso già letto
// e accettato", memorizzata sul dispositivo per non richiederlo ad ogni
// avvio.
class LocalFlags {
  LocalFlags._();

  static const _consentKey = 'gdpr_consent_given_v1';

  static Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  static Future<void> setConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
  }
}
