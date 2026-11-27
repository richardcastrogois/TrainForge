import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trainforge/core/config/app_config.dart';
import '../domain/auth_user.dart';
import '../domain/auth_profile.dart';
import 'auth_api.dart';
import 'auth_storage.dart';
import 'profile_photos.dart';
import '../../nutrition/data/nutrition_local_store.dart';

class AuthRepository implements SessionRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final AuthApi _api;
  final AuthStorage _storage;
  final Future<bool> Function(String) _accountErased;
  final Future<bool> Function(String) _accountLocked;
  final Future<void> Function(String) _unlockAccount;
  AuthRepository({
    AuthApi? api,
    AuthStorage? storage,
    Future<bool> Function(String)? accountErased,
    Future<bool> Function(String)? accountLocked,
    Future<void> Function(String)? unlockAccount,
  }) : _api = api ?? AuthApi(),
       _storage = storage ?? AuthStorage(),
       _accountErased = accountErased ?? NutritionLocalStore.isErased,
       _accountLocked = accountLocked ?? NutritionLocalStore.isLocked,
       _unlockAccount = unlockAccount ?? NutritionLocalStore.unlockAccount;

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
    GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code.name == "canceled") {
        throw const SessionException(SessionFailure.cancelled);
      }
      if (error.code.name == "clientConfigurationError") {
        throw const SessionException(SessionFailure.configuration);
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google não retornou credencial.');
    }
    final session = await _api.loginWithGoogleIdToken(idToken);
    await _storage.saveSession(session);
    await ProfilePhotos.instance.setGoogle(session.id, account.photoUrl);
    await _unlockAccount(session.id);
    return session;
  }

  @override
  Future<AuthProfile> signIn() async {
    final session = await signInWithGoogle();
    return AuthProfile(
      id: session.id,
      name: session.name,
      email: session.email,
      image: session.image,
    );
  }

  /// Google account picture without showing anything (null when the
  /// account is not available silently).
  Future<String?> googlePhotoUrl() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.attemptLightweightAuthentication();
      return account?.photoUrl;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async => await restoreSession() != null;

  @override
  Future<AuthProfile?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final profile = AuthProfile.fromJson(await _api.getMe());
      if (await _accountErased(profile.id)) {
        await _storage.clearIfAccessToken(token);
        return null;
      }
      await _storage.cacheProfile(token, profile);
      await _unlockAccount(profile.id);
      return profile;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.clearIfAccessToken(token);
        return null;
      }
      // A cached profile unlocks only account-scoped local data. All HTTP
      // operations still require live authorization and the normal interceptor.
      if (error.response == null || (error.response?.statusCode ?? 0) >= 500) {
        final cached = await _storage.offlineProfile(token);
        if (cached != null &&
            !await _accountErased(cached.id) &&
            !await _accountLocked(cached.id)) {
          return cached;
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMe() => _api.getMe();
  @override
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
