import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'package:trainforge/features/training_library/presentation/training_library_page.dart';

import 'figma_components.dart';
import 'shell_labels.dart';

/// Treinos tab: the library with place (modality) and level chips, already
/// set from the first answers. Secondary tools stay at the end.
class WorkoutsOverview extends StatelessWidget {
  final VoidCallback openCatalog;
  final VoidCallback? configure;
  final Future<String> Function()? read;
  const WorkoutsOverview({
    super.key,
    required this.openCatalog,
    this.configure,
    this.read,
  });

  @override
  Widget build(BuildContext context) {
    String l(String k) => shellLabel(context, k);
    final profile = OnboardingScope.maybeOf(context)?.profile;
    final place = profile == null || profile.places.isEmpty
        ? null
        : OnboardingProfile.placeIds.firstWhere(profile.places.contains);
    final cell = place != null && profile?.confidence != null
        ? profile!.cellFor(place)
        : null;
    return FigmaContent(
      title: l('workoutsTitle'),
      subtitle: l('workoutsIntro'),
      children: [
        TrainingLibraryView(read: read, initialPlace: place, initialCell: cell),
        const SizedBox(height: 4),
        Text(
          l('moreOptions'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.tf.ink,
          ),
        ),
        FigmaActionCard(
          title: l('exploreMoves'),
          subtitle: l('exploreMovesHint'),
          asset: 'activity',
          color: context.tf.blue,
          onTap: openCatalog,
        ),
        if (configure != null)
          FigmaActionCard(
            title: l('myPlan'),
            subtitle: l('myPlanHint'),
            asset: 'plan',
            onTap: configure!,
          ),
      ],
    );
  }
}
