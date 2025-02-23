import 'package:flutter/widgets.dart';

sealed class ViewState<T> {
  const ViewState();

  R when<R extends Object?>({
    required R Function() initialState,
    required R Function(String? message, double? progress) loadingState,
    required R Function(T successObject) dataState,
    required R Function(String? message) emptyState,
    required R Function(String? failureMessage, VoidCallback? onRetry,
            dynamic exception, StackTrace? stackTrace)
        errorState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState(),
      LoadingState<T>() => loadingState(state.message, state.progress),
      DataState<T>() => dataState(state.dataObject),
      EmptyState<T>() => emptyState(state.message),
      ErrorState<T>() => errorState(
          state.message, state.onRetry, state.exception, state.stackTrace),
    };
  }

  R map<R extends Object?>({
    required R Function(InitialState<T> initialState) initialState,
    required R Function(LoadingState<T> loadingState) loadingState,
    required R Function(DataState<T> succeedState) dataState,
    required R Function(EmptyState<T> emptyState) emptyState,
    required R Function(ErrorState<T> failedState) errorState,
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

  R maybeMap<R extends Object?>({
    required R Function() orElse,
    R Function(InitialState<T> initialState)? initialState,
    R Function(LoadingState<T> loadingState)? loadingState,
    R Function(DataState<T> succeedState)? dataState,
    R Function(EmptyState<T> emptyState)? emptyState,
    R Function(ErrorState<T> failedState)? errorState,
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

  R maybeWhen<R extends Object?>({
    required R Function() orElse,
    R Function()? initialState,
    R Function()? loadingState,
    R Function(T successObject)? dataState,
    R Function()? emptyState,
    R Function(String? failureMessage, VoidCallback? onRetry)? failedState,
  }) {
    final ViewState<T> state = this;
    return switch (state) {
      InitialState<T>() => initialState == null ? orElse() : initialState(),
      LoadingState<T>() => loadingState == null ? orElse() : loadingState(),
      DataState<T>() =>
        dataState == null ? orElse() : dataState(state.dataObject),
      EmptyState<T>() => emptyState == null ? orElse() : emptyState(),
      ErrorState<T>() => failedState == null
          ? orElse()
          : failedState(state.message, state.onRetry),
    };
  }
}

class InitialState<T> extends ViewState<T> {
  const InitialState();
}

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

class DataState<T> extends ViewState<T> {
  const DataState(this.dataObject);
  final T dataObject;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataState &&
          runtimeType == other.runtimeType &&
          dataObject == other.dataObject;

  @override
  int get hashCode => dataObject.hashCode;
}

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
