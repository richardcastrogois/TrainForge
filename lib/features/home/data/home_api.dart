//lib/features/home/data/home_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';

import '../domain/home_summary.dart';

class HomeApi {
  final Dio dio = AppDio.instance;

  Future<HomeSummary> fetchSummary(String date) async {
    final response = await dio.get('/mobile/home/$date');
    return HomeSummary.fromJson(response.data);
  }
}
