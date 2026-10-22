import 'package:dio/dio.dart';
import 'package:trainforge/core/config/app_config.dart';
import 'package:trainforge/core/log/app_logger.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';

class AppDio {
  static final Dio instance = create();

  // Only fixed event names, method, status and error category may reach logs.
  // URLs, headers, query parameters, bodies and exception text are untrusted.
  static Dio create({
    AuthStorage? storage,
    void Function(String)? log,
    String? baseUrl,
  }) {
    final tokenStorage = storage ?? AuthStorage();
    final writeLog = log ?? (message) => AppLogger.info(message, tag: 'HTTP');
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
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
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
              ),
            );
          }
        },
        onResponse: (response, handler) {
          writeLog('response status=${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          writeLog(
            'failure status=${error.response?.statusCode ?? 0} category=${error.type.name}',
          );
          handler.next(error);
        },
      ),
    );
    return dio;
  }
}
