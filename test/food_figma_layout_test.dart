import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_forms.dart';
import 'package:trainforge/features/food_reference/presentation/food_controller.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'food_reference_test.dart' show FixtureFoods, fixtureFood;
import 'nutrition_test.dart' show FakeNutrition;

void main() {
  testWidgets(
    'portion remains editable at320 with enlarged text and keyboard inset',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      t.view.viewInsets = const FakeViewPadding(bottom: 240);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetViewInsets);
      final repo = FakeNutrition();
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: EntryFormPage(
            food: asFood(fixtureFood('quantity-layout')),
            repository: repo,
          ),
        ),
      );
      await t.pumpAndSettle();
      final quantity = find.byKey(const Key('entry-quantity'));
      await t.ensureVisible(quantity);
      await t.enterText(quantity, '1,25');
      await t.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Confirmar consumo'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirmar consumo'));
      await t.pumpAndSettle();
      expect(repo.entryWrites, 0);
      expect(find.text('Escolha medida ou estimativa.'), findsOneWidget);
      await t.ensureVisible(quantity);
      await t.pumpAndSettle();
      expect(t.widget<TextFormField>(quantity).controller!.text, '1,25');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('food visual artifacts use isolated fixtures without writes', (
    t,
  ) async {
    if (!const bool.fromEnvironment('TF_RENDER_FOOD')) return;
    await t.runAsync(() async {
      final font = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final controller = FoodController(FixtureFoods());
    addTearDown(controller.dispose);
    final repo = FakeNutrition();
    for (final item in <String, Widget>{
      'food-search': FoodPage(controller: controller),
      'food-portion': EntryFormPage(
        food: asFood(fixtureFood('portion-layout')),
        repository: repo,
      ),
    }.entries) {
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TrainForgeTheme.light,
            home: MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(top: 24, bottom: 24),
              ),
              child: item.value,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = (await t.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
      final bytes = await t.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      );
      await t.runAsync(
        () => File(
          '.local/android-evaluation/${item.key}-figma-preview.png',
        ).writeAsBytes(bytes!.buffer.asUint8List()),
      );
      image.dispose();
      expect(t.takeException(), isNull);
    }
    expect(repo.entryWrites, 0);
  });
}
