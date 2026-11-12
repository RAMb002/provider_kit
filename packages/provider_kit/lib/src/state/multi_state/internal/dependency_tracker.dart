part of '../multi_state.dart';

/// Tracks dependencies discovered during a listenables evaluation.
///
/// Dependency collection is scoped and synchronous. Each call to [collect]
/// creates its own scope, and the scope is always removed when the evaluation
/// finishes, including when an exception is thrown.
///
/// Two kinds of dependencies can be collected:
///
/// - State dependencies discovered through `StateListenable.watch`.
/// - Provider identity dependencies discovered through `of<P>()`.
///
/// State dependencies are subscribed to through [_DependencySubscription].
/// Provider identity dependencies are used to detect when a provided
/// [StateListenable] instance is replaced.
final class _DependencyTracker {
  _DependencyTracker._();

  static final List<_DependencyScope> _scopes = <_DependencyScope>[];

  /// Whether a dependency-collecting callback is currently being evaluated.
  static bool get isCollecting => _scopes.isNotEmpty;

  /// Records [listenable] as a state dependency in the current scope.
  ///
  /// If there is no active collection, the dependency is ignored.
  ///
  /// The dependency is later subscribed to through
  /// [_DependencySubscription].
  static void record(StateListenable listenable) {
    if (_scopes.isEmpty) {
      return;
    }

    _scopes.last.dependencies.add(listenable);
  }

  /// Resolves a Provider-managed [StateListenable] of type [P].
  ///
  /// The resolved instance is registered as a Provider identity dependency.
  /// It is not registered as a state dependency automatically.
  ///
  /// To subscribe to its state changes, access it through `.watch` inside
  /// the dependency-collecting callback.
  ///
  /// Must be called inside a supported ProviderKit dependency-collecting
  /// callback through [of].
  ///
  /// Repeated resolutions of the same Provider type within one collection
  /// share a single identity dependency.
  static P readProvider<P extends StateListenable<dynamic>>() {
    if (_scopes.isEmpty) {
      throw StateError(
        'of<$P>() can only be used inside a '
        'dependency-collecting callback of a supported ProviderKit widget.',
      );
    }

    final _DependencyScope scope = _scopes.last;

    // Resolve the current instance without establishing an inherited
    // dependency. That is handled separately during the owning widget's build.
    final P listenable = scope.context.read<P>();

    // Track Provider replacement independently of state notifications.
    scope.providerDependencies[P] = _TypedProviderDependency<P>(listenable);

    return listenable;
  }

  /// Evaluates [callback] and collects the dependencies accessed during
  /// that evaluation.
  ///
  /// State dependencies are collected through `.watch`, while Provider
  /// identity dependencies are collected through [of].
  ///
  /// At least one state or Provider identity dependency must be collected.
  ///
  /// Any exception thrown by [callback] propagates normally. The active
  /// collection scope is removed even when an exception occurs.
  static _DependencyCollection<T> collect<T>(
    BuildContext context,
    T Function() callback, {
    required String widgetName,
  }) {
    final _DependencyScope scope = _DependencyScope(context: context);

    _scopes.add(scope);

    try {
      final T value = callback();

      assert(
        scope.dependencies.isNotEmpty ||
            scope.providerDependencies.isNotEmpty,
        '$widgetName requires at least one dependency.\n\n'
        'Use `.watch` to observe a StateListenable or `of<P>()` '
        'to resolve a Provider-managed StateListenable inside the '
        'dependency-collecting callback.',
      );

      return _DependencyCollection<T>(
        value: value,
        dependencies: scope.dependencies,
        providerDependencies: Map<Type, _ProviderDependency>.unmodifiable(
          scope.providerDependencies,
        ),
      );
    } finally {
      assert(
        _scopes.isNotEmpty,
        'Dependency tracker scope stack was unexpectedly empty.',
      );

      assert(
        identical(_scopes.last, scope),
        'Dependency tracker scope was modified unexpectedly.',
      );

      _scopes.removeLast();
    }
  }
}