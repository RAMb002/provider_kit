part of 'state_listener.dart';

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateListenable<dynamic>, T>
    extends StateListener<T> {
  const StateListenerBase({
    super.key,
    this.listenable,
    this.selectListenable,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.state_listener.listenable}
  /// The listenable whose state should be listened to.
  ///
  /// When null, the listenable is resolved from the current [BuildContext].
  /// {@endtemplate}
  final StateListenable<T>? listenable;

  /// {@template provider_kit.state_listener.select_listenable}
  /// Selects the [StateListenable] whose state should be observed from a
  /// Provider-managed object.
  ///
  /// The callback receives the provided object and returns the listenable
  /// to observe. This is useful for listening to resources owned by a
  /// notifier, such as a [Mutation] or [StateField].
  ///
  /// The callback may be evaluated multiple times, so return an existing
  /// listenable rather than creating a new instance.
  /// {@endtemplate}
  final SelectStateListenable<P, T>? selectListenable;

  void onStateChange(BuildContext context, T state);

  @override
  State<StateListenerBase<P, T>> createState() => _StateListenerState<P, T>();
}

class _StateListenerState<P extends StateListenable<dynamic>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return StateEngine<P, T>(
      listenable: widget.listenable,
      selectListenable: widget.selectListenable,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget.onStateChange,
      widgetName: widget.debugWidgetName,
      child: child,
    );
  }
}
