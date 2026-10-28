import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/training_configuration.dart';

class GoTrainingConfigurationRepository
    implements TrainingConfigurationRepository {
  final String accountId;
  final String? Function() currentAccountId;
  final Dio dio;
  GoTrainingConfigurationRepository({
    required this.accountId,
    required this.currentAccountId,
    Dio? dio,
  }) : dio = dio ?? AppDio.instance;
  void check() {
    if (currentAccountId() != accountId) throw StateError('Account changed');
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
    String? key,
  }) async {
    check();
    try {
      final result = await dio.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {'X-TrainForge-Account': accountId, 'Idempotency-Key': ?key},
        ),
      );
      check();
      return configObject(result.data);
    } on DioException catch (e) {
      check();
      final response = e.response;
      final raw = response?.data;
      final body = raw is Map ? raw : const {};
      final fields = <String, String>{};
      if (body['fields'] is Map) {
        for (final item in (body['fields'] as Map).entries) {
          if (item.key is String && item.value is String) {
            fields[item.key as String] = item.value as String;
          }
        }
      }
      throw TrainingFailure(
        body['code'] is String
            ? body['code'] as String
            : 'training_configuration_unavailable',
        fields: fields,
        uncertain:
            method == 'PUT' &&
            (response == null ||
                response.statusCode == null ||
                response.statusCode! >= 500 ||
                response.statusCode == 408),
      );
    }
  }

  @override
  Future<TrainingCurrent> load() async => TrainingCurrent.fromJson(
    await request('GET', '/api/v1/me/training-configuration'),
  );
  @override
  Future<TrainingCurrent> save(Map<String, dynamic> command, String key) async {
    final result = TrainingCurrent.fromJson(
      await request(
        'PUT',
        '/api/v1/me/training-configuration',
        data: command,
        key: key,
      ),
    );
    final saved = result.snapshot;
    if (saved == null ||
        saved.revision != (command['revision'] as int) + 1 ||
        canonicalTrainingConfiguration(saved.draft().toJson()) !=
            canonicalTrainingConfiguration(
              configObject(command['configuration']),
            )) {
      throw const TrainingFailure(
        'training_configuration_unavailable',
        uncertain: true,
      );
    }
    return result;
  }

  @override
  Future<TrainingResourcePage> resources({
    String q = '',
    String? cursor,
  }) async => TrainingResourcePage.fromJson(
    await request(
      'GET',
      '/api/v1/me/training-configuration/resources',
      query: {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        'cursor': ?cursor,
        'limit': 20,
      },
    ),
  );
}
