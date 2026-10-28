import 'package:trainforge/core/l10n/localized_context.dart';
import 'evaluation_guide_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:trainforge/features/catalog/domain/catalog_entry.dart';
import 'package:trainforge/features/catalog/presentation/catalog_controller.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'figma_components.dart';

class PlansOverview extends StatefulWidget {
  final CatalogController? controller;
  final VoidCallback? configure;
  const PlansOverview({super.key, this.controller, this.configure});
  @override
  State<PlansOverview> createState() => _PlansOverviewState();
}

class _PlansOverviewState extends State<PlansOverview> {
  late final CatalogController controller;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        CatalogController(
          AppDependencyScope.read(context).createCatalogRepository(),
        );
    controller.load(filters: CatalogFilters(kind: 'programs'));
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  void library({String kind = 'movements'}) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => CatalogPage(initialFilters: CatalogFilters(kind: kind)),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => FigmaContent(
      title: context.l10n.findMovement,
      subtitle: context.l10n.atYourPace,
      children: [
        Material(
          color: context.tf.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: library,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.searchUpper,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.tf.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    context.l10n.movementSearchHint,
                    style: TextStyle(fontSize: 15, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.busy) AppProgress(label: context.l10n.loadingPrograms),
        if (controller.error != null) ...[
          Text(context.l10n.programsUnconfirmed),
          OutlinedButton(
            onPressed: () => controller.load(),
            child: Text(context.l10n.retry),
          ),
        ] else if (!controller.busy)
          FigmaActionCard(
            title: controller.facets?.programCount == 0
                ? context.l10n.programsUnavailable
                : context.l10n.browsePrograms,
            subtitle: controller.facets?.programCount == 0
                ? context.l10n.noPracticeProgram
                : context.l10n.viewRequirements,
            asset: 'plan',
            color: context.tf.accent,
            onTap: () => library(kind: 'programs'),
          ),
        FigmaActionCard(
          title: context.l10n.exploreModalities,
          subtitle: context.l10n.referenceLibrary,
          asset: 'activity',
          color: context.tf.blue,
          onTap: library,
        ),
        FigmaActionCard(
          title: context.l10n.createMyPlan,
          subtitle: widget.configure == null
              ? context.l10n.organizeWeek
              : context.l10n.trainingConfiguration,
          asset: 'plus',
          onTap:
              widget.configure ??
              () => showAvailability(
                context,
                context.l10n.createMyPlan,
                context.l10n.compositionUnavailable,
              ),
        ),
        FigmaActionCard(
          title: context.l10n.helpStart,
          subtitle: context.l10n.audiencesEnvironments,
          asset: 'spark',
          color: context.tf.pink,
          onTap: () =>
              openEvaluationGuide(context, EvaluationTopic.firstAccess),
        ),
      ],
    ),
  );
}
