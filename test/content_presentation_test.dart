import 'package:trainforge/shared/widgets/content_sources_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/catalog/domain/catalog_entry.dart';
import 'package:trainforge/features/catalog/domain/catalog_names.dart';
import 'package:trainforge/features/catalog/presentation/catalog_detail_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_labels.dart';
import 'package:trainforge/features/food_reference/domain/food_display_names.dart';
import 'package:trainforge/features/food_reference/domain/food_reference.dart';
import 'package:trainforge/features/food_reference/presentation/food_detail_page.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_facts.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'catalog_test.dart' as catalog;
import 'food_reference_test.dart' as food;

Widget shell(Widget page, {Locale locale = const Locale('pt', 'BR')}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: page,
    );
void main() {
  test(
    'nutrition headings recognize common user labels in supported languages',
    () {
      const facts = NutritionFacts(values: []);
      for (final name in ['Proteínas', 'Protein', 'Protéines']) {
        expect(facts.category(name), 'protein');
      }
      for (final name in ['Fibras', 'Fibre', 'Fiber']) {
        expect(facts.category(name), 'fiber');
      }
      expect(facts.category('Carboidratos'), 'carbs');
      expect(facts.category('Grasas'), 'fat');
      expect(facts.category('Gorduras saturadas'), isNull);
    },
  );

  testWidgets(
    'public sources area has no private calculation action without a session',
    (t) async {
      await t.pumpWidget(shell(const ContentSourcesPage()));
      await t.pumpAndSettle();
      expect(find.text('Fontes e transparência'), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(
            t.element(find.byType(ContentSourcesPage)),
          ).preservedCalculation,
        ),
        findsNothing,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('normal movement detail is clean and never offers practice', (
    t,
  ) async {
    await t.pumpWidget(
      shell(
        CatalogDetailPage(
          entry: catalog.entry('clean'),
          repository: catalog.FixtureCatalog(),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Somente consulta'), findsOneWidget);
    expect(find.text('Fixture attribution'), findsNothing);
    expect(find.text('Fixture license'), findsNothing);
    expect(find.text('Origem e disponibilidade'), findsNothing);
    expect(find.text('Iniciar treino'), findsNothing);
  });
  testWidgets(
    'food summary hides metadata while evidence preserves the original',
    (t) async {
      final f = FoodReference.fromJson(food.fixtureFood('first'));
      await t.pumpWidget(
        shell(FoodDetailPage(food: f, repository: food.FixtureFoods())),
      );
      await t.pumpAndSettle();
      expect(find.text('Informações nutricionais'), findsOneWidget);
      expect(find.text('Fixture author and publication date'), findsNothing);
      expect(find.text('Fixture license'), findsNothing);
      expect(find.textContaining('fixture raw'), findsNothing);
      await t.pumpWidget(
        shell(
          FoodDetailPage(
            key: const ValueKey('evidence'),
            food: f,
            repository: food.FixtureFoods(),
            evidenceMode: true,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Fixture author and publication date'), findsOneWidget);
    },
  );
  testWidgets(
    'catalog labels follow locale and fail back on a changed source version',
    (t) async {
      final binding = catalogDisplayNames.entries.first;
      late String shown;
      Future<void> render(Locale locale, String version) async {
        final e = CatalogEntry.fromJson({
          'id': binding.key,
          'versionId': version,
          'kind': 'movement',
          'title': binding.value.original,
          'locale': 'en',
          'source': {'name': 'Isolated source'},
          'authors': [],
          'rights': {'displayCredits': {}, 'deliveryConditions': []},
          'audience': {},
          'requirements': {'equipment': []},
          'availability': {'reasons': []},
        });
        await t.pumpWidget(
          shell(
            Builder(
              builder: (context) {
                shown = localizedCatalogTitle(context, e);
                return Text(shown);
              },
            ),
            locale: locale,
          ),
        );
        await t.pumpAndSettle();
      }

      for (final locale in [
        const Locale('pt', 'BR'),
        const Locale('pt', 'PT'),
        const Locale('es'),
        const Locale('en'),
      ]) {
        await render(locale, binding.value.version);
        expect(shown, binding.value.names[locale.languageCode]);
      }
      await render(const Locale('pt', 'BR'), '0' * 64);
      expect(shown, binding.value.original);
    },
  );
  test(
    'food display translation cannot attach to a different food or preparation version',
    () {
      final binding = foodDisplayNames.entries.first;
      final fixture = food.fixtureFood(binding.key);
      fixture['versionId'] = binding.value.version;
      fixture['nameOriginal'] = binding.value.original;
      final f = FoodReference.fromJson(fixture);
      expect(f.displayNameFor('pt-BR'), binding.value.names['pt']);
      expect(f.name, binding.value.original);
      fixture['versionId'] = '0' * 64;
      expect(
        FoodReference.fromJson(fixture).displayNameFor('pt-BR'),
        binding.value.original,
      );
    },
  );
  testWidgets(
    'nutrition summary keeps units and never combines conflicting methods',
    (t) async {
      await t.pumpWidget(
        shell(
          const Scaffold(
            body: NutritionFacts(
              values: [
                (name: 'Energy method A', value: '100', unit: 'kcal'),
                (name: 'Energy method B', value: '110', unit: 'kcal'),
                (name: 'Energy method A', value: '418', unit: 'kJ'),
                (name: 'Protein', value: 'Traço', unit: 'g'),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('Valores de métodos diferentes'),
        findsOneWidget,
      );
      expect(find.text('418 kJ'), findsWidgets);
      expect(find.text('Traço g'), findsWidgets);
      expect(find.text('210 kcal'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
