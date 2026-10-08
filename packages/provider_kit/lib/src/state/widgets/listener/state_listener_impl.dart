part of 'state_listener.dart';

class _StateListener<T> extends StateListenerBase<StateValueListenable<T>, T> {
  const _StateListener({
    super.key,
    required this.listener,
    required StateValueListenable<T> provider,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: provider);

  /// {@template provider_kit.state_listener.listener}
  /// The listener function that is called when the state changes.
  /// {@endtemplate}
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
