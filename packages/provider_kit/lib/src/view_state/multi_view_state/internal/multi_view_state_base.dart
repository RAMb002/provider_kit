part of '../../../state/multi_state/multi_state.dart';

/// Internal implementation shared by the Multi View State listener, builder,
/// and consumer widgets.
///
/// This base owns Multi View State-specific change detection while delegating
/// dependency collection, subscription management, listener scheduling, and
/// rebuild scheduling to [_MultiStateCore].
///
/// The current combined value and aggregated View State are maintained as
/// separate snapshots. The combined value is used for Data-state equality,
/// while [_MultiViewStateAggregate] represents the observable Error, Initial,
/// Loading, and Empty state information.
class _MultiViewStateBase<T> extends StatefulWidget {
  const _MultiViewStateBase({
    required this.providers,
    required this.widgetName,
    this.listener,
    this.builder,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
    this.child,
  });

  /// Produces the combined state and declares dependencies through `.watch`.
  final MultiStateProviders<T> providers;

  /// Receives the current combined state and aggregated View State when a
  /// meaningful change passes [listenWhen].
  final _MultiViewStateListenerCallback<T>? listener;

  /// Builds the widget from the current combined state and aggregate.
  final _MultiViewStateBuilder<T>? builder;

  /// Determines whether a meaningful Multi View State change should invoke
  /// [listener].
  final ListenWhen<T>? listenWhen;

  /// Determines whether a meaningful Multi View State change should rebuild
  /// [builder].
  final RebuildWhen<T>? rebuildWhen;

  /// Whether [listener] should be called once after initialization.
  final bool callListenerOnInit;

  /// Optional subtree preserved by listener-only variants.
  final Widget? child;

  /// Name of the public widget using this private implementation.
  final String widgetName;

  @override
  State<_MultiViewStateBase<T>> createState() => _MultiViewStateBaseState<T>();
}

/// State implementation for [_MultiViewStateBase].
///
/// The state delegates shared dependency and scheduling mechanics to
/// [_MultiStateCore] and keeps the latest Multi View State aggregate locally.
class _MultiViewStateBaseState<T> extends State<_MultiViewStateBase<T>> {
  late final _MultiStateCore<T> _core;

  /// Providers currently used by the aggregated View State.
  ///
  /// Their order is preserved because the first matching provider determines
  /// Error, Loading, and Empty details.
  late List<ViewStateNotifier<dynamic>> _providers;

  /// Latest aggregated View State snapshot.
  late _MultiViewStateAggregate _currentAggregate;

  @override
  void initState() {
    super.initState();
    _core = _MultiStateCore<T>(onDependencyChange: _handleChange);
    _updateAndSync();
    if (widget.callListenerOnInit && widget.listener != null) {
      _scheduleInitialListener();
    }
  }

  @override
  void didUpdateWidget(_MultiViewStateBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAndSync();
  }

  void _updateAndSync() {
    final _DependencyCollection<T> collection = _collect();

    _core.state = collection.value;
    _providers = _resolveProviders(collection.dependencies);
    _currentAggregate = _MultiViewStateUtils._aggregate(_providers);

    _core.syncDependencies(collection.dependencies);
  }

  /// Schedules the initial listener with the state and aggregate captured
  /// during initialization.
  void _scheduleInitialListener() {
    final T initialState = _core.state;
    final _MultiViewStateAggregate initialAggregate = _currentAggregate;
    final _MultiViewStateListenerCallback<T> initialListener = widget.listener!;

    _core.listenerQueue.scheduleInitialListener(
      initialCallback: () {
        initialListener(context, initialState, initialAggregate);
      },
      isMounted: () => mounted,
    );
  }

  /// Handles a notification from one of the currently subscribed providers.
  ///
  /// Provider notifications are first converted into a new combined state
  /// and aggregate. Only meaningful changes continue to listener and rebuild
  /// processing.
  void _handleChange() {
    if (!mounted) {
      return;
    }

    final T previousState = _core.state;
    final _MultiViewStateAggregate previousAggregate = _currentAggregate;

    final _DependencyCollection<T> collection = _collect();
    final T currentState = collection.value;

    final bool dependenciesChanged = _core.syncDependencies(
      collection.dependencies,
    );

    if (dependenciesChanged) {
      _providers = _resolveProviders(collection.dependencies);
    }

    final _MultiViewStateAggregate currentAggregate =
        _MultiViewStateUtils._aggregate(_providers);

    _core.state = currentState;
    _currentAggregate = currentAggregate;

    if (!_hasMeaningfulChange(
      previousState,
      currentState,
      previousAggregate,
      currentAggregate,
    )) {
      return;
    }

    _notify(previousState, currentState);
  }

  /// Determines whether the aggregated Multi View State meaningfully changed.
  ///
  /// Aggregate changes are checked independently from the combined value.
  /// When both snapshots represent Data, the combined value is additionally
  /// compared using ProviderKit's standard equality behavior.
  bool _hasMeaningfulChange(
    T previousState,
    T currentState,
    _MultiViewStateAggregate previousAggregate,
    _MultiViewStateAggregate currentAggregate,
  ) {
    if (!previousAggregate.isSameAs(currentAggregate)) {
      return true;
    }

    if (currentAggregate.status != _MultiViewStateStatus.data) {
      return false;
    }

    return ObjectKit.shouldNotify(previousState, currentState, null);
  }

  /// Applies the user-level listener and rebuild filters after the framework
  /// has determined that a meaningful change occurred.
  void _notify(T previousState, T currentState) {
    final bool shouldRebuild =
        widget.builder != null &&
        (widget.rebuildWhen?.call(previousState, currentState) ?? true);

    final bool shouldListen =
        widget.listener != null &&
        (widget.listenWhen?.call(previousState, currentState) ?? true);

    if (shouldRebuild) {
      _core.rebuildScheduler.request(
        isMounted: () => mounted,
        rebuild: () => setState(() {}),
      );
    }

    if (shouldListen) {
      final _MultiViewStateListenerCallback<T>? listener = widget.listener;

      if (listener != null) {
        final T state = currentState;
        final _MultiViewStateAggregate aggregate = _currentAggregate;

        _core.listenerQueue.dispatch(() => listener(context, state, aggregate));
      }
    }
  }

  /// Collects the current combined state and its dependencies.
  _DependencyCollection<T> _collect() {
    return _core.collect(
      providers: widget.providers,
      widgetName: widget.widgetName,
    );
  }

  /// Converts the collected dependencies into the View State providers used
  /// for aggregation.
  ///
  /// The Multi View State API requires all watched sources to be
  /// [ViewStateNotifier] instances.
  List<ViewStateNotifier<dynamic>> _resolveProviders(
    Iterable<StateValueListenable> dependencies,
  ) {
    return dependencies
        .map((dependency) {
          if (dependency is! ViewStateNotifier<dynamic>) {
            throw StateError(
              '${widget.widgetName} can only watch ViewStateNotifier '
              'instances inside its `providers` callback. '
              'Received ${dependency.runtimeType}.',
            );
          }

          return dependency;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _core.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _MultiViewStateBuilder<T>? builder = widget.builder;

    if (builder != null) {
      return builder(context, _core.state, _currentAggregate, widget.child);
    }

    assert(
      widget.child != null,
      '''${widget.widgetName} requires a child when no builder is configured''',
    );

    return widget.child!;
  }
}

typedef _MultiViewStateListenerCallback<T> =
    void Function(
      BuildContext context,
      T state,
      _MultiViewStateAggregate aggregate,
    );

typedef _MultiViewStateBuilder<T> =
    Widget Function(
      BuildContext context,
      T state,
      _MultiViewStateAggregate aggregate,
      Widget? child,
    );
