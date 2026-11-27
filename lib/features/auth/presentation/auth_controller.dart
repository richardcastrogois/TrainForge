import 'package:trainforge/features/auth/data/profile_photos.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/auth_profile.dart';

enum AuthAction { restore, login, logout }

enum AuthFeedback {
  sessionTimeout(
    "A confirmação da sessão demorou mais que o esperado. Sua sessão foi preservada; tente novamente ou consulte a biblioteca sem entrar.",
  ),
  googleConfiguration(
    "O login com Google não está disponível nesta versão do app. Você pode explorar sem conta.",
  ),
  authConfiguration(
    "O acesso está indisponível no momento. Tente mais tarde ou explore sem conta.",
  ),
  googleUnavailable(
    "Não foi possível abrir o login do Google neste aparelho. Tente novamente ou explore sem conta.",
  ),
  googleNotCompleted(
    "O login com Google não foi concluído. Você pode tentar novamente ou explorar sem conta.",
  ),
  sessionExpired(
    "A sessão expirou ou foi revogada. Entre novamente com Google.",
  ),
  rateLimited("Muitas tentativas. Aguarde um minuto e tente novamente."),
  authUnavailable(
    "O serviço de autenticação está indisponível. Tente novamente mais tarde.",
  ),
  signOutUnconfirmed(
    "A saída não foi confirmada. Conecte-se e tente sair novamente.",
  ),
  signInFailed(
    "Não foi possível entrar. Confira sua conexão e tente novamente.",
  ),
  sessionOffline(
    "Não foi possível confirmar a conexão. Sua sessão foi preservada; tente novamente.",
  ),
  actionFailed("Não foi possível concluir esta ação. Tente novamente.");

  final String fallback;
  const AuthFeedback(this.fallback);
}

class AuthController extends ChangeNotifier {
  final SessionRepository repository;
  final Duration restoreTimeout;
  AuthController(
    this.repository, {
    this.restoreTimeout = const Duration(seconds: 10),
  });
  AuthProfile? profile;
  bool busy = false;

  /// Action in flight; only [AuthAction.restore] should cover the screen.
  AuthAction? running;
  bool get restoring => busy && running == AuthAction.restore;
  AuthFeedback? feedback;
  String? get message => feedback?.fallback;
  AuthAction? failedAction;
  bool _disposed = false;
  String? _erasedAccountId;

  void accountErased(String expectedId) {
    if (_disposed) return;
    _erasedAccountId = expectedId;
    ProfilePhotos.instance.forget(expectedId);
    if (profile?.id == expectedId) {
      profile = null;
      feedback = null;
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
    running = action;
    feedback = null;
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
      feedback = AuthFeedback.sessionTimeout;
      failedAction = AuthAction.restore;
    } on SessionException catch (error) {
      if (error.failure == SessionFailure.configuration) {
        feedback = AuthFeedback.googleConfiguration;
      } else if (error.failure == SessionFailure.cancelled) {
        feedback = AuthFeedback.googleNotCompleted;
      }
      failedAction = action;
    } on GoogleSignInException catch (error) {
      // Android can report a provider failure as canceled. Use neutral feedback
      // for both outcomes; never claim that the person canceled or consented.
      switch (error.code) {
        case GoogleSignInExceptionCode.canceled:
          feedback = AuthFeedback.googleNotCompleted;
          failedAction = action;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          feedback = AuthFeedback.googleConfiguration;
          failedAction = action;
        case GoogleSignInExceptionCode.uiUnavailable:
          feedback = AuthFeedback.googleUnavailable;
          failedAction = action;
        default:
          feedback = AuthFeedback.signInFailed;
          failedAction = action;
      }
    } on StateError catch (_) {
      feedback = AuthFeedback.authConfiguration;
      failedAction = action;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        profile = null;
        feedback = AuthFeedback.sessionExpired;
        failedAction = AuthAction.login;
      } else {
        failedAction = action;
        feedback = status == 429
            ? AuthFeedback.rateLimited
            : status == 503
            ? AuthFeedback.authUnavailable
            : action == AuthAction.logout
            ? AuthFeedback.signOutUnconfirmed
            : action == AuthAction.login
            ? AuthFeedback.signInFailed
            : AuthFeedback.sessionOffline;
      }
    } catch (_) {
      feedback = AuthFeedback.actionFailed;
      failedAction = action;
    } finally {
      busy = false;
      running = null;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
