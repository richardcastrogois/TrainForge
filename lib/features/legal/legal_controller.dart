import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
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

/// Consent state per signed-in account: Terms/Privacy acceptance and the
/// separate health-data decision. Visitors never see the gate (no account,
/// nothing leaves the device). Decisions are kept in memory first, saved on
/// the device when possible and queued for the server, which holds the proof.
class LegalController extends ChangeNotifier {
  /// Tests replace the default device store (flutter_test_config.dart).
  static LegalConsentStore Function() defaultStore =
      SecureLegalConsentStore.new;

  final LegalConsentStore store;
  final LegalTexts texts;
  final Dio? _dio;
  final String Function() locale;
  final DateTime Function() now;
  final Duration serverTimeout;
  LegalController({
    LegalConsentStore? store,
    LegalTexts? texts,
    Dio? dio,
    String Function()? locale,
    DateTime Function()? now,
    this.serverTimeout = const Duration(seconds: 6),
  }) : store = store ?? defaultStore(),
       texts = texts ?? LegalTexts(),
       _dio = dio,
       locale =
           locale ?? (() => PlatformDispatcher.instance.locale.toLanguageTag()),
       now = now ?? DateTime.now;

  Dio get dio => _dio ?? AppDio.instance;

  final Map<String, String> currentSha = {};
  final Map<String, Map<String, dynamic>?> _accepted = {};
  final Map<String, Map<String, dynamic>?> _health = {};
  final Map<String, List<Map<String, dynamic>>> _pendingMemory = {};
  final Set<String> _loading = {};
  bool busy = false;

  Future<void> _ensureSha() async {
    for (final document in legalDocuments) {
      if (currentSha.containsKey(document.id)) continue;
      try {
        currentSha[document.id] = await texts.sha(document);
      } catch (_) {
        // Without the bundled text the acceptance is still recorded by version.
      }
    }
  }

  Future<Map<String, dynamic>?> _read(String key) async {
    try {
      return await store.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic>? value) async {
    try {
      await store.write(key, value);
    } catch (_) {
      // Keystore/IO failure must not block the person: memory + server queue.
    }
  }

  bool accountLoaded(String accountId) => _accepted.containsKey(accountId);

  /// Loads local decisions, then recovers missing ones from the server
  /// (reinstall or another phone) and sends anything still queued.
  Future<void> loadAccount(String accountId) async {
    if (accountLoaded(accountId) || !_loading.add(accountId)) return;
    try {
      await _ensureSha();
      var accepted = await _read('accepted.$accountId');
      var health = await _read('health.$accountId');
      if (_termsMissing(accepted) || health == null) {
        final remote = await _remote();
        if (_termsMissing(accepted) && remote != null) {
          final fromServer = _termsFromServer(remote);
          if (!_termsMissing(fromServer)) {
            accepted = fromServer;
            await _write('accepted.$accountId', accepted);
          }
        }
        if (health == null && remote?['health_data'] != null) {
          final h = remote!['health_data']!;
          health = {
            'decision': h['decision'],
            'version': h['version'],
            'at': h['clientRecordedAt'],
          };
          await _write('health.$accountId', health);
        }
      }
      _accepted[accountId] = accepted;
      _health[accountId] = health;
      HealthConsentRegistry.set(accountId, health?['decision'] == 'granted');
    } finally {
      _loading.remove(accountId);
      _accepted.putIfAbsent(accountId, () => null);
      notifyListeners();
    }
    unawaited(flush(accountId));
  }

  Future<Map<String, Map<String, dynamic>>?> _remote() async {
    try {
      final response = await dio
          .get('/api/v1/me/legal-consents')
          .timeout(serverTimeout);
      final items = (response.data as Map)['items'] as List;
      return {
        for (final item in items.cast<Map>())
          item['document'] as String: Map<String, dynamic>.from(item),
      };
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _termsFromServer(
    Map<String, Map<String, dynamic>> remote,
  ) {
    final result = <String, dynamic>{'adultOrGuardian': true};
    for (final d in legalDocuments) {
      final item = remote[d.id];
      if (item == null || item['decision'] != 'accepted') return null;
      result[d.id] = {
        'version': item['version'],
        'sha': item['documentSha'],
        'at': item['clientRecordedAt'],
        'appVersion': item['appVersion'],
        'locale': item['locale'],
      };
    }
    return result;
  }

  Map<String, dynamic>? _entry(Map<String, dynamic>? accepted, String id) =>
      (accepted?[id] as Map?)?.cast<String, dynamic>();

  bool _termsMissing(Map<String, dynamic>? accepted) => legalDocuments.any((d) {
    final entry = _entry(accepted, d.id);
    final sha = currentSha[d.id];
    return entry == null ||
        entry['version'] != d.version ||
        (sha != null && entry['sha'] != sha);
  });

  /// True until this account accepted the current version and exact text.
  bool needsTerms(String accountId) => _termsMissing(_accepted[accountId]);

  /// A previous version was accepted: show the "terms changed" variant.
  bool isUpdate(String accountId) =>
      legalDocuments.any((d) => _entry(_accepted[accountId], d.id) != null);

  String? acceptedAt(String accountId, String id) =>
      _entry(_accepted[accountId], id)?['at'] as String?;
  String? acceptedVersion(String accountId, String id) =>
      _entry(_accepted[accountId], id)?['version'] as String?;

  Future<void> acceptTerms(String accountId) async {
    busy = true;
    notifyListeners();
    try {
      await _ensureSha();
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
      _accepted[accountId] = next;
      await _write('accepted.$accountId', next);
      await _enqueue(accountId, [
        for (final d in legalDocuments)
          if (currentSha[d.id] != null)
            {
              'document': d.id,
              'version': d.version,
              'documentSha': currentSha[d.id],
              'decision': 'accepted',
              'appVersion': legalAppVersion,
              'locale': locale(),
              'clientRecordedAt': at,
            },
      ]);
    } finally {
      busy = false;
      notifyListeners();
    }
    unawaited(flush(accountId));
  }

  // ---- Health data (per account) ----

  bool? healthGranted(String accountId) {
    final value = _health[accountId];
    return value == null ? null : value['decision'] == 'granted';
  }

  String? healthAt(String accountId) => _health[accountId]?['at'] as String?;

  Future<void> decideHealth(String accountId, {required bool granted}) async {
    final at = now().toUtc().toIso8601String();
    final value = {
      'decision': granted ? 'granted' : 'revoked',
      'version': healthConsentVersion,
      'at': at,
    };
    _health[accountId] = value;
    HealthConsentRegistry.set(accountId, granted);
    notifyListeners();
    await _write('health.$accountId', value);
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
    unawaited(flush(accountId));
  }

  Future<void> _enqueue(
    String accountId,
    List<Map<String, dynamic>> items,
  ) async {
    final memory = _pendingMemory.putIfAbsent(accountId, () => []);
    memory.addAll(items);
    await _write('pending.$accountId', {'items': memory});
  }

  /// Sends queued decisions; failures keep them for the next opening.
  Future<bool> flush(String accountId) async {
    try {
      final stored = await _read('pending.$accountId');
      final memory = _pendingMemory[accountId] ?? const [];
      final items = List<Object?>.of(
        memory.isNotEmpty ? memory : ((stored?['items'] as List?) ?? const []),
      );
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
      // Decisions added while sending stay queued for the next flush.
      final left = (_pendingMemory[accountId] ?? [])
          .skip(memory.isNotEmpty ? items.length : 0)
          .toList();
      if (left.isEmpty) {
        _pendingMemory.remove(accountId);
        await _write('pending.$accountId', null);
      } else {
        _pendingMemory[accountId] = left;
        await _write('pending.$accountId', {'items': left});
      }
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
