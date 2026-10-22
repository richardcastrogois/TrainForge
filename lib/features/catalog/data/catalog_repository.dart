import 'package:dio/dio.dart';
import 'package:trainforge/core/http/app_dio.dart';
import '../domain/catalog_entry.dart';

class GoCatalogRepository implements CatalogRepository {
  final Dio dio;
  GoCatalogRepository({Dio? dio}) : dio = dio ?? AppDio.instance;
  Options get _public => Options(extra: {'publicAuth': true});
  @override
  Future<CatalogPageData> list(CatalogFilters filters, {String? cursor}) async {
    final query = <String, dynamic>{'mode': 'consultation', 'limit': 20};
    for (final entry in {
      'q': filters.q,
      'environment': filters.environment,
      'population': filters.population,
      'equipment': filters.equipment,
      'category': filters.category,
      'modality': filters.modality,
    }.entries) {
      if (entry.value.isNotEmpty) query[entry.key] = entry.value;
    }
    if (cursor != null) query['cursor'] = cursor;
    final response = await dio.get(
      '/api/v1/catalog/${filters.kind}',
      queryParameters: query,
      options: _public,
    );
    return CatalogPageData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<CatalogFacets> facets() async {
    final response = await dio.get('/api/v1/catalog/filters', options: _public);
    return CatalogFacets.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<CatalogEntry> detail(CatalogEntry entry) async {
    final kind = entry.kind == 'movement' ? 'movements' : 'programs';
    final response = await dio.get(
      '/api/v1/catalog/$kind/${Uri.encodeComponent(entry.id)}',
      queryParameters: {'versionId': entry.versionId, 'mode': 'consultation'},
      options: _public,
    );
    return CatalogEntry.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
