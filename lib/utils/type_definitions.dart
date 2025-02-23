import 'package:flutter/widgets.dart';

typedef InitialStateBuilder = Widget Function(bool isSliver);
typedef LoadingStateBuilder = Widget Function(
    String? message, double? progress, bool isSliver);
typedef DataStateBuilder<T> = Widget Function(T data);
typedef ErrorStateBuilder = Widget Function(
    String? message,
    VoidCallback? onRetry,
    dynamic exception,
    StackTrace? stackTrace,
    bool isSliver);
typedef EmptyStateBuilder = Widget Function(String? message, bool isSliver);

typedef InitialStateListener = void Function();
typedef LoadingStateListener = void Function(String? message, double? progress);
typedef DataStateListener<T> = void Function(
  T data,
);
typedef ErrorStateListener = void Function(String? message,
    VoidCallback? onRetry, dynamic exception, StackTrace? stackTrace);
typedef EmptyStateListener = void Function(String? message);

typedef ListenWhen<T> = bool Function(T previous, T next);
typedef RebuildWhen<T> = bool Function(T previous, T next);

typedef StateWidgetBuilder<T> = Widget Function(
    BuildContext context, T state, Widget? child);

typedef MultiStateWidgetBuilder<T> = Widget Function(
    BuildContext context, T states, Widget? child);

typedef ListenerCallback<T> = void Function(BuildContext context, T state);
typedef MultiListenerCallback<T> = void Function(
    BuildContext context, T states);
