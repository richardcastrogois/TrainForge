import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/food_reference.dart';

class GoFoodRepository implements FoodRepository, LocalizedFoodRepository {
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

  @override
  Future<FoodPageData> localizedList({
    required String locale,
    String q = '',
    String sourceId = '',
    String? cursor,
    String? namesVersion,
  }) async {
    if (!foodNameLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale');
    }
    try {
      final response = await dio.get(
        '/api/v1/foods',
        queryParameters: {
          'limit': 20,
          'locale': locale,
          if (q.isNotEmpty) 'q': q,
          if (sourceId.isNotEmpty) 'sourceId': sourceId,
          'cursor': ?cursor,
          'namesVersion': ?namesVersion,
        },
        options: _public,
      );
      final page = FoodPageData.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      if (page.nameCatalog?.locale != locale) {
        throw const FormatException('Food locale not confirmed');
      }
      if (namesVersion != null && page.nameCatalog!.version != namesVersion) {
        throw const FoodNameCatalogChanged();
      }
      for (final food in page.items) {
        if (food.reviewedName != null && food.reviewedName!.locale != locale) {
          throw const FormatException('Food name locale mismatch');
        }
      }
      return page;
    } on DioException catch (error) {
      if (error.response?.statusCode == 409 &&
          error.response?.data is Map &&
          (error.response!.data as Map)['code'] ==
              'food_name_catalog_changed') {
        throw const FoodNameCatalogChanged();
      }
      rethrow;
    }
  }

  @override
  Future<FoodDetailData> localizedDetail(
    FoodReference food, {
    required String locale,
  }) async {
    if (!foodNameLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale');
    }
    final response = await dio.get(
      '/api/v1/foods/${Uri.encodeComponent(food.id)}',
      queryParameters: {'versionId': food.versionId, 'locale': locale},
      options: _public,
    );
    final detail = FoodDetailData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    if (detail.nameCatalog?.locale != locale ||
        detail.food.id != food.id ||
        detail.food.versionId != food.versionId ||
        (detail.food.reviewedName != null &&
            detail.food.reviewedName!.locale != locale)) {
      throw const FormatException('Food identity or locale not confirmed');
    }
    return detail;
  }
}
