import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/shared/widgets/product_shell.dart';
import 'package:trainforge/shared/widgets/startup_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_bottom_nav.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'auth_controller_test.dart' show SessionFixture, fixtureProfile;
import 'catalog_test.dart' show FixtureCatalog;
import 'nutrition_test.dart' show FakeNutrition;
import 'appearance_startup_motion_test.dart' show MemoryAppearance;

void main() {
  testWidgets('all five areas and profile render in dark at320 with text2x', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final auth = AuthController(SessionFixture())..profile = fixtureProfile;
    final plans = CatalogController(FixtureCatalog());
    addTearDown(auth.dispose);
    addTearDown(plans.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: TrainForgeTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2), disableAnimations: true),
          child: child!,
        ),
        home: ProductShell(
          controller: auth,
          plansController: plans,
          nutritionRepository: FakeNutrition(),
        ),
      ),
    );
    await t.pumpAndSettle();
    for (final destination in TrainForgeDestination.values) {
      await t.tap(find.byTooltip(destination.label));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
    final semantics = t.ensureSemantics();
    expect(find.bySemanticsLabel('Abrir perfil'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Abrir perfil'));
    semantics.dispose();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'compact startup and loaders respect enlarged text and reduced motion',
    (t) async {
      t.view.physicalSize = const Size(568, 320);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final page in <Widget>[
        const StartupPage(label: 'Confirmando sua sessão'),
        const Scaffold(body: AppLoading(label: 'Consultando os dados reais')),
      ]) {
        await t.pumpWidget(
          MaterialApp(
            theme: TrainForgeTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: page,
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'stage01to06 visual review artifacts contain only isolated fixtures',
    (t) async {
      if (!const bool.fromEnvironment('TF_RENDER_STAGE01')) return;
      await t.runAsync(() async {
        final font = FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await font.load();
        await icons.load();
      });
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final auth = AuthController(SessionFixture())..profile = fixtureProfile;
        final plans = CatalogController(FixtureCatalog());
        addTearDown(auth.dispose);
        addTearDown(plans.dispose);
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: TrainForgeTheme.build(brightness),
              home: MediaQuery(
                data: const MediaQueryData(
                  padding: EdgeInsets.only(top: 24, bottom: 24),
                ),
                child: ProductShell(
                  controller: auth,
                  plansController: plans,
                  nutritionRepository: FakeNutrition(),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        Future<void> capture(String name) async {
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
              '.local/android-evaluation/stage01-$name.png',
            ).writeAsBytes(data!.buffer.asUint8List()),
          );
          image.dispose();
        }

        await capture('today-${brightness.name}');
        for (final destination in TrainForgeDestination.values.skip(1)) {
          await t.tap(find.byTooltip(destination.label));
          await t.pumpAndSettle();
          await capture('${destination.name}-${brightness.name}');
        }
        await t.tap(find.byTooltip('Abrir perfil'));
        await t.pumpAndSettle();
        await capture('profile-${brightness.name}');
      }
      final appearance = AppearanceController(
        store: MemoryAppearance()..saved = 'dark',
      );
      addTearDown(appearance.dispose);
      await appearance.restore();
      for (final entry in <String, Widget>{
        'startup': const StartupPage(label: 'Confirmando sua sessão'),
        'appearance': AppearanceScope(
          controller: appearance,
          child: const AppearancePage(),
        ),
        'loading': const Scaffold(
          body: AppLoading(label: 'Consultando os dados reais'),
        ),
      }.entries) {
        final key = GlobalKey();
        await t.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: TrainForgeTheme.dark,
              home: entry.value,
            ),
          ),
        );
        if (entry.key == 'loading') {
          await t.pump();
        } else {
          await t.pumpAndSettle();
        }
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
            '.local/android-evaluation/stage01-${entry.key}.png',
          ).writeAsBytes(data!.buffer.asUint8List()),
        );
        image.dispose();
      }
    },
  );
}
