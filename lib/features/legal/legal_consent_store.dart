import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-side record of consents. Terms/Privacy are per device (they are
/// accepted before sign-in); health data is per account. Items not yet sent to
/// the server wait in a per-account queue.
abstract class LegalConsentStore {
  Future<Map<String, dynamic>?> read(String key);
  Future<void> write(String key, Map<String, dynamic>? value);
}

class SecureLegalConsentStore implements LegalConsentStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  static const _prefix = 'trainforge.legal.v1.';
  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await _storage.read(key: _prefix + key);
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  @override
  Future<void> write(String key, Map<String, dynamic>? value) => value == null
      ? _storage.delete(key: _prefix + key)
      : _storage.write(key: _prefix + key, value: jsonEncode(value));
}

class MemoryLegalConsentStore implements LegalConsentStore {
  final Map<String, Map<String, dynamic>> values;
  MemoryLegalConsentStore([Map<String, Map<String, dynamic>>? values])
    : values = values ?? {};
  @override
  Future<Map<String, dynamic>?> read(String key) async => values[key];
  @override
  Future<void> write(String key, Map<String, dynamic>? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
