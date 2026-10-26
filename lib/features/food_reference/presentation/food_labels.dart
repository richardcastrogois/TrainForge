import 'package:trainforge/core/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import '../../../core/l10n/localized_context.dart';
import '../domain/food_reference.dart';

String foodContentLocale(BuildContext context) => resolveAppLocale([
  Localizations.maybeLocaleOf(context) ?? const Locale('pt', 'BR'),
], supportedAppLocales).toLanguageTag();

extension FoodReferenceLabels on FoodReference {
  String localizedName(BuildContext context) =>
      displayNameFor(foodContentLocale(context));
  String localizedBasis(BuildContext context) =>
      basisQuantity == null || basisUnit == null
      ? context.l10n.basisUnknown
      : context.l10n.sourceBasis(
          context.displayDecimal(basisQuantity!),
          basisUnit!,
        );
  String localizedLanguage(BuildContext context) => switch (locale) {
    'und' => context.l10n.languageNotProvided,
    'fr' => context.l10n.languageFrench,
    'en' => context.l10n.languageEnglish,
    _ => locale,
  };
}

extension FoodNutrientLabels on FoodNutrient {
  String localizedValue(BuildContext context) {
    final suffix = unit == null ? '' : ' $unit';
    return switch (state) {
      'numeric' =>
        value == null
            ? context.l10n.valueUnavailable
            : '${context.displayDecimal(value!)}$suffix',
      'less_than' =>
        upperBound == null
            ? context.l10n.limitUnavailable
            : context.l10n.lessThanValue(
                context.displayDecimal(upperBound!),
                suffix,
              ),
      'trace' => context.l10n.traceValue,
      'missing' => context.l10n.notInformed,
      'present_quantity_unknown' => context.l10n.presentUnknown,
      _ => context.l10n.unparsedValue(raw),
    };
  }

  String localizedBasis(BuildContext context) {
    if (basisQuantity != null && basisUnit != null) {
      return context.l10n.perQuantity(
        context.displayDecimal(basisQuantity!),
        basisUnit!,
      );
    }
    final d = declared;
    return context.l10n.basisUnconfirmed +
        (d == null
            ? ''
            : ' · ${context.l10n.columnDeclares} ${d['quantity']} ${d['unit']} (${d['kind']})');
  }
}
