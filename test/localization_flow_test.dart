import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/app.dart';
import 'package:trainforge/core/l10n/language_page.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'package:trainforge/shared/widgets/product_shell.dart';
import 'package:trainforge/shared/widgets/figma_bottom_nav.dart';
import 'locale_controller_test.dart' show MemoryLocaleStore;
import 'appearance_startup_motion_test.dart' show MemoryAppearance;
import 'app_composition_test.dart' show CompositionFixture;
import 'auth_controller_test.dart' show fixtureProfile;

void main() {
  testWidgets(
    'changing language keeps account, navigation and session controller',
    (t) async {
      final services = CompositionFixture()..session.profile = fixtureProfile;
      final language = LocaleController(store: MemoryLocaleStore('pt-BR'));
      final appearance = AppearanceController(store: MemoryAppearance());
      addTearDown(language.dispose);
      addTearDown(appearance.dispose);
      await t.pumpWidget(
        TrainForgeApp(
          dependencies: services.dependencies,
          appearance: appearance,
          language: language,
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Planos'));
      await t.pumpAndSettle();
      final auth = t.widget<ProductShell>(find.byType(ProductShell)).controller;
      await language.select(LanguageChoice.english);
      await t.pumpAndSettle();
      expect(
        t.widget<ProductShell>(find.byType(ProductShell)).controller,
        same(auth),
      );
      expect(auth.profile?.id, fixtureProfile.id);
      expect(services.sessions, 1);
      expect(services.session.restores, 1);
      expect(
        t.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        TrainForgeDestination.plans,
      );
      expect(find.byTooltip('Plans'), findsOneWidget);
      await t.tap(find.byTooltip('Open profile'));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Language'),
        250,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await t.tap(find.text('Language'));
      await t.pumpAndSettle();
      expect(find.byType(LanguagePage), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Español'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Español'));
      await t.pumpAndSettle();
      expect(language.choice, LanguageChoice.spanish);
      await t.scrollUntilVisible(
        find.text('Elige el idioma de la interfaz en este dispositivo.'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Idioma'), findsOneWidget);
      expect(
        find.text('Elige el idioma de la interfaz en este dispositivo.'),
        findsOneWidget,
      );
      expect(services.session.restores, 1);
      expect(auth.profile?.id, fixtureProfile.id);
      expect(t.takeException(), isNull);
    },
  );

  for (final locale in supportedAppLocales) {
    testWidgets(
      'resources, formats and large text work for ${locale.toLanguageTag()}',
      (t) async {
        t.view.physicalSize = const Size(320, 640);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final language = LocaleController(
          store: MemoryLocaleStore(locale.toLanguageTag()),
        );
        addTearDown(language.dispose);
        await language.restore();
        late String day, decimal, unknown;
        await t.pumpWidget(
          LocaleScope(
            controller: language,
            child: MaterialApp(
              locale: locale,
              supportedLocales: supportedAppLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: TrainForgeTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) {
                  day = context.displayDate(DateTime(2026, 10, 25));
                  decimal = context.displayDecimal(
                    '12345.123456789012345678901',
                  );
                  unknown = context.displayDecimal('<0.01');
                  return const LanguagePage();
                },
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(day, locale.languageCode == 'en' ? '10/25/2026' : '25/10/2026');
        expect(
          decimal,
          locale.languageCode == 'en'
              ? '12345.123456789012345678901'
              : '12345,123456789012345678901',
        );
        expect(unknown, '<0.01');
        await t.scrollUntilVisible(
          find.text('Español'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Español'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('language previews use isolated preferences in both themes', (
    t,
  ) async {
    if (!const bool.fromEnvironment('TF_RENDER_LOCALE')) return;
    await t.runAsync(() async {
      await (FontLoader('Inter')
            ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
            ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await Directory('.local/localization').create(recursive: true);
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    for (final locale in supportedAppLocales) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final language = LocaleController(
          store: MemoryLocaleStore(locale.toLanguageTag()),
        );
        addTearDown(language.dispose);
        await language.restore();
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: LocaleScope(
              controller: language,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                locale: locale,
                supportedLocales: supportedAppLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: TrainForgeTheme.build(brightness),
                home: const LanguagePage(),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = (await t.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        ))!;
        final data = await t.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        await t.runAsync(
          () => File(
            '.local/localization/locale-${locale.toLanguageTag()}-${brightness.name}.png',
          ).writeAsBytes(data!.buffer.asUint8List()),
        );
        image.dispose();
        expect(t.takeException(), isNull);
      }
    }
  });
}
