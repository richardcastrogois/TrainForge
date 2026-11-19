import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'package:trainforge/shared/widgets/food_catalog_credits_page.dart';

void main() {
  testWidgets(
    'signed-manifest credits remain available without installing the catalog',
    (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoodCatalogCreditsPage(
            loadManifest: () async {
              reads++;
              return {
                'version': 'fixture',
                'sha256': 'a' * 64,
                'sources': [
                  {
                    'sourceId': 'TACO',
                    'name': 'TACO fixture',
                    'licenseLabel': 'Source attribution',
                    'attribution': 'Fixture source credit',
                    'url': 'https://example.invalid/source',
                    'licenseUrl': 'https://example.invalid/license',
                    'version': '2011',
                    'conditions': <String>[],
                  },
                ],
                'exports': [
                  {
                    'sourceId': 'TACO',
                    'file': 'fixture.jsonl.gz',
                    'bytes': 1024,
                  },
                ],
              };
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('TACO fixture'), findsOneWidget);
      expect(
        find.textContaining('Seus registros pessoais não fazem parte'),
        findsOneWidget,
      );
      await tester.tap(find.text('TACO fixture'));
      await tester.pumpAndSettle();
      expect(find.text('Fixture source credit'), findsOneWidget);
      expect(find.textContaining('Baixar dados'), findsOneWidget);
    },
  );
}
