import 'package:flutter/widgets.dart';

/// A function that builds a widget for the initial state.
///
/// The [isSliver] parameter indicates whether the widget should be a sliver.
typedef InitialStateBuilder = Widget Function(bool isSliver);

/// A function that builds a widget for the loading state.
///
/// The [message] parameter provides an optional loading message.
/// The [progress] parameter provides an optional loading progress value.
/// The [isSliver] parameter indicates whether the widget should be a sliver.
typedef LoadingStateBuilder = Widget Function(
    String? message, double? progress, bool isSliver);

/// A function that builds a widget for the data state.
///
/// The [data] parameter provides the data to be displayed.
typedef DataStateBuilder<T> = Widget Function(T data);

/// A function that builds a widget for multiple data states.
///
/// The [dataStates] parameter provides the data states to be displayed.
typedef MultiDataStateBuilder<T> = Widget Function(T dataStates);

/// A function that builds a widget for the error state.
///
/// The [message] parameter provides an optional error message.
/// The [onRetry] parameter provides an optional retry callback.
/// The [exception] parameter provides the exception that caused the error.
/// The [stackTrace] parameter provides the stack trace of the error.
/// The [isSliver] parameter indicates whether the widget should be a sliver.
typedef ErrorStateBuilder = Widget Function(
    String? message,
    VoidCallback? onRetry,
    dynamic exception,
    StackTrace? stackTrace,
    bool isSliver);

/// A function that builds a widget for the empty state.
///
/// The [message] parameter provides an optional empty state message.
/// The [isSliver] parameter indicates whether the widget should be a sliver.
typedef EmptyStateBuilder = Widget Function(String? message, bool isSliver);

/// A callback function that is invoked when the state is the initial state.
typedef InitialStateListener = void Function();

/// A callback function that is invoked when the state is the loading state.
///
/// The [message] parameter provides an optional loading message.
/// The [progress] parameter provides an optional loading progress value.
typedef LoadingStateListener = void Function(String? message, double? progress);

/// A callback function that is invoked when the state is the data state.
///
/// The [data] parameter provides the data to be handled.
typedef DataStateListener<T> = void Function(T data);

/// A callback function that is invoked when the state is multiple data states.
///
/// The [dataStates] parameter provides the data states to be handled.
typedef MultiDataStateListener<T> = void Function(T dataStates);

/// A callback function that is invoked when the state is the error state.
///
/// The [message] parameter provides an optional error message.
/// The [onRetry] parameter provides an optional retry callback.
/// The [exception] parameter provides the exception that caused the error.
/// The [stackTrace] parameter provides the stack trace of the error.
typedef ErrorStateListener = void Function(String? message,
    VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace);

/// A callback function that is invoked when the state is the empty state.
///
/// The [message] parameter provides an optional empty state message.
typedef EmptyStateListener = void Function(String? message);

/// A function that determines whether the listener should be called based on
/// the previous and current state.
///
/// The [previous] parameter provides the previous state.
/// The [next] parameter provides the current state.
typedef ListenWhen<T> = bool Function(T previous, T next);

/// A function that determines whether the builder should be called based on
/// the previous and current state.
///
/// The [previous] parameter provides the previous state.
/// The [next] parameter provides the current state.
typedef RebuildWhen<T> = bool Function(T previous, T next);

/// A function that builds a widget based on the state.
///
/// The [context] parameter provides the build context.
/// The [state] parameter provides the current state.
/// The [child] parameter provides an optional child widget.
typedef StateWidgetBuilder<T> = Widget Function(
    BuildContext context, T state, Widget? child);

/// A function that builds a widget based on multiple states.
///
/// The [context] parameter provides the build context.
/// The [states] parameter provides the current states.
/// The [child] parameter provides an optional child widget.
typedef MultiStateWidgetBuilder<T> = Widget Function(
    BuildContext context, T states, Widget? child);

/// A callback function that is invoked when the state changes.
///
/// The [context] parameter provides the build context.
/// The [state] parameter provides the current state.
typedef ListenerCallback<T> = void Function(BuildContext context, T state);

/// A callback function that is invoked when multiple states change.
///
/// The [context] parameter provides the build context.
/// The [states] parameter provides the current states.
typedef MultiListenerCallback<T> = void Function(
    BuildContext context, T states);
