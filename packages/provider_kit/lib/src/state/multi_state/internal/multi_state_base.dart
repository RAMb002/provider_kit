part of '../multi_state.dart';

/// Internal implementation shared by the multi-state listener, builder,
/// and consumer widgets.
///
/// This widget coordinates the shared [_MultiStateCore] with the specific
/// behavior required by each multi-state widget, such as listening,
/// rebuilding, or both.
///
/// The shared core owns dependency tracking, subscriptions, state collection,
/// listener scheduling, and rebuild scheduling. This base is responsible for
/// applying the widget-specific callback and state-change behavior around that
/// shared functionality.
///
/// The important invariant is that [providers] is collected exactly once
/// for each dependency notification handled by this widget. The returned
/// value becomes the combined state, while every `.watch` accessed during
/// the collection becomes a dependency.
@internal
final class MultiStateBase<T> extends StatefulWidget {
  const MultiStateBase({
    super.key,
    required this.providers,
    this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
    this.builder,
    this.child,
    required this.widgetName,
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
  /// When this is null, [MultiStateBase] behaves as a listener-only widget
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

  @override
  State<MultiStateBase<T>> createState() => _MultiStateBaseState<T>();
}

/// State implementation for [MultiStateBase].
///
/// The shared dependency, state, listener, and rebuild mechanics are owned
/// by [_MultiStateCore]. This state coordinates those mechanics with the
/// widget-specific callback behavior.
///
/// Dependency subscriptions are updated incrementally so that sources which
/// are no longer used are unsubscribed and newly used sources are subscribed.
class _MultiStateBaseState<T> extends State<MultiStateBase<T>> {
  late final _MultiStateCore<T> _core;
  @override
  void initState() {
    super.initState();

    _core = _MultiStateCore<T>(onDependencyChange: _handleChange);

    // Collect the initial state and dependencies together. Keeping these
    // operations in one collection ensures the state value and subscriptions
    // always correspond to the same providers() evaluation.
    final _DependencyCollection<T> collection = _core.collect(
      providers: widget.providers,
      widgetName: widget.widgetName,
    );

    _core.state = collection.value;
    _syncDependencies(collection.dependencies);
    if (widget.callListenerOnInit && widget.listener != null) {
      _scheduleInitialListener();
    }
  }

  void _scheduleInitialListener() {
    final T initialState = _core.state;
    final ListenerCallback<T> initialListener = widget.listener!;

    _core.listenerQueue.scheduleInitialListener(
      initialCallback: () => initialListener(context, initialState),
      isMounted: () => mounted,
    );
  }

  @override
  void didUpdateWidget(MultiStateBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-collect when the widget configuration changes. This is important
    // because the set of dependencies may itself depend on widget values.
    //
    // The new value becomes the new baseline without invoking listener or
    // rebuild callbacks.
    final _DependencyCollection<T> collection = _collect();

    _core.state = collection.value;

    _syncDependencies(collection.dependencies);
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

    final T previous = _core.state;

    // `providers` is evaluated exactly once for this state change.
    final _DependencyCollection<T> collection = _collect();
    final T current = collection.value;

    // The new collection may contain a different set of dependencies.
    _syncDependencies(collection.dependencies);

    _core.state = current;

    final shouldRebuild =
        widget.builder != null &&
        ObjectKit.shouldNotify(previous, current, widget.rebuildWhen);

    final shouldListen =
        widget.listener != null &&
        ObjectKit.shouldNotify(previous, current, widget.listenWhen);

    if (shouldRebuild) {
      _core.rebuildScheduler.request(
        isMounted: () => mounted,
        rebuild: () => setState(() {}),
      );
    }

    if (shouldListen) {
      final ListenerCallback<T>? listener = widget.listener;

      if (listener != null) {
        _core.listenerQueue.dispatch(() => listener(context, current));
      }
    }
  }

  /// Collects the current combined state and its dependencies.
  ///
  /// The dependency tracker executes [widget.providers] inside a temporary
  /// collection scope. Every `.watch` encountered during that execution is
  /// recorded and returned together with the resulting state value.
  _DependencyCollection<T> _collect() {
    return _core.collect(
      providers: widget.providers,
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
  void _syncDependencies(Set<StateValueListenable> nextDependencies) {
    _core.syncDependencies(nextDependencies);
  }

  @override
  void dispose() {
    _core.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;

    if (builder != null) {
      return builder(context, _core.state, widget.child);
    }

    // Listener-only variants do not build from state. They simply preserve
    // their child subtree.
    assert(widget.child != null, '${widget.widgetName} requires a child.');

    return widget.child!;
  }
}
