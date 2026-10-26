import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../../l10n/generated/app_localizations.dart';

bool _dateFormatsReady = false;
void _prepareDates() {
  if (_dateFormatsReady) return;
  // intl 0.20.2 registers its bundled CLDR data synchronously before returning.
  unawaited(initializeDateFormatting());
  _dateFormatsReady = true;
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('pt', 'BR'));
  String displayDate(DateTime value) {
    _prepareDates();
    return DateFormat.yMd(l10n.localeName).format(value);
  }

  String displayLongDate(DateTime value) {
    _prepareDates();
    return DateFormat.MMMMEEEEd(l10n.localeName).format(value);
  }

  String weekdayInitial(DateTime value) {
    _prepareDates();
    return DateFormat.E(
      l10n.localeName,
    ).format(value).characters.first.toUpperCase();
  }

  String displayTime(DateTime value) {
    _prepareDates();
    return DateFormat.Hm(l10n.localeName).format(value);
  }

  String displayTimestamp(String raw) {
    final value = DateTime.parse(raw).toLocal();
    final minutes = value.timeZoneOffset.inMinutes;
    final zone =
        '${minutes < 0 ? '-' : '+'}${(minutes.abs() ~/ 60).toString().padLeft(2, '0')}:${(minutes.abs() % 60).toString().padLeft(2, '0')}';
    return '${displayDate(value)} · ${displayTime(value)} ($zone)';
  }

  /// Display only: preserves every original decimal digit, without float rounding.
  String displayDecimal(String value) {
    if (!RegExp(r'^-?[0-9]+(\.[0-9]+)?$').hasMatch(value)) return value;
    return value.replaceFirst(
      '.',
      NumberFormat.decimalPattern(l10n.localeName).symbols.DECIMAL_SEP,
    );
  }
}
