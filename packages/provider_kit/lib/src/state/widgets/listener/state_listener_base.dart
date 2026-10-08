part of 'state_listener.dart';

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateValueListenable<T>, T>
    extends StateListener<T> {
  const StateListenerBase({
    super.key,
    this.provider,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.state_listener.provider}
  /// The provider whose state should be listened to.
  ///
  /// When null, the provider is resolved from the current [BuildContext].
  /// {@endtemplate}
  final P? provider;

  void onStateChange(BuildContext context, T state);

  @override
  State<StateListenerBase<P, T>> createState() => _StateListenerState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<P?>('provider', provider, defaultValue: null),
    );
  }
}

class _StateListenerState<P extends StateValueListenable<T>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  late T _previousState;
  late P _provider;
  final ListenerQueue _listenerQueue = ListenerQueue();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    _previousState = _currentState;
    _attachListener();

    if (widget.callListenerOnInit) {
      final T initialState = _currentState;
      final ListenerCallback<T> initialListener = widget.onStateChange;
      _listenerQueue.scheduleInitialListener(
        initialCallback: () => initialListener(context, initialState),
        isMounted: () => mounted,
      );
    }
  }

  @override
  void didUpdateWidget(StateListenerBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? oldProvider;
    if (oldProvider != currentProvider) {
      _detachListener(oldProvider);
      _provider = currentProvider;
      _previousState = _currentState;
      _attachListener();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) {
      _detachListener(_provider);
      _provider = provider;
      _previousState = _currentState;
      _attachListener();
    }
  }

  @override
  void dispose() {
    _listenerQueue.clear();
    _detachListener(_provider);
    super.dispose();
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  /// Gets the current state from the provider.
  T get _currentState => _provider.state;

  /// The listener function that is called when the state changes.
  void _listener() {
    final currentState = _currentState;

    final shouldCallListener = ObjectKit.shouldNotify<T>(
      _previousState,
      currentState,
      widget.listenWhen,
    );

    _previousState = currentState;

    if (!shouldCallListener) {
      return;
    }

    _listenerQueue.dispatch(() => widget.onStateChange(context, currentState));
  }

  /// Attaches the listener to the provider.
  void _attachListener() {
    _provider.addListener(_listener);
  }

  /// Detaches the listener from the provider.
  void _detachListener(P provider) {
    provider.removeListener(_listener);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(child != null, '${widget.debugWidgetName} requires a child.');

    if (widget.provider == null) {
      context.select<P, bool>((provider) => identical(_provider, provider));
    }

    return child!;
  }
}
