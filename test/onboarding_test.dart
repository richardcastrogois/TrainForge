import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/features/home/presentation/widgets/home_cards.dart';
import 'package:trainforge/features/onboarding/onboarding_page.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/features/training_library/data/training_library.dart';

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pt', 'BR'),
  supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

void main() {
  test('answers survive a round trip and unknown values are dropped', () {
    final p = OnboardingProfile(
      gender: 'nonbinary',
      heightCm: 170,
      weightKg: 72,
      places: const {'praca', 'casa'},
      confidence: 'iniciante',
      completedAt: DateTime.utc(2026, 11, 25),
    );
    final back = OnboardingProfile.fromJson(p.toJson());
    expect(back.gender, 'nonbinary');
    expect(back.heightCm, 170);
    expect(back.places, {'casa', 'praca'});
    expect(back.completed, isTrue);
    final bad = OnboardingProfile.fromJson({
      'gender': 'x',
      'heightCm': 999,
      'weightKg': '70',
      'places': ['lua', 'casa'],
      'confidence': 'expert',
    });
    expect(bad.gender, isNull);
    expect(bad.heightCm, isNull);
    expect(bad.weightKg, isNull);
    expect(bad.places, {'casa'});
    expect(bad.confidence, isNull);
    expect(bad.completed, isFalse);
  });

  test('confidence maps to library cells that exist', () {
    final lib = TrainingLibrary.parse(
      File(TrainingLibrary.asset).readAsStringSync(),
    );
    for (final c in OnboardingProfile.confidences) {
      for (final p in OnboardingProfile.placeIds) {
        final cell = OnboardingProfile(confidence: c).cellFor(p);
        expect(lib.forCell(cell), isNotEmpty, reason: '$c/$p → $cell');
      }
    }
  });

  test('controller saves, reads back and resets per account', () async {
    final store = MemoryOnboardingStore();
    final c = OnboardingController(store: store);
    await c.load('a');
    expect(c.loaded('a'), isTrue);
    expect(c.profile('a'), isNull);
    await c.save('a', const OnboardingProfile(places: {'casa'}));
    expect(store.values['a']!.places, {'casa'});
    await c.reset('a');
    expect(store.values['a'], isNull);
  });

  testWidgets('without health consent the flow skips height and weight', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    OnboardingProfile? done;
    await t.pumpWidget(
      _app(OnboardingPage(askBody: false, onDone: (p) => done = p)),
    );
    expect(find.text('Vamos preparar o app para você'), findsOneWidget);
    await t.tap(find.text('Vamos lá'));
    await t.pumpAndSettle();
    expect(find.text('Como você se identifica?'), findsOneWidget);
    await t.tap(find.text('Prefiro não dizer'));
    await t.tap(find.byKey(const Key('onboarding-next')));
    await t.pumpAndSettle();
    expect(find.text('Onde você pensa em se exercitar?'), findsOneWidget);
    // The tile's ink layer sits above its text and takes the tap.
    await t.tap(find.text('Em casa'), warnIfMissed: false);
    await t.tap(find.text('Na praça ou no parque'), warnIfMissed: false);
    await t.tap(find.byKey(const Key('onboarding-next')));
    await t.pumpAndSettle();
    expect(find.text('Como você se sente para se exercitar?'), findsOneWidget);
    await t.tap(find.text('Estou começando agora'));
    await t.tap(find.text('Começar'));
    await t.pumpAndSettle();
    expect(done!.completed, isTrue);
    expect(done!.gender, 'undisclosed');
    expect(done!.places, {'casa', 'praca'});
    expect(done!.confidence, 'iniciante');
    expect(done!.heightCm, isNull);
  });

  testWidgets(
    'with health consent height and weight use +/- and can be skipped',
    (t) async {
      t.view.physicalSize = const Size(800, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      OnboardingProfile? done;
      await t.pumpWidget(
        _app(OnboardingPage(askBody: true, onDone: (p) => done = p)),
      );
      await t.tap(find.text('Vamos lá'));
      await t.pumpAndSettle();
      await t.tap(
        find.byKey(const Key('onboarding-next')),
      ); // gender left empty
      await t.pumpAndSettle();
      expect(find.text('Qual é a sua altura?'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Aumentar'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Aumentar'));
      await t.pump();
      expect(find.textContaining('167'), findsOneWidget);
      await t.tap(find.byKey(const Key('onboarding-next')));
      await t.pumpAndSettle();
      expect(find.text('Qual é o seu peso?'), findsOneWidget);
      await t.tap(find.text('Pular'));
      await t.pumpAndSettle();
      await t.tap(find.text('Pular')); // places
      await t.pumpAndSettle();
      await t.tap(find.text('Pular')); // confidence → done
      await t.pumpAndSettle();
      expect(done!.heightCm, 167);
      expect(done!.weightKg, isNull);
      expect(done!.gender, isNull);
    },
  );

  testWidgets(
    'hero shows the chosen place and level; "+" asks for missing answers',
    (t) async {
      final text = File(TrainingLibrary.asset).readAsStringSync();
      var asked = 0;
      await t.pumpWidget(
        _app(
          Scaffold(
            body: ListView(
              children: [
                TrainingHeroCard(
                  profile: const OnboardingProfile(
                    places: {'casa'},
                    confidence: 'iniciante',
                  ),
                  library: () async => TrainingLibrary.parse(text),
                ),
                BuildWorkoutCard(
                  profile: const OnboardingProfile(),
                  completeAnswers: () => asked++,
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text('UM POUCO MAIS FORTE E SAUDÁVEL, TODOS OS DIAS'),
        findsOneWidget,
      );
      expect(find.text('Treino em casa'), findsOneWidget);
      expect(find.textContaining('Iniciante ·'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d+ treinos')), findsOneWidget);
      expect(find.text('Ver treinos'), findsOneWidget);
      await t.tap(find.text('Montar meu treino'));
      expect(asked, 1);
    },
  );
}
