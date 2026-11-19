import 'package:dio/dio.dart';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../../core/http/app_dio.dart';
import 'legal_consent_store.dart';
import 'legal_documents.dart';

/// Health-data decision per account, read by the nutrition synchronizer.
abstract final class HealthConsentRegistry {
  static final Map<String, bool> _granted = {};
  static bool granted(String accountId) => _granted[accountId] == true;
  static void set(String accountId, bool value) => _granted[accountId] = value;
}

/// Gate state for Terms/Privacy (device) and health data (account), plus the
/// queue of decisions waiting to be recorded on the server.
class LegalController extends ChangeNotifier {
  /// Tests replace the default device store (flutter_test_config.dart).
  static LegalConsentStore Function() defaultStore =
      SecureLegalConsentStore.new;

  final LegalConsentStore store;
  final LegalTexts texts;
  final Dio? _dio;
  final String Function() locale;
  final DateTime Function() now;
  LegalController({
    LegalConsentStore? store,
    LegalTexts? texts,
    Dio? dio,
    String Function()? locale,
    DateTime Function()? now,
  }) : store = store ?? defaultStore(),
       texts = texts ?? LegalTexts(),
       _dio = dio,
       locale =
           locale ?? (() => PlatformDispatcher.instance.locale.toLanguageTag()),
       now = now ?? DateTime.now;

  bool loaded = false;
  bool busy = false;
  Map<String, dynamic>? accepted;
  final Map<String, Map<String, dynamic>?> _health = {};
  Map<String, String> currentSha = {};

  Dio get dio => _dio ?? AppDio.instance;

  Future<void> load() async {
    try {
      for (final document in legalDocuments) {
        currentSha[document.id] = await texts.sha(document);
      }
      accepted = await store.read('accepted');
    } catch (_) {
      accepted = null;
    }
    loaded = true;
    notifyListeners();
  }

  Map<String, dynamic>? _entry(String id) =>
      (accepted?[id] as Map?)?.cast<String, dynamic>();

  /// True until the current version and exact text of every document is accepted.
  bool get needsTerms => legalDocuments.any((d) {
    final entry = _entry(d.id);
    return entry == null ||
        entry['version'] != d.version ||
        entry['sha'] != currentSha[d.id];
  });

  /// A previous version exists: show the "terms changed" variant.
  bool get isUpdate =>
      accepted != null && legalDocuments.any((d) => _entry(d.id) != null);

  String? acceptedAt(String id) => _entry(id)?['at'] as String?;
  String? acceptedVersion(String id) => _entry(id)?['version'] as String?;

  Future<void> acceptTerms() async {
    busy = true;
    notifyListeners();
    try {
      final at = now().toUtc().toIso8601String();
      final next = <String, dynamic>{'adultOrGuardian': true};
      for (final d in legalDocuments) {
        next[d.id] = {
          'version': d.version,
          'sha': currentSha[d.id],
          'at': at,
          'appVersion': legalAppVersion,
          'locale': locale(),
        };
      }
      await store.write('accepted', next);
      accepted = next;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ---- Health data (per account) ----

  bool healthLoaded(String accountId) => _health.containsKey(accountId);
  bool? healthGranted(String accountId) {
    final value = _health[accountId];
    return value == null ? null : value['decision'] == 'granted';
  }

  String? healthAt(String accountId) => _health[accountId]?['at'] as String?;

  final Set<String> _loading = {};
  Future<void> loadAccount(String accountId) async {
    if (healthLoaded(accountId) || !_loading.add(accountId)) return;
    Map<String, dynamic>? value;
    try {
      value = await store.read('health.$accountId');
    } catch (_) {
      value = null;
    }
    _health[accountId] = value;
    _loading.remove(accountId);
    HealthConsentRegistry.set(accountId, value?['decision'] == 'granted');
    notifyListeners();
    await _queueTermsFor(accountId);
    await flush(accountId);
  }

  Future<void> decideHealth(String accountId, {required bool granted}) async {
    final at = now().toUtc().toIso8601String();
    final value = {
      'decision': granted ? 'granted' : 'revoked',
      'version': healthConsentVersion,
      'at': at,
    };
    await store.write('health.$accountId', value);
    _health[accountId] = value;
    HealthConsentRegistry.set(accountId, granted);
    notifyListeners();
    await _enqueue(accountId, [
      {
        'document': 'health_data',
        'version': healthConsentVersion,
        'decision': value['decision'],
        'appVersion': legalAppVersion,
        'locale': locale(),
        'clientRecordedAt': at,
      },
    ]);
    await flush(accountId);
  }

  /// Device acceptance is linked to the account the first time it signs in here.
  Future<void> _queueTermsFor(String accountId) async {
    final linked = await store.read('linked.$accountId');
    final signature = legalDocuments
        .map(
          (d) => '${d.id}:${_entry(d.id)?['version']}:${_entry(d.id)?['sha']}',
        )
        .join('|');
    if (needsTerms || linked?['signature'] == signature) return;
    await _enqueue(accountId, [
      for (final d in legalDocuments)
        {
          'document': d.id,
          'version': _entry(d.id)!['version'],
          'documentSha': _entry(d.id)!['sha'],
          'decision': 'accepted',
          'appVersion': _entry(d.id)!['appVersion'],
          'locale': _entry(d.id)!['locale'],
          'clientRecordedAt': _entry(d.id)!['at'],
        },
    ]);
    await store.write('linked.$accountId', {'signature': signature});
  }

  Future<void> _enqueue(
    String accountId,
    List<Map<String, dynamic>> items,
  ) async {
    final pending = await store.read('pending.$accountId');
    final list = [...((pending?['items'] as List?) ?? const []), ...items];
    await store.write('pending.$accountId', {'items': list});
  }

  /// Sends queued decisions; failures keep them for the next opening.
  Future<bool> flush(String accountId) async {
    try {
      final pending = await store.read('pending.$accountId');
      final items = (pending?['items'] as List?) ?? const [];
      for (var i = 0; i < items.length; i += 3) {
        await dio.post(
          '/api/v1/me/legal-consents',
          data: {
            'items': items.sublist(
              i,
              i + 3 > items.length ? items.length : i + 3,
            ),
          },
        );
      }
      await store.write('pending.$accountId', null);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Makes the gate's controller reachable from settings inside the product shell.
class LegalScope extends InheritedNotifier<LegalController> {
  const LegalScope({
    super.key,
    required LegalController controller,
    required super.child,
  }) : super(notifier: controller);
  static LegalController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LegalScope>()?.notifier;
}
