part of 'state_listener.dart';

class _StateListenerOf<P extends StateValueListenable<T>, T>
    extends StateListenerBase<P, T> {
  const _StateListenerOf({
    super.key,
    required this.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);

  final ListenerCallback<T> listener;

  @override
  void onStateChange(BuildContext context, T state) {
    listener(context, state);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<ListenerCallback<T>>.has('listener', listener),
    );
  }
}