part of '../multi_state.dart';

/// Tracks dependencies discovered during a providers evaluation.
///
/// Dependency collection is scoped and synchronous. Each call to [collect]
/// creates its own scope, and the scope is always removed when the evaluation
/// finishes, including when an exception is thrown.
final class _DependencyTracker {
  _DependencyTracker._();

  static final List<_DependencyScope> _scopes = <_DependencyScope>[];

  /// Whether a providers evaluation is currently being collected.
  static bool get isCollecting => _scopes.isNotEmpty;

  /// Records [dependency] in the currently active collection scope.
  ///
  /// If there is no active collection, the dependency is ignored.
  static void record(StateValueListenable listenable) {
    if (_scopes.isEmpty) {
      return;
    }

    _scopes.last.dependencies.add(listenable);
  }

  /// Evaluates [providers] and collects every dependency accessed during
  /// that evaluation.
  ///
  /// Any exception thrown by [providers] propagates normally.
  static _DependencyCollection<T> collect<T>(
    T Function() providers, {
    required String widgetName,
  }) {
    final _DependencyScope scope = _DependencyScope(
      dependencies: Set<StateValueListenable>.identity(),
    );

    _scopes.add(scope);

    try {
      final T value = providers();

      assert(
        scope.dependencies.isNotEmpty,
        '$widgetName requires at least one watched state source.\n\n'
        'Use `.watch` inside the `providers` callback.\n\n'
        'Example:\n'
        'providers: () => (\n'
        '  user: userProvider.watch,\n'
        '  loading: loadingField.watch,\n'
        ')',
      );

      return _DependencyCollection<T>(
        value: value,
        dependencies: scope.dependencies,
      );
    } finally {
      assert(
        _scopes.isNotEmpty,
        'Dependency tracker scope stack was unexpectedly empty.',
      );

      assert(
        identical(_scopes.last, scope),
        'Dependency tracker scope stack was modified unexpectedly.',
      );

      _scopes.removeLast();
    }
  }
}
