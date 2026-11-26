import 'dart:async';
import 'package:trainforge/core/motion/app_motion.dart';
import 'package:trainforge/features/legal/legal_controller.dart';
import 'package:trainforge/features/onboarding/onboarding_profile.dart';
import 'support/legal_accepted_store.dart';
import 'support/onboarding_done_store.dart';

/// Repeating brand animations never settle; widget tests see the final frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppMotion.ambient = false;
  LegalController.defaultStore = AcceptedLegalConsentStore.new;
  OnboardingController.defaultStore = CompletedOnboardingStore.new;
  await testMain();
}
