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
          expect(
            find.bySemanticsLabel(
              target.localizedLabel(t.element(find.byType(FigmaBottomNav))),
            ),
            findsOneWidget,
          );
          await t.tap(find.byKey(ValueKey('nav-${target.name}')).first);
          await t.pump();
          // Tapping the open page changes nothing; any other opens it.
          expect(tapped, target == current ? null : target);
          tapped = null;
        }
        expect(t.takeException(), isNull);
      }
    },
  );
  testWidgets('320px and large text keep all targets usable, "+" included', (
    t,
  ) async {
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
    // Each of the five slots of the glass bar is a touch target.
    final bar = t.getSize(find.byType(FigmaBottomNav));
    expect(bar.width / 5, greaterThanOrEqualTo(48));
    expect(bar.height, greaterThanOrEqualTo(64));
    expect(
      t.getSize(find.byKey(const ValueKey('nav-add'))).width,
      greaterThanOrEqualTo(48),
    );
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
                selected: TrainForgeDestination.workouts,
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
  testWidgets(
    'dragging along the bar lights the icon under the finger and opens it on release',
    (t) async {
      final opened = <TrainForgeDestination>[];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 342,
                child: FigmaBottomNav(
                  selected: TrainForgeDestination.today,
                  onSelected: opened.add,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final start = t.getCenter(find.byKey(const ValueKey('nav-today')).first);
      final end = t.getCenter(find.byKey(const ValueKey('nav-food')).first);
      final gesture = await t.startGesture(start);
      await t.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(Offset.lerp(start, end, .5)!);
      await t.pump();
      expect(opened, isEmpty, reason: 'nothing opens while the finger is down');
      await gesture.moveTo(end);
      await t.pump();
      await gesture.up();
      await t.pumpAndSettle();
      expect(opened, [TrainForgeDestination.food]);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('the "+" calls its action and never selects a page', (t) async {
    final opened = <TrainForgeDestination>[];
    var added = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 342,
              child: FigmaBottomNav(
                selected: TrainForgeDestination.today,
                onSelected: opened.add,
                onAdd: () => added++,
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const ValueKey('nav-add')));
    await t.pump();
    expect(added, 1);
    expect(opened, isEmpty);
    expect(find.bySemanticsLabel('Adicionar'), findsOneWidget);
  });
}
