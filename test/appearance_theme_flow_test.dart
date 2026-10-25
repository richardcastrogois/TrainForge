import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/app.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/shared/widgets/product_shell.dart';
import 'package:trainforge/shared/widgets/figma_bottom_nav.dart';
import 'auth_controller_test.dart' show SessionFixture, fixtureProfile;
import 'nutrition_test.dart' show FakeNutrition;
import 'appearance_startup_motion_test.dart' show MemoryAppearance;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          NativeLocaleStore.channel,
          (call) async => call.method == 'read' ? 'pt-BR' : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeLocaleStore.channel, null);
  });
  testWidgets('device reduced motion disables root theme animation', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final appearance = AppearanceController(store: MemoryAppearance());
    final auth = AuthController(SessionFixture());
    addTearDown(appearance.dispose);
    addTearDown(auth.dispose);
    await t.pumpWidget(
      TrainForgeApp(
        appearance: appearance,
        authController: auth,
        nutritionRepository: FakeNutrition(),
      ),
    );
    await t.pumpAndSettle();
    await appearance.select(ThemeMode.dark);
    await t.pump();
    expect(
      t.widget<MaterialApp>(find.byType(MaterialApp)).themeAnimationDuration,
      Duration.zero,
    );
  });

  test('theme tokens preserve readable text and buttons in light and dark', () {
    for (final p in [TrainForgeColors.light, TrainForgeColors.dark]) {
      for (final surface in [
        p.background,
        p.surface,
        p.accent,
        p.nutrition,
        p.soft,
        p.blue,
        p.yellow,
        p.pink,
      ]) {
        expect(contrast(p.ink, surface), greaterThanOrEqualTo(4.5));
        expect(contrast(p.cardMuted, surface), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(p.muted, p.background), greaterThanOrEqualTo(4.5));
      expect(contrast(p.muted, p.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      expect(contrast(p.primary, p.surface), greaterThanOrEqualTo(4.5));
    }
  });
  testWidgets(
    'system theme follows device brightness and changing it retains the selected tab',
    (t) async {
      final store = MemoryAppearance()..saved = 'system';
      final appearance = AppearanceController(store: store);
      final auth = AuthController(SessionFixture()..profile = fixtureProfile);
      addTearDown(appearance.dispose);
      addTearDown(auth.dispose);
      t.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      await t.pumpWidget(
        TrainForgeApp(
          appearance: appearance,
          authController: auth,
          nutritionRepository: FakeNutrition(),
        ),
      );
      await t.pumpAndSettle();
      expect(
        Theme.of(t.element(find.byType(ProductShell))).brightness,
        Brightness.light,
      );
      await t.tap(find.byTooltip('Diário'));
      await t.pumpAndSettle();
      t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await t.pumpAndSettle();
      expect(
        Theme.of(t.element(find.byType(ProductShell))).brightness,
        Brightness.dark,
      );
      expect(
        t.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        TrainForgeDestination.food,
      );
      expect(auth.profile?.id, fixtureProfile.id);
      await appearance.select(ThemeMode.light);
      await t.pumpAndSettle();
      expect(
        Theme.of(t.element(find.byType(ProductShell))).brightness,
        Brightness.light,
      );
      expect(
        t.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        TrainForgeDestination.food,
      );
      expect(store.saved, 'light');
    },
  );
  testWidgets(
    'appearance choice is reachable without logging in and remains saved after reopening',
    (t) async {
      final store = MemoryAppearance(),
          appearance = AppearanceController(store: MemoryAppearance());
      appearance.dispose();
      final first = AppearanceController(store: store),
          auth = AuthController(SessionFixture());
      addTearDown(first.dispose);
      addTearDown(auth.dispose);
      await t.pumpWidget(
        TrainForgeApp(
          appearance: first,
          authController: auth,
          nutritionRepository: FakeNutrition(),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('Aparência'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Aparência'));
      await t.pumpAndSettle();
      await t.tap(find.text('Escuro'));
      await t.pumpAndSettle();
      expect(store.saved, 'dark');
      expect(first.mode, ThemeMode.dark);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      final second = AppearanceController(store: store),
          newAuth = AuthController(SessionFixture());
      addTearDown(second.dispose);
      addTearDown(newAuth.dispose);
      await t.pumpWidget(
        TrainForgeApp(
          key: const ValueKey('reopened'),
          appearance: second,
          authController: newAuth,
          nutritionRepository: FakeNutrition(),
        ),
      );
      await t.pumpAndSettle();
      expect(second.mode, ThemeMode.dark);
      expect(
        Theme.of(t.element(find.text('Entrar com Google'))).brightness,
        Brightness.dark,
      );
    },
  );
}
