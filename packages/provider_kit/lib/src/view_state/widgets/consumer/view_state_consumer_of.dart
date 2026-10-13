part of 'view_state_consumer.dart';

/// Private implementation of [ViewStateConsumer.of].
///
/// Resolves the [ViewStateNotifier] from the widget tree.
class _ViewStateConsumerOf<P extends ViewStateNotifier<T>, T>
    extends ViewStateConsumerBase<P, T> {
  const _ViewStateConsumerOf({
    super.key,
    required super.dataBuilder,
    super.initialBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.isSliver,
  }) : super(provider: null);
}