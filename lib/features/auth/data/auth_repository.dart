import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trainforge/core/config/app_config.dart';
import '../domain/auth_user.dart';
import 'auth_api.dart';
import 'auth_storage.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final AuthApi _api;
  final AuthStorage _storage;
  AuthRepository({AuthApi? api, AuthStorage? storage})
    : _api = api ?? AuthApi(),
      _storage = storage ?? AuthStorage();

  static Future<void>? _initialization;
  Future<void> _ensureInitialized() async {
    AppConfig.validate();
    if (kIsWeb || AppConfig.googleServerClientId.isEmpty) {
      throw StateError('Login Google indisponível: configure o client ID Web.');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        AppConfig.googleIosClientId.isEmpty) {
      throw StateError('OAuth iOS ainda não configurado.');
    }
    final pending = _initialization ??= _googleSignIn.initialize(
      serverClientId: AppConfig.googleServerClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? AppConfig.googleIosClientId
          : null,
    );
    try {
      await pending;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<AuthUser> signInWithGoogle() async {
    await _ensureInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google não retornou credencial.');
    }
    final session = await _api.loginWithGoogleIdToken(idToken);
    await _storage.saveSession(session);
    return session;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return false;
    try {
      await _api.getMe();
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.clearIfAccessToken(token);
        return false;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe() => _api.getMe();
  Future<void> logout() async {
    final refresh = await _storage.getRefreshToken();
    // Failure remains visible/retryable; never claim server revocation offline.
    if (refresh != null && refresh.isNotEmpty) await _api.logout(refresh);
    if (refresh != null) {
      await _storage.clearIfRefreshToken(refresh);
    } else {
      final access = await _storage.getToken();
      if (access != null) await _storage.clearIfAccessToken(access);
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<String?> getSavedToken() => _storage.getToken();
}
