part of 'state_consumer.dart';

/// Private implementation of [StateConsumer.multi].
///
/// Provides the concrete multi-provider consumer configuration.
class _MultiStateConsumer<T> extends MultiStateConsumerBase<T> {
  const _MultiStateConsumer({
    super.key,
    required super.providers,
    required this.builder,
    required this.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

  /// {@macro provider_kit.multi_state.builder_param}
  final StateWidgetBuilder<T> builder;

  /// {@macro provider_kit.multi_state.listener_param}
  final ListenerCallback<T> listener;

  @override
  Widget build(BuildContext context, T state, Widget? child) {
    return builder(context, state, child);
  }

  @override
  void onStateChange(BuildContext context, T state) {
    listener(context, state);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder))
      ..add(ObjectFlagProperty<ListenerCallback<T>>.has('listener', listener));
  }
}

/// Base class for multi-state consumers.
///
/// Provides the shared public configuration for multi-provider
/// [StateConsumer] implementations.
///
/// The actual dependency tracking, state collection, subscriptions,
/// equality checks, rebuild scheduling, and listener scheduling are handled
/// by the internal [MultiStateBase] implementation.
abstract class MultiStateConsumerBase<T> extends StateConsumer<T> {
  const MultiStateConsumerBase({
    super.key,
    required this.providers,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@macro provider_kit.multi_state.providers_param}
  ///
  /// The returned value becomes the combined state passed to [builder],
  /// [listener], [rebuildWhen], and [listenWhen].
  final MultiStateProviders<T> providers;

  /// Builds the widget tree from the current combined state.
  Widget build(BuildContext context, T state, Widget? child);

  /// Handles a listener notification for the current combined state.
  void onStateChange(BuildContext context, T state);

  @override
  String get debugWidgetName => 'StateConsumer<$T>.multi';

  @override
  State<MultiStateConsumerBase<T>> createState() =>
      _MultiStateConsumerBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
    );
  }
}

class _MultiStateConsumerBaseState<T> extends State<MultiStateConsumerBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiStateBase<T>(
      providers: widget.providers,
      builder: widget.build,
      listener: widget.onStateChange,
      rebuildWhen: widget.rebuildWhen,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      widgetName: widget.debugWidgetName,
      child: widget.child,
    );
  }
}
