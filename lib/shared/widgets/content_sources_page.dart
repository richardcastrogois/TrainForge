import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/nutrition/presentation/nutrition_page.dart';
import 'figma_components.dart';

class ContentSourcesPage extends StatelessWidget {
  final AuthController? controller;
  const ContentSourcesPage({super.key, this.controller});
  void open(BuildContext context, Widget page) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => page));
  @override
  Widget build(BuildContext context) => FigmaRouteFrame(
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        FigmaPageHeading(
          title: context.l10n.sourcesSettings,
          subtitle: context.l10n.sourcesExplanation,
        ),
        FigmaActionCard(
          title: context.l10n.movements,
          subtitle: context.l10n.sourceLicense,
          asset: 'plan',
          onTap: () => open(context, const CatalogPage(evidenceMode: true)),
        ),
        const SizedBox(height: 12),
        FigmaActionCard(
          title: context.l10n.foodReferences,
          subtitle: context.l10n.sourceLicense,
          asset: 'plan',
          onTap: () => open(context, const FoodPage(evidenceMode: true)),
        ),
        const SizedBox(height: 12),
        if (controller?.profile != null)
          FigmaActionCard(
            title: context.l10n.preservedCalculation,
            subtitle: context.l10n.privateDiaryUpper,
            asset: 'plan',
            onTap: () => open(
              context,
              NutritionPage(
                accountId: controller!.profile!.id,
                currentAccountId: () => controller!.profile?.id,
                sessionChanges: controller!,
                evidenceMode: true,
              ),
            ),
          ),
        const SizedBox(height: 12),
        FigmaSection(child: Text(context.l10n.translationsExplanation)),
      ],
    ),
  );
}
