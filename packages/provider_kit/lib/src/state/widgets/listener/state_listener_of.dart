part of 'state_listener.dart';

class _StateListenerOf<P extends StateValueListenable<T>, T>
    extends _CallbackStateListenerBase<P, T> {
  const _StateListenerOf({
    super.key,
    required super.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);
}
