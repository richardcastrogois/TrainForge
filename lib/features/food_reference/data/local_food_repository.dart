import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../domain/food_reference.dart';
import 'catalog_installer.dart';

typedef CatalogDatabase = Future<Database> Function();

Object? decodeCatalogJson(String? value) {
  final text = value ?? '[]';
  return jsonDecode(
    text.startsWith('zlib:')
        ? utf8.decode(zlib.decode(base64Decode(text.substring(5))))
        : text,
  );
}

/// Read-only source catalog. SQL is paginated; full catalogs never become Dart lists.
class LocalFoodRepository
    implements FoodRepository, LocalizedFoodRepository, BarcodeFoodRepository {
  final CatalogDatabase open;
  final CatalogInstaller? installer;

  /// Server catalog used for search and details when the device catalog
  /// cannot be installed or opened, so the screen never stays empty.
  final FoodRepository? fallback;
  LocalFoodRepository(this.open, {this.installer, this.fallback});

  Future<T> _orFallback<T>(
    Future<T> Function() local,
    Future<T> Function(FoodRepository server) remote,
  ) async {
    try {
      return await local();
    } catch (_) {
      final server = fallback;
      if (server == null) rethrow;
      return remote(server);
    }
  }

  static String normalize(String value) {
    const accents = 'áàâãäåéèêëíìîïóòôõöúùûüçñ';
    const plain = 'aaaaaaeeeeiiiiooooouuuucn';
    var result = value.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String normalizedBarcode(String code) {
    final digits = code.trim();
    if (!validBarcode(digits)) {
      throw const FormatException('Invalid GTIN');
    }
    return digits.padLeft(14, '0');
  }

  static bool validBarcode(String code) {
    if (!const {8, 12, 13, 14}.contains(code.length) ||
        !RegExp(r'^[0-9]+$').hasMatch(code)) {
      return false;
    }
    var sum = 0;
    for (var i = code.length - 2; i >= 0; i--) {
      sum += int.parse(code[i]) * ((code.length - 2 - i).isEven ? 3 : 1);
    }
    return (10 - sum % 10) % 10 == int.parse(code[code.length - 1]);
  }

  Future<Map<String, dynamic>> foodJson(String id, String version) async {
    final db = await open();
    final rows = await db.rawQuery(
      'SELECT f.*, s.name AS source_name, s.publisher, s.url, '
      's.license_label, s.license_url, s.attribution, s.conditions_json '
      'FROM foods f JOIN sources s ON s.source_id=f.source_id '
      'WHERE f.food_id=? AND f.version_id=?',
      [id, version],
    );
    if (rows.length != 1) {
      throw const FormatException('Food version unavailable');
    }
    final result = _food(rows.single);
    final originals = result['nutrients'] as List;
    final canonical = result['canonicalNutrients'] as List;
    if (originals.isNotEmpty && originals.first is List) {
      final columns = await db.query('nutrient_columns');
      final byId = {for (final c in columns) c['column_id']: c};
      final originalsById = {for (final c in originals) c[0]: c as List};
      if (canonical.isNotEmpty && canonical.first is List) {
        result['canonicalNutrients'] = canonical.map((raw) {
          final cell = raw as List;
          final column = byId[cell[0]], original = originalsById[cell[0]];
          if (column == null || original == null) {
            throw const FormatException('Unknown canonical nutrient column');
          }
          final id = column['nutrient_id'] as String;
          final suffix = id.split('_').last;
          return {
            'nutrientId': id,
            'methodId': column['method_id'],
            'sourceColumnKey': column['source_column_key'],
            'unit': suffix == 'ug'
                ? 'µg'
                : suffix == 'kj'
                ? 'kJ'
                : suffix,
            'primaryForTotals': cell[1],
            'value': cell[2],
            'upperBound': cell[3],
            'state': original[1],
            'basisQuantity': original[5],
            'basisUnit': original[6],
          };
        }).toList();
      }
      result['nutrients'] = originals.map((raw) {
        final cell = raw as List;
        final column = byId[cell[0]];
        if (column == null) {
          throw const FormatException('Unknown nutrient column');
        }
        return {
          'sourceColumnKey': column['source_column_key'],
          'nameOriginal': column['name_original'],
          'unit': column['unit'],
          'state': cell[1],
          'value': cell[2],
          'upperBound': cell[3],
          'rawText': cell[4] ?? '',
          'basisQuantity': cell[5],
          'basisUnit': cell[6],
        };
      }).toList();
    }
    final codes = await db.rawQuery(
      'SELECT code FROM barcodes WHERE food_id=? AND version_id=?',
      [id, version],
    );
    result['barcodes'] = codes.map((r) => r['code']).toList();
    return result;
  }

  Map<String, dynamic> _food(Map<String, Object?> r) => {
    'id': r['food_id'],
    'versionId': r['version_id'],
    'sourceId': r['source_id'],
    'sourceFoodId': r['source_food_id'],
    'sourcePublishedVersion': r['source_version'],
    'nameOriginal': r['name_original'],
    'nameLocale': r['name_locale'],
    'brand': r['brand'],
    'preparation': r['preparation'] ?? '',
    'basis': {'quantity': r['basis_quantity'], 'unit': r['basis_unit']},
    'portions': jsonDecode(r['portions_json'] as String? ?? '[]'),
    'canonicalNutrients': decodeCatalogJson(
      r['canonical_nutrients_json'] as String? ?? '[]',
    ),
    'nutrients': decodeCatalogJson(
      r['original_nutrients_json'] as String? ?? '[]',
    ),
    'source': {
      'name': r['source_name'],
      'publisher': r['publisher'],
      'sourceUrl': r['url'],
      'licenseLabel': r['license_label'],
      'licenseUrl': r['license_url'],
      'attribution': r['attribution'],
      'publishedAt': r['source_version'],
      'changes': '',
      'warrantyNotice': '',
      'conditions': jsonDecode(r['conditions_json'] as String? ?? '[]'),
    },
  };

  Future<FoodPageData> _list(
    String q,
    String source,
    String? cursor,
    String? locale,
  ) async {
    if (locale != null && !foodNameLocales.contains(locale)) {
      throw const FormatException('Invalid content locale');
    }
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const FormatException('Invalid catalog cursor');
    }
    final query = normalize(q);
    final tokens = RegExp(
      r'[a-z0-9]+',
    ).allMatches(query).map((m) => m.group(0)!).take(12).toList();
    final search = tokens.isEmpty
        ? ''
        : tokens.map((t) => '"$t"*').join(' AND ');
    final effectiveSource = source.isEmpty && search.isEmpty
        ? 'AL-TACO'
        : source;
    final rows = await (await open()).rawQuery(
      'SELECT f.*, s.name AS source_name, s.publisher, s.url, s.license_label, '
      's.license_url, s.attribution, s.conditions_json FROM foods f '
      'JOIN sources s ON s.source_id=f.source_id '
      '${search.isEmpty ? '' : 'JOIN foods_fts ON foods_fts.food_id=f.food_id AND foods_fts.version_id=f.version_id '}'
      "WHERE 1=1 ${effectiveSource.isEmpty ? '' : 'AND f.source_id=? '} ${search.isEmpty ? '' : 'AND foods_fts MATCH ? '}"
      '${search.isEmpty ? 'ORDER BY f.search_name,f.food_id ' : "ORDER BY CASE WHEN f.search_name=? THEN 0 WHEN f.name_locale IN ('pt','pt-BR','pt-PT') THEN 1 ELSE 2 END, f.search_name,f.food_id "}'
      'LIMIT 21 OFFSET ?',
      [
        if (effectiveSource.isNotEmpty) effectiveSource,
        if (search.isNotEmpty) search,
        if (search.isNotEmpty) query,
        offset,
      ],
    );
    return FoodPageData.fromJson({
      'items': rows.take(20).map(_food).toList(),
      'nextCursor': rows.length > 20 ? '${offset + 20}' : null,
      if (locale != null) 'nameCatalog': {'locale': locale, 'version': '0'},
    });
  }

  @override
  Future<FoodPageData> list({
    String q = '',
    String sourceId = '',
    String? cursor,
  }) => _orFallback(
    () => _list(q, sourceId, cursor, null),
    (server) => server.list(q: q, sourceId: sourceId, cursor: cursor),
  );

  @override
  Future<FoodPageData> localizedList({
    required String locale,
    String q = '',
    String sourceId = '',
    String? cursor,
    String? namesVersion,
  }) => _orFallback(
    () => _list(q, sourceId, cursor, locale),
    (server) => server is LocalizedFoodRepository
        ? (server as LocalizedFoodRepository).localizedList(
            locale: locale,
            q: q,
            sourceId: sourceId,
            cursor: cursor,
            namesVersion: namesVersion,
          )
        : server.list(q: q, sourceId: sourceId, cursor: cursor),
  );

  @override
  Future<FoodFacets> facets() =>
      _orFallback(_facets, (server) => server.facets());

  Future<FoodFacets> _facets() async {
    if (installer != null) {
      final manifest = await installer!.manifest();
      final sources = (manifest['sources'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
      final counts = Map<String, dynamic>.from(manifest['counts'] as Map);
      final total = counts['foods'];
      if (total is! int || total < 0) {
        throw const FormatException('Catalog food count is invalid');
      }
      return FoodFacets.fromJson({
        'sources': sources
            .map(
              (s) => {
                'id': s['sourceId'],
                'name': s['name'],
                'count': counts[s['sourceId']],
              },
            )
            .toList(),
        'total': total,
        'unknownBasisCount': manifest['unknownBasisCount'],
      });
    }
    final db = await open();
    final rows = await db.rawQuery(
      'SELECT s.source_id AS id,s.name,COUNT(f.food_id) AS count '
      'FROM sources s JOIN foods f ON f.source_id=s.source_id GROUP BY s.source_id,s.name',
    );
    final unknown =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM foods WHERE basis_quantity IS NULL OR basis_unit IS NULL',
          ),
        ) ??
        0;
    return FoodFacets.fromJson({
      'sources': rows,
      'total': rows.fold<int>(0, (sum, r) => sum + (r['count'] as int)),
      'unknownBasisCount': unknown,
    });
  }

  @override
  Future<FoodDetailData> detail(FoodReference food) => _orFallback(
    () async => FoodDetailData.fromJson({
      ...await foodJson(food.id, food.versionId),
      'notice': '',
    }),
    (server) => server.detail(food),
  );

  @override
  Future<FoodDetailData> localizedDetail(
    FoodReference food, {
    required String locale,
  }) => _orFallback(
    () async => FoodDetailData.fromJson({
      ...await foodJson(food.id, food.versionId),
      'notice': '',
      'nameCatalog': {'locale': locale, 'version': '0'},
    }),
    (server) => server is LocalizedFoodRepository
        ? (server as LocalizedFoodRepository).localizedDetail(
            food,
            locale: locale,
          )
        : server.detail(food),
  );

  @override
  Future<List<FoodReference>> barcode(String code) async {
    final normalized = normalizedBarcode(code);
    final rows = await (await open()).rawQuery(
      'SELECT food_id,version_id FROM barcodes WHERE normalized_code=? LIMIT 30',
      [normalized],
    );
    final result = <FoodReference>[];
    for (final r in rows) {
      result.add(
        FoodReference.fromJson(
          await foodJson(r['food_id'] as String, r['version_id'] as String),
        ),
      );
    }
    return result;
  }
}
