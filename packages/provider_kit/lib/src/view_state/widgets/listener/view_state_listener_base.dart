part of 'view_state_listener.dart';

/// Base class for [ViewStateListener] implementations.
///
/// Provides shared configuration and behavior for listening to
/// [ViewStateNotifier] providers and responding to their state changes.
abstract class ViewStateListenerBase<P extends ViewStateNotifier<T>, T>
    extends StateListenerBase<P, ViewState<T>> {

  /// {@template provider_kit.view_state.initial_listener}
  /// Called when the provider is in [InitialState].
  /// {@endtemplate}
  final InitialStateListener? initialStateListener;

  /// {@template provider_kit.view_state.loading_listener}
  /// Called when the provider is in [LoadingState].
  ///
  /// The callback receives the loading message and progress.
  /// {@endtemplate}
  final LoadingStateListener? loadingStateListener;

  /// {@template provider_kit.view_state.empty_listener}
  /// Called when the provider is in [EmptyState].
  ///
  /// The callback receives the empty-state message.
  /// {@endtemplate}
  final EmptyStateListener? emptyStateListener;

  /// {@template provider_kit.view_state.error_listener}
  /// Called when the provider is in [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, and a
  /// retry callback.
  /// {@endtemplate}
  final ErrorStateListener? errorStateListener;

  /// {@template provider_kit.view_state.data_listener}
  /// Called when the provider is in [DataState].
  ///
  /// The callback receives the data contained in the [DataState].
  /// {@endtemplate}
  final DataStateListener<T>? dataStateListener;

  const ViewStateListenerBase({
    super.key,
    super.provider,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

  @override
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
  String get debugWidgetName => 'ViewStateListener<$T>';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener',
          initialStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener',
          loadingStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener',
          emptyStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener',
          errorStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<DataStateListener<T>?>.has(
          'dataStateListener',
          dataStateListener,
        ),
      );
  }
}
