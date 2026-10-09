part of 'state_consumer.dart';

/// Private implementation of [StateConsumer.of].
///
/// Resolves the [StateValueListenable] from the widget tree.
class _StateConsumerOf<P extends StateValueListenable<T>, T>
    extends _CallbackStateConsumerBase<P, T> {
  const _StateConsumerOf({
    super.key,
    required super.builder,
    required super.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);
}
