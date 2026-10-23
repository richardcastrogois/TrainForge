import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/shared/widgets/figma_bottom_nav.dart';

void main() {
  testWidgets(
    'all original SVG states render and destinations are accessible',
    (t) async {
      for (final current in TrainForgeDestination.values) {
        TrainForgeDestination? tapped;
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 342,
                  child: FigmaBottomNav(
                    selected: current,
                    onSelected: (v) => tapped = v,
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        for (final target in TrainForgeDestination.values) {
          expect(find.bySemanticsLabel(target.label), findsWidgets);
          await t.tap(find.byTooltip(target.label));
          await t.pump();
          expect(tapped, target);
        }
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets('320px and large text keep all five targets usable', (t) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FigmaBottomNav(
                selected: TrainForgeDestination.food,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    for (final target in TrainForgeDestination.values) {
      final size = t.getSize(
        find.descendant(
          of: find.byTooltip(target.label),
          matching: find.byType(InkWell),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
    expect(t.takeException(), isNull);
  });
  testWidgets('navigation visual artifact for direct Figma comparison', (
    t,
  ) async {
    if (!const bool.fromEnvironment('TF_RENDER_NAV')) return;
    t.view.physicalSize = const Size(362, 86);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xfff6f6f1),
            body: Padding(
              padding: const EdgeInsets.all(10),
              child: FigmaBottomNav(
                selected: TrainForgeDestination.plans,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = (await t.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
    final data = await t.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    await t.runAsync(
      () => File(
        '.local/android-evaluation/nav-plans-preview.png',
      ).writeAsBytes(data!.buffer.asUint8List()),
    );
    image.dispose();
  });
}
