import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/auth/data/auth_api.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';

class MemoryStorage extends AuthStorage {
  String? token = 'access-secret';
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> clearIfAccessToken(String expected) async {
    if (token == expected) token = null;
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
}
