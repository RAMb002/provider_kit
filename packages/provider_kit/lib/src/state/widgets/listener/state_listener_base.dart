part of 'state_listener.dart';

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateListenable<T>, T>
    extends StateListener<T> {
  const StateListenerBase({
    super.key,
    this.listenable,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.state_listener.listenable}
  /// The listenable whose state should be listened to.
  ///
  /// When null, the listenable is resolved from the current [BuildContext].
  /// {@endtemplate}
  final P? listenable;

  void onStateChange(BuildContext context, T state);

  @override
  State<StateListenerBase<P, T>> createState() => _StateListenerState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<P?>('listenable', listenable, defaultValue: null),
    );
  }
}

class _StateListenerState<P extends StateListenable<T>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return StateEngine<P, T>(
      listenable: widget.listenable,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget.onStateChange,
      widgetName: widget.debugWidgetName,
      child: child,
    );
  }
}
