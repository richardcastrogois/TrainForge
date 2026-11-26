import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../domain/activity_repository.dart';
import '../domain/activity_session.dart';
import 'activity_controller.dart';

/// A tab body: selection stays inside the page and never creates a session from
/// navigation. Every mutation follows an explicit action by the current owner.
class ActivityPage extends StatefulWidget {
  final ActivityRepository repository;
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable? sessionChanges;
  final VoidCallback? configure, openCatalog;
  const ActivityPage({
    super.key,
    required this.repository,
    required this.accountId,
    required this.currentAccountId,
    this.sessionChanges,
    this.configure,
    this.openCatalog,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with WidgetsBindingObserver {
  late final ActivityController controller;
  Timer? clock;
  bool _visible = true;
  String? _editingSet;
  final _drafts = <String, _ActivitySetDraft>{};

  @override
  void initState() {
    super.initState();
    controller = ActivityController(
      repository: widget.repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
    )..addListener(changed);
    widget.sessionChanges?.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    controller.load();
    // Display only: this clock never records a set, changes state or ends a session.
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          _visible &&
          controller.active &&
          controller.selected?.snapshot.state == ActivityState.started) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
  }

  void changed() {
    if (mounted) setState(() {});
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active) {
      _editingSet = null;
      _clearDrafts();
    }
  }

  void _clearDrafts() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    _drafts.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || controller.locked) return;
    if (controller.selected == null) {
      controller.load();
    } else {
      controller.checkSession();
    }
  }

  @override
  void dispose() {
    clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionChanges?.removeListener(accountChanged);
    controller.removeListener(changed);
    controller.dispose();
    _clearDrafts();
    super.dispose();
  }

  String stateName(ActivityState state) => switch (state) {
    ActivityState.started => context.l10n.activityStateStarted,
    ActivityState.paused => context.l10n.activityStatePaused,
    ActivityState.partial => context.l10n.activityStatePartial,
    ActivityState.completed => context.l10n.activityStateCompleted,
    ActivityState.cancelled => context.l10n.activityStateCancelled,
  };

  String feedbackText(ActivityFeedback value) => switch (value) {
    ActivityFeedback.readFailed => context.l10n.activityReadFailed,
    ActivityFeedback.writeRejected => context.l10n.activityWriteRejected,
    ActivityFeedback.uncertain => context.l10n.activityUncertain,
    ActivityFeedback.conflict => context.l10n.activityConflict,
    ActivityFeedback.retryExpired => context.l10n.activityRetryExpired,
    ActivityFeedback.confirmed => context.l10n.activityConfirmed,
    ActivityFeedback.invalidSet => context.l10n.activityInvalidSet,
    ActivityFeedback.practiceUnavailable =>
      context.l10n.activityPracticeUnavailable,
  };

  Future<void> confirm(String action, String title) async {
    if (!controller.active || controller.locked) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(context.l10n.activityConfirmNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.activityConfirmAction),
          ),
        ],
      ),
    );
    if (accepted == true && mounted && controller.active) {
      await controller.command(action);
    }
  }

  Widget heading(String text) => Semantics(
    header: true,
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  Widget feedback() => FigmaSection(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(feedbackText(controller.feedback!)),
        ),
        if (controller.uncertain) ...[
          const SizedBox(height: 8),
          Text(context.l10n.activityPendingExit),
          const SizedBox(height: 8),
          if (!controller.needsReconciliation)
            FilledButton(
              onPressed: controller.busy ? null : controller.retry,
              child: Text(context.l10n.retryConfirmation),
            ),
          OutlinedButton(
            onPressed: controller.busy || controller.detailLoading
                ? null
                : controller.checkSession,
            child: Text(context.l10n.activityCheckSession),
          ),
        ] else if (controller.feedback == ActivityFeedback.readFailed ||
            controller.needsReconciliation) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.detailLoading || controller.busy
                ? null
                : controller.selected == null
                ? controller.load
                : controller.checkSession,
            child: Text(context.l10n.retry),
          ),
        ],
      ],
    ),
  );

  List<Widget> feedRows() {
    final value = controller.feed;
    return [
      Text(
        context.l10n.activity,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      Text(context.l10n.activitySessionIntro),
      if (controller.loading) AppProgress(label: context.l10n.loadingRecords),
      if (controller.feedback != null) feedback(),
      if (value != null) ...[
        heading(context.l10n.activityUpcoming),
        if (value.upcoming.isEmpty)
          FigmaSection(child: Text(context.l10n.activityEmptyUpcoming)),
        for (final occurrence in value.upcoming)
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading(occurrence.title),
                const SizedBox(height: 8),
                Text(
                  context.displayTimestamp(
                    occurrence.plannedFor.toIso8601String(),
                  ),
                ),
                const SizedBox(height: 8),
                if (!occurrence.practiceAvailable)
                  Text(context.l10n.activityPracticeUnavailable),
                FilledButton(
                  onPressed: controller.locked || !occurrence.practiceAvailable
                      ? null
                      : () => controller.start(occurrence),
                  child: Text(context.l10n.activityStartSession),
                ),
              ],
            ),
          ),
        heading(context.l10n.activityRecent),
        if (value.sessions.isEmpty)
          FigmaSection(child: Text(context.l10n.activityEmptyHistory)),
        for (final session in value.sessions)
          FigmaSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading(session.title),
                const SizedBox(height: 8),
                Text(stateName(session.snapshot.state)),
                Text(
                  context.displayTimestamp(
                    session.snapshot.startedAt.toIso8601String(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: controller.locked
                      ? null
                      : () {
                          _editingSet = null;
                          controller.open(session.snapshot.id);
                        },
                  child: Text(context.l10n.activityOpenSession),
                ),
              ],
            ),
          ),
        if (!value.complete) Text(context.l10n.activityPartialFeed),
        if (widget.configure != null)
          OutlinedButton(
            onPressed: controller.locked ? null : widget.configure,
            child: Text(context.l10n.trainingConfiguration),
          ),
        if (widget.openCatalog != null)
          TextButton(
            onPressed: controller.locked ? null : widget.openCatalog,
            child: Text(context.l10n.publicCatalog),
          ),
      ],
    ];
  }

  List<Widget> detailHeader(ActivityDetail detail) {
    final snapshot = detail.snapshot;
    final time = snapshot.elapsedAt(DateTime.now().toUtc());
    return [
      TextButton.icon(
        onPressed: controller.locked
            ? null
            : () {
                _editingSet = null;
                controller.backToFeed();
              },
        icon: const Icon(Icons.arrow_back),
        label: Text(context.l10n.activityBackToFeed),
      ),
      Text(detail.title, style: Theme.of(context).textTheme.headlineLarge),
      FigmaSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading(stateName(snapshot.state)),
            const SizedBox(height: 8),
            Text(
              '${context.l10n.activityRecordedSets}: '
              '${snapshot.sets.length}/${snapshot.plannedSets}',
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.state == ActivityState.started
                  ? context.l10n.activityEstimatedTime
                  : context.l10n.activityConfirmedTime,
            ),
            Text(
              elapsedText(time),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              context.displayTimestamp(snapshot.lastEventAt.toIso8601String()),
            ),
          ],
        ),
      ),
      if (!detail.practiceAvailable)
        Text(context.l10n.activityPracticeUnavailable),
      if (controller.busy) AppProgress(label: context.l10n.confirming),
      if (controller.feedback != null) feedback(),
      if (snapshot.isOpen) ...[
        if (snapshot.canPause)
          OutlinedButton(
            onPressed: controller.canPause
                ? () => controller.command('pause')
                : null,
            child: Text(context.l10n.activityPauseSession),
          ),
        if (snapshot.canResume)
          FilledButton(
            onPressed: controller.canResume
                ? () => controller.command('resume')
                : null,
            child: Text(context.l10n.activityResumeSession),
          ),
        if (snapshot.canComplete)
          FilledButton(
            onPressed: controller.canComplete
                ? () =>
                      confirm('complete', context.l10n.activityCompleteSession)
                : null,
            child: Text(context.l10n.activityCompleteSession),
          ),
        OutlinedButton(
          onPressed: controller.canEnd
              ? () => confirm('partial', context.l10n.activityPartialSession)
              : null,
          child: Text(context.l10n.activityPartialSession),
        ),
        TextButton(
          onPressed: controller.canEnd
              ? () => confirm('cancel', context.l10n.activityCancelSession)
              : null,
          child: Text(context.l10n.activityCancelSession),
        ),
      ],
      heading(context.l10n.activityPrescription),
    ];
  }

  List<Widget> itemRows(ActivityDetail detail) {
    final snapshot = detail.snapshot;
    final recorded = {
      for (final set in snapshot.sets) '${set.position}/${set.number}': set,
    };
    final rows = <Widget>[];
    for (final item in snapshot.items) {
      rows.add(heading(detail.titleFor(item) ?? item.movementId));
      for (var index = 0; index < item.targets.length; index++) {
        final number = index + 1;
        final rowKey = '${snapshot.id}/${item.position}/$number';
        final done = recorded['${item.position}/$number'];
        rows.add(
          FigmaSection(
            key: ValueKey('activity-set-${item.position}-$number'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${context.l10n.activitySet} $number',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${context.l10n.activityPlanned}: '
                  '${targetText(context, item.targets[index])}',
                ),
                if (done != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.activityRecorded}: '
                    '${targetText(context, done.actual)}'
                    '${done.loadKg == null ? '' : ' · ${context.displayDecimal(done.loadKg!)} kg'}',
                  ),
                ] else if (snapshot.isOpen) ...[
                  const SizedBox(height: 8),
                  if (_editingSet == rowKey)
                    _ActivitySetForm(
                      key: ValueKey(rowKey),
                      draft: _drafts[rowKey]!,
                      enabled: controller.canRecord,
                      duration: item.mode == 'duration',
                      onSubmit: (measurement, kg) => controller.recordSet(
                        position: item.position,
                        number: number,
                        measurement: measurement,
                        loadKg: kg,
                      ),
                    )
                  else
                    OutlinedButton(
                      key: ValueKey('activity-record-${item.position}-$number'),
                      onPressed: controller.canRecord
                          ? () => setState(() {
                              _drafts.putIfAbsent(
                                rowKey,
                                _ActivitySetDraft.new,
                              );
                              _editingSet = rowKey;
                            })
                          : null,
                      child: Text(context.l10n.activityRecordSet),
                    ),
                ],
              ],
            ),
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.active) return const SizedBox.shrink();
    final detail = controller.selected;
    final rows = detail == null
        ? feedRows()
        : [...detailHeader(detail), ...itemRows(detail)];
    if (controller.detailLoading) {
      rows.insert(0, AppProgress(label: context.l10n.loadingDetail));
    }
    return RefreshIndicator(
      onRefresh: () async {
        if (controller.locked) return;
        if (controller.selected == null) {
          await controller.load();
        } else {
          await controller.checkSession();
        }
      },
      child: ListView.builder(
        key: ValueKey(detail?.snapshot.id ?? 'activity-feed'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: rows[index],
        ),
      ),
    );
  }
}

String elapsedText(Duration value) {
  final seconds = value.inSeconds < 0 ? 0 : value.inSeconds;
  return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
      '${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}

String targetText(BuildContext context, ActivityTarget target) {
  if (target.repetitions != null) return '${target.repetitions}';
  final milliseconds = target.durationMilliseconds!;
  final remainder = milliseconds % 1000;
  final seconds =
      '${milliseconds ~/ 1000}'
      '${remainder == 0 ? '' : '.${remainder.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}'}';
  return '${context.displayDecimal(seconds)} s';
}

class _ActivitySetForm extends StatefulWidget {
  final bool enabled, duration;
  final _ActivitySetDraft draft;
  final Future<void> Function(String measurement, String kg) onSubmit;
  const _ActivitySetForm({
    super.key,
    required this.enabled,
    required this.duration,
    required this.draft,
    required this.onSubmit,
  });
  @override
  State<_ActivitySetForm> createState() => _ActivitySetFormState();
}

class _ActivitySetFormState extends State<_ActivitySetForm> {
  final form = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.duration
              ? context.l10n.activityDurationSeconds
              : context.l10n.activityRepetitions,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.duration
              ? context.l10n.activityDurationSeconds
              : context.l10n.activityRepetitions,
          child: TextFormField(
            key: const ValueKey('activity-measurement'),
            controller: widget.draft.measurement,
            enabled: widget.enabled,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.duration,
            ),
            decoration: const InputDecoration(errorMaxLines: 4),
            validator: (raw) {
              final value = (raw ?? '').trim().replaceAll(',', '.');
              var valid = widget.duration
                  ? RegExp(r'^\d{1,5}(\.\d{1,3})?$').hasMatch(value)
                  : RegExp(r'^\d{1,5}$').hasMatch(value) &&
                        int.parse(value) <= 10000;
              if (valid && widget.duration) {
                final parts = value.split('.');
                final milliseconds =
                    int.parse(parts.first) * 1000 +
                    (parts.length == 1
                        ? 0
                        : int.parse(parts.last.padRight(3, '0')));
                valid = milliseconds <= 86400000;
              }
              return valid ? null : context.l10n.activityInvalidSet;
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(context.l10n.activityLoadKg),
        const SizedBox(height: 8),
        Semantics(
          label: context.l10n.activityLoadKg,
          child: TextFormField(
            key: const ValueKey('activity-load-kg'),
            controller: widget.draft.kg,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(errorMaxLines: 4),
            validator: (raw) =>
                (raw ?? '').trim().isEmpty ||
                    RegExp(r'^\d{1,6}([.,]\d{1,3})?$').hasMatch(raw!.trim())
                ? null
                : context.l10n.activityInvalidSet,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: widget.enabled
              ? () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (form.currentState!.validate()) {
                    widget.onSubmit(
                      widget.draft.measurement.text,
                      widget.draft.kg.text,
                    );
                  }
                }
              : null,
          child: Text(context.l10n.activityRecordSet),
        ),
      ],
    ),
  );
}

/// Kept by the page rather than a lazy row: scrolling and status banners must
/// not discard an actual value while a response is still unknown.
class _ActivitySetDraft {
  final measurement = TextEditingController();
  final kg = TextEditingController();
  void dispose() {
    measurement.dispose();
    kg.dispose();
  }
}
