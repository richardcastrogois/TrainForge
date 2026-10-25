import 'package:flutter/widgets.dart';
import 'app_dependencies.dart';

class AppDependencyScope extends InheritedWidget {
  final AppDependencies dependencies;
  const AppDependencyScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  /// Factories have root lifetime; reading them does not subscribe a screen.
  static AppDependencies read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppDependencyScope>();
    if (scope == null) {
      throw StateError('As dependências do aplicativo não foram fornecidas.');
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependencyScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
