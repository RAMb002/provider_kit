import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';

/// {@template provider_kit.view_state}
/// A sealed class representing the different states of a view.
///
/// [ViewState] provides a common type for representing the lifecycle of
/// view-related data, including initial, loading, data, empty, and error
/// states.
///
/// Use the concrete state classes such as [InitialState], [LoadingState],
/// [DataState], [EmptyState], and [ErrorState] to represent the current state.
/// {@endtemplate}
sealed class ViewState<T> {
  /// {@macro provider_kit.view_state}
  const ViewState();

  /// Executes the callback corresponding to the current state.
  ///
  /// All state callbacks are required, so every possible state must be handled.
  ///
  /// Use [when] when you want to provide behavior for every state.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final text = state.when(
  ///   initialState: () => 'Initial',
  ///   loadingState: (_, __) => 'Loading',
  ///   dataState: (data) => 'Data: $data',
  ///   emptyState: (_) => 'No data',
  ///   errorState: (errorInfo, error, stackTrace, onRetry) =>
  ///       errorInfo.message,
  /// );
  /// ```
  R when<R extends Object?>({
    required InitialStateCallback<R> initialState,
    required LoadingStateCallback<R> loadingState,
    required DataStateCallback<T, R> dataState,
    required EmptyStateCallback<R> emptyState,
    required ErrorStateCallback<R> errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState(),
      LoadingState<T>() => loadingState(state.message, state.progress),
      DataState<T>() => dataState(state.data),
      EmptyState<T>() => emptyState(state.message),
      ErrorState<T>() => errorState(
          state.errorInfo,
          state.error,
          state.stackTrace,
          state.onRetry,
        ),
    };
  }

  /// Executes the callback corresponding to the current state.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, [orElse] is invoked instead.
  ///
  /// Use [maybeWhen] when you want to handle only specific states and provide
  /// your own fallback behavior for all other states.
  ///
  /// ### Example
  ///
  /// ```dart
  /// state.maybeWhen(
  ///   errorState: (errorInfo, error, stackTrace, onRetry) {
  ///     showError(errorInfo.message);
  ///   },
  ///   orElse: () {
  ///     showContent();
  ///   },
  /// );
  /// ```
  R maybeWhen<R extends Object?>({
    required R Function() orElse,
    InitialStateCallback<R>? initialState,
    LoadingStateCallback<R>? loadingState,
    DataStateCallback<T, R>? dataState,
    EmptyStateCallback<R>? emptyState,
    ErrorStateCallback<R>? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState == null ? orElse() : initialState(),
      LoadingState<T>() => loadingState == null
          ? orElse()
          : loadingState(state.message, state.progress),
      DataState<T>() => dataState == null ? orElse() : dataState(state.data),
      EmptyState<T>() =>
        emptyState == null ? orElse() : emptyState(state.message),
      ErrorState<T>() => errorState == null
          ? orElse()
          : errorState(
              state.errorInfo,
              state.error,
              state.stackTrace,
              state.onRetry,
            ),
    };
  }

  /// Executes the callback corresponding to the current state.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, this method returns `null`.
  ///
  /// Use [whenOrNull] when you want to handle only specific states and do not
  /// need custom fallback behavior for the remaining states.
  ///
  /// ### Example
  ///
  /// ```dart
  /// state.whenOrNull(
  ///   errorState: (errorInfo, error, stackTrace, onRetry) {
  ///     showError(errorInfo.message);
  ///   },
  /// );
  /// ```
  ///
  /// In this example, `errorState` is invoked only for [ErrorState].
  /// For all other states, `whenOrNull` returns `null`.
  R? whenOrNull<R extends Object?>({
    InitialStateCallback<R>? initialState,
    LoadingStateCallback<R>? loadingState,
    DataStateCallback<T, R>? dataState,
    EmptyStateCallback<R>? emptyState,
    ErrorStateCallback<R>? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState?.call(),
      LoadingState<T>() => loadingState?.call(
          state.message,
          state.progress,
        ),
      DataState<T>() => dataState?.call(state.data),
      EmptyState<T>() => emptyState?.call(state.message),
      ErrorState<T>() => errorState?.call(
          state.errorInfo,
          state.error,
          state.stackTrace,
          state.onRetry,
        ),
    };
  }

  /// Maps the current state to a corresponding callback.
  ///
  /// All state callbacks are required, so every possible state must be handled.
  ///
  /// The callbacks receive the complete state object rather than individual
  /// state values.
  ///
  /// Use [map] when you prefer to work with the complete state object.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final text = state.map(
  ///   initialState: (_) => 'Initial',
  ///   loadingState: (state) => 'Loading: ${state.message}',
  ///   dataState: (state) => 'Data: ${state.data}',
  ///   emptyState: (state) => 'No data',
  ///   errorState: (state) => 'Error: ${state.errorInfo.message}',
  /// );
  /// ```
  R map<R extends Object?>({
    required InitialStateMapper<R, T> initialState,
    required LoadingStateMapper<R, T> loadingState,
    required DataStateMapper<R, T> dataState,
    required EmptyStateMapper<R, T> emptyState,
    required ErrorStateMapper<R, T> errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState(state),
      LoadingState<T>() => loadingState(state),
      DataState<T>() => dataState(state),
      EmptyState<T>() => emptyState(state),
      ErrorState<T>() => errorState(state),
    };
  }

  /// Maps the current state to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, [orElse] is invoked instead.
  ///
  /// The callbacks receive the complete state object rather than individual
  /// state values.
  ///
  /// Use [maybeMap] to handle only specific states while providing a fallback
  /// through [orElse].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final widget = state.maybeMap(
  ///   dataState: (state) => Text('Data: ${state.data}'),
  ///   errorState: (state) => Text(state.errorInfo.message),
  ///   orElse: () => const CircularProgressIndicator(),
  /// );
  /// ```
  R maybeMap<R extends Object?>({
    required R Function() orElse,
    InitialStateMapper<R, T>? initialState,
    LoadingStateMapper<R, T>? loadingState,
    DataStateMapper<R, T>? dataState,
    EmptyStateMapper<R, T>? emptyState,
    ErrorStateMapper<R, T>? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() =>
        initialState == null ? orElse() : initialState(state),
      LoadingState<T>() =>
        loadingState == null ? orElse() : loadingState(state),
      DataState<T>() => dataState == null ? orElse() : dataState(state),
      EmptyState<T>() => emptyState == null ? orElse() : emptyState(state),
      ErrorState<T>() => errorState == null ? orElse() : errorState(state),
    };
  }

  /// Maps the current state to a corresponding callback.
  ///
  /// Only the callbacks you provide are invoked. If the current state does
  /// not have a matching callback, this method returns `null`.
  ///
  /// The callbacks receive the complete state object rather than individual
  /// state values.
  ///
  /// Use [mapOrNull] to handle only specific states without providing a
  /// fallback.
  ///
  /// ### Example
  ///
  /// ```dart
  /// state.mapOrNull(
  ///   errorState: (state) => state.errorInfo.message,
  /// );
  /// ```
  ///
  /// In this example, the callback is invoked only for [ErrorState].
  /// For all other states, `mapOrNull` returns `null`.
  R? mapOrNull<R extends Object?>({
    InitialStateMapper<R, T>? initialState,
    LoadingStateMapper<R, T>? loadingState,
    DataStateMapper<R, T>? dataState,
    EmptyStateMapper<R, T>? emptyState,
    ErrorStateMapper<R, T>? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState?.call(state),
      LoadingState<T>() => loadingState?.call(state),
      DataState<T>() => dataState?.call(state),
      EmptyState<T>() => emptyState?.call(state),
      ErrorState<T>() => errorState?.call(state),
    };
  }

  /// Whether this view is in the initial state.
  bool get isInitial => this is InitialState<T>;

  /// Whether this view is currently loading.
  bool get isLoading => this is LoadingState<T>;

  /// Whether this view contains data.
  bool get isData => this is DataState<T>;

  /// Whether this view is empty.
  bool get isEmpty => this is EmptyState<T>;

  /// Whether this view represents an error.
  bool get isError => this is ErrorState<T>;
}

/// Represents the initial state of a view.
class InitialState<T> extends ViewState<T> {
  const InitialState();
}

/// Represents the loading state of a view.
///
/// [message] optionally describes the current loading operation.
/// [progress] optionally indicates the loading progress.
class LoadingState<T> extends ViewState<T> {
  final String? message;
  final double? progress;
  const LoadingState([this.message, this.progress]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingState &&
        other.message == message &&
        other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(message, progress);

  @override
  String toString() =>
      'LoadingState { message: $message, progress: $progress }';
}

/// Represents the empty state of a view.
///
/// [message] optionally describes why no data is available.
class EmptyState<T> extends ViewState<T> {
  final String? message;
  const EmptyState([this.message]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmptyState && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'EmptyState { message: $message }';
}

/// Represents the data state of a view.
///
/// [data] contains the data produced by the operation.
class DataState<T> extends ViewState<T> {
  const DataState(this.data);
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataState &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'DataState { data: $data }';
}

/// {@template provider_kit.error_state}
/// Represents a failed state of a view.
///
/// [error] contains the original error, [stackTrace] contains its associated
/// stack trace, and [errorInfo] contains the mapped error information.
/// An optional [onRetry] callback can be provided to retry the operation.
/// {@endtemplate}
class ErrorState<T> extends ViewState<T> {
  /// {@template provider_kit.error_info_field}
  /// The mapped information for this error.
  ///
  /// The information is produced by the configured [ErrorInfoMapper] via
  /// [ProviderKit.configure].
  /// {@endtemplate}
  final ErrorInfo errorInfo;

  /// The original error that caused this state.
  final Object error;

  /// The stack trace associated with [error].
  final StackTrace stackTrace;

  /// Called when the operation should be retried.
  final VoidCallback? onRetry;

  /// The message provided by [errorInfo].
  String get message => errorInfo.message;

  ErrorState(
    this.error,
    this.stackTrace, {
    ErrorInfo? errorInfo,
    this.onRetry,
  }) : errorInfo = errorInfo ??
            ProviderKit.resolveErrorInfo(
              error,
              stackTrace,
            );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState<T> &&
        other.errorInfo == errorInfo &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.onRetry == onRetry;
  }

  @override
  int get hashCode => Object.hash(errorInfo, error, stackTrace, onRetry);

  @override
  String toString() => 'ErrorState { errorInfo: $errorInfo, error: $error, '
      'stackTrace: $stackTrace, onRetry: ${onRetry != null} }';
}
