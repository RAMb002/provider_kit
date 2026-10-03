part of '../multi_state.dart';

/// Internal core shared by multi-state and multi-view-state implementations.
///
/// This class owns the mechanics required to collect combined state values,
/// track their dependencies, maintain subscriptions, and manage shared
/// listener/rebuild scheduling.
///
/// It intentionally contains no state-comparison or callback semantics.
/// Those behaviors belong to the concrete multi-state implementations.
final class _MultiStateCore<T> {
  _MultiStateCore({required VoidCallback onDependencyChange})
    : _dependencySubscription = _DependencySubscription(
        onChange: onDependencyChange,
      );

  /// The most recently collected combined state.
  ///
  /// This acts as the baseline for both [ListenWhen] and [RebuildWhen]
  /// comparisons.
  late T state;

  /// Manages subscriptions to the dependencies discovered from [providers].
  final _DependencySubscription _dependencySubscription;

  /// Manages deferred listener delivery.
  final ListenerQueue listenerQueue = ListenerQueue();

  /// Manages immediate and deferred rebuild requests.
  final RebuildScheduler rebuildScheduler = RebuildScheduler();

  /// Collects the current combined state and its dependencies.
  ///
  /// The dependency tracker executes [providers] inside a temporary
  /// collection scope. Every `.watch` encountered during that execution is
  /// recorded and returned together with the resulting state value.
  _DependencyCollection<T> collect({
    required MultiStateProviders<T> providers,
    required String widgetName,
  }) {
    return _DependencyTracker.collect(providers, widgetName: widgetName);
  }

  /// Synchronizes active subscriptions with [nextDependencies].
  ///
  /// Returns `true` when the dependency set changed.
  bool syncDependencies(Set<StateValueListenable> nextDependencies) {
    return _dependencySubscription.sync(nextDependencies);
  }

  /// Returns the currently subscribed dependencies.
  Iterable<StateValueListenable> get dependencies =>
      _dependencySubscription.dependencies;

  /// Releases all resources owned by this core.
  void dispose() {
    _dependencySubscription.dispose();
    listenerQueue.clear();
  }
}
