import 'dart:async';
import '../preferences/read_diagnostics.dart';
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
  bool loaded = false, reading = false, saving = false, _disposed = false;
  ThemeMode? _retryMode;
  bool get readFailed =>
      feedback == AppearanceFeedback.appearanceReadFailed ||
      feedback == AppearanceFeedback.appearanceInvalid;
  AppearanceFeedback? feedback;
  String? get message => feedback?.fallback;
  int _readGeneration = 0;
  Future<void>? _restore;
  Future<void> restore() => _restore ??= _load();
  void _applySaved(String? saved) {
    mode = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    feedback = saved != null && !{'system', 'light', 'dark'}.contains(saved)
        ? AppearanceFeedback.appearanceInvalid
        : null;
  }

  Future<void> _load() async {
    final generation = ++_readGeneration;
    Future<String?>? pending;
    reading = true;
    feedback = null;
    _retryMode = null;
    try {
      pending = store.read();
      final saved = await pending.timeout(restoreTimeout);
      if (_disposed) return;
      _applySaved(saved);
    } catch (error) {
      if (error is TimeoutException && pending != null) {
        unawaited(
          pending.then((saved) {
            if (_disposed ||
                generation != _readGeneration ||
                reading ||
                saving ||
                !readFailed) {
              return;
            }
            _applySaved(saved);
            notifyListeners();
          }, onError: (Object _, StackTrace s) {}),
        );
      }
      reportPreferenceReadFailure(PreferenceArea.appearance, error);
      if (!_disposed) {
        feedback = AppearanceFeedback.appearanceReadFailed;
      }
    } finally {
      if (!_disposed) {
        loaded = true;
        reading = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() {
    if (_disposed || !loaded || reading || saving) return Future.value();
    if (readFailed) {
      final pending = _load();
      _restore = pending;
      notifyListeners();
      return pending;
    }
    final next = _retryMode;
    return next == null ? Future.value() : select(next);
  }

  Future<void> select(ThemeMode next) async {
    if (_disposed ||
        !loaded ||
        reading ||
        saving ||
        (next == mode && feedback == null)) {
      return;
    }
    _readGeneration++;
    final previous = mode;
    _retryMode = next;
    mode = next;
    saving = true;
    feedback = null;
    notifyListeners();
    try {
      await store.write(next.name).timeout(restoreTimeout);
      if (!_disposed) _retryMode = null;
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
