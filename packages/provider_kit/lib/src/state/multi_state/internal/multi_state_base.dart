part of '../multi_state.dart';

/// Internal implementation shared by the multi-state listener, builder,
/// and consumer widgets.
///
/// This widget owns the actual dependency-tracking and subscription logic.
/// Public multi-state widgets only configure this base with the behavior they
/// need, such as listening, rebuilding, or both.
///
/// The important invariant is that [providers] is collected exactly once
/// for each dependency notification handled by this widget. The returned
/// value becomes the combined state, while every `.watch` accessed during
/// the collection becomes a dependency.
///
/// This allows ProviderKit to:
/// - automatically discover the state sources used by the widget,
/// - subscribe only to those sources,
/// - dynamically update subscriptions when the dependencies change,
/// - compare previous and current combined state values,
/// - independently trigger rebuilding and/or listening.
class _MultiStateBase<T> extends StatefulWidget {
  const _MultiStateBase({
    required this.providers,
    this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
    this.builder,
    this.child,
    required this.widgetName,
    this.onDependenciesUpdate,
  });

  /// Produces the combined state for the widget and declares its
  /// dependencies through `.watch`.
  ///
  /// The callback is evaluated inside ProviderKit's dependency collector.
  /// Every watched [StateValueListenable] is recorded automatically.
  final MultiStateProviders<T> providers;

  /// Called when the combined state changes and [listenWhen] allows it.
  final ListenerCallback<T>? listener;

  /// Determines whether [listener] should be called when the combined state
  /// changes.
  final ListenWhen<T>? listenWhen;

  /// Determines whether [builder] should rebuild when the combined state
  /// changes.
  final RebuildWhen<T>? rebuildWhen;

  /// Whether [listener] should be called once after the widget is initialized.
  ///
  /// When enabled, [listener] is first called after the first frame with the
  /// initial combined state. Any listener notifications that occur before the
  /// initial callback are delivered afterward in the order they were received.
  final bool callListenerOnInit;

  /// Builds the widget from the current combined state.
  ///
  /// When this is null, [_MultiStateBase] behaves as a listener-only widget
  /// and returns [child] directly.
  final StateWidgetBuilder<T>? builder;

  /// Optional subtree passed directly to [builder] or returned directly when
  /// no builder is configured.
  final Widget? child;

  /// Name of the public widget using this implementation.
  ///
  /// Used for dependency-tracking assertions and diagnostic messages so that
  /// errors refer to the actual public widget rather than this private base.
  final String widgetName;

  /// Called when the collected dependencies are updated.
  ///
  /// The callback is invoked when the dependency set changes and when the
  /// widget configuration is replaced, even if the dependency objects remain
  /// the same.
  final void Function(Iterable<StateValueListenable> dependencies)?
  onDependenciesUpdate;

  @override
  State<_MultiStateBase<T>> createState() => _MultiStateBaseState<T>();
}

/// State implementation for [_MultiStateBase].
///
/// The state keeps the last collected combined value and the exact set of
/// [StateValueListenable] dependencies discovered from the most recent [providers]
/// evaluation.
///
/// Dependency subscriptions are updated incrementally so that sources which
/// are no longer used are unsubscribed and newly used sources are subscribed.
class _MultiStateBaseState<T> extends State<_MultiStateBase<T>> {
  /// The most recently collected combined state.
  ///
  /// This acts as the baseline for both [ListenWhen] and [RebuildWhen]
  /// comparisons.
  late T _state;

  /// Manages subscriptions to the dependencies discovered by [providers].
  late final _DependencySubscription _dependencySubscription;

  /// Manages deferred listener delivery during initialization.
  final ListenerQueue _listenerQueue = ListenerQueue();

  /// Manages immediate and deferred rebuild requests.
  final RebuildScheduler _rebuildScheduler = RebuildScheduler();

  @override
  void initState() {
    super.initState();

    _dependencySubscription = _DependencySubscription(onChange: _handleChange);

    // Collect the initial state and dependencies together. Keeping these
    // operations in one collection ensures the state value and subscriptions
    // always correspond to the same providers() evaluation.
    final _DependencyCollection<T> collection = _collect();

    _state = collection.value;

    _syncDependencies(collection.dependencies);

    if (widget.callListenerOnInit && widget.listener != null) {
      _scheduleInitialListener();
    }
  }

  void _scheduleInitialListener() {
    final T initialState = _state;
    final ListenerCallback<T> initialListener = widget.listener!;

    _listenerQueue.scheduleInitialListener(
      initialCallback: () => initialListener(context, initialState),
      isMounted: () => mounted,
    );
  }

  @override
  void didUpdateWidget(_MultiStateBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-collect when the widget configuration changes. This is important
    // because the set of dependencies may itself depend on widget values.
    //
    // The new value becomes the new baseline without invoking either callback.
    final _DependencyCollection<T> collection = _collect();

    _state = collection.value;

    _syncDependencies(collection.dependencies, notifyDependencyHook: true);
  }

  /// Handles notifications from any currently subscribed dependency.
  ///
  /// A dependency notification does not necessarily mean the combined state
  /// changed. We therefore:
  ///
  /// 1. collect the combined state again,
  /// 2. update dependency subscriptions,
  /// 3. compare the previous and current values,
  /// 4. independently trigger rebuilding and listening.
  void _handleChange() {
    if (!mounted) {
      return;
    }

    final T previous = _state;

    // `providers` is evaluated exactly once for this state change.
    final _DependencyCollection<T> collection = _collect();
    final T current = collection.value;

    // The new collection may contain a different set of dependencies.
    _syncDependencies(collection.dependencies);

    _state = current;

    final shouldRebuild =
        widget.builder != null &&
        ObjectKit.shouldNotify(previous, current, widget.rebuildWhen);

    final shouldListen =
        widget.listener != null &&
        ObjectKit.shouldNotify(previous, current, widget.listenWhen);

    if (shouldRebuild) {
      _rebuildScheduler.request(
        isMounted: () => mounted,
        rebuild: () => setState(() {}),
      );
    }

    if (shouldListen) {
      final ListenerCallback<T>? listener = widget.listener;

      if (listener != null) {
        _listenerQueue.dispatch(() => listener(context, current));
      }
    }
  }

  /// Collects the current combined state and its dependencies.
  ///
  /// The dependency tracker executes [widget.providers] inside a temporary
  /// collection scope. Every `.watch` encountered during that execution is
  /// recorded and returned together with the resulting state value.
  _DependencyCollection<T> _collect() {
    return _DependencyTracker.collect(
      widget.providers,
      widgetName: widget.widgetName,
    );
  }

  /// Synchronizes the active subscriptions with the newly collected
  /// dependencies.
  ///
  /// Only changed dependencies are touched:
  /// - dependencies missing from the new set are unsubscribed,
  /// - newly discovered dependencies are subscribed,
  /// - unchanged dependencies remain subscribed.
  void _syncDependencies(
    Set<StateValueListenable> nextDependencies, {
    bool notifyDependencyHook = false,
  }) {
    final bool dependenciesChanged = _dependencySubscription.sync(
      nextDependencies,
    );

    if (dependenciesChanged || notifyDependencyHook) {
      widget.onDependenciesUpdate?.call(_dependencySubscription.dependencies);
    }
  }

  @override
  void dispose() {
    _dependencySubscription.dispose();
    _listenerQueue.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;

    if (builder != null) {
      return builder(context, _state, widget.child);
    }

    // Listener-only variants do not build from state. They simply preserve
    // their child subtree.
    assert(
      widget.child != null,
      '''${widget.widgetName} used outside of MultiStateListener must specify a child''',
    );

    return widget.child!;
  }
}

typedef _DependenciesUpdateCallback =
    void Function(Iterable<StateValueListenable> dependencies);
