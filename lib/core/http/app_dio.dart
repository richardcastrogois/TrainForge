import 'package:dio/dio.dart';
import 'package:trainforge/core/config/app_config.dart';
import 'package:trainforge/core/log/app_logger.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';
import 'package:trainforge/features/auth/data/session_refresh.dart';

class AppDio {
  static final Dio instance = create();
  // Only fixed event names, status and error category. Never URL/body/exception text.
  static Dio create({
    AuthStorage? storage,
    void Function(String)? log,
    String? baseUrl,
    Dio? refreshTransport,
  }) {
    final tokenStorage = storage ?? AuthStorage();
    final writeLog = log ?? (message) => AppLogger.info(message, tag: 'HTTP');
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        followRedirects: false,
        maxRedirects: 0,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final refresh = SessionRefresh(
      tokenStorage,
      refreshTransport ?? Dio(dio.options.copyWith()),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            if (baseUrl == null) AppConfig.validate();
            if (options.uri.origin != Uri.parse(dio.options.baseUrl).origin) {
              throw StateError('Unexpected API origin');
            }
            if (options.extra['publicAuth'] != true) {
              final token = await tokenStorage.getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
            writeLog('request');
            handler.next(options);
          } catch (_) {
            writeLog('credential_storage_unavailable');
            handler.reject(DioException(requestOptions: options));
          }
        },
        onResponse: (response, handler) {
          writeLog('response status=${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) async {
          writeLog(
            'failure status=${error.response?.statusCode ?? 0} category=${error.type.name}',
          );
          final request = error.requestOptions;
          try {
            if (error.response?.statusCode == 401 &&
                request.extra['publicAuth'] != true) {
              final authorization = request.headers['Authorization'] as String?;
              final observed = authorization?.replaceFirst('Bearer ', '');
              if (request.extra['authRetried'] == true) {
                if (observed != null) {
                  await tokenStorage.clearIfAccessToken(observed);
                }
              } else {
                final nextToken = await refresh.afterUnauthorized(observed);
                if (nextToken != null) {
                  request.extra['authRetried'] = true;
                  request.headers['Authorization'] = 'Bearer $nextToken';
                  handler.resolve(await dio.fetch<dynamic>(request));
                  return;
                }
              }
            }
            handler.next(error);
          } on DioException catch (refreshError) {
            handler.reject(refreshError);
          } catch (_) {
            handler.reject(DioException(requestOptions: request));
          }
        },
      ),
    );
    return dio;
  }
}
