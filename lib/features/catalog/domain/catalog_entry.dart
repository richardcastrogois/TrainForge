List<String> catalogStrings(dynamic value) =>
    value == null ? <String>[] : List<String>.from(value as List);

class CatalogEntry {
  final String id, versionId, kind, sourceName;
  final String? title, locale, sourcePublishedVersion;
  final List<String> authors, creators, deliveryConditions, reasons, equipment;
  final List<String>? environments, populations;
  final bool? supportRequired;
  final String? supportSource, category, modality;
  final String? attribution,
      licenseLabel,
      licenseUrl,
      sourceUrl,
      changes,
      warrantyNotice;
  final List<String> nameCreators;
  final String? nameLicenseUrl;
  CatalogEntry.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      versionId = json['versionId'] as String,
      kind = json['kind'] as String,
      title = json['title'] as String?,
      locale = json['locale'] as String?,
      sourcePublishedVersion = json['sourcePublishedVersion'] as String?,
      sourceName = (json['source'] as Map)['name'] as String,
      authors = catalogStrings(json['authors']),
      creators = catalogStrings(
        (json['rights'] as Map)['displayCredits']['creators'],
      ),
      attribution = (json['rights'] as Map)['attribution'] as String?,
      licenseLabel =
          (json['rights'] as Map)['displayCredits']['licenseLabel'] as String?,
      licenseUrl =
          (json['rights'] as Map)['displayCredits']['licenseUrl'] as String?,
      sourceUrl =
          (json['rights'] as Map)['displayCredits']['sourceUrl'] as String?,
      changes = (json['rights'] as Map)['displayCredits']['changes'] as String?,
      warrantyNotice =
          (json['rights'] as Map)['displayCredits']['warrantyNotice']
              as String?,
      deliveryConditions = catalogStrings(
        (json['rights'] as Map)['deliveryConditions'],
      ),
      reasons = catalogStrings((json['availability'] as Map)['reasons']),
      environments = (json['audience'] as Map)['environment'] == null
          ? null
          : catalogStrings((json['audience'] as Map)['environment']),
      populations = (json['audience'] as Map)['population'] == null
          ? null
          : catalogStrings((json['audience'] as Map)['population']),
      supportRequired = (json['audience'] as Map)['supportRequired'] as bool?,
      supportSource = (json['audience'] as Map)['supportSource'] as String?,
      category = (json['requirements'] as Map)['category']?['name'] as String?,
      modality = (json['requirements'] as Map)['modality'] as String?,
      equipment = ((json['requirements'] as Map)['equipment'] as List)
          .map((e) => (e as Map)['name'] as String)
          .toList(),
      nameCreators = catalogStrings(
        (json['rights']
            as Map)['displayCredits']['selectedNameCredit']?['creators'],
      ),
      nameLicenseUrl =
          (json['rights']
                  as Map)['displayCredits']['selectedNameCredit']?['licenseUrl']
              as String?;
}

class CatalogFilters {
  final String kind, q, environment, population, equipment, category, modality;
  const CatalogFilters({
    this.kind = 'movements',
    this.q = '',
    this.environment = '',
    this.population = '',
    this.equipment = '',
    this.category = '',
    this.modality = '',
  });
  CatalogFilters copyWith({
    String? kind,
    String? q,
    String? environment,
    String? population,
    String? equipment,
    String? category,
    String? modality,
  }) => CatalogFilters(
    kind: kind ?? this.kind,
    q: q ?? this.q,
    environment: environment ?? this.environment,
    population: population ?? this.population,
    equipment: equipment ?? this.equipment,
    category: category ?? this.category,
    modality: modality ?? this.modality,
  );
}

class CatalogPageData {
  final List<CatalogEntry> items;
  final String? nextCursor;
  CatalogPageData(this.items, this.nextCursor);
  factory CatalogPageData.fromJson(Map<String, dynamic> json) =>
      CatalogPageData(
        (json['items'] as List)
            .map(
              (e) => CatalogEntry.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
        json['nextCursor'] as String?,
      );
}

class CatalogFacets {
  final List<String> environments,
      populations,
      equipment,
      categories,
      modalities;
  final int movementCount,
      programCount,
      unknownEnvironmentCount,
      unknownPopulationCount;
  CatalogFacets.fromJson(Map<String, dynamic> json)
    : environments = catalogStrings(json['environments']),
      populations = catalogStrings(json['populations']),
      equipment = catalogStrings(json['equipment']),
      categories = catalogStrings(json['categories']),
      modalities = catalogStrings(json['modalities']),
      movementCount = json['movementCount'] as int,
      programCount = json['programCount'] as int,
      unknownEnvironmentCount = json['unknownEnvironmentCount'] as int,
      unknownPopulationCount = json['unknownPopulationCount'] as int;
}

abstract interface class CatalogRepository {
  Future<CatalogPageData> list(CatalogFilters filters, {String? cursor});
  Future<CatalogFacets> facets();
  Future<CatalogEntry> detail(CatalogEntry entry);
}
