part of '../multi_state.dart';
/// Manages subscriptions to a dynamic set of [StateValueListenable] sources.
///
/// Only dependencies that were added or removed since the previous
/// synchronization are subscribed or unsubscribed.
final class _DependencySubscription {
  _DependencySubscription({
    required this.onChange,
  });

  final void Function() onChange;

  Set<StateValueListenable> _dependencies =
      Set<StateValueListenable>.identity();

  /// The currently subscribed dependencies.
  Iterable<StateValueListenable> get dependencies => _dependencies;

  /// Synchronizes the active subscriptions with [nextDependencies].
  ///
  /// Returns `true` when the dependency set changed.
  bool sync(Set<StateValueListenable> nextDependencies) {
    final Set<StateValueListenable> previousDependencies = _dependencies;

    bool changed = previousDependencies.length != nextDependencies.length;

    for (final StateValueListenable dependency in previousDependencies) {
      if (!nextDependencies.contains(dependency)) {
        changed = true;
        dependency.removeListener(onChange);
      }
    }

    for (final StateValueListenable dependency in nextDependencies) {
      if (!previousDependencies.contains(dependency)) {
        changed = true;
        dependency.addListener(onChange);
      }
    }

    _dependencies = nextDependencies;

    return changed;
  }

  /// Removes every active subscription.
  void dispose() {
    for (final StateValueListenable dependency in _dependencies) {
      dependency.removeListener(onChange);
    }

    _dependencies.clear();
  }
}