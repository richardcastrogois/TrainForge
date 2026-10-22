import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';

class SessionFixture implements SessionRepository {
  AuthProfile? profile;
  Object? restoreError;
  Object? loginError;
  Object? logoutError;
  Completer<AuthProfile>? pendingLogin;
  int restores = 0, logins = 0, logouts = 0;
  @override
  Future<AuthProfile?> restoreSession() async {
    restores++;
    if (restoreError != null) throw restoreError!;
    return profile;
  }

  @override
  Future<AuthProfile> signIn() async {
    logins++;
    if (loginError != null) throw loginError!;
    if (pendingLogin != null) return pendingLogin!.future;
    return profile ?? fixtureProfile;
  }

  @override
  Future<void> logout() async {
    logouts++;
    if (logoutError != null) throw logoutError!;
    profile = null;
  }
}

const fixtureProfile = AuthProfile(
  id: 'isolated-ui-fixture',
  name: 'Fixture isolada',
  email: 'fixture@example.invalid',
);
DioException outage() => DioException(
  requestOptions: RequestOptions(path: '/api/v1/auth/logout'),
  type: DioExceptionType.connectionTimeout,
);

void main() {
  testWidgets(
    'restore makes one identity call and logout failure retries logout',
    (tester) async {
      final repo = SessionFixture()..profile = fixtureProfile;
      final controller = AuthController(repo);
      await tester.pumpWidget(
        MaterialApp(home: AuthGate(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(repo.restores, 1);
      expect(find.text('Conta conectada'), findsOneWidget);
      repo.logoutError = outage();
      await tester.ensureVisible(find.text('Sair desta sessão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair desta sessão'));
      await tester.pumpAndSettle();
      expect(repo.logouts, 1);
      expect(repo.restores, 1);
      expect(find.textContaining('A saída não foi confirmada'), findsOneWidget);
      repo.logoutError = null;
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(repo.logouts, 2);
      expect(repo.restores, 1);
      expect(find.text('Entrar com Google'), findsOneWidget);
      controller.dispose();
    },
  );
  testWidgets(
    'offline restore retains a retry path without leaking exception text',
    (tester) async {
      final repo = SessionFixture()
        ..restoreError = DioException(
          requestOptions: RequestOptions(path: '/private-secret'),
          error: 'secret-token',
        );
      final controller = AuthController(repo);
      await tester.pumpWidget(
        MaterialApp(home: AuthGate(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sua sessão foi preservada'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      repo.restoreError = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(repo.restores, 2);
      controller.dispose();
    },
  );
  test(
    'concurrent taps trigger one login and cancellation remains usable',
    () async {
      final repo = SessionFixture()..pendingLogin = Completer<AuthProfile>();
      final controller = AuthController(repo);
      final pending = controller.login();
      await controller.login();
      expect(repo.logins, 1);
      repo.pendingLogin!.complete(fixtureProfile);
      await pending;
      expect(controller.profile?.id, fixtureProfile.id);
      repo.pendingLogin = null;
      repo.loginError = const SessionException(SessionFailure.cancelled);
      await controller.login();
      expect(controller.message, isNull);
      expect(controller.busy, isFalse);
      controller.dispose();
    },
  );
  test(
    'configuration errors and service unavailability are distinct, with fixed messages',
    () async {
      final repo = SessionFixture()
        ..loginError = const SessionException(SessionFailure.configuration);
      final controller = AuthController(repo);
      await controller.login();
      expect(controller.message, contains('não está configurado'));
      final req = RequestOptions(path: '/api/v1/auth/google');
      repo.loginError = DioException(
        requestOptions: req,
        response: Response(
          requestOptions: req,
          statusCode: 503,
          data: {'secret': 'do-not-display'},
        ),
      );
      await controller.retry();
      expect(controller.message, contains('indisponível'));
      expect(controller.message, isNot(contains('do-not-display')));
      controller.dispose();
    },
  );
  test(
    'completion after disposal does not notify a disposed controller',
    () async {
      final repo = SessionFixture()..pendingLogin = Completer<AuthProfile>();
      final controller = AuthController(repo);
      final pending = controller.login();
      controller.dispose();
      repo.pendingLogin!.complete(fixtureProfile);
      await pending;
    },
  );
}
