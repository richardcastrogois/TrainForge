import 'package:dio/dio.dart';
import '../domain/auth_user.dart';
import 'auth_storage.dart';

class SessionRefresh {
  final AuthStorage storage;
  final Dio transport;
  Future<String?>? _pending;
  SessionRefresh(this.storage, this.transport);

  Future<String?> afterUnauthorized(String? observedToken) async {
    final current = await storage.getToken();
    if (current == null) return null;
    if (current != observedToken) return current;
    final pending = _pending;
    if (pending != null) return pending;
    final task = _rotate(current);
    _pending = task;
    try {
      return await task;
    } finally {
      _pending = null;
    }
  }

  Future<String?> _rotate(String observedAccess) async {
    final refresh = await storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await storage.clearIfAccessToken(observedAccess);
      return null;
    }
    try {
      final response = await transport.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final session = AuthUser.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      if (!await storage.replaceSession(refresh, session)) {
        return storage.getToken();
      }
      return session.token;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // Avoid clearing a new login established while this request was in flight.
        await storage.clearIfRefreshToken(refresh);
      }
      rethrow;
    }
  }
}
