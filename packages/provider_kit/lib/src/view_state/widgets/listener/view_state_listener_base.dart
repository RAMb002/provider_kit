part of 'view_state_listener.dart';

/// Base class for [ViewStateListener] implementations.
///
/// Provides shared configuration and behavior for listening to
/// [ViewStateNotifier] instances and responding to their state changes.
abstract class ViewStateListenerBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateListener<T> {
  const ViewStateListenerBase({
    super.key,
    this.listenable,
    this.listenWhen,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.view_state_widget.listenable}
  /// The view-state notifier whose state should be listened to.
  ///
  /// When null, the notifier is resolved from the current [BuildContext].
  /// {@endtemplate}
  final P? listenable;

  /// {@template provider_kit.view_state_listener.listen_when}
  /// Determines whether the listener should be called when the view state changes.
  /// The callback receives the previous and current view states.
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final ListenWhen<ViewState<T>>? listenWhen;

  /// Dispatches the current state to its corresponding callback.
  void onStateChange(BuildContext context, ViewState<T> state) {
    ViewStateWidgetUtils.handleListener<T>(
      state: state,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      dataStateListener: dataStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
    );
  }

  @override
  State<ViewStateListenerBase<P, T>> createState() =>
      _ViewStateListenerBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<P?>('listenable', listenable, defaultValue: null))
      ..add(
        ObjectFlagProperty<ListenWhen<ViewState<T>>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}

/// Connects [ViewStateListenerBase] to the shared [StateEngine] implementation.
class _ViewStateListenerBaseState<P extends ViewStateNotifier<T>, T>
    extends SingleChildState<ViewStateListenerBase<P, T>> {
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return StateEngine<P, ViewState<T>>(
      listenable: widget.listenable,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: widget.onStateChange,
      widgetName: widget.debugWidgetName,
      child: child,
    );
  }
}
