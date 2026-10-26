import 'package:flutter/widgets.dart';
import 'package:trainforge/core/l10n/localized_context.dart';

/// Translate only sanitized controller messages; keep the effective API policy verbatim.
String localizedPrivacyFeedback(
  BuildContext context,
  String message,
) => switch (message) {
  "Digite EXCLUIR MINHA CONTA para confirmar." =>
    context.l10n.privacyConfirmPhrase,
  "Confirme sua conta com Google novamente para autorizar a exclusão." =>
    context.l10n.privacyRecentLogin,
  "Sua sessão precisa ser confirmada. Entre novamente com Google." =>
    context.l10n.privacySessionConfirm,
  "A confirmação expirou ou não pertence a esta sessão. Solicite uma nova confirmação." =>
    context.l10n.privacyIntentExpired,
  "A conta já foi excluída. A limpeza local permanece pendente." =>
    context.l10n.privacyCleanupPending,
  "Não foi possível confirmar a exclusão. Verifique a conexão e tente novamente." =>
    context.l10n.privacyDeletionUnconfirmed,
  "Não foi possível consultar os dados. Verifique a conexão e tente novamente." =>
    context.l10n.privacyQueryFailed,
  "Não foi possível concluir. Tente novamente." =>
    context.l10n.privacyActionFailed,
  'Muitas solicitações. Aguarde um minuto e tente novamente.' =>
    context.l10n.rateLimited,
  _ => context.l10n.privacyActionFailed,
};
