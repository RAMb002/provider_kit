part of '../../state/multi_state/multi_state.dart';

/// Stores the currently watched ViewState providers for multi-ViewState
/// widgets.
///
/// Dependencies are kept in the same order in which they are collected.
/// This order is used when determining the first error, loading message,
/// empty state, and other aggregate ViewState behavior.
class _MultiViewStateDependencyDelegate {
  List<ViewStateNotifier<dynamic>> _providers = const [];

  /// Updates the currently watched providers.
  ///
  /// The provider order is preserved and duplicate dependencies are removed
  /// using identity equality.
  void updateDependencies(
    Iterable<StateValueListenable> dependencies,
  ) {
    final providers = <ViewStateNotifier<dynamic>>[];
    final seen = Set<StateValueListenable>.identity();

    for (final dependency in dependencies) {
      if (dependency is! ViewStateNotifier<dynamic>) {
        throw StateError(
          'MultiViewState widgets require all watched providers '
          'to be ViewStateNotifier instances.',
        );
      }

      if (seen.add(dependency)) {
        providers.add(dependency);
      }
    }

    _providers = List.unmodifiable(providers);
  }

  /// The currently watched providers in dependency order.
  List<ViewStateNotifier<dynamic>> get providers => _providers;
}