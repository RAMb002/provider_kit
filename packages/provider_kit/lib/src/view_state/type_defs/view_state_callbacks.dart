import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/errors/error_info.dart';

/// {@template provider_kit.initial_state_callback}
/// A callback invoked for the [InitialState].
/// {@endtemplate}
typedef InitialStateCallback<R> = R Function();

/// {@template provider_kit.loading_state_callback}
/// A callback invoked for the [LoadingState].
///
/// [message] is the optional loading message.
/// [progress] is the optional loading progress value.
/// {@endtemplate}
typedef LoadingStateCallback<R> = R Function(
  String? message,
  double? progress,
);

/// {@template provider_kit.data_state_callback}
/// A callback invoked for the [DataState].
///
/// [data] is the data contained in the state.
/// {@endtemplate}
typedef DataStateCallback<T, R> = R Function(T data);

/// {@template provider_kit.empty_state_callback}
/// A callback invoked for the [EmptyState].
///
/// [message] is the optional empty-state message.
/// {@endtemplate}
typedef EmptyStateCallback<R> = R Function(String? message);

/// {@template provider_kit.error_state_callback}
/// A callback invoked for the [ErrorState].
///
/// [errorInfo] contains mapped information about the error.
/// [error] is the original error.
/// [stackTrace] is the stack trace associated with the error.
/// [onRetry] is the optional retry callback.
/// {@endtemplate}
typedef ErrorStateCallback<R> = R Function(
  ErrorInfo errorInfo,
  Object error,
  StackTrace stackTrace,
  VoidCallback? onRetry,
);

/// {@macro provider_kit.initial_state_callback}
typedef InitialStateListener = InitialStateCallback<void>;

/// {@macro provider_kit.loading_state_callback}
typedef LoadingStateListener = LoadingStateCallback<void>;

/// {@macro provider_kit.data_state_callback}
typedef DataStateListener<T> = DataStateCallback<T, void>;

/// {@macro provider_kit.empty_state_callback}
typedef EmptyStateListener = EmptyStateCallback<void>;

/// {@macro provider_kit.error_state_callback}
typedef ErrorStateListener = ErrorStateCallback<void>;

/// A callback that builds a widget for the initial state.
///
/// [isSliver] indicates whether the widget should be built as a sliver.
typedef InitialStateBuilder = Widget Function(bool isSliver);

/// A callback that builds a widget for the loading state.
///
/// [message] provides an optional loading message.
/// [progress] provides an optional loading progress value.
/// [isSliver] indicates whether the widget should be built as a sliver.
typedef LoadingStateBuilder = Widget Function(
  String? message,
  double? progress,
  bool isSliver,
);

/// A callback that builds a widget for the data state.
///
/// [data] is the data to be displayed.
typedef DataStateBuilder<T> = Widget Function(T data);

/// A callback that builds a widget for the error state.
///
/// [errorInfo] provides mapped information about the error.
/// [error] provides the original error.
/// [stackTrace] provides the stack trace associated with the error.
/// [onRetry] provides an optional retry callback.
/// [isSliver] indicates whether the widget should be built as a sliver.
typedef ErrorStateBuilder = Widget Function(
  ErrorInfo errorInfo,
  Object error,
  StackTrace stackTrace,
  VoidCallback? onRetry,
  bool isSliver,
);

/// A callback that builds a widget for the empty state.
///
/// [message] provides an optional empty-state message.
/// [isSliver] indicates whether the widget should be built as a sliver.
typedef EmptyStateBuilder = Widget Function(
  String? message,
  bool isSliver,
);

// Multi-state callbacks.

/// A callback that builds a widget for multiple data states.
///
/// [dataStates] provides the data states to be displayed.
typedef MultiDataStateBuilder<T> = Widget Function(T dataStates);

/// A callback invoked when multiple data states are available.
///
/// [dataStates] provides the data states to be handled.
typedef MultiDataStateListener<T> = void Function(T dataStates);