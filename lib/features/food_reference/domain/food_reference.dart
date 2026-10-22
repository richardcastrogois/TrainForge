class FoodSource {
  final String name,
      publisher,
      url,
      license,
      licenseUrl,
      attribution,
      publishedAt,
      changes,
      warranty;
  final List<String> conditions;
  FoodSource.fromJson(Map<String, dynamic> j)
    : name = j['name'] as String,
      publisher = j['publisher'] as String,
      url = j['sourceUrl'] as String,
      license = j['licenseLabel'] as String,
      licenseUrl = j['licenseUrl'] as String,
      attribution = j['attribution'] as String,
      publishedAt = j['publishedAt'] as String,
      changes = j['changes'] as String,
      warranty = j['warrantyNotice'] as String,
      conditions = List<String>.from(j['conditions'] as List);
}

class FoodReference {
  final String id,
      versionId,
      sourceId,
      sourceFoodId,
      sourceVersion,
      name,
      locale;
  final String? basisQuantity, basisUnit;
  final FoodSource source;
  FoodReference.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      versionId = j['versionId'] as String,
      sourceId = j['sourceId'] as String,
      sourceFoodId = j['sourceFoodId'] as String,
      sourceVersion = j['sourcePublishedVersion'] as String,
      name = j['nameOriginal'] as String,
      locale = j['nameLocale'] as String,
      basisQuantity = (j['basis'] as Map)['quantity'] as String?,
      basisUnit = (j['basis'] as Map)['unit'] as String?,
      source = FoodSource.fromJson(
        Map<String, dynamic>.from(j['source'] as Map),
      );
  String get displayName => name.replaceAll(RegExp(r'\s+'), ' ').trim();
  String get basisLabel => basisQuantity == null || basisUnit == null
      ? 'Base de composição desconhecida'
      : 'Base da fonte: $basisQuantity $basisUnit';
  String get languageLabel => switch (locale) {
    'fr' => 'Francês',
    'en' => 'Inglês',
    _ => locale,
  };
}

class FoodNutrient {
  final String column, name, state, raw;
  final String? value, upperBound, unit, basisQuantity, basisUnit;
  final Map<String, dynamic>? declared;
  FoodNutrient.fromJson(Map<String, dynamic> j)
    : column = j['sourceColumnKey'] as String,
      name = j['nameOriginal'] as String,
      state = j['state'] as String,
      raw = j['rawText'] as String,
      value = j['value'] as String?,
      upperBound = j['upperBound'] as String?,
      unit = j['unit'] as String?,
      basisQuantity = j['basisQuantity'] as String?,
      basisUnit = j['basisUnit'] as String?,
      declared = j['declaredColumnBasis'] == null
          ? null
          : Map<String, dynamic>.from(j['declaredColumnBasis'] as Map);
  String get displayName => name.replaceAll(RegExp(r'\s+'), ' ').trim();
  String get displayValue {
    final suffix = unit == null ? '' : ' $unit';
    return switch (state) {
      'numeric' => value == null ? 'Valor indisponível' : '$value$suffix',
      'less_than' =>
        upperBound == null
            ? 'Limite indisponível'
            : '< $upperBound$suffix (limite; sem valor exato)',
      'trace' => 'Traço (sem quantidade exata)',
      'missing' => 'Não informado',
      'present_quantity_unknown' => 'Presente; quantidade desconhecida',
      _ => 'Valor original não interpretado: $raw',
    };
  }

  String get basisLabel {
    if (basisQuantity != null && basisUnit != null) {
      return 'Por $basisQuantity $basisUnit';
    }
    final d = declared;
    final original = d == null
        ? ''
        : ' · Coluna declara ${d['quantity']} ${d['unit']} (${d['kind']})';
    return 'Base não confirmada para este valor$original';
  }
}

class FoodDetailData {
  final FoodReference food;
  final List<FoodNutrient> nutrients;
  final String notice;
  FoodDetailData.fromJson(Map<String, dynamic> j)
    : food = FoodReference.fromJson(j),
      notice = j['notice'] as String,
      nutrients = (j['nutrients'] as List)
          .map(
            (v) => FoodNutrient.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList();
}

class FoodPageData {
  final List<FoodReference> items;
  final String? nextCursor;
  FoodPageData.fromJson(Map<String, dynamic> j)
    : items = (j['items'] as List)
          .map(
            (v) => FoodReference.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      nextCursor = j['nextCursor'] as String?;
}

class FoodSourceCount {
  final String id, name;
  final int count;
  FoodSourceCount.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      count = j['count'] as int;
}

class FoodFacets {
  final List<FoodSourceCount> sources;
  final int total, unknownBasis;
  FoodFacets.fromJson(Map<String, dynamic> j)
    : sources = (j['sources'] as List)
          .map(
            (v) =>
                FoodSourceCount.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      total = j['total'] as int,
      unknownBasis = j['unknownBasisCount'] as int;
}

abstract interface class FoodRepository {
  Future<FoodPageData> list({
    String q = '',
    String sourceId = '',
    String? cursor,
  });
  Future<FoodFacets> facets();
  Future<FoodDetailData> detail(FoodReference food);
}
