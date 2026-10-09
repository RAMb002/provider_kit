part of 'state_consumer.dart';

/// Private implementation of [StateConsumer].
///
/// Configures a consumer for a directly provided [StateValueListenable].
class _StateConsumer<T> extends StateConsumerBase<StateValueListenable<T>, T> {
  const _StateConsumer({
    super.key,
    required StateValueListenable<T> provider,
    required this.builder,
    required this.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: provider);

  /// {@macro provider_kit.state_builder.builder}
  final StateWidgetBuilder<T> builder;

  /// {@macro provider_kit.state_listener.listener}
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
