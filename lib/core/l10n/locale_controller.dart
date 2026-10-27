import 'dart:async';
import '../preferences/read_diagnostics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

enum LanguageChoice {
  system('system', null),
  portugueseBrazil('pt-BR', Locale('pt', 'BR')),
  portuguesePortugal('pt-PT', Locale('pt', 'PT')),
  english('en', Locale('en')),
  spanish('es', Locale('es'));

  final String tag;
  final Locale? locale;
  const LanguageChoice(this.tag, this.locale);
  static LanguageChoice? parse(String? tag) {
    for (final value in values) {
      if (value.tag == tag) return value;
    }
    return null;
  }
}

const supportedAppLocales = [
  Locale('pt', 'BR'),
  Locale('pt', 'PT'),
  Locale('en'),
  Locale('es'),
];

Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> _) {
  for (final candidate in preferred ?? const <Locale>[]) {
    for (final supported in supportedAppLocales) {
      if (candidate.languageCode == supported.languageCode &&
          candidate.countryCode == supported.countryCode) {
        return supported;
      }
    }
    if (candidate.languageCode == 'pt') return supportedAppLocales.first;
    if (candidate.languageCode == 'en') return const Locale('en');
    if (candidate.languageCode == 'es') return const Locale('es');
  }
  return supportedAppLocales.first;
}

abstract interface class LocaleStore {
  Future<String?> read();
  Future<void> write(String tag);
}

class NativeLocaleStore implements LocaleStore {
  static const channel = MethodChannel('trainforge/locale');
  @override
  Future<String?> read() => channel.invokeMethod<String>('read');
  @override
  Future<void> write(String tag) => channel.invokeMethod<void>('write', tag);
}

enum LocaleIssue { readFallback, saveFailed, saveUncertain }

class LocaleController extends ChangeNotifier {
  final LocaleStore store;
  final Duration timeout;
  LocaleController({
    LocaleStore? store,
    this.timeout = const Duration(seconds: 2),
  }) : store = store ?? NativeLocaleStore();
  LanguageChoice choice = LanguageChoice.system;
  bool loaded = false, reading = false, saving = false, _disposed = false;
  LanguageChoice? _retryChoice;
  bool get readFailed => issue == LocaleIssue.readFallback;
  LocaleIssue? issue;
  Future<void>? _restore;
  Future<void> restore() => _restore ??= _load();

  Future<void> _load() async {
    reading = true;
    issue = null;
    _retryChoice = null;
    try {
      final saved = await store.read().timeout(timeout);
      if (_disposed) return;
      choice = LanguageChoice.parse(saved) ?? LanguageChoice.system;
      if (saved != null && LanguageChoice.parse(saved) == null) {
        issue = LocaleIssue.readFallback;
      }
    } catch (error) {
      reportPreferenceReadFailure(PreferenceArea.locale, error);
      if (!_disposed) issue = LocaleIssue.readFallback;
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
    final next = _retryChoice;
    return next == null ? Future.value() : select(next);
  }

  Future<void> select(LanguageChoice next) async {
    if (_disposed ||
        !loaded ||
        reading ||
        saving ||
        (choice == next && issue == null)) {
      return;
    }
    final previous = choice;
    _retryChoice = next;
    choice = next;
    saving = true;
    issue = null;
    notifyListeners();
    try {
      await store.write(next.tag).timeout(timeout);
      if (!_disposed) _retryChoice = null;
    } on TimeoutException {
      if (!_disposed) issue = LocaleIssue.saveUncertain;
    } catch (_) {
      if (!_disposed) {
        choice = previous;
        issue = LocaleIssue.saveFailed;
      }
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

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);
  static LocaleController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.notifier;
}
