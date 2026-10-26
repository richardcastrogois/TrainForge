import 'package:flutter/widgets.dart';
import 'package:trainforge/core/l10n/localized_context.dart';

/// Only controller-owned, sanitized messages are translated; never source data.
String localizedNutritionFeedback(
  BuildContext context,
  String message,
) => switch (message) {
  "Informe quantidade e escolha se foi medida ou estimada." =>
    context.l10n.quantityEvidenceRequired,
  "A conta mudou. Volte à entrada antes de continuar." =>
    context.l10n.nutritionAccountChanged,
  "Confira quantidade, unidade, data, preparo e campos informados." =>
    context.l10n.nutritionCheckFields,
  "O alimento ou registro está indisponível. Atualize a consulta." =>
    context.l10n.nutritionUnavailable,
  "O registro ou a conta mudou. Atualize o histórico antes de corrigir." =>
    context.l10n.nutritionConflict,
  "Não foi possível confirmar a ação. Confira a conexão e tente novamente. Repetir a mesma ação não duplica o registro." =>
    context.l10n.nutritionRetrySafe,
  "Não foi possível confirmar a ação. Tente novamente." =>
    context.l10n.nutritionActionFailed,
  'Sua sessão expirou. Entre novamente com Google.' =>
    context.l10n.sessionExpired,
  'Muitas tentativas. Aguarde um minuto e tente novamente.' =>
    context.l10n.rateLimited,
  _ => context.l10n.nutritionActionFailed,
};
