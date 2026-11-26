import 'package:trainforge/features/onboarding/onboarding_profile.dart';

/// Existing flows start after the first questions; onboarding tests use their own store.
class CompletedOnboardingStore implements OnboardingStore {
  @override
  Future<OnboardingProfile?> read(String accountId) async => OnboardingProfile(
    places: const {'casa'},
    confidence: 'iniciante',
    completedAt: DateTime.utc(2026, 11, 25),
  );
  @override
  Future<void> write(String accountId, OnboardingProfile? profile) async {}
}
