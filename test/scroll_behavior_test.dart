import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/app.dart';
import 'package:trainforge/core/scroll/trainforge_scroll_behavior.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'appearance_startup_motion_test.dart' show MemoryAppearance;
import 'auth_controller_test.dart' show SessionFixture;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Android scroll boundaries without stretch in ${brightness.name}',
      (t) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await t.pumpWidget(
          MaterialApp(
            scrollBehavior: const TrainForgeScrollBehavior(),
            theme: TrainForgeTheme.build(
              brightness,
            ).copyWith(platform: TargetPlatform.android),
            home: Scaffold(
              body: ListView.builder(
                controller: controller,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 30,
                itemExtent: 80,
                itemBuilder: (_, i) => Text('Reference row $i'),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(StretchingOverscrollIndicator), findsNothing);
        expect(find.byType(GlowingOverscrollIndicator), findsNothing);
        final gesture = await t.startGesture(const Offset(200, 150));
        await gesture.moveBy(const Offset(0, 180));
        await t.pump();
        expect(controller.offset, 0);
        await gesture.up();
        await t.pumpAndSettle();
        await t.drag(find.byType(ListView), const Offset(0, -500));
        await t.pumpAndSettle();
        expect(controller.offset, greaterThan(0));
        controller.jumpTo(controller.position.maxScrollExtent);
        await t.pump();
        await t.drag(find.byType(ListView), const Offset(0, -300));
        await t.pumpAndSettle();
        expect(controller.offset, controller.position.maxScrollExtent);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'short Android list keeps pull to refresh without stretching content',
    (t) async {
      final pending = Completer<void>();
      var calls = 0;
      await t.pumpWidget(
        MaterialApp(
          scrollBehavior: const TrainForgeScrollBehavior(),
          theme: TrainForgeTheme.light.copyWith(
            platform: TargetPlatform.android,
          ),
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () {
                calls++;
                return pending.future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100, child: Text('Empty real-day state')),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.fling(
        find.text('Empty real-day state'),
        const Offset(0, 300),
        1000,
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(calls, 1);
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      pending.complete();
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'iOS retains platform bouncing and Android override never replaces physics',
    (t) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await t.pumpWidget(
        MaterialApp(
          scrollBehavior: const TrainForgeScrollBehavior(),
          theme: TrainForgeTheme.dark.copyWith(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1400)],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(controller.position.physics, isA<BouncingScrollPhysics>());
      final gesture = await t.startGesture(const Offset(200, 100));
      await gesture.moveBy(const Offset(0, 160));
      await t.pump();
      expect(controller.offset, lessThan(0));
      expect(find.byType(StretchingOverscrollIndicator), findsNothing);
      await gesture.up();
      await t.pumpAndSettle();
      expect(controller.offset.abs(), lessThan(1));
    },
  );
  testWidgets('production composition applies the common scroll behavior', (
    t,
  ) async {
    final appearance = AppearanceController(store: MemoryAppearance());
    final auth = AuthController(SessionFixture());
    addTearDown(appearance.dispose);
    addTearDown(auth.dispose);
    await t.pumpWidget(
      TrainForgeApp(appearance: appearance, authController: auth),
    );
    await t.pumpAndSettle();
    expect(
      t.widget<MaterialApp>(find.byType(MaterialApp)).scrollBehavior,
      isA<TrainForgeScrollBehavior>(),
    );
  });
}
