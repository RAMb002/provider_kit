import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/errors/error_info.dart';

/// A sealed class representing different states of a view.
sealed class ViewState<T> {
  const ViewState();

  /// Executes the corresponding callback based on the current state.
  ///
  /// - [initialState]: Callback for the initial state.
  /// - [loadingState]: Callback for the loading state, with optional message and progress.
  /// - [dataState]: Callback for the data state, with the data object.
  /// - [emptyState]: Callback for the empty state, with an optional message.
  /// - [errorState]: Callback for the error state, with error information,
  ///   the original error, its stack trace, and an optional retry callback.
  R when<R extends Object?>({
    required R Function() initialState,
    required R Function(String? message, double? progress) loadingState,
    required R Function(T dataObject) dataState,
    required R Function(String? message) emptyState,
    required R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
      VoidCallback? onRetry,
    ) errorState,
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

  /// Executes the corresponding callback based on the current state, or executes [orElse] if no match is found.
  ///
  /// - [orElse]: Callback to execute if no match is found.
  /// - [initialState]: Optional Callback for the initial state.
  /// - [loadingState]: Optional Callback for the loading state, with optional message and progress.
  /// - [dataState]: Optional Callback for the data state, with the data object.
  /// - [emptyState]: Optional Callback for the empty state, with an optional message.
  /// - [errorState]: Optional Callback for the error state, with error information,
  ///   the original error, its stack trace, and an optional retry callback.
  R maybeWhen<R extends Object?>({
    required R Function() orElse,
    R Function()? initialState,
    R Function()? loadingState,
    R Function(T dataObject)? dataState,
    R Function()? emptyState,
    R Function(
      ErrorInfo errorInfo,
      Object error,
      StackTrace stackTrace,
      VoidCallback? onRetry,
    )? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState == null ? orElse() : initialState(),
      LoadingState<T>() => loadingState == null ? orElse() : loadingState(),
      DataState<T>() => dataState == null ? orElse() : dataState(state.data),
      EmptyState<T>() => emptyState == null ? orElse() : emptyState(),
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

  /// Maps the current state to a corresponding callback.
  ///
  /// - [initialState]: Callback for the initial state.
  /// - [loadingState]: Callback for the loading state.
  /// - [dataState]: Callback for the data state.
  /// - [emptyState]: Callback for the empty state.
  /// - [errorState]: Callback for the error state.
  R map<R extends Object?>({
    required R Function(InitialState<T> initialState) initialState,
    required R Function(LoadingState<T> loadingState) loadingState,
    required R Function(DataState<T> succeedState) dataState,
    required R Function(EmptyState<T> emptyState) emptyState,
    required R Function(ErrorState<T> errorState) errorState,
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

  /// Maps the current state to a corresponding callback, or executes [orElse] if no match is found.
  ///
  /// - [orElse]: Callback to execute if no match is found.
  /// - [initialState]: Optional callback for the initial state.
  /// - [loadingState]: Optional callback for the loading state.
  /// - [dataState]: Optional callback for the data state.
  /// - [emptyState]: Optional callback for the empty state.
  /// - [errorState]: Optional callback for the error state.
  R maybeMap<R extends Object?>({
    required R Function() orElse,
    R Function(InitialState<T> initialState)? initialState,
    R Function(LoadingState<T> loadingState)? loadingState,
    R Function(DataState<T> succeedState)? dataState,
    R Function(EmptyState<T> emptyState)? emptyState,
    R Function(ErrorState<T> errorState)? errorState,
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
}

/// Represents the initial state of a view.
class InitialState<T> extends ViewState<T> {
  const InitialState();
}

/// Represents the loading state of a view.
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
