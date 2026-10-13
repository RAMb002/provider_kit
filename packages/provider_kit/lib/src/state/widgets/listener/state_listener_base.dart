part of 'state_listener.dart';

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateListenable<T>, T>
    extends StateListener<T> {
  const StateListenerBase({
    super.key,
    this.provider,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.state_listener.provider}
  /// The provider whose state should be listened to.
  ///
  /// When null, the provider is resolved from the current [BuildContext].
  /// {@endtemplate}
  final P? provider;

  void onStateChange(BuildContext context, T state);

  @override
  State<StateListenerBase<P, T>> createState() => _StateListenerState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<P?>('provider', provider, defaultValue: null),
    );
  }
}

class _StateListenerState<P extends StateListenable<T>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return StateEngine<P, T>(
      provider: widget.provider,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget.onStateChange,
      widgetName: widget.debugWidgetName,
      child: child,
    );
  }
}
