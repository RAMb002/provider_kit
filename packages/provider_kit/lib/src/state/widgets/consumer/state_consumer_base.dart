part of 'state_consumer.dart';

/// Base class for [StateConsumer] implementations.
///
/// Provides shared configuration and behavior for single-provider
/// consumers.
///
/// The actual provider resolution, subscriptions, equality checks, rebuild
/// scheduling, and listener scheduling are handled by this base's state.
abstract class StateConsumerBase<P extends StateValueListenable<T>, T>
    extends StateConsumer<T> {
  const StateConsumerBase({
    super.key,
    this.provider,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.state_listener.provider}
  final P? provider;

  /// Builds the widget tree using the current state.
  Widget build(BuildContext context, T state, Widget? child);

  /// Handles a state change after [listenWhen] allows the notification.
  void onStateChange(BuildContext context, T state);

  @override
  State<StateConsumerBase<P, T>> createState() =>
      _StateConsumerBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<P?>('provider', provider));
  }
}

class _StateConsumerBaseState<P extends StateValueListenable<T>, T>
    extends State<StateConsumerBase<P, T>> {
  late P _provider;
  final ListenerQueue _listenerQueue = ListenerQueue();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    if (widget.callListenerOnInit) {
      final T initialState = _provider.state;
      final ListenerCallback<T> initialListener = widget.onStateChange;
      _listenerQueue.scheduleInitialListener(
        initialCallback: () => initialListener(context, initialState),
        isMounted: () => mounted,
      );
    }
  }

  @override
  void didUpdateWidget(StateConsumerBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? _readProvider;
    if (oldProvider != currentProvider) {
      _provider = widget.provider ?? _readProvider;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) _provider = provider;
  }

  @override
  void dispose() {
    _listenerQueue.clear();
    super.dispose();
  }

  bool _handleStateChange(T previous, T current) {
    final shouldListen = ObjectKit.shouldNotify<T>(
      previous,
      current,
      widget.listenWhen,
    );

    if (shouldListen) {
      _listenerQueue.dispatch(() => widget.onStateChange(context, current));
    }

    return ObjectKit.shouldNotify<T>(previous, current, widget.rebuildWhen);
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  @override
  Widget build(BuildContext context) {
    if (widget.provider == null) {
      context.select<P, bool>((provider) => identical(_provider, provider));
    }
    return StateBuilder<T>(
      provider: _provider,
      builder: widget.build,
      rebuildWhen: _handleStateChange,
      child: widget.child,
    );
  }
}
