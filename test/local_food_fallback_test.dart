import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/food_reference/data/local_food_repository.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';

import 'food_names_client_test.dart' show LocalizedFixtures;
import 'food_reference_test.dart' show FixtureFoods, fixtureFood;

void main() {
  test(
    'failed device catalog keeps localized server search and food identity',
    () async {
      final server = LocalizedFixtures();
      final repository = LocalFoodRepository(
        () async => throw StateError('device catalog unavailable'),
        fallback: server,
      );
      final page = await repository.localizedList(
        locale: 'pt-BR',
        q: 'arroz branco',
        sourceId: 'AL-TACO',
        cursor: 'server-cursor',
        namesVersion: '1',
      );
      expect(server.calls.single, {
        'locale': 'pt-BR',
        'q': 'arroz branco',
        'sourceId': 'AL-TACO',
        'cursor': 'server-cursor',
        'version': '1',
      });
      final detail = await repository.localizedDetail(
        page.items.single,
        locale: 'pt-BR',
      );
      expect(detail.food.id, page.items.single.id);
      expect(detail.food.versionId, page.items.single.versionId);
      expect(detail.nameCatalog?.locale, 'pt-BR');
      expect(detail.nutrients, isNotEmpty);
      expect((await repository.facets()).total, 2);
    },
  );

  test(
    'failed device catalog also supports a server without localization',
    () async {
      final repository = LocalFoodRepository(
        () async => throw StateError('device catalog unavailable'),
        fallback: FixtureFoods(),
      );
      final page = await repository.list(q: 'arroz');
      expect(page.items.single.id, 'arroz');
      final more = await repository.localizedList(
        locale: 'pt-BR',
        q: 'arroz',
        cursor: page.nextCursor,
      );
      expect(more.items.single.id, 'second');
      expect(more.nextCursor, isNull);
      expect((await repository.detail(page.items.single)).food.id, 'arroz');
      expect(
        (await repository.localizedDetail(
          page.items.single,
          locale: 'pt-BR',
        )).food.id,
        'arroz',
      );
    },
  );

  test(
    'both catalogs failing remains an error rather than an empty result',
    () async {
      final failure = StateError('server unavailable');
      final repository = LocalFoodRepository(
        () async => throw StateError('device catalog unavailable'),
        fallback: FixtureFoods()..listError = failure,
      );
      await expectLater(repository.list(q: 'arroz'), throwsA(same(failure)));
    },
  );

  test(
    'without a fallback the original catalog failure remains visible',
    () async {
      final failure = StateError('device catalog unavailable');
      final repository = LocalFoodRepository(() async => throw failure);
      final food = FoodReference.fromJson(fixtureFood('arroz'));
      await expectLater(repository.list(q: 'arroz'), throwsA(same(failure)));
      await expectLater(repository.detail(food), throwsA(same(failure)));
    },
  );
}
