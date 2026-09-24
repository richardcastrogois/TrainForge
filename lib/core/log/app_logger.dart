import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message, {String tag = 'APP'}) {
    final text = '[$tag] $message';
    developer.log(text, name: tag);
    if (kDebugMode) {
      debugPrint(text);
    }
  }

  static void warning(String message, {String tag = 'WARN'}) {
    final text = '[$tag] $message';
    developer.log(text, name: tag);
    if (kDebugMode) {
      debugPrint(text);
    }
  }

  static void error(
    String message, {
    String tag = 'ERROR',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final text = '[$tag] $message';
    developer.log(text, name: tag, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      debugPrint(text);
      if (error != null) {
        debugPrint('[$tag] error: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$tag] stackTrace: $stackTrace');
      }
    }
  }
}
