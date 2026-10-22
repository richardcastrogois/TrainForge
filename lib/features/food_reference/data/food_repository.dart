import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/food_reference.dart';

class GoFoodRepository implements FoodRepository {
  final Dio dio;
  GoFoodRepository({Dio? dio}) : dio = dio ?? AppDio.instance;
  Options get _public => Options(extra: {'publicAuth': true});
  @override
  Future<FoodPageData> list({
    String q = '',
    String sourceId = '',
    String? cursor,
  }) async {
    final r = await dio.get(
      '/api/v1/foods',
      queryParameters: {
        'limit': 20,
        if (q.isNotEmpty) 'q': q,
        if (sourceId.isNotEmpty) 'sourceId': sourceId,
        'cursor': ?cursor,
      },
      options: _public,
    );
    return FoodPageData.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  @override
  Future<FoodFacets> facets() async {
    final r = await dio.get('/api/v1/foods/filters', options: _public);
    return FoodFacets.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  @override
  Future<FoodDetailData> detail(FoodReference food) async {
    final r = await dio.get(
      '/api/v1/foods/${Uri.encodeComponent(food.id)}',
      queryParameters: {'versionId': food.versionId},
      options: _public,
    );
    return FoodDetailData.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
