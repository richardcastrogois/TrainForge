//lib/features/auth/data/auth_repository.dart
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_user.dart';
import 'auth_api.dart';
import 'auth_storage.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final _api = AuthApi();
  final _storage = AuthStorage();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    if (kIsWeb) {
      await _googleSignIn.initialize();
    } else {
      await _googleSignIn.initialize(
        serverClientId:
            '975945820703-phranuo6urju23c43fb6n2102do767kl.apps.googleusercontent.com',
      );
    }

    _initialized = true;
  }

  Future<AuthUser> signInWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google não retornou idToken');
    }

    final user = await _api.loginWithGoogleIdToken(idToken);
    await _storage.saveToken(user.token);

    return user;
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await _api.getMe();
      return true;
    } catch (_) {
      await _storage.clearToken();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearToken();

    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<String?> getSavedToken() async {
    return _storage.getToken();
  }
}
