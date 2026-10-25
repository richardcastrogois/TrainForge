import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('pt', 'BR'));
  String displayDate(DateTime value) =>
      DateFormat.yMd(l10n.localeName).format(value);
  String displayTime(DateTime value) =>
      DateFormat.Hm(l10n.localeName).format(value);

  /// Display only: preserves every original decimal digit, without float rounding.
  String displayDecimal(String value) {
    if (!RegExp(r'^-?[0-9]+(\.[0-9]+)?$').hasMatch(value)) return value;
    return value.replaceFirst(
      '.',
      NumberFormat.decimalPattern(l10n.localeName).symbols.DECIMAL_SEP,
    );
  }
}
