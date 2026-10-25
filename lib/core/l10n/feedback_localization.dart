import 'package:flutter/widgets.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';
import 'package:trainforge/core/theme/appearance_controller.dart';
import 'localized_context.dart';

extension AuthFeedbackLocalization on AuthFeedback {
  String localized(BuildContext context) => switch (this) {
    AuthFeedback.sessionTimeout => context.l10n.sessionTimeout,
    AuthFeedback.googleConfiguration => context.l10n.googleConfiguration,
    AuthFeedback.authConfiguration => context.l10n.authConfiguration,
    AuthFeedback.sessionExpired => context.l10n.sessionExpired,
    AuthFeedback.rateLimited => context.l10n.rateLimited,
    AuthFeedback.authUnavailable => context.l10n.authUnavailable,
    AuthFeedback.signOutUnconfirmed => context.l10n.signOutUnconfirmed,
    AuthFeedback.signInFailed => context.l10n.signInFailed,
    AuthFeedback.sessionOffline => context.l10n.sessionOffline,
    AuthFeedback.actionFailed => context.l10n.actionFailed,
  };
}

extension AppearanceFeedbackLocalization on AppearanceFeedback {
  String localized(BuildContext context) => switch (this) {
    AppearanceFeedback.appearanceInvalid => context.l10n.appearanceInvalid,
    AppearanceFeedback.appearanceReadFailed =>
      context.l10n.appearanceReadFailed,
    AppearanceFeedback.appearanceSaveUncertain =>
      context.l10n.appearanceSaveUncertain,
    AppearanceFeedback.appearanceSaveFailed =>
      context.l10n.appearanceSaveFailed,
  };
}
