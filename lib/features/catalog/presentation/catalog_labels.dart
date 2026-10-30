import 'package:flutter/widgets.dart';
import 'package:trainforge/core/l10n/localized_context.dart';
import '../domain/catalog_entry.dart';
import '../domain/catalog_names.dart';

String localizedCatalogTitle(BuildContext context, CatalogEntry entry) {
  final name = catalogDisplayNames[entry.id];
  if (name == null ||
      name.version != entry.versionId ||
      name.original != entry.title) {
    return entry.title ?? context.l10n.titleNotProvided;
  }
  return name.names[Localizations.localeOf(context).languageCode] ??
      entry.title ??
      context.l10n.titleNotProvided;
}

String localizedCatalogTerm(BuildContext context, String value) {
  const names = {
    'Dumbbell': {'pt': 'Haltere', 'es': 'Mancuerna'},
    'Barbell': {'pt': 'Barra', 'es': 'Barra'},
    'Bench': {'pt': 'Banco', 'es': 'Banco'},
    'none (bodyweight exercise)': {
      'pt': 'Peso do corpo',
      'es': 'Peso corporal',
    },
    'Kettlebell': {'pt': 'Kettlebell', 'es': 'Kettlebell'},
    'Pull-up bar': {'pt': 'Barra fixa', 'es': 'Barra de dominadas'},
  };
  return names[value]?[Localizations.localeOf(context).languageCode] ?? value;
}
