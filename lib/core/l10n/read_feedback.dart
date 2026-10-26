import 'package:flutter/widgets.dart';
import 'localized_context.dart';

/// Only controlled controller messages are passed here, never source names or text.
String localizedReadFeedback(
  BuildContext context,
  String message,
) => switch (message) {
  'A busca ficou longa. Use uma parte do nome original.' =>
    context.l10n.foodSearchTooLong,
  'Não foi possível consultar os alimentos. Verifique a conexão e tente novamente.' =>
    context.l10n.foodQueryFailed,
  'Não foi possível carregar mais alimentos. Tente novamente.' =>
    context.l10n.foodMoreFailed,
  'Não foi possível consultar a biblioteca. Verifique a conexão e tente novamente.' =>
    context.l10n.catalogQueryFailed,
  'Não foi possível carregar a próxima página. Tente novamente.' =>
    context.l10n.catalogMoreFailed,
  _ => context.l10n.actionFailed,
};
