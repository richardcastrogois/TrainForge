import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/auth/data/auth_api.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';

class MemoryStorage extends AuthStorage {
  String? token = 'access-secret';
  AuthProfile? cachedProfile;
  @override
  Future<AuthProfile?> offlineProfile(String expectedToken) async =>
      token == expectedToken ? cachedProfile : null;
  @override
  Future<void> cacheProfile(String expectedToken, AuthProfile profile) async {
    if (token == expectedToken) cachedProfile = profile;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> clearIfAccessToken(String expected) async {
    if (token == expected) {
      token = null;
      cachedProfile = null;
    }
  }

  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> clearToken() async {
    token = null;
  }
}

class FailingApi extends AuthApi {
  final DioException failure;
  FailingApi(this.failure);
  @override
  Future<Map<String, dynamic>> getMe() async => throw failure;
}

class SuccessfulApi extends AuthApi {
  @override
  Future<Map<String, dynamic>> getMe() async => {
    'id': 'fixture-account',
    'name': 'Fixture',
    'email': 'fixture@example.invalid',
  };
}

class ResponseAdapter implements HttpClientAdapter {
  final int status;
  ResponseAdapter(this.status);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{"token":"response-secret","email":"private@example.invalid"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'HTTP success and failure logs never contain credentials or personal data',
    () async {
      final logs = <String>[];
      final dio = AppDio.create(
        storage: MemoryStorage(),
        log: logs.add,
        baseUrl: 'https://example.invalid',
      );
      for (final status in [200, 401, 500]) {
        dio.httpClientAdapter = ResponseAdapter(status);
        try {
          await dio.post(
            '/private-path-secret?token=url-secret',
            queryParameters: {'email': 'query-secret'},
            data: {'idToken': 'body-secret'},
            options: Options(headers: {'private': 'header-secret'}),
          );
        } on DioException {
          /* expected HTTP failures */
        }
      }
      final output = logs.join(' ');
      expect(logs, isNotEmpty);
      for (final secret in [
        'secret',
        'private',
        'example.invalid',
        'token',
        'email',
      ]) {
        expect(output.contains(secret), isFalse, reason: secret);
      }
    },
  );
  for (final status in [null, 401, 403, 429, 500, 503]) {
    test(
      'session is removed only for confirmed 401 (status=$status)',
      () async {
        final storage = MemoryStorage();
        final request = RequestOptions(path: '/me');
        final failure = DioException(
          requestOptions: request,
          type: status == null
              ? DioExceptionType.connectionTimeout
              : DioExceptionType.badResponse,
          response: status == null
              ? null
              : Response(requestOptions: request, statusCode: status),
        );
        final repository = AuthRepository(
          api: FailingApi(failure),
          storage: storage,
        );
        if (status == 401) {
          expect(await repository.isAuthenticated(), isFalse);
          expect(storage.token, isNull);
        } else {
          await expectLater(
            repository.isAuthenticated(),
            throwsA(isA<DioException>()),
          );
          expect(storage.token, 'access-secret');
        }
      },
    );
  }
  test(
    'offline profile restores only after prior login and never bypasses a confirmed 401',
    () async {
      final storage = MemoryStorage()
        ..cachedProfile = const AuthProfile(
          id: 'fixture-account',
          name: 'Fixture',
          email: 'fixture@example.invalid',
        );
      final request = RequestOptions(path: '/me');
      final offline = AuthRepository(
        storage: storage,
        accountErased: (_) async => false,
        accountLocked: (_) async => false,
        api: FailingApi(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      expect((await offline.restoreSession())?.id, 'fixture-account');
      final revoked = AuthRepository(
        storage: storage,
        accountErased: (_) async => false,
        api: FailingApi(
          DioException(
            requestOptions: request,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: request, statusCode: 401),
          ),
        ),
      );
      expect(await revoked.restoreSession(), isNull);
      expect(storage.cachedProfile, isNull);
    },
  );
  test(
    'an erasure tombstone prevents offline reopening with cached credentials',
    () async {
      final storage = MemoryStorage()
        ..cachedProfile = const AuthProfile(
          id: 'erased-fixture',
          name: 'Fixture',
          email: 'fixture@example.invalid',
        );
      final request = RequestOptions(path: '/me');
      final repository = AuthRepository(
        storage: storage,
        accountErased: (_) async => true,
        api: FailingApi(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      await expectLater(
        repository.restoreSession(),
        throwsA(isA<DioException>()),
      );
    },
  );
  test(
    'a persisted reauthentication lock blocks cached offline restore after repository recreation',
    () async {
      final storage = MemoryStorage()
        ..cachedProfile = const AuthProfile(
          id: 'locked-fixture',
          name: 'Fixture',
          email: 'fixture@example.invalid',
        );
      final request = RequestOptions(path: '/me');
      final reopened = AuthRepository(
        storage: storage,
        accountErased: (_) async => false,
        accountLocked: (_) async => true,
        api: FailingApi(
          DioException(
            requestOptions: request,
            type: DioExceptionType.connectionError,
          ),
        ),
      );
      await expectLater(
        reopened.restoreSession(),
        throwsA(isA<DioException>()),
      );
      expect(storage.cachedProfile?.id, 'locked-fixture');
    },
  );
  test(
    'a successful online identity check unlocks only the returned account',
    () async {
      final storage = MemoryStorage();
      final unlocked = <String>[];
      final repository = AuthRepository(
        storage: storage,
        api: SuccessfulApi(),
        accountErased: (_) async => false,
        accountLocked: (_) async => true,
        unlockAccount: (id) async {
          unlocked.add(id);
        },
      );
      expect((await repository.restoreSession())?.id, 'fixture-account');
      expect(unlocked, ['fixture-account']);
      expect(storage.cachedProfile?.id, 'fixture-account');
    },
  );
}
