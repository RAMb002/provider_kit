part of 'view_state_listener.dart';

/// Private implementation of [ViewStateListener].
///
/// Configures a listener for a directly provided [ViewStateNotifier].
class _ViewStateListener<T> extends ViewStateListener<T> {
  const _ViewStateListener({
    super.key,
    required ViewStateNotifier<T> provider,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base(provider: provider);
}
