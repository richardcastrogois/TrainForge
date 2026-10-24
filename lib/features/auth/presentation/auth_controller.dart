import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/auth_profile.dart';

enum AuthAction { restore, login, logout }

class AuthController extends ChangeNotifier {
  final SessionRepository repository;
  final Duration restoreTimeout;
  AuthController(
    this.repository, {
    this.restoreTimeout = const Duration(seconds: 30),
  });
  AuthProfile? profile;
  bool busy = false;
  String? message;
  AuthAction? failedAction;
  bool _disposed = false;
  String? _erasedAccountId;

  void accountErased(String expectedId) {
    if (_disposed) return;
    _erasedAccountId = expectedId;
    if (profile?.id == expectedId) {
      profile = null;
      message = null;
      failedAction = null;
    }
    notifyListeners();
  }

  Future<void> restore() => _run(AuthAction.restore);
  Future<void> login() => _run(AuthAction.login);
  Future<void> logout() => _run(AuthAction.logout);
  Future<void> retry() => _run(failedAction ?? AuthAction.restore);

  Future<void> _run(AuthAction action) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    failedAction = null;
    notifyListeners();
    try {
      switch (action) {
        case AuthAction.restore:
          final restored = await repository.restoreSession().timeout(
            restoreTimeout,
          );
          profile = restored?.id == _erasedAccountId ? null : restored;
        case AuthAction.login:
          final signedIn = await repository.signIn();
          profile = signedIn.id == _erasedAccountId ? null : signedIn;
        case AuthAction.logout:
          await repository.logout();
          profile = null;
      }
    } on TimeoutException catch (_) {
      message =
          'A confirmação da sessão demorou mais que o esperado. Sua sessão foi preservada; tente novamente ou consulte a biblioteca sem entrar.';
      failedAction = AuthAction.restore;
    } on SessionException catch (error) {
      if (error.failure == SessionFailure.configuration) {
        message =
            'O login Google não está configurado neste ambiente. Confira o roteiro de avaliação.';
        failedAction = action;
      }
      // Cancellation leaves the signed-out screen usable, without treating consent as failure.
    } on StateError catch (_) {
      message =
          'O ambiente de autenticação precisa de configuração. Confira o roteiro de avaliação.';
      failedAction = action;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        profile = null;
        message =
            'A sessão expirou ou foi revogada. Entre novamente com Google.';
        failedAction = AuthAction.login;
      } else {
        failedAction = action;
        message = status == 429
            ? 'Muitas tentativas. Aguarde um minuto e tente novamente.'
            : status == 503
            ? 'O serviço de autenticação está indisponível. Tente novamente mais tarde.'
            : action == AuthAction.logout
            ? 'A saída não foi confirmada. Conecte-se e tente sair novamente.'
            : action == AuthAction.login
            ? 'Não foi possível entrar. Confira sua conexão e tente novamente.'
            : 'Não foi possível confirmar a conexão. Sua sessão foi preservada; tente novamente.';
      }
    } catch (_) {
      message = 'Não foi possível concluir esta ação. Tente novamente.';
      failedAction = action;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
