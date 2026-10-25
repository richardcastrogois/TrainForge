import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract interface class AppearanceStore {
  Future<String?> read();
  Future<void> write(String mode);
}

/// Native preference contains only system/light/dark, separate from account credentials.
class NativeAppearanceStore implements AppearanceStore {
  static const channel = MethodChannel('trainforge/appearance');
  @override
  Future<String?> read() => channel.invokeMethod<String>('read');
  @override
  Future<void> write(String mode) => channel.invokeMethod<void>('write', mode);
}

enum AppearanceFeedback {
  appearanceInvalid(
    "A preferência anterior não pôde ser usada. O tema segue o aparelho.",
  ),
  appearanceReadFailed(
    "Não foi possível ler a aparência salva. O tema segue o aparelho.",
  ),
  appearanceSaveUncertain(
    "A aparência foi aplicada, mas a gravação não foi confirmada. Tente novamente.",
  ),
  appearanceSaveFailed("Não foi possível salvar a aparência. Tente novamente.");

  final String fallback;
  const AppearanceFeedback(this.fallback);
}

class AppearanceController extends ChangeNotifier {
  final AppearanceStore store;
  final Duration restoreTimeout;
  AppearanceController({
    AppearanceStore? store,
    this.restoreTimeout = const Duration(seconds: 2),
  }) : store = store ?? NativeAppearanceStore();
  ThemeMode mode = ThemeMode.system;
  bool loaded = false, saving = false, _disposed = false;
  AppearanceFeedback? feedback;
  String? get message => feedback?.fallback;
  Future<void>? _restore;
  Future<void> restore() => _restore ??= _load();
  Future<void> _load() async {
    try {
      final saved = await store.read().timeout(restoreTimeout);
      if (_disposed) return;
      mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (saved != null && !{'system', 'light', 'dark'}.contains(saved)) {
        feedback = AppearanceFeedback.appearanceInvalid;
      }
    } catch (_) {
      if (!_disposed) {
        feedback = AppearanceFeedback.appearanceReadFailed;
      }
    } finally {
      if (!_disposed) {
        loaded = true;
        notifyListeners();
      }
    }
  }

  Future<void> select(ThemeMode next) async {
    if (_disposed || !loaded || saving || (next == mode && feedback == null)) {
      return;
    }
    final previous = mode;
    mode = next;
    saving = true;
    feedback = null;
    notifyListeners();
    try {
      await store.write(next.name).timeout(restoreTimeout);
    } on TimeoutException catch (_) {
      if (_disposed) return;
      feedback = AppearanceFeedback.appearanceSaveUncertain;
    } catch (_) {
      if (_disposed) return;
      mode = previous;
      feedback = AppearanceFeedback.appearanceSaveFailed;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}
