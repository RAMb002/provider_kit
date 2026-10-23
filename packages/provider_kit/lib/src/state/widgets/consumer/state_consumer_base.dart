part of 'state_consumer.dart';

/// Base class for [StateConsumer] implementations.
///
/// Provides shared configuration and behavior for single-listenable
/// consumers.
///
/// The actual listenable resolution, subscriptions, equality checks, rebuild
/// scheduling, and listener scheduling are handled by this base's state.
abstract class StateConsumerBase<P extends StateListenable<T>, T>
    extends StateConsumer<T> {
  const StateConsumerBase({
    super.key,
    this.listenable,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.state_listener.listenable}
  final P? listenable;

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
    properties.add(DiagnosticsProperty<P?>('listenable', listenable));
  }
}

class _StateConsumerBaseState<P extends StateListenable<T>, T>
    extends State<StateConsumerBase<P, T>> {
  @override
  Widget build(BuildContext context) {
    return StateEngine<P, T>(
      listenable: widget.listenable,
      rebuildWhen: widget.rebuildWhen,
      builder: widget.build,
      listener: widget.onStateChange,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      widgetName: widget.debugWidgetName,
      child: widget.child,
    );
  }
}
