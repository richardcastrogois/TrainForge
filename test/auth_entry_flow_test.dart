import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'package:trainforge/features/auth/domain/auth_profile.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/guest_page.dart';
import 'package:trainforge/features/auth/presentation/widgets/entry_scene.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'package:trainforge/shared/widgets/startup_page.dart';
import 'auth_controller_test.dart' show SessionFixture, fixtureProfile;
import 'nutrition_test.dart' show FakeNutrition;

Widget gate(AuthController controller) => MaterialApp(
  theme: TrainForgeTheme.light,
  locale: const Locale('pt', 'BR'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: AuthGate(controller: controller, nutritionRepository: FakeNutrition()),
);

void main() {
  testWidgets('sign-in keeps the entry visible instead of the startup cover', (
    t,
  ) async {
    final repo = SessionFixture()..pendingLogin = Completer<AuthProfile>();
    final controller = AuthController(repo);
    addTearDown(controller.dispose);
    await t.pumpWidget(gate(controller));
    await t.pumpAndSettle();
    await t.tap(find.text('Continuar com o Google'));
    await t.pump();
    expect(controller.busy, isTrue);
    expect(find.byType(StartupPage), findsNothing);
    expect(find.text('Aguardando confirmação do Google'), findsOneWidget);
    repo.pendingLogin!.complete(fixtureProfile);
    await t.pumpAndSettle();
    expect(controller.profile?.id, fixtureProfile.id);
  });

  testWidgets('first-time link explains the account and offers both paths', (
    t,
  ) async {
    final repo = SessionFixture()..pendingLogin = Completer<AuthProfile>();
    final controller = AuthController(repo);
    addTearDown(controller.dispose);
    await t.pumpWidget(gate(controller));
    await t.pumpAndSettle();
    expect(find.text('Primeiro acesso e configuração'), findsNothing);
    await t.ensureVisible(find.text('Primeira vez? Veja como funciona'));
    await t.tap(find.text('Primeira vez? Veja como funciona'));
    await t.pumpAndSettle();
    expect(find.text('Como funciona o primeiro acesso'), findsOneWidget);
    expect(find.textContaining('e-mail verificado'), findsOneWidget);
    await t.tap(find.text('Continuar com o Google').last);
    await t.pump();
    expect(repo.logins, 1);
    repo.pendingLogin!.complete(fixtureProfile);
    await t.pumpAndSettle();
    expect(find.text('Como funciona o primeiro acesso'), findsNothing);
  });

  testWidgets('guest route exposes only public areas', (t) async {
    final controller = AuthController(SessionFixture());
    addTearDown(controller.dispose);
    await t.pumpWidget(gate(controller));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Conheça o app sem criar conta'));
    await t.tap(find.text('Conheça o app sem criar conta'));
    await t.pumpAndSettle();
    expect(find.byType(GuestPage), findsOneWidget);
    expect(find.text('Consultar biblioteca sem entrar'), findsOneWidget);
    expect(
      find.text('Consultar alimentos sem registrar consumo'),
      findsOneWidget,
    );
  });

  test('Google plugin failures map to actionable feedback', () async {
    Future<AuthFeedback?> feedbackFor(GoogleSignInExceptionCode code) async {
      final controller = AuthController(
        SessionFixture()..loginError = GoogleSignInException(code: code),
      );
      await controller.login();
      final feedback = controller.feedback;
      controller.dispose();
      return feedback;
    }

    expect(await feedbackFor(GoogleSignInExceptionCode.canceled), isNull);
    expect(
      await feedbackFor(GoogleSignInExceptionCode.providerConfigurationError),
      AuthFeedback.googleConfiguration,
    );
    expect(
      await feedbackFor(GoogleSignInExceptionCode.uiUnavailable),
      AuthFeedback.googleUnavailable,
    );
    expect(
      await feedbackFor(GoogleSignInExceptionCode.interrupted),
      AuthFeedback.signInFailed,
    );
  });

  testWidgets(
    'brand sequence plays once per launch and settles into the entry',
    (t) async {
      AppMotion.ambient = true;
      AuthPage.playedThisLaunch = false;
      addTearDown(() => AppMotion.ambient = false);
      final controller = AuthController(SessionFixture());
      addTearDown(controller.dispose);
      await t.pumpWidget(gate(controller));
      await t.pump(const Duration(milliseconds: 1500));
      // Splash phase: entry actions are not reachable yet.
      expect(find.bySemanticsLabel('Continuar com o Google'), findsNothing);
      await t.pump(const Duration(milliseconds: 3200));
      await t.pump(const Duration(milliseconds: 2000));
      expect(find.text('Continuar com o Google'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'a tap skips the sequence and a second mount does not replay it',
    (t) async {
      AppMotion.ambient = true;
      AuthPage.playedThisLaunch = false;
      addTearDown(() => AppMotion.ambient = false);
      final controller = AuthController(SessionFixture());
      addTearDown(controller.dispose);
      await t.pumpWidget(gate(controller));
      await t.pump(const Duration(milliseconds: 800));
      await t.tapAt(const Offset(200, 300));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text('Continuar com o Google'));
      await t.pump(const Duration(milliseconds: 50));
      expect(controller.busy || controller.profile != null, isTrue);
      await t.pumpWidget(const SizedBox());
      expect(AuthPage.playedThisLaunch, isTrue);
    },
  );

  testWidgets('rings react to the person and the TF answers a tap', (t) async {
    // Real glyph widths (Inter), so two-line sentences measure as on device.
    await t.runAsync(() async {
      final inter = FontLoader('Inter')
        ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
      await inter.load();
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final controller = AuthController(SessionFixture());
    addTearDown(controller.dispose);
    await t.pumpWidget(gate(controller));
    await t.pumpAndSettle();
    final rings = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is EntryRingsPainter,
    );
    EntryRingsPainter painter() =>
        t.widget<CustomPaint>(rings).painter! as EntryRingsPainter;
    final box = t.getRect(rings);
    final k = math.min(math.min(box.width, box.height), 320.0) / 300;
    Offset onRing(int ring, double fraction) {
      final r = EntryRingsPainter.rings[ring].$1 * k;
      final a = -math.pi / 2 + fraction * 2 * math.pi;
      return box.center + Offset(math.cos(a) * r, math.sin(a) * r);
    }

    expect(
      find.text('Treino, alimentação e evolução em um só lugar.'),
      findsOneWidget,
    );
    await t.tapAt(onRing(0, .3));
    await t.pumpAndSettle();
    expect(painter().values[0], closeTo(.3, .03));
    // The longer guidance sentence must not move the rings.
    expect(t.getRect(rings), box);
    expect(
      find.text('Treinar com frequência dá mais disposição para o seu dia.'),
      findsOneWidget,
    );
    await t.tapAt(onRing(0, .9));
    await t.pumpAndSettle();
    expect(
      find.text('Treino, alimentação e evolução em um só lugar.'),
      findsOneWidget,
    );

    await t.tapAt(box.center);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(painter().pulse, greaterThan(0));
    await t.pumpAndSettle();
    expect(find.text('Conheça o app sem criar conta'), findsOneWidget);
  });
}
