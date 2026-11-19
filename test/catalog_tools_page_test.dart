import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/food_reference/data/catalog_installer.dart';
import 'package:trainforge/features/food_reference/presentation/catalog_tools_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';

class _Installer extends CatalogInstaller {
  String? pack;
  int imports = 0;
  _Installer(this.pack);
  @override
  Future<Map<String, dynamic>> manifest() async {
    if (pack == null) throw const FormatException('not installed');
    return {
      'pack': {'id': pack},
    };
  }

  @override
  Future<void> importArchive(String path) async => imports++;
}

Widget _app(CatalogInstaller installer) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: TrainForgeTheme.light,
  home: CatalogToolsPage(installer: installer),
);

void main() {
  testWidgets('installed pack shows a badge instead of a download action', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Installer('br')));
    await tester.pumpAndSettle();
    expect(find.text('Instalado'), findsOneWidget);
    expect(find.byTooltip('Baixar pacote'), findsNothing);
    expect(find.textContaining('GitHub'), findsOneWidget);
  });

  testWidgets('bundled pack retries local preparation without downloading', (
    tester,
  ) async {
    final installer = _Installer(null);
    await tester.pumpWidget(_app(installer));
    await tester.pumpAndSettle();
    installer.pack = 'br';
    await tester.tap(find.byTooltip('Preparar catálogo incluído no app'));
    await tester.pumpAndSettle();
    expect(find.text('Instalado'), findsOneWidget);
    expect(find.byTooltip('Baixar pacote'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(installer.imports, 0);
  });

  testWidgets('failed local preparation remains visible and retryable', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Installer(null)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Preparar catálogo incluído no app'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Não foi possível verificar ou instalar'),
      findsOneWidget,
    );
    expect(find.byTooltip('Preparar catálogo incluído no app'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
