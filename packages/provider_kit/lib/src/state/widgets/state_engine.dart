import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/index.dart';
import 'package:provider_kit/src/state/internal/listener_queue.dart';
import 'package:provider_kit/src/state/internal/rebuild_scheduler.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/utils/equality_check.dart';

/// Internal engine shared by single-provider state builders, listeners,
/// and consumers.
///
/// Manages provider resolution, state subscriptions, state comparisons,
/// callback scheduling, and disposal.
///
/// The [builder] and [listener] determine how the engine behaves:
/// - A builder only rebuilds when [rebuildWhen] allows it.
/// - A listener only invokes callbacks when [listenWhen] allows it.
/// - Both callbacks can be supplied to support consumer widgets.
///
/// When [provider] is null, the provider is resolved from the current
/// [BuildContext].
@internal
final class StateEngine<P extends StateListenable<T>, T>
    extends StatefulWidget {
  const StateEngine({
    super.key,
    this.provider,
    this.listener,
    this.listenWhen,
    this.rebuildWhen,
    this.callListenerOnInit = false,
    this.builder,
    this.child,
    required this.widgetName,
  });

  /// The provider whose state is observed.
  ///
  /// When null, the provider is resolved from the current [BuildContext].
  final P? provider;

  /// Called when the state changes and [listenWhen] allows the notification.
  final ListenerCallback<T>? listener;

  /// Determines whether [listener] should be called after a state change.
  final ListenWhen<T>? listenWhen;

  /// Determines whether [builder] should rebuild after a state change.
  final RebuildWhen<T>? rebuildWhen;

  /// Whether [listener] should be called once after initialization.
  ///
  /// The initial callback is scheduled after the first frame. Listener
  /// notifications received before it runs are delivered afterward in order.
  final bool callListenerOnInit;

  /// Builds the widget from the latest state accepted by [rebuildWhen].
  ///
  /// When null, the engine preserves [child] directly.
  final StateWidgetBuilder<T>? builder;

  /// Optional subtree passed to [builder] or preserved directly when no
  /// builder is configured.
  final Widget? child;

  /// Name of the public widget using this engine.
  ///
  /// Used in assertions and diagnostic messages.
  final String widgetName;

  @override
  State<StateEngine<P, T>> createState() => _StateEngineState<P, T>();
}

/// Manages the subscription and state lifecycle for [StateEngine].
class _StateEngineState<P extends StateListenable<T>, T>
    extends State<StateEngine<P, T>> {
  late P _provider;
  late T _previousState;
  late T _state;

  final ListenerQueue _listenerQueue = ListenerQueue();
  final RebuildScheduler _rebuildScheduler = RebuildScheduler();

  /// Gets the current state directly from the provider.
  T get _currentState => _provider.state;

  @override
  void initState() {
    super.initState();

    _provider = widget.provider ?? _readProvider;

    _state = _currentState;
    _previousState = _state;

    _attachListener();

    if (widget.callListenerOnInit && widget.listener != null) {
      _scheduleInitialListener();
    }
  }

  /// Schedules the initial listener callback with the initial state snapshot.
  void _scheduleInitialListener() {
    final T initialState = _currentState;
    final ListenerCallback<T> initialListener = widget.listener!;

    _listenerQueue.scheduleInitialListener(
      initialCallback: () => initialListener(context, initialState),
      isMounted: () => mounted,
    );
  }

  @override
  void didUpdateWidget(StateEngine<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _syncProvider();

    // If a builder is added to an existing listener-only engine, establish
    // the current provider state as its initial build state.
    if (oldWidget.builder == null && widget.builder != null) {
      _state = _currentState;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Context-resolved providers may change independently of widget updates.
    if (widget.provider == null) {
      _syncProvider();
    }
  }

  /// Resolves the effective provider and updates the subscription if needed.
  ///
  /// Replacing the provider establishes a new state baseline without
  /// invoking listener or rebuild callbacks.
  void _syncProvider() {
    final P nextProvider = widget.provider ?? _readProvider;

    if (identical(_provider, nextProvider)) {
      return;
    }

    _detachListener(_provider);

    _provider = nextProvider;

    _state = _currentState;
    _previousState = _state;

    _attachListener();
  }

  /// Handles notifications from the current provider.
  ///
  /// Listening and rebuilding are evaluated independently. A single provider
  /// notification can trigger either behavior, both, or neither.
  void _handleChange() {
    if (!mounted) {
      return;
    }

    final T previousState = _previousState;
    final T currentState = _currentState;

    // Advance the change-detection baseline.
    _previousState = currentState;

    // Evaluate listening and rebuilding independently.
    final bool shouldListen =
        widget.listener != null &&
        ObjectKit.shouldNotify<T>(
          previousState,
          currentState,
          widget.listenWhen,
        );

    final bool shouldRebuild =
        widget.builder != null &&
        ObjectKit.shouldNotify<T>(
          previousState,
          currentState,
          widget.rebuildWhen,
        );

    // Update the build snapshot before invoking user callbacks, so a
    // synchronous state change from a listener cannot be overwritten by
    // this notification afterward.
    if (shouldRebuild) {
      _state = currentState;

      _rebuildScheduler.request(
        isMounted: () => mounted,
        rebuild: () => setState(() {}),
      );
    }

    if (shouldListen) {
      _listenerQueue.dispatch(
        () => widget.listener?.call(context, currentState),
      );
    }
  }

  /// Attaches the state-change callback to the current provider.
  void _attachListener() {
    _provider.addListener(_handleChange);
  }

  /// Removes the state-change callback from the specified provider.
  void _detachListener(P provider) {
    provider.removeListener(_handleChange);
  }

  /// Reads the provider from the current context.
  P get _readProvider => context.read<P>();

  @override
  void dispose() {
    _listenerQueue.clear();
    _detachListener(_provider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.provider == null) {
      // Track provider replacement without subscribing to every state
      // notification through the Provider dependency.
      context.select<P, bool>((provider) => identical(_provider, provider));
    }

    final StateWidgetBuilder<T>? builder = widget.builder;

    if (builder != null) {
      return builder(context, _state, widget.child);
    }

    assert(widget.child != null, '${widget.widgetName} requires a child.');

    return widget.child!;
  }
}
