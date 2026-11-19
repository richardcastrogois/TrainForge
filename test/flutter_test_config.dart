import 'dart:async';
import 'package:trainforge/core/motion/app_motion.dart';

/// Repeating brand animations never settle; widget tests see the final frame.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppMotion.ambient = false;
  await testMain();
}
