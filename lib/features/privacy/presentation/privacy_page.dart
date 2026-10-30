import 'package:trainforge/shared/widgets/content_sources_page.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'privacy_feedback.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'privacy_controller.dart';

class PrivacyPage extends StatefulWidget {
  final bool authenticated;
  final Future<void> Function()? reauthenticate;
  final Future<void> Function(String)? onDeleted;
  final String? Function()? currentAccountId;
  final PrivacyController? controller;
  const PrivacyPage({
    super.key,
    this.authenticated = false,
    this.reauthenticate,
    this.onDeleted,
    this.currentAccountId,
    this.controller,
  });
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final PrivacyController controller;
  final confirmation = TextEditingController();
  bool acknowledged = false;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        PrivacyController(
          AppDependencyScope.read(context).createPrivacyRepository(),
          afterDeletion: widget.onDeleted,
          currentAccountId: widget.currentAccountId,
        );
    controller.loadPolicy();
  }

  @override
  void dispose() {
    confirmation.dispose();
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final policy = controller.policy,
          export = controller.exportPage,
          erased = controller.erased;
      return PopScope(
        canPop: !controller.busy,
        child: FigmaRouteFrame(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                FigmaPageHeading(
                  title: context.l10n.privacy,
                  subtitle: context.l10n.privacyUpper,
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ContentSourcesPage(),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: Text(context.l10n.sourcesSettings),
                ),
                if (controller.busy)
                  AppProgress(label: context.l10n.processingData),
                if (controller.error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      localizedPrivacyFeedback(context, controller.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (erased != null) ...[
                  Text(
                    context.l10n.accountDeleted,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(erased.backupNotice),
                  Text(context.l10n.googleAccountKept),
                  if (erased.cleanupPending) ...[
                    Text(context.l10n.erasureLocalPending),
                    FilledButton(
                      onPressed: controller.busy
                          ? null
                          : controller.finishCleanup,
                      child: Text(context.l10n.finishLocalCleanup),
                    ),
                  ] else
                    FilledButton(
                      onPressed: controller.busy
                          ? null
                          : () => Navigator.maybePop(context),
                      child: Text(context.l10n.finish),
                    ),
                ] else ...[
                  Text(
                    context.l10n.dataControls,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(context.l10n.policyOriginalNotice),
                  if (policy == null && !controller.busy)
                    FilledButton(
                      onPressed: controller.loadPolicy,
                      child: Text(context.l10n.retryPolicy),
                    ),
                  if (policy != null) ...[
                    FigmaSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(policy.accountDeletion),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.backupsRecovery,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(policy.backupRetention),
                          Text(policy.restoreRequirement),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.erasureMinimum,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(policy.erasureLedger),
                          Text(policy.sessionRetention),
                          const SizedBox(height: 12),
                          Text(policy.otherServices),
                          Text(policy.futureStorage),
                          const SizedBox(height: 12),
                          Text(context.l10n.externalCopiesNotice),
                        ],
                      ),
                    ),
                    if (!widget.authenticated) ...[
                      const SizedBox(height: 20),
                      Text(context.l10n.signInPrivacy),
                    ] else ...[
                      const Divider(height: 32),
                      Text(
                        context.l10n.viewCopyData,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(context.l10n.exportPageNotice),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: controller.section,
                        itemHeight: null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.dataSection,
                        ),
                        items: policy.sections
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(sectionLabel(context, s)),
                              ),
                            )
                            .toList(),
                        onChanged: controller.busy
                            ? null
                            : (s) {
                                if (s != null) {
                                  controller.loadExport(section: s);
                                }
                              },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => controller.loadExport(),
                        child: Text(context.l10n.viewSection),
                      ),
                      if (export != null) ...[
                        Text(export.notice),
                        Text(context.l10n.currentPageOnly),
                        if (export.items.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(context.l10n.noSectionRecords),
                          )
                        else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(export.previewText),
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: controller.busy
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: export.jsonText),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              context.l10n.pageCopied,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: Text(context.l10n.copyJsonPage),
                            ),
                            if (export.cursor != null)
                              OutlinedButton(
                                onPressed: controller.busy
                                    ? null
                                    : () => controller.loadExport(next: true),
                                child: Text(context.l10n.nextPage),
                              ),
                          ],
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        context.l10n.deleteMyAccount,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(context.l10n.deleteAccountNotice),
                      if (widget.reauthenticate != null)
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.confirmAccount(
                                    widget.reauthenticate!,
                                  );
                                },
                          child: Text(context.l10n.confirmGoogleAgain),
                        ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: acknowledged,
                        onChanged: controller.busy
                            ? null
                            : (v) => setState(() => acknowledged = v ?? false),
                        title: Text(context.l10n.readDeletionLimits),
                      ),
                      if (controller.deletionIntent == null)
                        OutlinedButton(
                          onPressed: controller.busy || !acknowledged
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.requestDeletion();
                                },
                          child: Text(context.l10n.requestDeletionIntent),
                        )
                      else ...[
                        Text(context.l10n.temporaryDeletionNotice),
                        TextField(
                          controller: confirmation,
                          enabled: !controller.busy,
                          maxLength: 19,
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'EXCLUIR MINHA CONTA',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError,
                          ),
                          onPressed:
                              controller.busy ||
                                  !acknowledged ||
                                  confirmation.text != 'EXCLUIR MINHA CONTA'
                              ? null
                              : () => controller.erase(confirmation.text),
                          child: Text(context.l10n.deleteAccountData),
                        ),
                        TextButton(
                          onPressed: controller.busy
                              ? null
                              : () {
                                  confirmation.clear();
                                  controller.cancelDeletion();
                                },
                          child: Text(context.l10n.cancelDeletion),
                        ),
                      ],
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

String sectionLabel(BuildContext context, String section) => switch (section) {
  'account' => context.l10n.privacySectionAccount,
  'trainingConfigurations' => context.l10n.privacySectionTrainingConfigurations,
  'sessions' => context.l10n.privacySectionSessions,
  'enrollments' => context.l10n.privacySectionEnrollments,
  'occurrences' => context.l10n.privacySectionSchedule,
  'activitySessions' => context.l10n.privacySectionActivities,
  'activityEvents' => context.l10n.privacySectionEvents,
  'foods' => context.l10n.privacySectionFoods,
  'foodEntries' => context.l10n.privacySectionIntakes,
  'meals' => context.l10n.privacySectionMeals,
  'mealItems' => context.l10n.privacySectionMealItems,
  'mealVersions' => context.l10n.privacySectionMealVersions,
  _ => section,
};
