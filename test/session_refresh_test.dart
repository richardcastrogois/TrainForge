import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';
import 'package:trainforge/features/auth/domain/auth_user.dart';

class TestStorage extends AuthStorage {
  String? access = 'old-access', refresh = 'old-refresh';
  @override
  Future<String?> getToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> clearToken() async {
    access = null;
    refresh = null;
  }

  @override
  Future<void> clearIfAccessToken(String expected) async {
    if (access == expected) await clearToken();
  }

  @override
  Future<void> clearIfRefreshToken(String expected) async {
    if (refresh == expected) await clearToken();
  }

  @override
  Future<bool> replaceSession(String expected, AuthUser session) async {
    if (refresh != expected) return false;
    access = session.token;
    refresh = session.refreshToken;
    return true;
  }
}

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, String json) => ResponseBody.fromString(
  json,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
const session =
    '{"accessToken":"new-access","refreshToken":"new-refresh","expiresIn":900,"user":{"id":"fixture","name":"fixture","email":"fixture@example.invalid","image":null}}';
void main() {
  test('concurrent 401 triggers one refresh and one retry per call', () async {
    final storage = TestStorage();
    var refreshCalls = 0;
    var calls = 0;
    final transport = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    transport.httpClientAdapter = Adapter((_) async {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return body(200, session);
    });
    final dio = AppDio.create(
      baseUrl: 'https://example.invalid',
      storage: storage,
      refreshTransport: transport,
      log: (_) {},
    );
    dio.httpClientAdapter = Adapter((r) async {
      calls++;
      return r.headers['Authorization'] == 'Bearer new-access'
          ? body(200, '{}')
          : body(401, '{}');
    });
    final responses = await Future.wait(
      List.generate(6, (_) => dio.get('/api/v1/me')),
    );
    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
    expect(calls, 12);
    expect(storage.refresh, 'new-refresh');
  });
  for (final status in [401, 503]) {
    test('refresh $status separates invalid session from outage', () async {
      final storage = TestStorage();
      final transport = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      transport.httpClientAdapter = Adapter((_) async => body(status, '{}'));
      final dio = AppDio.create(
        baseUrl: 'https://example.invalid',
        storage: storage,
        refreshTransport: transport,
        log: (_) {},
      );
      dio.httpClientAdapter = Adapter((_) async => body(401, '{}'));
      await expectLater(
        dio.get('/api/v1/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            status,
          ),
        ),
      );
      expect(storage.access, status == 401 ? isNull : 'old-access');
    });
  }
  test('logout during refresh does not restore credentials', () async {
    final storage = TestStorage();
    final entered = Completer<void>();
    final release = Completer<void>();
    final transport = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    transport.httpClientAdapter = Adapter((_) async {
      entered.complete();
      await release.future;
      return body(200, session);
    });
    final dio = AppDio.create(
      baseUrl: 'https://example.invalid',
      storage: storage,
      refreshTransport: transport,
      log: (_) {},
    );
    dio.httpClientAdapter = Adapter((_) async => body(401, '{}'));
    final request = dio.get('/api/v1/me');
    final expected = expectLater(request, throwsA(isA<DioException>()));
    await entered.future;
    await storage.clearToken();
    release.complete();
    await expected;
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
  test('public login does not attach an existing access token', () async {
    final storage = TestStorage();
    final dio = AppDio.create(
      baseUrl: 'https://example.invalid',
      storage: storage,
      log: (_) {},
    );
    dio.httpClientAdapter = Adapter((r) async {
      expect(r.headers['Authorization'], isNull);
      return body(401, '{}');
    });
    await expectLater(
      dio.post(
        '/api/v1/auth/google',
        data: {'idToken': 'fixture'},
        options: Options(extra: {'publicAuth': true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(storage.access, 'old-access');
  });
}
