//lib/core/http/app_dio.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/config/app_config.dart';
import 'package:trainforge/core/log/app_logger.dart';
import 'package:trainforge/features/auth/data/auth_storage.dart';

class AppDio {
  static final Dio instance =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              try {
                final storage = AuthStorage();
                final token = await storage.getToken();

                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                  AppLogger.info(
                    'Token anexado na requisição ${options.method} ${options.path}',
                    tag: 'AUTH',
                  );
                } else {
                  AppLogger.info(
                    'Requisição sem token ${options.method} ${options.path}',
                    tag: 'AUTH',
                  );
                }

                AppLogger.info(
                  'REQ ${options.method} ${options.path}',
                  tag: 'HTTP',
                );

                if (options.queryParameters.isNotEmpty) {
                  AppLogger.info(
                    'Query: ${options.queryParameters}',
                    tag: 'HTTP',
                  );
                }

                if (options.data != null) {
                  AppLogger.info('Body: ${options.data}', tag: 'HTTP');
                }

                handler.next(options);
              } catch (error, stackTrace) {
                AppLogger.error(
                  'Erro no interceptor de request',
                  tag: 'HTTP',
                  error: error,
                  stackTrace: stackTrace,
                );
                handler.next(options);
              }
            },
            onResponse: (response, handler) {
              AppLogger.info(
                'RES ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}',
                tag: 'HTTP',
              );

              if (response.data != null) {
                AppLogger.info('Response body: ${response.data}', tag: 'HTTP');
              }

              handler.next(response);
            },
            onError: (error, handler) {
              final request = error.requestOptions;

              AppLogger.error(
                'ERR ${error.response?.statusCode ?? 'NO_STATUS'} ${request.method} ${request.path}',
                tag: 'HTTP',
                error: error.message,
                stackTrace: error.stackTrace,
              );

              if (error.response?.data != null) {
                AppLogger.error(
                  'Error body: ${error.response?.data}',
                  tag: 'HTTP',
                );
              }

              handler.next(error);
            },
          ),
        );
}
