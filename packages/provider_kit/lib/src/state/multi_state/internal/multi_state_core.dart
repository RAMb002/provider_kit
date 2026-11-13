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

  /// Provider identity dependencies discovered during the latest collection.
  ///
  /// These dependencies detect when a Provider supplies a different instance
  /// for a previously resolved Provider type.
  ///
  /// They are registered with the owning widget's [BuildContext] during build.
  Map<Type, _ProviderDependency> _providerDependencies =
      const <Type, _ProviderDependency>{};

  /// Whether the owning widget has completed its first build-time Provider
  /// dependency registration.
  ///
  /// This prevents the initial [didChangeDependencies] lifecycle callback
  /// from attempting to process Provider dependencies before the first build.
  bool _hasBuilt = false;

  /// Manages deferred listener delivery.
  final ListenerQueue listenerQueue = ListenerQueue();

  /// Manages immediate and deferred rebuild requests.
  final RebuildScheduler rebuildScheduler = RebuildScheduler();

  /// Whether the initial build has registered Provider dependencies.
  bool get hasBuilt => _hasBuilt;

  /// Whether the latest collection contains Provider identity dependencies.
  bool get hasProviderDependencies => _providerDependencies.isNotEmpty;

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
  /// Newly discovered dependencies are subscribed to, and dependencies no
  /// longer present in the collection are unsubscribed from.
  ///
  /// Returns `true` when the dependency membership changes.
  bool syncDependencies(Set<StateListenable> nextDependencies) {
    return _dependencySubscription.sync(nextDependencies);
  }

  /// Synchronizes the currently collected Provider identity dependencies.
  ///
  /// Provider dependencies are compared by their Provider type and resolved
  /// instance identity.
  ///
  /// Returns `true` when a Provider dependency is added, removed, or resolves
  /// to a different instance.
  bool syncProviderDependencies(
    Map<Type, _ProviderDependency> nextDependencies,
  ) {
    final previousDependencies = _providerDependencies;

    bool changed = previousDependencies.length != nextDependencies.length;

    if (!changed) {
      for (final entry in previousDependencies.entries) {
        final next = nextDependencies[entry.key];

        if (next == null || !identical(entry.value.identity, next.identity)) {
          changed = true;
          break;
        }
      }
    }

    _providerDependencies = nextDependencies;

    return changed;
  }

  /// Registers the current Provider identity dependencies with [context].
  ///
  /// Must be called during the owning widget's build so Provider can establish
  /// its inherited dependencies.
  ///
  /// Marks the initial build as completed after registering the dependencies.
  void trackProviderDependencies(BuildContext context) {
    for (final dependency in _providerDependencies.values) {
      dependency.dependOn(context);
    }

    _hasBuilt = true;
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
