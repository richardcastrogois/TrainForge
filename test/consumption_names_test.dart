import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/data/nutrition_repository.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_controller.dart';
import 'package:trainforge/features/nutrition/presentation/entry_read_controller.dart';
import 'package:trainforge/features/nutrition/presentation/entry_detail_page.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'food_names_client_test.dart' show reviewedFixture, reviewedFixtureId;
import 'nutrition_test.dart' show FakeNutrition;

const consumptionId = '11111111-1111-4111-8111-111111111111';
Json consumed(String locale, {String revision = '1', bool reviewed = true}) {
  final food = reviewedFixture(locale)..remove('reviewedName');
  return {
    'id': consumptionId,
    'foodId': reviewedFixtureId,
    'foodVersion': 'a' * 64,
    'quantity': '1.25',
    'unit': 'g',
    'occurredAt': '2026-10-23T18:15:09Z',
    'timezone': 'UTC',
    'deletedAt': null,
    'calculation': {
      'food': food,
      'revision': 1,
      'algorithm': 'source-rational-v1',
      'origin': 'editorial',
      'quantityEvidence': 'estimated',
      'preparation': '',
      'nutrients': [],
      'changes': [],
    },
    'foodDisplay': {
      'foodId': reviewedFixtureId,
      'foodVersion': 'a' * 64,
      'nameCatalog': {'locale': locale, 'version': revision},
      if (reviewed)
        'reviewedName': reviewedFixture(
          locale,
          revision: revision,
        )['reviewedName'],
    },
  };
}

NutritionPageData consumedPage(
  String locale, {
  String revision = '1',
  String? cursor = 'next',
}) => NutritionPageData.fromJson({
  'items': [consumed(locale, revision: revision)],
  'nextCursor': cursor,
  'nameCatalog': {'locale': locale, 'version': revision},
});

class NamesNutrition extends FakeNutrition
    implements LocalizedNutritionRepository {
  final calls = <Json>[];
  final deferred = <String, Completer<NutritionPageData>>{};
  final detailPending = <Completer<Json>>[];
  String revision = '1';
  bool changeOnMore = false;
  @override
  Future<NutritionPageData> localizedEntries(
    String day,
    String zone, {
    required String locale,
    String? cursor,
    String? namesVersion,
  }) async {
    calls.add({
      'locale': locale,
      'cursor': cursor,
      'version': namesVersion,
      'day': day,
    });
    if (deferred[locale] != null) return deferred[locale]!.future;
    if (cursor != null && changeOnMore) {
      changeOnMore = false;
      revision = '2';
      throw const FoodNameCatalogChanged();
    }
    return consumedPage(
      locale,
      revision: revision,
      cursor: cursor == null ? 'next' : null,
    );
  }

  @override
  Future<Json> localizedEntry(String id, {required String locale}) async =>
      detailPending.isEmpty
      ? consumed(locale, revision: revision)
      : detailPending.removeAt(0).future;
}

NutritionController history(NamesNutrition repo, String? Function() account) =>
    NutritionController(
      repository: repo,
      accountId: 'account-a',
      currentAccountId: account,
      initialDate: DateTime(2026, 10, 23),
    );
void main() {
  test(
    'legacy detail edit still notifies without localized capability',
    () async {
      final c = EntryReadController(
        repository: FakeNutrition(),
        entry: consumed('en'),
      );
      addTearDown(c.dispose);
      await c.load('en');
      var notices = 0;
      c.addListener(() => notices++);
      final corrected = consumed('en')..['quantity'] = '2.5';
      await c.edited(corrected);
      expect(c.entry['quantity'], '2.5');
      expect(notices, 1);
    },
  );
  test(
    'read display preserves immutable calculation, original and numeric strings',
    () {
      final entry = consumed('pt-BR'),
          before = jsonEncode(entry['calculation']);
      expect(entryDisplayName(entry, 'pt-BR'), 'Reviewed fixture pt-BR / 1');
      for (final language in ['pt-PT', 'en', 'es']) {
        expect(entryDisplayName(entry, language), 'Isolated original name');
      }
      expect(jsonEncode(entry['calculation']), before);
      expect(
        entryPresentationFood(entry, 'pt-BR').displayNameFor('pt-BR'),
        'Reviewed fixture pt-BR / 1',
      );
      expect(
        entryPresentationFood(entry, 'pt-BR').name,
        'Isolated original name',
      );
      expect(entry['quantity'], '1.25');
      expect(entry['foodVersion'], 'a' * 64);
    },
  );
  test(
    'private names ignore forged translation and keep declared language',
    () {
      final entry = consumed('es');
      entry['foodId'] = 'own:fixture';
      final food = object(object(entry['calculation'])['food'])
        ..['id'] = 'own:fixture'
        ..['sourceId'] = 'personal'
        ..['nameLocale'] = 'und';
      object(entry['calculation']);
      (entry['calculation'] as Map)['food'] = food;
      (entry['foodDisplay'] as Map)['foodId'] = 'own:fixture';
      (entry['foodDisplay'] as Map)['reviewedName'] = 'forged';
      expect(entryDisplayName(entry, 'es'), 'Isolated original name');
      expect(EntryFoodDisplay.fromEntry(entry)!.name, isNull);
    },
  );
  test('mismatched source version or locale is rejected', () {
    final wrong = consumed('en');
    (wrong['foodDisplay'] as Map)['foodVersion'] = 'f' * 64;
    expect(() => EntryFoodDisplay.fromEntry(wrong), throwsFormatException);
    final language = consumed('en');
    ((language['foodDisplay'] as Map)['nameCatalog'] as Map)['locale'] = 'es';
    expect(() => EntryFoodDisplay.fromEntry(language), throwsFormatException);
  });
  test(
    'history discards old locale replies without changing date or private query',
    () async {
      final repo = NamesNutrition(), en = Completer<NutritionPageData>();
      repo.deferred['en'] = en;
      final c = history(repo, () => 'account-a');
      addTearDown(c.dispose);
      final old = c.selectLocale('en');
      await c.submitQuery('private declaration');
      await c.selectLocale('es');
      en.complete(consumedPage('en'));
      await old;
      expect(c.locale, 'es');
      expect(c.namesVersion, '1');
      expect(
        entryDisplayName(c.entries.single, 'es'),
        'Reviewed fixture es / 1',
      );
      expect(c.date, DateTime(2026, 10, 23));
    },
  );
  test(
    'changed editorial revision reloads first page and never mixes pages',
    () async {
      final repo = NamesNutrition(), c = history(repo, () => 'account-a');
      addTearDown(c.dispose);
      await c.load();
      repo.changeOnMore = true;
      await c.more(false);
      expect(repo.calls.length, 3);
      expect(repo.calls[1]['version'], '1');
      expect(repo.calls.last['cursor'], isNull);
      expect(c.entries.length, 1);
      expect(c.namesVersion, '2');
      expect(c.loading, false);
      expect(c.moreBusy, false);
      expect(c.error, isNull);
    },
  );
  test('history ignores localized reply after account change', () async {
    var account = 'account-a';
    final repo = NamesNutrition(), pending = Completer<NutritionPageData>();
    repo.deferred['pt-BR'] = pending;
    final c = history(repo, () => account);
    addTearDown(c.dispose);
    final read = c.load();
    account = 'account-b';
    c.accountChanged();
    pending.complete(consumedPage('pt-BR'));
    await read;
    expect(c.entries, isEmpty);
    expect(c.summary, isNull);
    expect(c.active, false);
  });
  test(
    'detail locale generations and withdrawal keep original snapshot',
    () async {
      final repo = NamesNutrition(), old = Completer<Json>();
      repo.detailPending.add(old);
      final c = EntryReadController(repository: repo, entry: consumed('en'));
      addTearDown(c.dispose);
      final read = c.load('en');
      expect(c.name('en'), 'Isolated original name');
      await c.load('es');
      old.complete(consumed('en'));
      await read;
      expect(c.name('es'), 'Reviewed fixture es / 1');
      final withdrawal = Completer<Json>();
      repo.detailPending.add(withdrawal);
      final reload = c.load('es');
      withdrawal.complete(consumed('es', revision: '2', reviewed: false));
      await reload;
      expect(c.name('es'), 'Isolated original name');
      expect(c.display!.catalog.version, '2');
      expect(object(c.entry['calculation'])['revision'], 1);
    },
  );
  test(
    'detail late read cannot overwrite edit or notify after dispose',
    () async {
      final repo = NamesNutrition(), old = Completer<Json>();
      repo.detailPending.add(old);
      final c = EntryReadController(repository: repo, entry: consumed('en'));
      final read = c.load('en');
      repo.revision = '2';
      await c.edited(consumed('en', revision: '2'));
      old.complete(consumed('en'));
      await read;
      expect(c.display!.catalog.version, '2');
      final pending = Completer<Json>();
      repo.detailPending.add(pending);
      final last = c.load('en');
      var notices = 0;
      c.addListener(() => notices++);
      c.dispose();
      pending.complete(consumed('en'));
      await last;
      expect(notices, 0);
    },
  );
  test(
    'failed detail refresh clears reviewed display and permits explicit retry',
    () async {
      final repo = NamesNutrition(), pending = Completer<Json>();
      repo.detailPending.add(pending);
      final c = EntryReadController(repository: repo, entry: consumed('en'));
      addTearDown(c.dispose);
      final read = c.load('en');
      pending.completeError(StateError('account changed'));
      await read;
      expect(c.error, isNotNull);
      expect(c.display, isNull);
      expect(c.name('en'), 'Isolated original name');
      await c.load('en');
      expect(c.error, isNull);
      expect(c.name('en'), 'Reviewed fixture en / 1');
    },
  );
  test(
    'repository sends only read parameters and validates exact display catalog',
    () async {
      final dio = Dio();
      RequestOptions? seen;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            seen = o;
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'items': [consumed('en')],
                  'nextCursor': null,
                  'nameCatalog': {'locale': 'en', 'version': '1'},
                },
              ),
            );
          },
        ),
      );
      final repo = GoNutritionRepository(
        accountId: 'account-a',
        currentAccountId: () => 'account-a',
        dio: dio,
      );
      final result = await repo.localizedEntries(
        '2026-10-23',
        'UTC',
        locale: 'en',
        namesVersion: '1',
        cursor: 'opaque',
      );
      expect(result.nameCatalog!.version, '1');
      expect(seen!.method, 'GET');
      expect(seen!.queryParameters['namesVersion'], '1');
      expect(seen!.queryParameters['locale'], 'en');
      expect(seen!.headers['X-TrainForge-Account'], 'account-a');
      expect(seen!.headers.containsKey('Idempotency-Key'), false);
    },
  );
  test('repository maps409 and rejects mismatched detail identity', () async {
    var detail = false;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (!detail) {
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
                data: consumed('en')
                  ..['id'] = '22222222-2222-4222-8222-222222222222',
              ),
            );
          }
        },
      ),
    );
    final repo = GoNutritionRepository(
      accountId: 'account-a',
      currentAccountId: () => 'account-a',
      dio: dio,
    );
    await expectLater(
      repo.localizedEntries('2026-10-23', 'UTC', locale: 'en'),
      throwsA(isA<FoodNameCatalogChanged>()),
    );
    detail = true;
    await expectLater(
      repo.localizedEntry(consumptionId, locale: 'en'),
      throwsFormatException,
    );
  });
  test(
    'repository discards private response when identity changes in flight',
    () async {
      var account = 'account-a';
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            account = 'account-b';
            h.resolve(Response(requestOptions: o, data: consumed('en')));
          },
        ),
      );
      final repo = GoNutritionRepository(
        accountId: 'account-a',
        currentAccountId: () => account,
        dio: dio,
      );
      await expectLater(
        repo.localizedEntry(consumptionId, locale: 'en'),
        throwsStateError,
      );
    },
  );
  for (final locale in supportedAppLocales) {
    testWidgets(
      'consumption detail reviewed and original at320px text2x ${locale.toLanguageTag()}',
      (t) async {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final repo = NamesNutrition(),
            tag = locale.toLanguageTag(),
            strings = lookupAppLocalizations(locale);
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
            home: EntryDetailPage(
              evidenceMode: true,
              entry: consumed(tag),
              repository: repo,
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('Reviewed fixture $tag / 1').hitTestable(),
          180,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        expect(find.text('Reviewed fixture $tag / 1'), findsOneWidget);
        await t.scrollUntilVisible(
          find.text(strings.nameReviewSource).hitTestable(),
          180,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await t.tap(find.text(strings.nameReviewSource));
        await t.pumpAndSettle();
        expect(find.text('Isolated name review fixture'), findsOneWidget);
        expect(repo.entryWrites, 0);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets('history reacts to system-resolved locale without a write', (
    t,
  ) async {
    final repo = NamesNutrition(),
        changes = ChangeNotifier(),
        language = ValueNotifier(const Locale('en'));
    addTearDown(changes.dispose);
    addTearDown(language.dispose);
    final page = NutritionPage(
      accountId: 'account-a',
      currentAccountId: () => 'account-a',
      sessionChanges: changes,
      repository: repo,
    );
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
    expect(find.text('Reviewed fixture en / 1'), findsOneWidget);
    language.value = const Locale('es');
    await t.pumpAndSettle();
    expect(find.text('Reviewed fixture es / 1'), findsOneWidget);
    expect(find.text('Reviewed fixture en / 1'), findsNothing);
    expect(repo.entryWrites, 0);
    expect(t.takeException(), isNull);
  });
}
