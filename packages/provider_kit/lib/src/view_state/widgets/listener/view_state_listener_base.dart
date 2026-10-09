part of 'view_state_listener.dart';

/// Base class for [ViewStateListener] implementations.
///
/// Provides shared configuration and behavior for listening to
/// [ViewStateNotifier] providers and responding to their state changes.
abstract class ViewStateListenerBase<P extends ViewStateNotifier<T>, T>
    extends ViewStateListener<T> {
  const ViewStateListenerBase({
    super.key,
    this.provider,
    this.listenWhen,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.callListenerOnInit,
    super.child,
  }) : super.base();

  /// {@template provider_kit.view_state_listener.provider}
  /// The provider whose ViewState should be listened to.
  ///
  /// When null, the provider is resolved from the current [BuildContext].
  /// {@endtemplate}
  final P? provider;

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
    state.when(
      initialState: () {
        initialStateListener?.call();
      },
      loadingState: (message, progress) {
        loadingStateListener?.call(message, progress);
      },
      dataState: (data) {
        dataStateListener?.call(data);
      },
      emptyState: (message) {
        emptyStateListener?.call(message);
      },
      errorState: (errorInfo, error, stackTrace, onRetry) {
        errorStateListener?.call(errorInfo, error, stackTrace, onRetry);
      },
    );
  }

  @override
  State<ViewStateListenerBase<P, T>> createState() =>
      _ViewStateListenerBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<P?>('provider', provider, defaultValue: null))
      ..add(
        ObjectFlagProperty<ListenWhen<ViewState<T>>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}

/// Delegates single-provider listening to [StateListener].
class _ViewStateListenerBaseState<P extends ViewStateNotifier<T>, T>
    extends SingleChildState<ViewStateListenerBase<P, T>> {

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {

    final ListenerCallback<ViewState<T>> listener = widget.onStateChange;

    final provider = widget.provider;

    if (provider != null) {
      return StateListener<ViewState<T>>(
        provider: provider,
        listenWhen: widget.listenWhen,
        callListenerOnInit: widget.callListenerOnInit,
        listener: listener,
        child: child,
      );
    }

    return StateListener.of<P, ViewState<T>>(
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      listener: listener,
      child: child,
    );
  }
}
