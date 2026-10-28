import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/training_configuration/domain/training_configuration.dart';
import 'package:trainforge/features/training_configuration/data/training_configuration_repository.dart';
import 'package:trainforge/features/training_configuration/presentation/training_configuration_controller.dart';
import 'package:trainforge/features/training_configuration/presentation/training_configuration_page.dart';
import 'package:trainforge/l10n/generated/app_localizations.dart';
import 'nutrition_localization_test.dart' show reach, small;

Map<String, dynamic> configFixture() => {
  'environments': ['home'],
  'context': 'caregiver_break',
  'timezone': '-03:00',
  'resources': {'status': 'unknown', 'items': []},
  'availability': [
    {'weekday': 1, 'minutesAvailable': 15, 'startTime': null},
  ],
};
Map<String, dynamic> currentJson({
  int revision = 1,
  Map<String, dynamic>? configuration,
}) => {
  'current': {
    'contract': trainingConfigurationContract,
    'revision': revision,
    'confirmedAt': '2026-10-27T12:00:00Z',
    'configuration': configuration ?? configFixture(),
  },
  'resourceLabels': [],
  'unavailableResources': [],
};
TrainingCurrent absent() => TrainingCurrent.fromJson({
  'current': null,
  'resourceLabels': [],
  'unavailableResources': [],
});

class ConfigurationFixture implements TrainingConfigurationRepository {
  TrainingCurrent current = absent();
  Object? error;
  int reads = 0;
  final keys = <String>[], bodies = <Map<String, dynamic>>[];
  Completer<TrainingCurrent>? pendingRead, pendingSave;
  final pages = <Completer<TrainingResourcePage>>[];
  @override
  Future<TrainingCurrent> load() async {
    reads++;
    if (pendingRead != null) return pendingRead!.future;
    if (error != null) throw error!;
    return current;
  }

  @override
  Future<TrainingCurrent> save(Map<String, dynamic> command, String key) async {
    keys.add(key);
    bodies.add(configObject(jsonDecode(jsonEncode(command))));
    if (pendingSave != null) return pendingSave!.future;
    if (error != null) throw error!;
    return current = TrainingCurrent.fromJson(
      currentJson(
        revision: (command['revision'] as int) + 1,
        configuration: configObject(command['configuration']),
      ),
    );
  }

  @override
  Future<TrainingResourcePage> resources({String q = '', String? cursor}) {
    final p = Completer<TrainingResourcePage>();
    pages.add(p);
    return p.future;
  }
}

TrainingConfigurationController control(
  ConfigurationFixture repo, {
  String? Function()? owner,
}) => TrainingConfigurationController(
  repository: repo,
  accountId: 'owner',
  currentAccountId: owner ?? () => 'owner',
  timezone: '-03:00',
);
void fill(TrainingConfigurationController c) =>
    c.update((_) => c.draft = TrainingDraft.fromJson(configFixture()));
Widget configShell(Locale locale, Widget page) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: supportedAppLocales,
  theme: TrainForgeTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(2), disableAnimations: true),
    child: child!,
  ),
  home: page,
);

void main() {
  test('absence has no training facts and does not auto-save', () async {
    final r = ConfigurationFixture();
    final c = control(r);
    await c.load();
    expect(c.ready, true);
    expect(c.draft.environments, isEmpty);
    expect(c.draft.context, isNull);
    expect(c.draft.resourceStatus, isNull);
    expect(c.draft.availability.single.weekday, isNull);
    expect(c.draft.availability.single.minutes, isEmpty);
    expect(c.dirty, false);
    expect(r.bodies, isEmpty);
    expect(await c.save(), false);
    c.dispose();
  });
  test(
    'unknown differs from none, slots are availability and version copies are isolated',
    () {
      final d = TrainingDraft.fromJson(configFixture());
      expect(d.validate(), isEmpty);
      final s = TrainingSnapshot.fromJson(currentJson()['current']);
      d.resources['x/1'] = const TrainingResourceRef('x', 1);
      expect(d.validate(), contains('configuration.resources.items'));
      d.resources.clear();
      d.resourceStatus = 'none';
      expect(d.validate(), isEmpty);
      d.availability.add(AvailabilityDraft(id: 9, weekday: 1, minutes: '10'));
      expect(d.validate(), contains('configuration.availability.1'));
      d.availability.last.start = '23:59';
      expect(d.validate(), isEmpty);
      d.availability.last.minutes = '1441';
      expect(
        d.validate(),
        contains('configuration.availability.1.minutesAvailable'),
      );
      d.timezone = 'Local';
      expect(d.validate(), contains('configuration.timezone'));
      final copy = s.draft();
      copy.environments.clear();
      expect(s.draft().environments, {'home'});
    },
  );
  test(
    'resource projection rejects unrelated, duplicate or missing identities',
    () {
      final j = currentJson();
      j['resourceLabels'] = [
        {
          'sourceId': 's',
          'equipmentId': 1,
          'nameOriginal': 'Fixture',
          'sourceName': 'Source',
        },
      ];
      expect(() => TrainingCurrent.fromJson(j), throwsFormatException);
      final selected = configFixture();
      selected['resources'] = {
        'status': 'declared',
        'items': [
          {'sourceId': 's', 'equipmentId': 1},
        ],
      };
      expect(
        () => TrainingCurrent.fromJson(currentJson(configuration: selected)),
        throwsFormatException,
      );
      final label = TrainingResourceOption.fromJson({
        'sourceId': 's',
        'equipmentId': 1,
        'nameOriginal': 'Banc de musculation',
        'sourceName': 'Original source',
      });
      expect(label.name, 'Banc de musculation');
    },
  );
  test(
    'uncertain save freezes exact intent, retries same key, and does not discard on read',
    () async {
      final r = ConfigurationFixture();
      final x = control(r);
      await x.load();
      fill(x);
      r.error = const TrainingFailure(
        'training_configuration_unavailable',
        uncertain: true,
      );
      expect(await x.save(), false);
      final body = jsonEncode(r.bodies.single), key = r.keys.single;
      expect(x.uncertain, true);
      expect(x.editable, false);
      x.update((d) => d.context = 'personal');
      await x.load();
      expect(jsonEncode(r.bodies.single), body);
      r.error = null;
      expect(await x.save(), true);
      expect(r.keys, [key, key]);
      expect(jsonEncode(r.bodies.last), body);
      expect(x.dirty, false);
      expect(x.snapshot!.revision, 1);
      x.dispose();
    },
  );
  test(
    'conflict preserves draft; explicit reload recovers latest revision',
    () async {
      final r = ConfigurationFixture();
      final x = control(r);
      await x.load();
      fill(x);
      final body = x.draft.fingerprint;
      r.error = const TrainingFailure('training_configuration_conflict');
      expect(await x.save(), false);
      expect(x.draft.fingerprint, body);
      expect(x.uncertain, false);
      r.error = null;
      r.current = TrainingCurrent.fromJson(currentJson(revision: 3));
      await x.load();
      expect(x.snapshot!.revision, 3);
      expect(x.dirty, false);
      x.dispose();
    },
  );
  test(
    'initial read failure blocks editing and save; retry does not fabricate a current',
    () async {
      final r = ConfigurationFixture()
        ..error = const TrainingFailure('training_configuration_unavailable');
      final c = control(r);
      await c.load();
      expect(c.ready, false);
      expect(c.editable, false);
      expect(await c.save(), false);
      r.error = null;
      await c.load();
      expect(c.ready, true);
      expect(c.snapshot, isNull);
      c.dispose();
    },
  );
  test(
    'account change clears draft, pending intent and ignores late save or read',
    () async {
      String? owner = 'owner';
      final r = ConfigurationFixture();
      final x = control(r, owner: () => owner);
      await x.load();
      fill(x);
      r.pendingSave = Completer();
      final saving = x.save();
      owner = 'other';
      x.accountChanged();
      r.pendingSave!.complete(TrainingCurrent.fromJson(currentJson()));
      expect(await saving, false);
      expect(x.snapshot, isNull);
      expect(x.draft.environments, isEmpty);
      expect(x.active, false);
      x.dispose();
      owner = 'owner';
      r.pendingRead = Completer();
      final y = control(r, owner: () => owner);
      final read = y.load();
      owner = null;
      y.accountChanged();
      r.pendingRead!.complete(TrainingCurrent.fromJson(currentJson()));
      await read;
      expect(y.snapshot, isNull);
      y.dispose();
    },
  );
  test(
    'late resource search response cannot replace new results or cross account',
    () async {
      final r = ConfigurationFixture(), c = control(r);
      await c.load();
      final old = c.loadOptions(q: 'a'), recent = c.loadOptions(q: 'b');
      r.pages[1].complete(
        TrainingResourcePage.fromJson({
          'items': [
            {
              'sourceId': 'b',
              'equipmentId': 1,
              'nameOriginal': 'B',
              'sourceName': 'Source B',
            },
          ],
          'nextCursor': 'next',
        }),
      );
      await recent;
      r.pages[0].complete(
        TrainingResourcePage.fromJson({'items': [], 'nextCursor': null}),
      );
      await old;
      expect(c.options.single.reference.sourceId, 'b');
      expect(c.cursor, 'next');
      c.dispose();
    },
  );
  test(
    'real HTTP adapter sends account guard and no owner body; verifies saved contract',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
      String? owner = 'a';
      final r = GoTrainingConfigurationRepository(
        accountId: 'a',
        currentAccountId: () => owner,
        dio: dio,
      );
      final seen = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            seen.add(o);
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: o.method == 'PUT'
                    ? currentJson()
                    : {
                        'current': null,
                        'resourceLabels': [],
                        'unavailableResources': [],
                      },
              ),
            );
          },
        ),
      );
      expect((await r.load()).snapshot, isNull);
      final cmd = {
        'revision': 0,
        'reviewed': true,
        'configuration': configFixture(),
      };
      await r.save(cmd, 'stable-key');
      expect(seen.last.headers['X-TrainForge-Account'], 'a');
      expect(seen.last.headers['Idempotency-Key'], 'stable-key');
      expect((seen.last.data as Map).containsKey('userId'), false);
      owner = 'b';
      await expectLater(r.load(), throwsStateError);
      expect(seen.length, 2);
      dio.close();
    },
  );
  for (final locale in supportedAppLocales) {
    final strings = lookupAppLocalizations(locale);
    testWidgets(
      'four-step draft, review, language change, safe retry and finish at 320px/2x $locale',
      (t) async {
        small(t);
        final r = ConfigurationFixture(),
            session = ChangeNotifier(),
            language = ValueNotifier(locale);
        addTearDown(session.dispose);
        addTearDown(language.dispose);
        final page = TrainingConfigurationPage(
          accountId: 'owner',
          currentAccountId: () => 'owner',
          sessionChanges: session,
          repository: r,
        );
        await t.pumpWidget(
          ValueListenableBuilder<Locale>(
            valueListenable: language,
            builder: (_, locale, _) => configShell(locale, page),
          ),
        );
        await t.pumpAndSettle();
        expect(r.bodies, isEmpty);
        await reach(t, find.byKey(const Key('place-home')));
        await t.tap(find.byKey(const Key('place-home')));
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('context-caregiver')));
        await t.tap(find.byKey(const Key('context-caregiver')));
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('config-next')));
        await t.tap(find.byKey(const Key('config-next')));
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('resources-unknown')));
        await t.tap(find.byKey(const Key('resources-unknown')));
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('config-next')));
        await t.tap(find.byKey(const Key('config-next')));
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('day-1')));
        await t.tap(find.byKey(const Key('day-1')));
        await t.pumpAndSettle();
        await t.tap(find.text(strings.configMonday).last);
        await t.pumpAndSettle();
        await reach(t, find.byKey(const Key('minutes-1')));
        await t.enterText(find.byKey(const Key('minutes-1')), '15');
        await t.pumpAndSettle();
        // Locale changes must not refetch private data or erase answers.
        language.value = const Locale('en');
        await t.pumpAndSettle();
        expect(r.reads, 1);
        expect(find.text('15'), findsOneWidget);
        await reach(t, find.byKey(const Key('config-next')));
        await t.tap(find.byKey(const Key('config-next')));
        await t.pumpAndSettle();
        r.error = const TrainingFailure(
          'training_configuration_unavailable',
          uncertain: true,
        );
        await reach(t, find.byKey(const Key('config-confirm')));
        await t.tap(find.byKey(const Key('config-confirm')));
        await t.pumpAndSettle();
        expect(r.bodies.length, 1);
        expect(r.bodies.single['reviewed'], true);
        expect(r.bodies.single['configuration']['context'], 'caregiver_break');
        final body = jsonEncode(r.bodies.single), key = r.keys.single;
        r.error = null;
        await reach(t, find.text('Retry confirmation'), delta: -250);
        await t.tap(find.text('Retry confirmation'));
        await t.pumpAndSettle();
        expect(r.keys, [key, key]);
        expect(jsonEncode(r.bodies.last), body);
        expect(find.text('Setup confirmed'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'exiting dirty form offers discard and keeping draft preserves answers',
    (t) async {
      final r = ConfigurationFixture(), session = ChangeNotifier();
      addTearDown(session.dispose);
      await t.pumpWidget(
        configShell(
          const Locale('en'),
          TrainingConfigurationPage(
            accountId: 'owner',
            currentAccountId: () => 'owner',
            sessionChanges: session,
            repository: r,
          ),
        ),
      );
      await t.pumpAndSettle();
      await reach(t, find.byKey(const Key('place-home')));
      await t.tap(find.byKey(const Key('place-home')));
      await t.pumpAndSettle();
      await reach(t, find.text('Cancel'));
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Leave without saving?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await t.pumpAndSettle();
      await reach(t, find.byKey(const Key('place-home')), delta: -200);
      expect(
        t.widget<CheckboxListTile>(find.byKey(const Key('place-home'))).value,
        true,
      );
      expect(r.bodies, isEmpty);
    },
  );
  testWidgets(
    'field errors preserve input and conflict reload requires explicit discard',
    (t) async {
      final r = ConfigurationFixture()
        ..current = TrainingCurrent.fromJson(currentJson());
      final session = ChangeNotifier();
      addTearDown(session.dispose);
      await t.pumpWidget(
        configShell(
          const Locale('en'),
          TrainingConfigurationPage(
            accountId: 'owner',
            currentAccountId: () => 'owner',
            sessionChanges: session,
            repository: r,
          ),
        ),
      );
      await t.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await reach(t, find.byKey(const Key('config-next')));
        await t.tap(find.byKey(const Key('config-next')));
        await t.pumpAndSettle();
      }
      await t.ensureVisible(find.byKey(const Key('config-timezone')));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('config-timezone')),
        'America/Fixture',
      );
      await t.pumpAndSettle();
      await reach(t, find.byKey(const Key('config-next')));
      await t.tap(find.byKey(const Key('config-next')));
      await t.pumpAndSettle();
      r.error = const TrainingFailure(
        'invalid_training_configuration',
        fields: {'configuration.timezone': 'invalid_timezone'},
      );
      await reach(t, find.byKey(const Key('config-confirm')));
      await t.tap(find.byKey(const Key('config-confirm')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('config-timezone')), findsOneWidget);
      expect(find.text('America/Fixture'), findsOneWidget);
      expect(
        find.text(
          'Check the time zone: UTC, an offset up to 14:00 or a recognized zone.',
        ),
        findsOneWidget,
      );
      await t.ensureVisible(find.byKey(const Key('config-timezone')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('config-timezone')), 'UTC');
      await t.pumpAndSettle();
      await reach(t, find.byKey(const Key('config-next')));
      await t.tap(find.byKey(const Key('config-next')));
      await t.pumpAndSettle();
      r.error = const TrainingFailure('training_configuration_conflict');
      await reach(t, find.byKey(const Key('config-confirm')));
      await t.tap(find.byKey(const Key('config-confirm')));
      await t.pumpAndSettle();
      final remote = configFixture()..['timezone'] = '+02:00';
      r.error = null;
      r.current = TrainingCurrent.fromJson(
        currentJson(revision: 4, configuration: remote),
      );
      await reach(t, find.text('Reload saved setup'), delta: -200);
      await t.tap(find.text('Reload saved setup'));
      await t.pumpAndSettle();
      await t.tap(find.text('Keep editing'));
      await t.pumpAndSettle();
      expect(r.reads, 1);
      await t.tap(find.text('Reload saved setup'));
      await t.pumpAndSettle();
      await t.tap(find.text('Reload saved setup').last);
      await t.pumpAndSettle();
      expect(r.reads, 2);
      for (var i = 0; i < 2; i++) {
        await reach(t, find.byKey(const Key('config-next')));
        await t.tap(find.byKey(const Key('config-next')));
        await t.pumpAndSettle();
      }
      expect(find.text('+02:00'), findsOneWidget);
      expect(find.text('America/Fixture'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
