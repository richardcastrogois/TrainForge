//lib/features/stats/data/stats_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/stats/domain/stats_data.dart';

class StatsApi {
  final Dio dio = AppDio.instance;

  Future<StatsData> fetchStats({
    required String from,
    required String to,
  }) async {
    final response = await dio.get(
      '/mobile/stats',
      queryParameters: {'from': from, 'to': to},
    );

    return StatsData.fromJson(response.data);
  }
}
