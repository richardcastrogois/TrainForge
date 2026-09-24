//lib/main.dart
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/log/app_logger.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'FlutterError capturado',
      tag: 'APP',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  AppLogger.info('Inicializando app', tag: 'APP');

  runApp(const TrainForgeApp());
}
