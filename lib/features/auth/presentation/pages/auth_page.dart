import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/language_page.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/shared/widgets/evaluation_guide_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/shared/widgets/auth_gate.dart';
import 'package:trainforge/shared/widgets/figma_components.dart';
import '../auth_controller.dart';

class AuthPage extends StatelessWidget {
  final AuthController? _controller;
  const AuthPage({super.key, AuthController? controller})
    : _controller = controller;
  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return AuthGate();
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                FigmaHeader(),
                Expanded(
                  child: FigmaContent(
                    title: context.l10n.welcome,
                    subtitle: context.l10n.welcomeHint,
                    children: [
                      if (controller.busy)
                        AppProgress(label: context.l10n.waitingGoogle),
                      OutlinedButton(
                        onPressed: controller.busy ? null : controller.login,
                        child: Text(
                          controller.busy
                              ? context.l10n.connecting
                              : context.l10n.signInGoogle,
                        ),
                      ),
                      Material(
                        color: context.tf.accent,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          onTap: controller.busy ? null : controller.login,
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.noAccount,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  context.l10n.createGoogle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.tf.cardMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        context.l10n.googleOnly,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: context.tf.muted,
                        ),
                      ),
                      if (controller.message != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(controller.feedback!.localized(context)),
                        ),
                        if (controller.failedAction != null)
                          TextButton(
                            onPressed: controller.busy
                                ? null
                                : controller.retry,
                            child: Text(context.l10n.retry),
                          ),
                      ],
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => openEvaluationGuide(
                                context,
                                EvaluationTopic.firstAccess,
                              ),
                        child: Text(context.l10n.firstAccess),
                      ),
                      Text(
                        context.l10n.exploreFirst,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CatalogPage(),
                                ),
                              ),
                        child: Text(context.l10n.publicCatalog),
                      ),
                      OutlinedButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(builder: (_) => FoodPage()),
                              ),
                        child: Text(context.l10n.publicFood),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AppearancePage(),
                                ),
                              ),
                        child: Text(context.l10n.appearance),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LanguagePage(),
                                ),
                              ),
                        child: Text(context.l10n.language),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PrivacyPage(),
                                ),
                              ),
                        child: Text(context.l10n.privacy),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
