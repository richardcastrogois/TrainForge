import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_user.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  // Deliberately separate from the legacy Fastify credential.
  static const _key = 'trainforge.go.v1.tokens';
  static Future<void> _pending = Future.value();

  static Future<T> _serial<T>(Future<T> Function() action) {
    final task = _pending.then((_) => action());
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<Map<String, dynamic>?> _read() async {
    final raw = await _storage.read(key: _key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String?> getToken() =>
      _serial(() async => (await _read())?['accessToken'] as String?);
  Future<String?> getRefreshToken() =>
      _serial(() async => (await _read())?['refreshToken'] as String?);
  Future<void> saveSession(AuthUser session) => _serial(() async {
    await _write(session);
    await _storage.delete(key: 'auth_token');
  });
  Future<void> _write(AuthUser session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'accessToken': session.token,
      'refreshToken': session.refreshToken,
    }),
  );
  // Serialize compare-and-replace with login/logout to prevent stale refresh
  // responses from restoring an old session after logout/account switching.
  Future<bool> replaceSession(String expectedRefresh, AuthUser session) =>
      _serial(() async {
        if ((await _read())?['refreshToken'] != expectedRefresh) return false;
        await _write(session);
        return true;
      });
  Future<void> clearIfRefreshToken(String expected) => _serial(() async {
    if ((await _read())?['refreshToken'] == expected) {
      await _storage.delete(key: _key);
    }
  });
  Future<void> clearIfAccessToken(String expected) => _serial(() async {
    if ((await _read())?['accessToken'] == expected) {
      await _storage.delete(key: _key);
    }
  });
  Future<void> clearToken() => _serial(() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: 'auth_token');
  });
}
