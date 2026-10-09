part of 'state_consumer.dart';

/// Private implementation of [StateConsumer.of].
///
/// Resolves the [StateValueListenable] from the widget tree.
class _StateConsumerOf<P extends StateValueListenable<T>, T>
    extends StateConsumerBase<P, T> {
  const _StateConsumerOf({
    super.key,
    required this.builder,
    required this.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);

  final StateWidgetBuilder<T> builder;

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
      ..add(
        ObjectFlagProperty<StateWidgetBuilder<T>>.has(
          'builder',
          builder,
        ),
      )
      ..add(
        ObjectFlagProperty<ListenerCallback<T>>.has(
          'listener',
          listener,
        ),
      );
  }
}