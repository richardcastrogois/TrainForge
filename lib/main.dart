//lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'app.dart';
import 'core/log/app_logger.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Inter'], license);
  });
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('FlutterError capturado', tag: 'APP');
  };

  AppLogger.info('Inicializando app', tag: 'APP');

  WidgetsFlutterBinding.ensureInitialized();
  // Warms the Liquid Glass shaders without delaying the first frame.
  unawaited(LiquidGlassWidgets.initialize(enablePerformanceMonitor: false));
  runApp(const TrainForgeApp());
}
