//lib/features/bootstrap/data/bootstrap_api.dart
import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import 'package:trainforge/features/bootstrap/domain/bootstrap_data.dart';

class BootstrapApi {
  final Dio dio = AppDio.instance;

  Future<BootstrapData> fetchBootstrap() async {
    final response = await dio.get('/mobile/bootstrap');
    return BootstrapData.fromJson(response.data as Map<String, dynamic>);
  }
}
