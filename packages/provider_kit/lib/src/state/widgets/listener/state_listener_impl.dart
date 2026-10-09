part of 'state_listener.dart';

class _StateListener<T>
    extends _CallbackStateListenerBase<StateListenable<T>, T> {
  const _StateListener({
    super.key,
    required super.listener,
    required StateListenable<T> provider,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: provider);
}

/// Shared implementation for callback-based [StateListener] variants.
abstract class _CallbackStateListenerBase<P extends StateListenable<T>, T>
    extends StateListenerBase<P, T> {
  const _CallbackStateListenerBase({
    super.key,
    required super.provider,
    required this.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

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
