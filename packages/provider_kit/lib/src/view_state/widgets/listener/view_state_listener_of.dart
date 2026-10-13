part of 'view_state_listener.dart';

/// Private implementation of [ViewStateListener.of].
///
/// Resolves the [ViewStateNotifier] from the widget tree.
class _ViewStateListenerOf<P extends ViewStateNotifier<T>, T>
    extends ViewStateListenerBase<P, T> {
  const _ViewStateListenerOf({
    super.key,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);
}