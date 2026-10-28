import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/view_state/notifiers/async/async_notifiers.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/view_state_widgets_provider.dart';
import 'package:provider_kit/src/view_state/widgets/view_state_details.dart';

@internal
abstract class ViewStateWidgetUtils {
  static Widget buildInitialWidget(
    BuildContext context,
    InitialStateBuilder? initialBuilder,
    bool isSliver,
  ) {
    return initialBuilder != null
        ? initialBuilder(context)
        : context.initialStateWidget(context, isSliver);
  }

  static Widget buildLoadingWidget(
    BuildContext context,
    LoadingStateBuilder? loadingBuilder,
    String? message,
    double? progress,
    bool isSliver,
  ) {
    final details = LoadingStateDetails(
      message: context.resolveViewStateMessage(message),
      progress: progress,
    );

    return loadingBuilder != null
        ? loadingBuilder(context, details)
        : context.loadingStateWidget(context, details, isSliver);
  }

  static Widget buildEmptyWidget(
    BuildContext context,
    EmptyStateBuilder? emptyBuilder,
    String? message,
    bool isSliver,
  ) {
    final details = EmptyStateDetails(
      message: context.resolveViewStateMessage(message),
    );
    return emptyBuilder != null
        ? emptyBuilder(context, details)
        : context.emptyStateWidget(context, details, isSliver);
  }

  static Widget buildStateWidget<P, T>(
    BuildContext context,
    P? listenable,
    ViewState<T> state,
    InitialStateBuilder? initialBuilder,
    DataStateBuilder<T> dataBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    bool isSliver,
    Widget? child,
  ) {
    switch (state) {
      case InitialState<T>():
        return ViewStateWidgetUtils.buildInitialWidget(
          context,
          initialBuilder,
          isSliver,
        );

      case LoadingState<T>():
        return ViewStateWidgetUtils.buildLoadingWidget(
          context,
          loadingBuilder,
          state.message,
          state.progress,
          isSliver,
        );

      case EmptyState<T>():
        return ViewStateWidgetUtils.buildEmptyWidget(
          context,
          emptyBuilder,
          state.message,
          isSliver,
        );

      case ErrorState<T>():
        return _buildErrorState<P, T>(
          listenable,
          state,
          context,
          errorBuilder,
          isSliver,
        );

      case DataState<T>():
        return dataBuilder(context, state.data, child);
    }
  }

  static Widget _buildErrorState<P, T>(
    P? listenable,
    ErrorState<T> errorState,
    BuildContext context,
    ErrorStateBuilder? errorBuilder,
    bool isSliver,
  ) {
    final effectiveOnRetry =
        errorState.onRetry ??
        _getOnRetryFromListenable<P, T>(context, listenable);

    final resolvedErrorInfo = resolveErrorInfo(context, errorState.errorInfo);

    final details = ErrorStateDetails(
      errorInfo: resolvedErrorInfo,
      error: errorState.error,
      stackTrace: errorState.stackTrace,
      onRetry: effectiveOnRetry,
    );

    return errorBuilder != null
        ? errorBuilder(context, details)
        : context.errorStateWidget(context, details, isSliver);
  }

  static ErrorInfo resolveErrorInfo(BuildContext context, ErrorInfo errorInfo) {
    final resolvedMessage =
        context.resolveViewStateMessage(errorInfo.message) ?? errorInfo.message;

    if (resolvedMessage == errorInfo.message) {
      return errorInfo;
    }

    return ErrorInfo(message: resolvedMessage, code: errorInfo.code);
  }

  static void handleListener<P, T>({
    required BuildContext context,
    required ViewState<T> state,
    required P? listenable,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    DataStateListener<T>? dataStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
  }) {
    state.when(
      initialState: () {
        initialStateListener?.call(context);
      },
      loadingState: (message, progress) {
        final loadingDetails = LoadingStateDetails(
          message: context.resolveViewStateMessage(message),
          progress: progress,
        );

        loadingStateListener?.call(context, loadingDetails);
      },
      dataState: (data) {
        dataStateListener?.call(context, data);
      },
      emptyState: (message) {
        final emptyDetails = EmptyStateDetails(
          message: context.resolveViewStateMessage(message),
        );

        emptyStateListener?.call(context, emptyDetails);
      },
      errorState: (errorInfo, error, stackTrace, onRetry) {
        final effectiveOnRetry =
            onRetry ?? _getOnRetryFromListenable<P, T>(context, listenable);

        final errorDetails = ErrorStateDetails(
          errorInfo: resolveErrorInfo(context, errorInfo),
          error: error,
          stackTrace: stackTrace,
          onRetry: effectiveOnRetry,
        );

        errorStateListener?.call(context, errorDetails);
      },
    );
  }

  static VoidCallback? _getOnRetryFromListenable<P, T>(
    BuildContext context,
    P? listenableParam,
  ) {
    final listenable = listenableParam ?? context.read<P>();
    if (listenable is AsyncViewStateNotifier<T>) {
      return () => listenable.refresh().ignore();
    }
    return null;
  }
}
