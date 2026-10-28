import 'package:trainforge/core/l10n/feedback_localization.dart';
import 'package:trainforge/core/l10n/language_page.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import 'evaluation_guide_page.dart';
import 'package:trainforge/core/theme/appearance_page.dart';
import 'package:trainforge/shared/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/privacy/presentation/privacy_page.dart';
import 'figma_components.dart';

class AccountPage extends StatelessWidget {
  final AuthController controller;
  final VoidCallback? configure;
  const AccountPage({super.key, required this.controller, this.configure});
  void privacy(BuildContext context) => Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => PrivacyPage(
        authenticated: true,
        reauthenticate: () async {
          await controller.login();
          if (controller.message != null) {
            throw StateError('Confirmação indisponível');
          }
        },
        currentAccountId: () => controller.profile?.id,
        onDeleted: (erasedId) async {
          controller.accountErased(erasedId);
          await controller.restore();
        },
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final profile = controller.profile;
      if (profile == null) return const SizedBox.shrink();
      return Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  FigmaHeader(name: profile.name),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        FigmaBack(),
                        Text(
                          context.l10n.yourSpace,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        SizedBox(height: 12),
                        Text(
                          context.l10n.connected,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tf.muted,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.tf.accent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox.square(
                                dimension: 48,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/figma/profile-user.svg',
                                    excludeFromSemantics: true,
                                    colorFilter:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? ColorFilter.mode(
                                            context.tf.primary,
                                            BlendMode.srcIn,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      profile.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.tf.primary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.accountData,
                          subtitle: context.l10n.identityHint,
                          asset: 'user',
                          onTap: () => openEvaluationGuide(
                            context,
                            EvaluationTopic.profile,
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.trainingConfiguration,
                          subtitle: context.l10n.equipmentDays,
                          asset: 'plan',
                          onTap:
                              configure ??
                              () => openEvaluationGuide(
                                context,
                                EvaluationTopic.firstAccess,
                              ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.preferences,
                          subtitle: context.l10n.preferenceHint,
                          asset: 'settings',
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppearancePage(),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.language,
                          subtitle: context.l10n.languageNames,
                          asset: 'settings',
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LanguagePage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.devicesPermissions,
                          subtitle: context.l10n.devicesHint,
                          asset: 'activity',
                          color: context.tf.blue,
                          onTap: () => openEvaluationGuide(
                            context,
                            EvaluationTopic.devices,
                          ),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.privacy,
                          subtitle: context.l10n.privacyHint,
                          asset: 'heart',
                          color: context.tf.soft,
                          onTap: () => privacy(context),
                        ),
                        SizedBox(height: 12),
                        FigmaActionCard(
                          title: context.l10n.helpEvaluation,
                          subtitle: context.l10n.helpHint,
                          asset: 'plan',
                          onTap: () => openEvaluationGuide(
                            context,
                            EvaluationTopic.help,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (controller.busy)
                          AppProgress(label: context.l10n.confirmingSession),
                        if (controller.message != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              controller.feedback!.localized(context),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.busy
                                ? null
                                : controller.retry,
                            child: Text(context.l10n.retry),
                          ),
                        ],
                        OutlinedButton(
                          onPressed: controller.busy
                              ? null
                              : controller.restore,
                          child: Text(context.l10n.confirmConnection),
                        ),
                        SizedBox(height: 12),
                        FilledButton(
                          onPressed: controller.busy ? null : controller.logout,
                          child: Text(context.l10n.signOut),
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
    },
  );
}
