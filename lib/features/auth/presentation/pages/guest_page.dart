import 'package:flutter/material.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../auth_controller.dart';
import '../widgets/google_sign_in_button.dart';

/// Public, read-only areas available before signing in.
class GuestPage extends StatelessWidget {
  final AuthController controller;
  const GuestPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => FigmaRouteFrame(
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        FigmaPageHeading(
          title: context.l10n.guestTitle,
          subtitle: context.l10n.guestHint,
        ),
        FigmaActionCard(
          title: context.l10n.publicCatalog,
          subtitle: context.l10n.guestLibraryHint,
          asset: 'activity',
          color: context.tf.accent,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => CatalogPage()),
          ),
        ),
        const SizedBox(height: 12),
        FigmaActionCard(
          title: context.l10n.publicFood,
          subtitle: context.l10n.guestFoodHint,
          asset: 'food',
          color: context.tf.nutrition,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => FoodPage()),
          ),
        ),
        const SizedBox(height: 28),
        GoogleSignInButton(
          label: context.l10n.signInGoogle,
          // Return to the entry first so the signed-in shell is not left below this route.
          onPressed: () {
            Navigator.pop(context);
            controller.login();
          },
        ),
      ],
    ),
  );
}
