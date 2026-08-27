import 'package:flutter/widgets.dart';

/// A sealed class representing different states of a view.
sealed class ViewState<T> {
  const ViewState();

  /// Executes the corresponding callback based on the current state.
  ///
  /// - [initialState]: Callback for the initial state.
  /// - [loadingState]: Callback for the loading state, with optional message and progress.
  /// - [dataState]: Callback for the data state, with the data object.
  /// - [emptyState]: Callback for the empty state, with an optional message.
  /// - [errorState]: Callback for the error state, with optional error message, retry callback, exception, and stack trace.
  R when<R extends Object?>({
    required R Function() initialState,
    required R Function(String? message, double? progress) loadingState,
    required R Function(T dataObject) dataState,
    required R Function(String? message) emptyState,
    required R Function(String? errorMessage, VoidCallback? onRetry,
            dynamic exception, StackTrace? stackTrace)
        errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState(),
      LoadingState<T>() => loadingState(state.message, state.progress),
      DataState<T>() => dataState(state.data),
      EmptyState<T>() => emptyState(state.message),
      ErrorState<T>() => errorState(
          state.message, state.onRetry, state.exception, state.stackTrace),
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

  /// Executes the corresponding callback based on the current state, or executes [orElse] if no match is found.
  ///
  /// - [orElse]: Callback to execute if no match is found.
  /// - [initialState]: Optional callback for the initial state.
  /// - [loadingState]: Optional callback for the loading state.
  /// - [dataState]: Optional callback for the data state.
  /// - [emptyState]: Optional callback for the empty state.
  /// - [errorState]: Optional callback for the error state.
  R maybeWhen<R extends Object?>({
    required R Function() orElse,
    R Function()? initialState,
    R Function()? loadingState,
    R Function(T dataObject)? dataState,
    R Function()? emptyState,
    R Function(String? errorMessage, VoidCallback? onRetry)? errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState == null ? orElse() : initialState(),
      LoadingState<T>() => loadingState == null ? orElse() : loadingState(),
      DataState<T>() => dataState == null ? orElse() : dataState(state.data),
      EmptyState<T>() => emptyState == null ? orElse() : emptyState(),
      ErrorState<T>() => errorState == null
          ? orElse()
          : errorState(state.message, state.onRetry),
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
}

/// Represents the error state of a view.
class ErrorState<T> extends ViewState<T> {
  final String? message;
  final VoidCallback? onRetry;
  final dynamic exception;
  final StackTrace? stackTrace;

  const ErrorState([
    this.message,
    this.exception,
    this.stackTrace,
    this.onRetry,
  ]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorState<T> &&
        other.message == message &&
        other.onRetry == onRetry &&
        other.exception == exception &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => Object.hash(message, onRetry, exception, stackTrace);
}
