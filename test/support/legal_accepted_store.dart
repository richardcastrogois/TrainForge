import 'package:trainforge/features/legal/legal_consent_store.dart';
import 'package:trainforge/features/legal/legal_documents.dart';

/// Existing widget tests start past the legal gate: current documents accepted
/// and health data granted, unless a test writes another decision.
class AcceptedLegalConsentStore extends MemoryLegalConsentStore {
  final texts = LegalTexts();
  @override
  Future<Map<String, dynamic>?> read(String key) async {
    if (values.containsKey(key)) return values[key];
    if (key.startsWith('accepted.')) {
      return {
        for (final d in legalDocuments)
          d.id: {
            'version': d.version,
            'sha': await texts.sha(d),
            'at': '2026-11-19T12:00:00Z',
            'appVersion': legalAppVersion,
            'locale': 'pt-BR',
          },
      };
    }
    if (key.startsWith('health.')) {
      return {
        'decision': 'granted',
        'version': healthConsentVersion,
        'at': '2026-11-19T12:00:00Z',
      };
    }
    return null;
  }

  /// No network in widget tests: decisions are never queued for the server.
  @override
  Future<void> write(String key, Map<String, dynamic>? value) async {
    if (!key.startsWith('pending.')) await super.write(key, value);
  }
}
