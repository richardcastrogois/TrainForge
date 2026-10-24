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

class AppearanceController extends ChangeNotifier {
  final AppearanceStore store;
  final Duration restoreTimeout;
  AppearanceController({
    AppearanceStore? store,
    this.restoreTimeout = const Duration(seconds: 2),
  }) : store = store ?? NativeAppearanceStore();
  ThemeMode mode = ThemeMode.system;
  bool loaded = false, saving = false, _disposed = false;
  String? message;
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
        message =
            'A preferência anterior não pôde ser usada. O tema segue o aparelho.';
      }
    } catch (_) {
      if (!_disposed) {
        message =
            'Não foi possível ler a aparência salva. O tema segue o aparelho.';
      }
    } finally {
      if (!_disposed) {
        loaded = true;
        notifyListeners();
      }
    }
  }

  Future<void> select(ThemeMode next) async {
    if (_disposed || !loaded || saving || (next == mode && message == null)) {
      return;
    }
    final previous = mode;
    mode = next;
    saving = true;
    message = null;
    notifyListeners();
    try {
      await store.write(next.name).timeout(restoreTimeout);
    } on TimeoutException catch (_) {
      if (_disposed) return;
      message =
          'A aparência foi aplicada, mas a gravação não foi confirmada. Tente novamente.';
    } catch (_) {
      if (_disposed) return;
      mode = previous;
      message = 'Não foi possível salvar a aparência. Tente novamente.';
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
