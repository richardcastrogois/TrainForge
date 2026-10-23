import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/data/nutrition_repository.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'food_reference_test.dart' show fixtureFood;

class FakeNutrition implements NutritionRepository {
  Json? body;
  final keys = <String>[];
  int foodWrites = 0, entryWrites = 0;
  Object? error;
  Completer<Json>? pending;
  @override
  Future<Json> createFood(Json b, String k) async {
    foodWrites++;
    body = b;
    keys.add(k);
    if (error != null) throw error!;
    return fixtureFood('own:fixture');
  }

  @override
  Future<Json> saveEntry(Json b, String k, {String? id}) async {
    entryWrites++;
    body = b;
    keys.add(k);
    if (error != null) throw error!;
    return pending == null ? <String, dynamic>{} : pending!.future;
  }

  @override
  Future<NutritionPageData> entries(
    String day,
    String zone, {
    String? cursor,
  }) async => NutritionPageData.fromJson({'items': [], 'nextCursor': null});
  @override
  Future<NutritionPageData> foods({String q = '', String? cursor}) async =>
      NutritionPageData.fromJson({'items': [], 'nextCursor': null});
  @override
  Future<Json> summary(String day, String zone) async => {
    'entries': 0,
    'complete': true,
    'nutrients': [],
    'notice': 'Sem registros',
  };
  @override
  Future<void> deleteEntry(String id, int revision, String key) async {}
}

Future<void> chooseEvidence(WidgetTester t) async {
  final dropdown = find.byType(DropdownButtonFormField<String>).last;
  await t.ensureVisible(dropdown);
  await t.tap(dropdown);
  await t.pumpAndSettle();
  await t.tap(find.text('Fiz uma estimativa').last);
  await t.pumpAndSettle();
}

void main() {
  test('decimal remains a string; no float conversion', () {
    expect(decimal(' 0,123456 '), '0.123456');
    for (final s in ['0', '-1', '1e3', '1/2', 'NaN', '10000000']) {
      expect(validDecimal(s, positive: true), false);
    }
    expect(validDecimal('0.000001', positive: true), true);
    expect(validDecimal('0'), true);
    expect(mutationKey(), matches(RegExp(r'^[a-f0-9-]{36}$')));
  });
  testWidgets(
    'own food allows unknown composition and never records consumption',
    (t) async {
      final repo = FakeNutrition();
      await t.pumpWidget(MaterialApp(home: OwnFoodFormPage(repository: repo)));
      await t.enterText(
        find.byKey(const Key('own-food-name')),
        'Alimento informado no teste',
      );
      await t.ensureVisible(find.text('Salvar somente o alimento'));
      await t.tap(find.text('Salvar somente o alimento'));
      await t.pumpAndSettle();
      expect(repo.foodWrites, 1);
      expect(repo.entryWrites, 0);
      expect(repo.body!['basis'], {'quantity': null, 'unit': null});
      expect(repo.body!['nutrients'], isEmpty);
    },
  );
  testWidgets('quantity and measurement evidence require explicit input', (
    t,
  ) async {
    final repo = FakeNutrition();
    await t.pumpWidget(
      MaterialApp(
        home: EntryFormPage(
          food: asFood(fixtureFood('fixture')),
          repository: repo,
        ),
      ),
    );
    await t.scrollUntilVisible(
      find.text('Confirmar consumo'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text('Confirmar consumo'));
    await t.pumpAndSettle();
    expect(repo.entryWrites, 0);
    expect(find.text('Escolha medida ou estimativa.'), findsOneWidget);
  });
  testWidgets('ambiguous retry retains same key and frozen quantity', (
    t,
  ) async {
    final repo = FakeNutrition()
      ..error = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    await t.pumpWidget(
      MaterialApp(
        home: EntryFormPage(
          food: asFood(fixtureFood('fixture')),
          repository: repo,
        ),
      ),
    );
    await t.enterText(find.byKey(const Key('entry-quantity')), '25,5');
    await chooseEvidence(t);
    await t.scrollUntilVisible(
      find.text('Confirmar consumo'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text('Confirmar consumo'));
    await t.pumpAndSettle();
    expect(repo.body!['quantity'], '25.5');
    expect(repo.body!['quantityEvidence'], 'estimated');
    final field = t.widget<TextFormField>(
      find.byKey(const Key('entry-quantity')),
    );
    expect(field.enabled, false);
    await t.scrollUntilVisible(
      find.text('Tentar confirmar novamente'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text('Tentar confirmar novamente'));
    await t.pumpAndSettle();
    expect(repo.entryWrites, 2);
    expect(repo.keys.toSet().length, 1);
  });
  testWidgets('double tap sends a single write', (t) async {
    final repo = FakeNutrition()..pending = Completer<Json>();
    await t.pumpWidget(
      MaterialApp(
        home: EntryFormPage(
          food: asFood(fixtureFood('fixture')),
          repository: repo,
        ),
      ),
    );
    await t.enterText(find.byKey(const Key('entry-quantity')), '30');
    await chooseEvidence(t);
    await t.scrollUntilVisible(
      find.text('Confirmar consumo'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await t.tap(find.text('Confirmar consumo'));
    await t.tap(find.text('Confirmar consumo'));
    await t.pump();
    expect(repo.entryWrites, 1);
    repo.pending!.complete({});
    await t.pumpAndSettle();
  });
  testWidgets(
    'empty history has no invented meals; small screen and large text',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final account = ValueNotifier<String?>('a');
      addTearDown(account.dispose);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: NutritionPage(
            accountId: 'a',
            currentAccountId: () => account.value,
            sessionChanges: account,
            repository: FakeNutrition(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Nenhum consumo registrado neste dia.'),
        150,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('Nenhum consumo registrado neste dia.'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Meus alimentos'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  test('repository blocks account change before request', () async {
    final dio = Dio();
    var calls = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          calls++;
          h.reject(DioException(requestOptions: o));
        },
      ),
    );
    final repo = GoNutritionRepository(
      accountId: 'a',
      currentAccountId: () => 'b',
      dio: dio,
    );
    await expectLater(repo.foods(), throwsStateError);
    expect(calls, 0);
  });
  test('repository rejects late responses from a different account', () async {
    var current = 'a';
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          expect(o.headers['X-TrainForge-Account'], 'a');
          current = 'b';
          h.resolve(
            Response(
              requestOptions: o,
              data: {'items': [], 'nextCursor': null},
            ),
          );
        },
      ),
    );
    final repo = GoNutritionRepository(
      accountId: 'a',
      currentAccountId: () => current,
      dio: dio,
    );
    await expectLater(repo.foods(), throwsStateError);
  });
}
