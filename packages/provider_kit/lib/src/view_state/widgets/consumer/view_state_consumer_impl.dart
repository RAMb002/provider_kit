part of 'view_state_consumer.dart';

/// Private implementation of [ViewStateConsumer].
///
/// Configures a consumer for a directly provided [ViewStateNotifier].
class _ViewStateConsumer<T>
    extends ViewStateConsumerBase<ViewStateNotifier<T>, T> {
  const _ViewStateConsumer({
    super.key,
    required ViewStateNotifier<T> provider,
    super.rebuildWhen,
    super.listenWhen,
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
    super.callListenerOnInit,
    super.isSliver,
  }) : super(provider: provider);
}