import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'auth_controller_test.dart' show SessionFixture;

void main() {
  testWidgets(
    'branded entry stays usable with enlarged text and has no fake login channels',
    (t) async {
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final controller = AuthController(SessionFixture());
      addTearDown(controller.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: TrainForgeTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: AuthPage(controller: controller),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(TrainForgeBrand), findsOneWidget);
      await t.scrollUntilVisible(find.text('Entrar com Google'), 100);
      expect(t.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
    },
  );
  testWidgets('entry visual inspection artifact', (t) async {
    if (!const bool.fromEnvironment('TF_RENDER_AUTH')) return;
    await t.runAsync(() async {
      final font = File(
        'C:/Users/richa/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      );
      if (await font.exists()) {
        final loader = FontLoader('Roboto')
          ..addFont(font.readAsBytes().then((b) => ByteData.sublistView(b)))
          ..addFont(
            File(
              'C:/Users/richa/flutter/bin/cache/artifacts/material_fonts/roboto-bold.ttf',
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            File(
              'C:/Users/richa/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        await icons.load();
        await loader.load();
      }
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final controller = AuthController(SessionFixture());
    addTearDown(controller.dispose);
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: TrainForgeTheme.light.copyWith(
            textTheme: TrainForgeTheme.light.textTheme.apply(
              fontFamily: 'Roboto',
            ),
          ),
          home: AuthPage(controller: controller),
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
        '.local/android-evaluation/auth-figma-colors-preview.png',
      ).writeAsBytes(data!.buffer.asUint8List()),
    );
    image.dispose();
    expect(t.takeException(), isNull);
  });
}
