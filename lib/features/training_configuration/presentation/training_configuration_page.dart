import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart'
    show offsetZone;
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/shared/widgets/draft_guard.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/flow_components.dart';
import '../domain/training_configuration.dart';
import 'training_configuration_controller.dart';
import 'training_configuration_sections.dart';

void openTrainingConfiguration(
  BuildContext context,
  AuthController auth,
  TrainingConfigurationRepository repository,
) {
  final id = auth.profile?.id;
  if (id == null) return;
  Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => TrainingConfigurationPage(
        accountId: id,
        currentAccountId: () => auth.profile?.id,
        sessionChanges: auth,
        repository: repository,
      ),
    ),
  );
}

class TrainingConfigurationPage extends StatefulWidget {
  final String accountId;
  final String? Function() currentAccountId;
  final Listenable sessionChanges;
  final TrainingConfigurationRepository repository;
  const TrainingConfigurationPage({
    super.key,
    required this.accountId,
    required this.currentAccountId,
    required this.sessionChanges,
    required this.repository,
  });
  @override
  State<TrainingConfigurationPage> createState() =>
      _TrainingConfigurationPageState();
}

class _TrainingConfigurationPageState extends State<TrainingConfigurationPage>
    with WidgetsBindingObserver {
  late final TrainingConfigurationController controller;
  final guard = GlobalKey<DraftGuardState>();
  GlobalKey<FormState> form = GlobalKey<FormState>();
  final scroll = ScrollController();
  int step = 0, epoch = 0;
  bool saved = false;
  @override
  void initState() {
    super.initState();
    controller = TrainingConfigurationController(
      repository: widget.repository,
      accountId: widget.accountId,
      currentAccountId: widget.currentAccountId,
      timezone: offsetZone(DateTime.now()),
    );
    controller.addListener(changed);
    widget.sessionChanges.addListener(accountChanged);
    WidgetsBinding.instance.addObserver(this);
    controller.load();
  }

  void accountChanged() {
    controller.accountChanged();
    if (!controller.active && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void changed() {
    if (!mounted) return;
    if (epoch != controller.dataEpoch) {
      epoch = controller.dataEpoch;
      form = GlobalKey<FormState>();
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !controller.dirty &&
        !controller.saving &&
        !controller.uncertain) {
      controller.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.sessionChanges.removeListener(accountChanged);
    controller.removeListener(changed);
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  void go(int target) {
    if (!controller.editable) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => step = target);
    if (scroll.hasClients) scroll.jumpTo(0);
    if (target == 1 && controller.draft.resourceStatus == 'declared') {
      controller.loadOptions();
    }
  }

  bool validate() {
    final invalid = form.currentState?.validateGranularly() ?? {};
    if (invalid.isEmpty) return true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !invalid.first.mounted) return;
      Scrollable.ensureVisible(
        invalid.first.context,
        alignment: .12,
        duration: AppMotion.reduced(context)
            ? Duration.zero
            : AppMotion.duration,
      );
    });
    return false;
  }

  void next() {
    if (!controller.editable || !validate()) return;
    go(step + 1);
  }

  int issueStep(String path) => path.startsWith('configuration.resources')
      ? 1
      : path.startsWith('configuration.availability') ||
            path == 'configuration.timezone'
      ? 2
      : 0;
  Future<void> save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ok = await controller.save();
    if (!mounted) return;
    if (ok) {
      setState(() => saved = true);
      if (scroll.hasClients) scroll.jumpTo(0);
    } else if (controller.issues.isNotEmpty) {
      final targets = controller.issues.keys.map(issueStep).toList()..sort();
      go(targets.first);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) validate();
      });
    }
  }

  Future<void> reload() async {
    if (controller.dirty) {
      final accepted = await showDialog<bool>(
        context: context,
        animationStyle: AppMotion.style(context),
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(context.l10n.configReload),
          content: Text(context.l10n.configReloadNotice),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.continueEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.configReload),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    setState(() {
      saved = false;
      step = 0;
    });
    await controller.load();
  }

  String title() => switch (step) {
    0 => context.l10n.configPlaces,
    1 => context.l10n.configResources,
    2 => context.l10n.configAvailability,
    _ => context.l10n.configReview,
  };
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return DraftGuard(
      key: guard,
      dirty: c.dirty,
      busy: c.saving,
      uncertain: c.uncertain,
      uncertainMessage: context.l10n.configUncertain,
      uncertainLeaveLabel: context.l10n.configLeaveCheck,
      onStepBack: step > 0 && c.editable ? () => go(step - 1) : null,
      child: FigmaRouteFrame(
        body: Form(
          key: form,
          child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FigmaPageHeading(
                  title: context.l10n.trainingConfiguration,
                  subtitle: context.l10n.trainingConfigIntro,
                ),
                if (c.loading)
                  AppProgress(label: context.l10n.loadingQuery)
                else if (!c.ready)
                  FlowStatus(
                    title: context.l10n.queryUnavailable,
                    message: context.l10n.configUnavailable,
                    actionLabel: context.l10n.retry,
                    onAction: c.load,
                  )
                else ...[
                  Text(context.l10n.configStep(step + 1)),
                  FlowSectionTitle(title()),
                  if (c.error != null || c.uncertain)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FlowStatus(
                        title: context.l10n.requestUnconfirmed,
                        message: c.uncertain
                            ? context.l10n.configUncertain
                            : c.error!.code == 'training_configuration_conflict'
                            ? context.l10n.configConflict
                            : context.l10n.configUnavailable,
                        actionLabel: c.saving
                            ? null
                            : c.uncertain
                            ? context.l10n.retryConfirmation
                            : c.error!.code == 'training_configuration_conflict'
                            ? context.l10n.configReload
                            : null,
                        onAction: c.saving
                            ? null
                            : c.uncertain
                            ? save
                            : c.error!.code == 'training_configuration_conflict'
                            ? reload
                            : null,
                      ),
                    ),
                  TrainingConfigurationSections(
                    controller: c,
                    step: step,
                    edit: go,
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.trainingConfigNotice),
                  const SizedBox(height: 16),
                  if (c.saving)
                    AppProgress(label: context.l10n.confirming)
                  else if (step < 3)
                    FilledButton(
                      key: const Key('config-next'),
                      onPressed: c.editable ? next : null,
                      child: Text(context.l10n.configNext),
                    )
                  else if (saved && !c.dirty)
                    FlowStatus(
                      title: context.l10n.configSaved,
                      message: context.l10n.configSavedHint,
                    )
                  else
                    FilledButton(
                      key: const Key('config-confirm'),
                      onPressed: c.editable ? save : null,
                      child: Text(context.l10n.configConfirm),
                    ),
                  if (c.snapshot != null &&
                      !c.dirty &&
                      !c.saving &&
                      !c.uncertain)
                    FilledButton(
                      onPressed: () => guard.currentState!.complete(true),
                      child: Text(context.l10n.finish),
                    ),
                  if (step > 0)
                    TextButton(
                      onPressed: c.editable ? () => go(step - 1) : null,
                      child: Text(context.l10n.back),
                    ),
                ],
                TextButton(
                  onPressed: c.saving
                      ? null
                      : () {
                          if (c.dirty || c.uncertain) {
                            guard.currentState!.ask();
                          } else {
                            guard.currentState!.complete(null);
                          }
                        },
                  child: Text(context.l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
