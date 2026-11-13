part of '../multi_state.dart';

/// Internal implementation shared by the multi-state listener, builder,
/// and consumer widgets.
///
/// This widget coordinates the shared [_MultiStateCore] with the specific
/// behavior required by each multi-state widget, such as listening,
/// rebuilding, or both.
///
/// The shared core owns state and Provider dependency tracking, state
/// collection, subscriptions, listener scheduling, and rebuild scheduling.
/// This engine applies the widget-specific state-comparison and callback
/// behavior.
///
/// The important invariant is that [listenables] is collected exactly once
/// for each dependency notification handled by this widget. The returned
/// value becomes the combined state, while every `.watch` and `of<P>()`
/// accessed during collection contributes its corresponding dependency.
@internal
final class MultiStateEngine<T> extends StatefulWidget {
  const MultiStateEngine({
    super.key,
    required this.listenables,
    this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
    this.builder,
    this.child,
    required this.widgetName,
  });

  /// Produces the combined state for the widget and declares its dependencies.
  ///
  /// Access [StateListenable] values through `.watch` and resolve
  /// Provider-owned listenables through `of<P>()`.
  ///
  /// Provider identity dependencies and state dependencies are tracked
  /// separately.
  final MultiStateListenables<T> listenables;

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
  /// When this is null, [MultiStateEngine] behaves as a listener-only widget
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
  State<MultiStateEngine<T>> createState() => _MultiStateEngineState<T>();
}

/// State implementation for [MultiStateEngine].
///
/// The shared state and Provider dependency tracking, subscriptions, listener
/// scheduling, and rebuild scheduling are owned by [_MultiStateCore].
///
/// This state handles the widget lifecycle, state collection, and
/// widget-specific state-change and callback behavior.
class _MultiStateEngineState<T> extends State<MultiStateEngine<T>> {
  late final _MultiStateCore<T> _core;

  @override
  void initState() {
    super.initState();

    _core = _MultiStateCore<T>(onDependencyChange: _handleChange);

    // Collect the initial state and dependencies together.
    // This ensures the state value and subscriptions correspond to the
    // same listenables evaluation.
    final _DependencyCollection<T> collection = _collect();

    _core.state = collection.value;
    _core.syncProviderDependencies(collection.providerDependencies);

    _core.syncDependencies(collection.dependencies);
    if (widget.callListenerOnInit && widget.listener != null) {
      _scheduleInitialListener();
    }
  }

  /// Schedules the initial listener callback.
  void _scheduleInitialListener() {
    final T initialState = _core.state;
    final ListenerCallback<T> initialListener = widget.listener!;

    _core.listenerQueue.scheduleInitialListener(
      initialCallback: () => initialListener(context, initialState),
      isMounted: () => mounted,
    );
  }

  @override
  void didUpdateWidget(MultiStateEngine<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-collect when the widget configuration changes.
    // This is important because the dependency set may depend on
    // widget configuration.
    //
    // The newly collected value becomes the baseline without invoking
    // listener or rebuild callbacks.
    final _DependencyCollection<T> collection = _collect();

    _core.state = collection.value;
    _core.syncProviderDependencies(collection.providerDependencies);
    _core.syncDependencies(collection.dependencies);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // The first didChangeDependencies occurs before the initial build.
    // Provider identity dependencies have not been established yet.
    if (!_core.hasBuilt || !_core.hasProviderDependencies) {
      return;
    }

    // A Provider identity dependency changed. Resolve the current
    // instances again and establish a new state baseline.
    final _DependencyCollection<T> collection = _collect();

    _core.state = collection.value;

    _core.syncProviderDependencies(collection.providerDependencies);
    _core.syncDependencies(collection.dependencies);
  }

  /// Handles notifications from any currently subscribed state dependency.
  ///
  /// A dependency notification does not necessarily mean the combined state
  /// changed. Therefore, this method:
  ///
  /// 1. Collects the combined state again.
  /// 2. Updates state and Provider dependencies.
  /// 3. Compares the previous and current combined values.
  /// 4. Independently triggers rebuilding and listening.
  void _handleChange() {
    if (!mounted) {
      return;
    }

    final T previous = _core.state;

    // `listenables` is evaluated exactly once for this state change.
    final _DependencyCollection<T> collection = _collect();
    final T current = collection.value;

    final bool providerDependenciesChanged = _core.syncProviderDependencies(
      collection.providerDependencies,
    );

    // The new collection may contain a different set of dependencies.
    _core.syncDependencies(collection.dependencies);

    _core.state = current;

    final shouldRebuild =
        widget.builder != null &&
        ObjectKit.shouldNotify(previous, current, widget.rebuildWhen);

    final shouldListen =
        widget.listener != null &&
        ObjectKit.shouldNotify(previous, current, widget.listenWhen);

    // A changed Provider dependency must also trigger a build so that
    // context.select can establish the new inherited dependencies.
    if (shouldRebuild || providerDependenciesChanged) {
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
  /// The dependency tracker evaluates [widget.listenables] inside a
  /// temporary collection scope using this state's [BuildContext] for
  /// Provider resolution.
  ///
  /// State dependencies accessed through `.watch` and Provider identity
  /// dependencies accessed through `of<P>()` are collected separately.
  _DependencyCollection<T> _collect() {
    return _core.collect(
      context: context,
      listenables: widget.listenables,
      widgetName: widget.widgetName,
    );
  }

  @override
  void dispose() {
    _core.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider.select must be registered during build.
    _core.trackProviderDependencies(context);

    final StateWidgetBuilder<T>? builder = widget.builder;

    if (builder != null) {
      return builder(context, _core.state, widget.child);
    }

    // Listener-only variants do not build from state. They simply preserve
    // their child subtree.
    assert(widget.child != null, '${widget.widgetName} requires a child.');

    return widget.child!;
  }
}
