part of 'state_consumer.dart';

/// Private implementation of [StateConsumer].
///
/// Configures a consumer for a [StateListenable] passed directly to the widget.
class _StateConsumer<T>
    extends _CallbackStateConsumerBase<StateListenable<T>, T> {
  const _StateConsumer({
    super.key,
    required StateListenable<T> listenable,
    super.selectListenable,
    required super.builder,
    required super.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(listenable: listenable);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<StateListenable<T>?>('listenable', listenable),
    );
  }
}

/// Shared implementation for callback-based [StateConsumer] variants.
abstract class _CallbackStateConsumerBase<P extends StateListenable<dynamic>, T>
    extends StateConsumerBase<P, T> {
  const _CallbackStateConsumerBase({
    super.key,
    super.listenable,
    required this.builder,
    required this.listener,
    super.selectListenable,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

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
