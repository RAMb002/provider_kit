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

  /// Manages subscriptions to the state dependencies discovered through
  /// `.watch`
  final _DependencySubscription _dependencySubscription;

  /// Manages deferred listener delivery.
  final ListenerQueue listenerQueue = ListenerQueue();

  /// Manages immediate and deferred rebuild requests.
  final RebuildScheduler rebuildScheduler = RebuildScheduler();

  /// Collects the current combined state and its dependencies.
  ///
  /// Evaluates [listenables] inside a temporary dependency collection scope.
  ///
  /// State dependencies accessed through `.watch` and Provider identity
  /// dependencies accessed through `of<P>()` are collected separately.
  ///
  /// [context] is used to resolve Provider-managed listenables. Provider
  /// identity dependencies are registered with the owning widget during
  /// its build.
  _DependencyCollection<T> collect({
    required BuildContext context,
    required MultiStateListenables<T> listenables,
    required String widgetName,
  }) {
    return _DependencyTracker.collect(
      context,
      listenables,
      widgetName: widgetName,
    );
  }

  /// Synchronizes active subscriptions with [nextDependencies].
  ///
  /// Returns `true` when the dependency set changed.
  bool syncDependencies(Set<StateListenable> nextDependencies) {
    return _dependencySubscription.sync(nextDependencies);
  }

  /// Returns the currently subscribed dependencies.
  Iterable<StateListenable> get dependencies =>
      _dependencySubscription.dependencies;

  /// Releases all resources owned by this core.
  void dispose() {
    _dependencySubscription.dispose();
    listenerQueue.clear();
  }
}
