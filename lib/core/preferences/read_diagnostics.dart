import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../log/app_logger.dart';

enum PreferenceArea { appearance, locale }

/// Only fixed codes are emitted. Never serialize exceptions or saved values.
void reportPreferenceReadFailure(PreferenceArea area, Object error) {
  if (!kDebugMode) return;
  final code = switch (error) {
    TimeoutException() => 'timeout',
    MissingPluginException() => 'missing_channel',
    PlatformException() => 'platform',
    _ => 'other',
  };
  AppLogger.warning(['read', area.name, code].join('_'), tag: 'PREFERENCES');
}
