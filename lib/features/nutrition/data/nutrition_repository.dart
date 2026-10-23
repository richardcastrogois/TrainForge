import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/nutrition.dart';

class GoNutritionRepository implements NutritionRepository {
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
}

String nutritionError(Object error) {
  if (error is StateError) {
    return 'A conta mudou. Volte à entrada antes de continuar.';
  }
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      400 => 'Confira quantidade, unidade, data, preparo e campos informados.',
      401 => 'Sua sessão expirou. Entre novamente com Google.',
      404 => 'O alimento ou registro está indisponível. Atualize a consulta.',
      409 =>
        'O registro ou a conta mudou. Atualize o histórico antes de corrigir.',
      429 => 'Muitas tentativas. Aguarde um minuto e tente novamente.',
      _ =>
        'Não foi possível confirmar a ação. Confira a conexão e tente novamente. Repetir a mesma ação não duplica o registro.',
    };
  }
  return 'Não foi possível confirmar a ação. Tente novamente.';
}
