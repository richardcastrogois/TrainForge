import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/nutrition.dart';
import '../domain/meals.dart';
import '../../food_reference/domain/food_reference.dart';

class GoNutritionRepository
    implements
        NutritionRepository,
        LocalizedNutritionRepository,
        MealRepository {
  final Dio dio;
  final String accountId;
  final String? Function() currentAccountId;
  GoNutritionRepository({
    required this.accountId,
    required this.currentAccountId,
    Dio? dio,
  }) : dio = dio ?? AppDio.instance;
  void _check() {
    if (currentAccountId() != accountId) throw StateError('Conta alterada');
  }

  Future<Json> _request(
    String method,
    String path, {
    Json? body,
    Json? query,
    String? key,
  }) async {
    _check();
    final r = await dio.request(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        method: method,
        headers: {'X-TrainForge-Account': accountId, 'Idempotency-Key': ?key},
      ),
    );
    _check();
    return object(r.data);
  }

  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async =>
      NutritionPageData.fromJson(
        await _request(
          'GET',
          '/api/v1/me/foods',
          query: {if (q.isNotEmpty) 'q': q, 'cursor': ?cursor, 'limit': 10},
        ),
      );
  @override
  Future<Json> createFood(Json body, String key) =>
      _request('POST', '/api/v1/me/foods', body: body, key: key);
  @override
  Future<NutritionPageData> entries(
    String day,
    String zone, {
    String? cursor,
  }) async => NutritionPageData.fromJson(
    await _request(
      'GET',
      '/api/v1/me/food-entries',
      query: {'date': day, 'timezone': zone, 'cursor': ?cursor, 'limit': 10},
    ),
  );
  @override
  Future<NutritionPageData> localizedEntries(
    String day,
    String zone, {
    required String locale,
    String? cursor,
    String? namesVersion,
  }) async {
    if (!foodNameLocales.contains(locale)) {
      throw const FormatException('Invalid content locale');
    }
    final NutritionPageData page;
    try {
      page = NutritionPageData.fromJson(
        await _request(
          'GET',
          '/api/v1/me/food-entries',
          query: {
            'date': day,
            'timezone': zone,
            'locale': locale,
            'cursor': ?cursor,
            'namesVersion': ?namesVersion,
            'limit': 10,
          },
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 &&
          e.response?.data is Map &&
          e.response?.data['code'] == 'food_name_catalog_changed') {
        throw const FoodNameCatalogChanged();
      }
      rethrow;
    }
    if (page.nameCatalog?.locale != locale) {
      throw const FormatException('Entry catalog locale mismatch');
    }
    if (namesVersion != null && page.nameCatalog?.version != namesVersion) {
      throw const FoodNameCatalogChanged();
    }
    for (final entry in page.items) {
      final d = EntryFoodDisplay.fromEntry(entry);
      if (d == null ||
          d.catalog.locale != locale ||
          d.catalog.version != page.nameCatalog?.version) {
        throw const FormatException('Entry name catalog mismatch');
      }
    }
    return page;
  }

  @override
  Future<Json> localizedEntry(String id, {required String locale}) async {
    if (!RegExp(r'^[a-f0-9]{8}(-[a-f0-9]{4}){3}-[a-f0-9]{12}$').hasMatch(id) ||
        !foodNameLocales.contains(locale)) {
      throw const FormatException('Invalid entry read');
    }
    final entry = await _request(
      'GET',
      '/api/v1/me/food-entries/$id',
      query: {'locale': locale},
    );
    final d = EntryFoodDisplay.fromEntry(entry);
    if (entry['id'] != id || d == null || d.catalog.locale != locale) {
      throw const FormatException('Entry read identity mismatch');
    }
    return entry;
  }

  @override
  Future<Json> summary(String day, String zone) => _request(
    'GET',
    '/api/v1/me/food-summary',
    query: {'date': day, 'timezone': zone},
  );
  @override
  Future<Json> saveEntry(Json body, String key, {String? id}) => _request(
    id == null ? 'POST' : 'PATCH',
    '/api/v1/me/food-entries${id == null ? '' : '/$id'}',
    body: body,
    key: key,
  );
  @override
  Future<void> deleteEntry(String id, int revision, String key) async {
    await _request(
      'DELETE',
      '/api/v1/me/food-entries/$id',
      body: {'revision': revision},
      key: key,
    );
  }

  void _mealRead(String? id, String locale) {
    if ((id != null && !mealUuid(id)) || !foodNameLocales.contains(locale)) {
      throw const FormatException('Invalid meal read');
    }
  }

  @override
  Future<MealDay> mealDay(
    String day,
    String timezone, {
    required String locale,
  }) async {
    _mealRead(null, locale);
    final result = MealDay.fromJson(
      await _request(
        'GET',
        '/api/v1/me/meal-diary',
        query: {'date': day, 'timezone': timezone, 'locale': locale},
      ),
    );
    if (result.date != day ||
        result.timezone != timezone ||
        result.nameCatalog?.locale != locale) {
      throw const FormatException('Meal diary scope mismatch');
    }
    for (final e in result.entries) {
      final display = EntryFoodDisplay.fromEntry(e);
      if (display == null ||
          display.catalog.locale != locale ||
          display.catalog.version != result.nameCatalog?.version) {
        throw const FormatException('Meal diary name revision mismatch');
      }
    }
    return result;
  }

  @override
  Future<ConfirmedMeal> meal(String id, {required String locale}) async {
    _mealRead(id, locale);
    final result = ConfirmedMeal.fromJson(
      await _request('GET', '/api/v1/me/meals/$id', query: {'locale': locale}),
    );
    if (result.meal.id != id) {
      throw const FormatException('Meal identity mismatch');
    }
    for (final e in result.entries) {
      final display = EntryFoodDisplay.fromEntry(e);
      if (display == null || display.catalog.locale != locale) {
        throw const FormatException('Meal name locale mismatch');
      }
    }
    return result;
  }

  Future<ConfirmedMeal> _saveMeal(
    String method,
    Json body,
    String key, {
    String? id,
  }) async {
    if (!mealUuid(key) || (id != null && !mealUuid(id))) {
      throw const FormatException('Invalid meal write identity');
    }
    final expected = copyMealJson(body);
    final result = ConfirmedMeal.fromJson(
      await _request(
        method,
        '/api/v1/me/meals${id == null ? '' : '/$id'}',
        body: copyMealJson(expected),
        key: key,
      ),
    );
    if (id != null && result.meal.id != id) {
      throw const FormatException('Meal write identity mismatch');
    }
    final expectedRevision = method == 'POST'
        ? 1
        : (expected['revision'] as int) + 1;
    if (result.meal.revision != expectedRevision ||
        (method == 'DELETE'
            ? result.deletedAt == null
            : result.deletedAt != null)) {
      throw const FormatException('Meal confirmation revision mismatch');
    }
    if (method != 'DELETE' &&
        (result.meal.title != expected['title'] ||
            result.meal.timezone != expected['timezone'] ||
            !sameMealInstant(result.meal.occurredAt, expected['occurredAt']))) {
      throw const FormatException('Meal confirmation metadata mismatch');
    }
    if (method == 'POST') {
      final items = objects(expected['items']);
      if (result.entries.length != items.length) {
        throw const FormatException('Meal item count mismatch');
      }
      for (var i = 0; i < items.length; i++) {
        final input = items[i],
            entry = result.entries[i],
            calculation = object(entry['calculation']);
        if (entry['foodId'] != input['foodId'] ||
            entry['foodVersion'] != input['foodVersion'] ||
            !sameMealQuantity(
              entry['quantity'] as String,
              input['quantity'] as String,
            ) ||
            entry['unit'] != input['unit'] ||
            entry['timezone'] != input['timezone'] ||
            !sameMealInstant(entry['occurredAt'], input['occurredAt']) ||
            calculation['revision'] != 1 ||
            calculation['preparation'] != input['preparation'] ||
            calculation['quantityEvidence'] != input['quantityEvidence']) {
          throw const FormatException('Meal confirmation item mismatch');
        }
      }
    }
    return result;
  }

  @override
  Future<ConfirmedMeal> createMeal(Json body, String key) =>
      _saveMeal('POST', body, key);
  @override
  Future<ConfirmedMeal> editMeal(String id, Json body, String key) =>
      _saveMeal('PATCH', body, key, id: id);
  @override
  Future<ConfirmedMeal> deleteMeal(String id, int revision, String key) =>
      _saveMeal(
        'DELETE',
        {'revision': revision, 'reviewed': true},
        key,
        id: id,
      );
}
