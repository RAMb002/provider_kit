part of '../view_state_widgets.dart';

/// {@template provider_kit.view_state_listener}
/// A widget that listens to changes in a [ViewStateNotifier] and triggers callbacks
/// based on the specific [ViewState].
///
/// The [ViewStateListener] is used to perform actions in response to different view states
/// such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate callback is called based on the current view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateListener<Provider, DataType>(
///   provider: provider,
///   callListenerOnInit: false, // Optional, default is false
///   initialStateListener: () {
///     // Handle initial state
///   },
///   loadingStateListener: (message, progress) {
///     // Handle loading state
///   },
///   emptyStateListener: (message) {
///     // Handle empty state
///   },
///   errorStateListener: (errorInfo, error, stackTrace, onRetry) {
///     // Handle error state
///   },
///   dataStateListener: (data) {
///     // Handle data state
///   },
///   child: SomeWidget(),
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [ViewStateListener.of] to resolve it from the widget tree:
///
/// ```dart
/// ViewStateListener.of<MyProvider, DataType>(
///   loadingStateListener: (message, progress) {
///     // Handle loading state.
///   },
///   dataStateListener: (data) {
///     // Handle data state.
///   },
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
///
class ViewStateListener<T>
    extends ViewStateListenerBase<ViewStateNotifier<T>, T> {
  /// {@macro provider_kit.view_state_listener}
  ViewStateListener({
    super.key,
    required ViewStateNotifier<T> provider,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: provider);

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// ViewStateListener.of<MyProvider, DataType>(
  ///   loadingStateListener: (message, progress) {
  ///     // Handle loading state.
  ///   },
  ///   dataStateListener: (data) {
  ///     // Handle data state.
  ///   },
  ///   child: SomeWidget(),
  /// )
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return _ViewStateListenerOf<P, T>(
      key: key,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
      dataStateListener: dataStateListener,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      child: child,
    );
  }
}

class _ViewStateListenerOf<P extends ViewStateNotifier<T>, T>
    extends ViewStateListenerBase<P, T> {
  _ViewStateListenerOf({
    super.key,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);
}

abstract class ViewStateListenerBase<P extends ViewStateNotifier<T>, T>
    extends StateListenerBase<P, ViewState<T>> {
  final InitialStateListener? initialStateListener;
  final LoadingStateListener? loadingStateListener;
  final EmptyStateListener? emptyStateListener;
  final ErrorStateListener? errorStateListener;
  final DataStateListener<T>? dataStateListener;

  ViewStateListenerBase({
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
  }) : super(
          listener: _createViewStateListener<T>(
            initialStateListener: initialStateListener,
            loadingStateListener: loadingStateListener,
            emptyStateListener: emptyStateListener,
            errorStateListener: errorStateListener,
            dataStateListener: dataStateListener,
          ),
        );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener', initialStateListener))
      ..add(ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener', loadingStateListener))
      ..add(ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener', emptyStateListener))
      ..add(ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener', errorStateListener))
      ..add(ObjectFlagProperty<DataStateListener<T>?>.has(
          'dataStateListener', dataStateListener));
  }
}

ListenerCallback<ViewState<T>> _createViewStateListener<T>({
  InitialStateListener? initialStateListener,
  LoadingStateListener? loadingStateListener,
  EmptyStateListener? emptyStateListener,
  ErrorStateListener? errorStateListener,
  DataStateListener<T>? dataStateListener,
}) {
  return (context, state) {
    state.when(
      initialState: () => initialStateListener?.call(),
      loadingState: (message, progress) =>
          loadingStateListener?.call(message, progress),
      dataState: (data) => dataStateListener?.call(data),
      emptyState: (message) => emptyStateListener?.call(message),
      errorState: (errorMessage, onRetry, exception, stackTrace) =>
          errorStateListener?.call(
        errorMessage,
        onRetry,
        exception,
        stackTrace,
      ),
    );
  };
}
