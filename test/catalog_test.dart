import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/catalog/domain/catalog_entry.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_detail_page.dart';

CatalogEntry entry(String id) => CatalogEntry.fromJson({
  'id': id,
  'versionId': 'a' * 64,
  'kind': 'movement',
  'title': 'Isolated fixture $id',
  'locale': 'en',
  'source': {'name': 'Isolated source'},
  'authors': ['Fixture author'],
  'rights': {
    'attribution': 'Fixture attribution',
    'deliveryConditions': ['Isolated delivery condition'],
    'displayCredits': {
      'creators': ['Fixture creator'],
      'licenseLabel': 'Fixture license',
      'licenseUrl': 'https://example.invalid/license',
      'sourceUrl': 'https://example.invalid/source',
      'changes': 'Fixture changes',
      'warrantyNotice': 'Fixture warranty',
      'selectedNameCredit': {
        'creators': ['Fixture name creator'],
        'licenseUrl': 'https://example.invalid/name-license',
      },
    },
  },
  'audience': {
    'population': null,
    'environment': null,
    'supportRequired': null,
    'supportSource': null,
  },
  'requirements': {'category': null, 'equipment': [], 'modality': null},
  'availability': {
    'reasons': ['Consulta de fixture isolada; nunca seed do app.'],
  },
});

class FixtureCatalog implements CatalogRepository {
  final Map<String, Completer<CatalogPageData>> pending = {};
  Object? detailError, listError;
  int pageCalls = 0;
  @override
  Future<CatalogPageData> list(CatalogFilters f, {String? cursor}) async {
    pageCalls++;
    if (listError != null) throw listError!;
    if (pending.containsKey(f.q)) return pending[f.q]!.future;
    if (f.kind == 'programs') return CatalogPageData([], null);
    return cursor == null
        ? CatalogPageData([
            entry(f.q.isEmpty ? 'first' : f.q),
          ], 'next-fixture-cursor')
        : CatalogPageData([entry('second')], null);
  }

  @override
  Future<CatalogFacets> facets() async => CatalogFacets.fromJson({
    'environments': [],
    'populations': [],
    'equipment': ['Fixture bench'],
    'categories': ['Fixture category'],
    'modalities': [],
    'movementCount': 2,
    'programCount': 0,
    'unknownEnvironmentCount': 2,
    'unknownPopulationCount': 2,
  });
  @override
  Future<CatalogEntry> detail(CatalogEntry e) async {
    if (detailError != null) throw detailError!;
    return e;
  }
}

void main() {
  test('outdated filter responses cannot replace the current result', () async {
    final repo = FixtureCatalog();
    repo.pending['old'] = Completer<CatalogPageData>();
    final controller = CatalogController(repo);
    final old = controller.load(filters: const CatalogFilters(q: 'old'));
    await controller.load(filters: const CatalogFilters(q: 'new'));
    repo.pending['old']!.complete(CatalogPageData([entry('old')], null));
    await old;
    expect(controller.items.single.id, 'new');
    controller.dispose();
  });
  test(
    'pagination appends and failed reload does not keep stale metadata visible',
    () async {
      final repo = FixtureCatalog();
      final controller = CatalogController(repo);
      await controller.load();
      await controller.more();
      expect(controller.items.map((e) => e.id), ['first', 'second']);
      repo.listError = StateError('do-not-expose-secret');
      await controller.load();
      expect(controller.items, isEmpty);
      expect(controller.error, isNot(contains('secret')));
      controller.dispose();
    },
  );
  testWidgets(
    'small-screen enlarged text remains scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = CatalogController(FixtureCatalog());
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: CatalogPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.textContaining('Isolated fixture first'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );
  testWidgets('empty programs do not relabel movements as programs', (
    tester,
  ) async {
    final controller = CatalogController(FixtureCatalog());
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(controller: controller)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programas (0)'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Nenhum programa autorizado'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('Nenhum programa autorizado'), findsOneWidget);
    expect(find.textContaining('Isolated fixture'), findsNothing);
    controller.dispose();
  });
  testWidgets(
    'detail shows full attribution and unknown requirements without practice action',
    (tester) async {
      final e = entry('detail');
      await tester.pumpWidget(
        MaterialApp(
          home: CatalogDetailPage(
            entry: e,
            repository: FixtureCatalog(),
            evidenceMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Fixture license'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Fixture license'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Público: Não informado'),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.textContaining('Apoio: Não informado'), findsOneWidget);
      expect(find.text('Iniciar treino'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('withdrawn detail does not reuse stale list content', (
    tester,
  ) async {
    final request = RequestOptions(path: '/catalog');
    final repo = FixtureCatalog()
      ..detailError = DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 404),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogDetailPage(entry: entry('withdrawn'), repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('foi retirado'), findsOneWidget);
    expect(find.textContaining('Isolated fixture withdrawn'), findsNothing);
  });
  test(
    'external source links only allow HTTPS without embedded credentials',
    () {
      expect(safeCatalogLink('https://example.invalid/license'), isNotNull);
      for (final value in [
        'javascript:alert(1)',
        'file:///private',
        'http://example.invalid',
        'https://user:password@example.invalid',
      ]) {
        expect(safeCatalogLink(value), isNull);
      }
    },
  );
}
