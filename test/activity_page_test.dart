import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/activity/domain/activity_repository.dart';
import 'package:trainforge/features/activity/presentation/activity_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'activity_controller_test.dart'
    show
        ActivityFake,
        activityFixture,
        activityOccurrence,
        activityId,
        activityTitle;

Widget activityHarness(
  ActivityFake api, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
  String? Function()? current,
  Listenable? changes,
  VoidCallback? configure,
  VoidCallback? openCatalog,
}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: brightness == Brightness.dark
      ? TrainForgeTheme.dark
      : TrainForgeTheme.light,
  builder: (context, child) => RepaintBoundary(
    key: const ValueKey('activity-preview'),
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
  ),
  home: Scaffold(
    body: ActivityPage(
      repository: api,
      accountId: activityId(2),
      currentAccountId: current ?? () => activityId(2),
      sessionChanges: changes,
      configure: configure,
      openCatalog: openCatalog,
    ),
  ),
);

Future<void> tapActivity(WidgetTester tester, Finder finder) async {
  final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
  scroll.position.jumpTo(scroll.position.minScrollExtent);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void activityView(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
}

void main() {
  testWidgets('empty real feed offers configuration/library without starting', (
    tester,
  ) async {
    activityView(tester);
    final api = ActivityFake();
    var configurations = 0, catalogs = 0;
    await tester.pumpWidget(
      activityHarness(
        api,
        configure: () => configurations++,
        openCatalog: () => catalogs++,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No approved session is available right now.'),
      findsOneWidget,
    );
    expect(find.text('No sessions recorded.'), findsOneWidget);
    expect(api.starts, isEmpty);
    await tapActivity(tester, find.text('Training setup'));
    expect(configurations, 1);
    await tapActivity(
      tester,
      find.text('Browse the library without signing in'),
    );
    expect(catalogs, 1);
    expect(api.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opening a session does not start it and manual results begin empty',
    (tester) async {
      activityView(tester);
      final api = ActivityFake()
        ..feed = ActivityFeed(
          upcoming: [],
          sessions: [activityFixture()],
          complete: true,
        );
      await tester.pumpWidget(activityHarness(api));
      await tester.pumpAndSettle();
      await tapActivity(tester, find.text('Open session'));
      expect(api.starts, isEmpty);
      await tapActivity(
        tester,
        find.byKey(const ValueKey('activity-record-0-1')),
      );
      final actual = tester.widget<TextFormField>(
        find.byKey(const ValueKey('activity-measurement')),
      );
      final kg = tester.widget<TextFormField>(
        find.byKey(const ValueKey('activity-load-kg')),
      );
      expect(actual.controller!.text, isEmpty);
      expect(kg.controller!.text, isEmpty);
      expect(find.text('Planned: 10'), findsWidgets);
      expect(api.commands, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual quantity and optional load are confirmed through the repository',
    (tester) async {
      activityView(tester);
      final api = ActivityFake()
        ..feed = ActivityFeed(
          upcoming: [],
          sessions: [activityFixture()],
          complete: true,
        );
      api.onCommand = (_) async => ActivityMutation(
        detail: activityFixture(
          revision: 2,
          recorded: 1,
          actual: 6,
          loadKg: '12.375',
        ),
        appliedRevision: 2,
        replayed: false,
      );
      await tester.pumpWidget(activityHarness(api));
      await tester.pumpAndSettle();
      await tapActivity(tester, find.text('Open session'));
      await tapActivity(
        tester,
        find.byKey(const ValueKey('activity-record-0-1')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity-measurement')),
        '6',
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity-load-kg')),
        '12,375',
      );
      await tapActivity(
        tester,
        find.widgetWithText(FilledButton, 'Record set'),
      );
      expect(api.commands, hasLength(1));
      expect(api.commands.single['confirmed'], isFalse);
      expect((api.commands.single['set'] as Map)['repetitions'], 6);
      expect((api.commands.single['set'] as Map)['loadKg'], '12.375');
      expect(find.text('Recorded: 6 · 12.375 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelling the terminal confirmation never sends an action', (
    tester,
  ) async {
    activityView(tester);
    final api = ActivityFake()
      ..feed = ActivityFeed(
        upcoming: [],
        sessions: [activityFixture()],
        complete: true,
      );
    await tester.pumpWidget(activityHarness(api));
    await tester.pumpAndSettle();
    await tapActivity(tester, find.text('Open session'));
    await tapActivity(tester, find.text('Finish as partial'));
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(api.commands, isEmpty);
    await tapActivity(tester, find.text('Finish as partial'));
    api.onCommand = (_) async => ActivityMutation(
      detail: activityFixture(state: 'partial', revision: 2),
      appliedRevision: 2,
      replayed: false,
    );
    await tester.tap(find.text('Confirm action'));
    await tester.pumpAndSettle();
    expect(api.commands.single['action'], 'partial');
    expect(api.commands.single['confirmed'], isTrue);
    expect(find.text('Finished partially'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a session requires an explicit start; rebuilds do not repeat it',
    (tester) async {
      activityView(tester);
      final api = ActivityFake()
        ..feed = ActivityFeed(
          upcoming: [activityOccurrence()],
          sessions: [],
          complete: true,
        );
      await tester.pumpWidget(activityHarness(api));
      await tester.pumpAndSettle();
      expect(api.starts, isEmpty);
      await tapActivity(tester, find.text('Start session'));
      expect(api.starts, hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      expect(api.starts, hasLength(1));
      expect(api.loads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account invalidation removes the visible private session', (
    tester,
  ) async {
    activityView(tester);
    final changes = ChangeNotifier();
    addTearDown(changes.dispose);
    String? owner = activityId(2);
    final api = ActivityFake()
      ..feed = ActivityFeed(
        upcoming: [],
        sessions: [activityFixture()],
        complete: true,
      );
    await tester.pumpWidget(
      activityHarness(api, current: () => owner, changes: changes),
    );
    await tester.pumpAndSettle();
    await tapActivity(tester, find.text('Open session'));
    expect(find.text(activityTitle), findsOneWidget);
    owner = activityId(55);
    changes.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text(activityTitle), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(api.commands, isEmpty);
  });

  testWidgets(
    'an unresolved response preserves the draft and blocks a new command',
    (tester) async {
      activityView(tester);
      final api = ActivityFake()
        ..feed = ActivityFeed(
          upcoming: [],
          sessions: [activityFixture()],
          complete: true,
        );
      api.onCommand = (_) async =>
          throw const ActivityFailure('network', uncertain: true);
      await tester.pumpWidget(activityHarness(api));
      await tester.pumpAndSettle();
      await tapActivity(tester, find.text('Open session'));
      await tapActivity(
        tester,
        find.byKey(const ValueKey('activity-record-0-1')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('activity-measurement')),
        '8',
      );
      await tapActivity(
        tester,
        find.widgetWithText(FilledButton, 'Record set'),
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('activity-measurement')),
      );
      expect(field.controller!.text, '8');
      expect(field.enabled, isFalse);
      expect(api.commands, hasLength(1));
      await tapActivity(tester, find.text('Retry confirmation'));
      expect(api.commands, hasLength(2));
      expect(api.commands.first, api.commands.last);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in [
    const Locale('pt', 'BR'),
    const Locale('pt', 'PT'),
    const Locale('en'),
    const Locale('es'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'session fits 320px/text2x ${locale.toLanguageTag()} ${brightness.name}',
        (tester) async {
          activityView(tester);
          final api = ActivityFake()
            ..feed = ActivityFeed(
              upcoming: [],
              sessions: [activityFixture(mode: 'duration')],
              complete: true,
            )
            ..value = activityFixture(mode: 'duration');
          final labels = lookupAppLocalizations(locale);
          await tester.pumpWidget(
            activityHarness(
              api,
              locale: locale,
              brightness: brightness,
              textScale: 2,
            ),
          );
          await tester.pumpAndSettle();
          await tapActivity(tester, find.text(labels.activityOpenSession));
          await tapActivity(
            tester,
            find.byKey(const ValueKey('activity-record-0-1')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('activity-measurement')),
            '12,345',
          );
          await tester.enterText(
            find.byKey(const ValueKey('activity-load-kg')),
            '2,5',
          );
          expect(tester.takeException(), isNull);
          expect(api.commands, isEmpty);
        },
      );
    }
  }

  final previewDirectory = Platform.environment['TF_ACTIVITY_PREVIEW_DIR'];
  if (previewDirectory != null && previewDirectory.isNotEmpty) {
    testWidgets('isolated fixture previews (opt-in, no app or database)', (
      tester,
    ) async {
      activityView(tester);
      await tester.runAsync(() async {
        final fonts = FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
        await fonts.load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      for (final width in [320.0, 390.0]) {
        tester.view.physicalSize = Size(width, width == 320 ? 568 : 844);
        final api = ActivityFake()
          ..feed = ActivityFeed(
            upcoming: [],
            sessions: [activityFixture()],
            complete: true,
          );
        final labels = lookupAppLocalizations(const Locale('pt', 'BR'));
        await tester.pumpWidget(
          activityHarness(
            api,
            locale: const Locale('pt', 'BR'),
            brightness: Brightness.dark,
            textScale: width == 320 ? 2 : 1,
          ),
        );
        await tester.pumpAndSettle();
        await captureActivity(
          tester,
          previewDirectory,
          'activity-feed-${width.toInt()}.png',
        );
        await tapActivity(tester, find.text(labels.activityOpenSession));
        await captureActivity(
          tester,
          previewDirectory,
          'activity-session-${width.toInt()}.png',
        );
        await tapActivity(
          tester,
          find.byKey(const ValueKey('activity-record-0-1')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('activity-measurement')),
          '7',
        );
        await tester.enterText(
          find.byKey(const ValueKey('activity-load-kg')),
          '12,5',
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await captureActivity(
          tester,
          previewDirectory,
          'activity-form-${width.toInt()}.png',
        );
        expect(api.commands, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}

Future<void> captureActivity(
  WidgetTester tester,
  String directory,
  String name,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('activity-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = Directory(directory);
      await output.create(recursive: true);
      await File(
        '${output.path}${Platform.pathSeparator}$name',
      ).writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
