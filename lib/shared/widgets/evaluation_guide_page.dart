import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'figma_components.dart';
import 'flow_components.dart';

enum EvaluationTopic { firstAccess, activity, devices, profile, help }

/// Explains current capability boundaries; never collects a fake configuration.
class EvaluationGuidePage extends StatelessWidget {
  final EvaluationTopic topic;
  const EvaluationGuidePage({super.key, this.topic = EvaluationTopic.help});
  @override
  Widget build(BuildContext context) {
    final title = switch (topic) {
      EvaluationTopic.firstAccess => context.l10n.startingPoint,
      EvaluationTopic.activity => context.l10n.activityProgress,
      EvaluationTopic.devices => context.l10n.devicesPermissions,
      EvaluationTopic.profile => context.l10n.accountPreferences,
      EvaluationTopic.help => context.l10n.versionHelp,
    };
    return FigmaRouteFrame(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          FigmaPageHeading(
            title: title,
            subtitle: context.l10n.evaluationUpper,
          ),
          if (topic == EvaluationTopic.firstAccess) ...[
            FlowStatus(
              announce: false,
              title: context.l10n.exploreWithoutSetup,
              message: context.l10n.exploreWithoutSetupHint,
            ),
            FlowSectionTitle(context.l10n.setupNotAvailable),
            FigmaSection(child: Text(context.l10n.setupNotAvailableHint)),
            const SizedBox(height: 12),
            FigmaSection(child: Text(context.l10n.scopeCaregivers)),
          ],
          if (topic == EvaluationTopic.activity ||
              topic == EvaluationTopic.devices) ...[
            FlowStatus(
              announce: false,
              title: context.l10n.noActivityRecording,
              message: context.l10n.noActivityRecordingHint,
            ),
            FlowSectionTitle(context.l10n.permissionsDevices),
            FigmaSection(child: Text(context.l10n.permissionsDevicesHint)),
            FlowSectionTitle(context.l10n.historyProgress),
            FigmaSection(child: Text(context.l10n.historyProgressHint)),
          ],
          if (topic == EvaluationTopic.profile) ...[
            FlowStatus(
              announce: false,
              title: context.l10n.googleIdentity,
              message: context.l10n.googleIdentityHint,
            ),
            FlowSectionTitle(context.l10n.devicePreferences),
            FigmaSection(child: Text(context.l10n.devicePreferencesHint)),
          ],
          if (topic == EvaluationTopic.help) ...[
            FlowStatus(
              announce: false,
              title: context.l10n.whatToTest,
              message: context.l10n.whatToTestHint,
            ),
            FlowSectionTitle(context.l10n.faq),
            FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.whyOriginalNames,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.whyOriginalNamesHint),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.unknownMeansZero,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.unknownMeansZeroHint),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.libraryGuidesTraining,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.libraryGuidesTrainingHint),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.reportProblem,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(context.l10n.reportProblemHint),
                ],
              ),
            ),
            FlowSectionTitle(context.l10n.evaluationConditions),
            FigmaSection(child: Text(context.l10n.evaluationConditionsHint)),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
            child: Text(context.l10n.browseLibrary),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const FoodPage()),
            ),
            child: Text(context.l10n.browseFoods),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: Text(context.l10n.back),
          ),
        ],
      ),
    );
  }
}

void openEvaluationGuide(BuildContext context, EvaluationTopic topic) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => EvaluationGuidePage(topic: topic)),
  );
}
