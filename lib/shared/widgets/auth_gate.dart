import 'package:trainforge/core/l10n/localized_context.dart';
import 'package:trainforge/core/motion/app_motion.dart';
import 'startup_page.dart';
import 'package:trainforge/features/nutrition/domain/nutrition.dart';
import 'package:flutter/material.dart';
import 'package:trainforge/composition/app_dependency_scope.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/features/auth/presentation/pages/auth_page.dart';
import 'product_shell.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/legal/presentation/legal_pages.dart';
import 'package:trainforge/features/onboarding/onboarding_page.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';

class AuthGate extends StatefulWidget {
  final AuthController? controller;
  final NutritionRepository? nutritionRepository;
  final LegalController? legal;
  final OnboardingController? onboarding;
  const AuthGate({
    super.key,
    this.controller,
    this.nutritionRepository,
    this.legal,
    this.onboarding,
  });
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthController controller;
  late final LegalController legal = widget.legal ?? LegalController();
  late final OnboardingController onboarding =
      widget.onboarding ?? OnboardingController();
  String? accountId;
  @override
  void initState() {
    super.initState();
    controller =
        widget.controller ??
        AuthController(
          AppDependencyScope.read(context).createSessionRepository(),
        );
    accountId = controller.profile?.id;
    controller.addListener(accountChanged);
    controller.restore();
  }

  void accountChanged() {
    final next = controller.profile?.id;
    if (next == accountId) return;
    final previous = accountId;
    accountId = next;
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(accountChanged);
    if (widget.controller == null) controller.dispose();
    if (widget.legal == null) legal.dispose();
    if (widget.onboarding == null) onboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([controller, legal, onboarding]),
    builder: (context, _) {
      final profile = controller.profile;
      // Only session restoration covers the screen; sign-in keeps the entry visible.
      if (controller.restoring && profile == null) {
        return StartupPage(label: context.l10n.restoringSession);
      }
      if (profile == null) {
        // No fade: the entry continues the splash on the same green canvas.
        return LegalScope(
          controller: legal,
          child: AuthPage(
            key: const ValueKey('signed-out'),
            controller: controller,
          ),
        );
      }
      // Terms, Privacy and health consent belong to the account: visitors keep
      // everything on the device and never reach this gate.
      if (!legal.accountLoaded(profile.id)) {
        final id = profile.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) legal.loadAccount(id);
        });
        return StartupPage(label: context.l10n.restoringSession);
      }
      if (legal.needsTerms(profile.id)) {
        return LegalConsentPage(
          key: ValueKey('legal-${profile.id}'),
          controller: legal,
          accountId: profile.id,
          onDeleteAccount: controller.logout,
        );
      }
      if (legal.healthGranted(profile.id) == null) {
        return HealthConsentPage(
          key: ValueKey('health-${profile.id}'),
          controller: legal,
          accountId: profile.id,
        );
      }
      // First questions: once per account on this device, all optional.
      if (!onboarding.loaded(profile.id)) {
        final id = profile.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) onboarding.load(id);
        });
        return StartupPage(label: context.l10n.restoringSession);
      }
      if (onboarding.profile(profile.id)?.completed != true) {
        return OnboardingPage(
          key: ValueKey('onboarding-${profile.id}'),
          initial: onboarding.profile(profile.id),
          askBody: legal.healthGranted(profile.id) == true,
          onDone: (answers) => onboarding.save(profile.id, answers),
        );
      }
      return LegalScope(
        controller: legal,
        child: OnboardingScope(
          controller: onboarding,
          accountId: profile.id,
          child: AppAppear(
            key: ValueKey(profile.id),
            child: ProductShell(
              key: ValueKey(profile.id),
              controller: controller,
              nutritionRepository: widget.nutritionRepository,
            ),
          ),
        ),
      );
    },
  );
}
