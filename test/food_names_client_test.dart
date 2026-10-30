import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/data/food_repository.dart';
import 'package:trainforge/features/food_reference/presentation/food_controller.dart';
import 'package:trainforge/features/food_reference/presentation/food_detail_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'food_reference_test.dart' show fixtureFood, fixtureCell, FixtureFoods;

final reviewedFixtureId = 'food:${'1' * 64}';
Map<String, dynamic> reviewedFixture(String locale, {String revision = '1'}) =>
    {
      ...fixtureFood(reviewedFixtureId),
      'nameOriginal': 'Isolated original name',
      'reviewedName': {
        'name': 'Reviewed fixture $locale / $revision',
        'locale': locale,
        'versionId': (revision == '1' ? 'b' : 'f') * 64,
        'attribution': 'Isolated name review fixture',
        'licenseLabel': 'Fixture only',
        'licenseUrl': 'https://example.invalid/name-rights',
        'reviewEvidenceSha256': 'c' * 64,
        'rightsEvidenceSha256': 'd' * 64,
      },
    };
Map<String, dynamic> localizedPageJson(
  String locale, {
  String revision = '1',
  String? cursor = 'next',
}) => {
  'items': [reviewedFixture(locale, revision: revision)],
  'nextCursor': cursor,
  'nameCatalog': {'locale': locale, 'version': revision},
};

class LocalizedFixtures extends FixtureFoods
    implements LocalizedFoodRepository {
  final calls = <Map<String, String?>>[];
  final pendingLocale = <String, Completer<FoodPageData>>{};
  String revision = '1';
  bool changeOnMore = false;
  int legacyCalls = 0;
  @override
  Future<FoodPageData> list({
    String q = '',
    String sourceId = '',
    String? cursor,
  }) async {
    legacyCalls++;
    return super.list(q: q, sourceId: sourceId, cursor: cursor);
  }

  @override
  Future<FoodPageData> localizedList({
    required String locale,
    String q = '',
    String sourceId = '',
    String? cursor,
    String? namesVersion,
  }) async {
    calls.add({
      'locale': locale,
      'q': q,
      'sourceId': sourceId,
      'cursor': cursor,
      'version': namesVersion,
    });
    if (pendingLocale[locale] != null) return pendingLocale[locale]!.future;
    if (cursor != null && changeOnMore) {
      changeOnMore = false;
      revision = '2';
      throw const FoodNameCatalogChanged();
    }
    return FoodPageData.fromJson(localizedPageJson(locale, revision: revision));
  }

  @override
  Future<FoodDetailData> localizedDetail(
    FoodReference food, {
    required String locale,
  }) async => FoodDetailData.fromJson({
    ...reviewedFixture(locale, revision: revision),
    'notice': 'Isolated fixture only',
    'nameCatalog': {'locale': locale, 'version': revision},
    'nutrients': [fixtureCell('numeric', value: '0'), fixtureCell('trace')],
  });
}

void main() {
  test(
    'reviewed name is presentation only and exact-locale fallback stays original',
    () {
      final food = FoodReference.fromJson(reviewedFixture('pt-BR'));
      expect(food.displayNameFor('pt-BR'), 'Reviewed fixture pt-BR / 1');
      for (final locale in ['pt-PT', 'en', 'es']) {
        expect(food.displayNameFor(locale), 'Isolated original name');
      }
      expect(food.name, 'Isolated original name');
      expect(food.versionId, 'a' * 64);
      expect(food.id, reviewedFixtureId);
      final private = reviewedFixture('en')
        ..['sourceId'] = 'personal'
        ..['id'] = 'own:fixture'
        ..['reviewedName'] = 'invalid publication';
      final own = FoodReference.fromJson(private);
      expect(own.reviewedName, isNull);
      expect(own.displayNameFor('en'), 'Isolated original name');
    },
  );
  test(
    'malformed review and revision are rejected without replacing original',
    () {
      for (final change in <String, dynamic>{
        'locale': 'pt',
        'versionId': 'latest',
        'name': 'bad\u202ename',
        'licenseUrl': 'http://example.invalid',
        'rightsEvidenceSha256': 'bad',
      }.entries) {
        final json = reviewedFixture('en');
        (json['reviewedName'] as Map)[change.key] = change.value;
        expect(() => FoodReference.fromJson(json), throwsFormatException);
      }
      for (final revision in ['01', '-1', '9223372036854775808']) {
        expect(
          () => FoodNameCatalog.fromJson({'locale': 'en', 'version': revision}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'language change discards late page and revision from the previous locale',
    () async {
      final repo = LocalizedFixtures()
        ..pendingLocale['en'] = Completer<FoodPageData>();
      final controller = FoodController(repo);
      addTearDown(controller.dispose);
      final old = controller.load(locale: 'en', q: 'alias');
      await controller.load(locale: 'es');
      repo.pendingLocale['en']!.complete(
        FoodPageData.fromJson(localizedPageJson('en', revision: '9')),
      );
      await old;
      expect(controller.locale, 'es');
      expect(controller.namesVersion, '1');
      expect(controller.items.single.reviewedName!.locale, 'es');
      expect(repo.legacyCalls, 0);
    },
  );
  test(
    'changed lexicon restarts once without stale cursor or mixed rows',
    () async {
      final repo = LocalizedFixtures();
      final controller = FoodController(repo);
      addTearDown(controller.dispose);
      await controller.load(locale: 'pt-PT', q: 'alias', sourceId: 'fixture');
      repo.changeOnMore = true;
      await controller.more();
      expect(repo.calls.length, 3);
      expect(repo.calls[1], {
        'locale': 'pt-PT',
        'q': 'alias',
        'sourceId': 'fixture',
        'cursor': 'next',
        'version': '1',
      });
      expect(repo.calls[2]['cursor'], isNull);
      expect(repo.calls[2]['version'], isNull);
      expect(controller.catalogChanged, isTrue);
      expect(controller.namesVersion, '2');
      expect(
        controller.items.single.reviewedName!.name,
        'Reviewed fixture pt-PT / 2',
      );
      expect(controller.loadingMore, isFalse);
      expect(controller.busy, isFalse);
    },
  );
  test(
    'localized HTTP sends canonical tag, revision and public GET only',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add(o);
            h.resolve(
              Response(requestOptions: o, data: localizedPageJson('pt-BR')),
            );
          },
        ),
      );
      final repo = GoFoodRepository(dio: dio);
      final page = await repo.localizedList(
        locale: 'pt-BR',
        q: 'alias',
        cursor: 'bound',
        namesVersion: '1',
      );
      expect(page.items.single.name, 'Isolated original name');
      expect(requests.single.method, 'GET');
      expect(requests.single.queryParameters['locale'], 'pt-BR');
      expect(requests.single.queryParameters['namesVersion'], '1');
      expect(requests.single.extra['publicAuth'], isTrue);
      await expectLater(
        repo.localizedList(locale: 'pt_BR'),
        throwsArgumentError,
      );
      expect(requests.length, 1);
    },
  );
  test(
    'server409 is typed and a mismatched detail identity is refused',
    () async {
      final dio = Dio();
      var detailMode = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (!detailMode) {
              h.reject(
                DioException(
                  requestOptions: o,
                  response: Response(
                    requestOptions: o,
                    statusCode: 409,
                    data: {'code': 'food_name_catalog_changed'},
                  ),
                ),
              );
            } else {
              h.resolve(
                Response(
                  requestOptions: o,
                  data: {
                    ...reviewedFixture('en'),
                    'id': 'food:${'2' * 64}',
                    'nameCatalog': {'locale': 'en', 'version': '1'},
                    'notice': 'Fixture only',
                    'nutrients': [],
                  },
                ),
              );
            }
          },
        ),
      );
      final repo = GoFoodRepository(dio: dio);
      await expectLater(
        repo.localizedList(locale: 'en'),
        throwsA(isA<FoodNameCatalogChanged>()),
      );
      detailMode = true;
      await expectLater(
        repo.localizedDetail(
          FoodReference.fromJson(reviewedFixture('en')),
          locale: 'en',
        ),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'language change applies pending search text instead of dropping it',
    (t) async {
      final repo = LocalizedFixtures();
      final controller = FoodController(repo);
      addTearDown(controller.dispose);
      final language = ValueNotifier(const Locale('en'));
      addTearDown(language.dispose);
      final page = FoodPage(controller: controller);
      await t.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: language,
          builder: (_, locale, _) => MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: supportedAppLocales,
            home: page,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'alias pending');
      language.value = const Locale('es');
      await t.pumpAndSettle();
      expect(controller.locale, 'es');
      expect(controller.q, 'alias pending');
      expect(repo.calls.last['locale'], 'es');
      expect(repo.calls.last['q'], 'alias pending');
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'alias pending',
      );
      expect(t.takeException(), isNull);
    },
  );
  for (final locale in supportedAppLocales) {
    testWidgets(
      'reviewed selection preserves original identity at320 text2x for $locale',
      (t) async {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final strings = lookupAppLocalizations(locale);
        FoodReference? selected;
        await t.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: supportedAppLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    selected = await Navigator.push<FoodReference>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailPage(
                          evidenceMode: true,
                          food: FoodReference.fromJson(
                            reviewedFixture(locale.toLanguageTag()),
                          ),
                          repository: LocalizedFixtures(),
                          selectForConsumption: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('open isolated review'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('open isolated review'));
        await t.pumpAndSettle();
        final scrollable = find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first;
        await t.scrollUntilVisible(
          find.text(strings.reviewedFoodName).hitTestable(),
          250,
          scrollable: scrollable,
          maxScrolls: 60,
        );
        expect(
          find.text('${strings.originalFoodName}: Isolated original name'),
          findsOneWidget,
        );
        await t.scrollUntilVisible(
          find.text(strings.useFoodVersion).hitTestable(),
          200,
          scrollable: scrollable,
          maxScrolls: 60,
        );
        await t.tap(find.text(strings.useFoodVersion));
        await t.pumpAndSettle();
        expect(selected!.id, reviewedFixtureId);
        expect(selected!.versionId, 'a' * 64);
        expect(selected!.name, 'Isolated original name');
        expect(selected!.reviewedName!.locale, locale.toLanguageTag());
        expect(t.takeException(), isNull);
      },
    );
  }
}
