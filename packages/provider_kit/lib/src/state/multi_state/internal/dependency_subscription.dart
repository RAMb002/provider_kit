part of '../multi_state.dart';

/// Manages subscriptions to a dynamic set of [StateListenable] sources.
///
/// Only dependencies that were added or removed since the previous
/// synchronization are subscribed or unsubscribed.
final class _DependencySubscription {
  _DependencySubscription({required this.onChange});

  final void Function() onChange;

  Set<StateListenable> _dependencies = Set<StateListenable>.identity();

  /// The currently subscribed dependencies.
  Iterable<StateListenable> get dependencies => _dependencies;

  /// Synchronizes the active subscriptions with [nextDependencies].
  ///
  /// Returns `true` when the dependency set changed.
  bool sync(Set<StateListenable> nextDependencies) {
    final Set<StateListenable> previousDependencies = _dependencies;

    bool changed = previousDependencies.length != nextDependencies.length;

    for (final StateListenable dependency in previousDependencies) {
      if (!nextDependencies.contains(dependency)) {
        changed = true;
        dependency.removeListener(onChange);
      }
    }

    for (final StateListenable dependency in nextDependencies) {
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
    for (final StateListenable dependency in _dependencies) {
      dependency.removeListener(onChange);
    }

    _dependencies.clear();
  }
}
