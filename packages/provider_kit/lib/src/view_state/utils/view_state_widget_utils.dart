import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/view_state/notifiers/async/async_notifiers.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/view_state_widgets_provider.dart';

@internal
abstract class ViewStateWidgetUtils {
  static Widget buildInitialWidget(
    BuildContext context,
    InitialStateBuilder? initialBuilder,
    bool isSliver,
  ) {
    return initialBuilder != null
        ? initialBuilder(isSliver)
        : context.initialStateWidget(isSliver);
  }

  static Widget buildLoadingWidget(
    BuildContext context,
    LoadingStateBuilder? loadingBuilder,
    String? message,
    double? progress,
    bool isSliver,
  ) {
    final resolvedMessage = context.resolveViewStateMessage(message);
    return loadingBuilder != null
        ? loadingBuilder(resolvedMessage, progress, isSliver)
        : context.loadingStateWidget(resolvedMessage, progress, isSliver);
  }

  static Widget buildEmptyWidget(
    BuildContext context,
    EmptyStateBuilder? emptyBuilder,
    String? message,
    bool isSliver,
  ) {
    final resolvedMessage = context.resolveViewStateMessage(message);
    return emptyBuilder != null
        ? emptyBuilder(resolvedMessage, isSliver)
        : context.emptyStateWidget(resolvedMessage, isSliver);
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
        return dataBuilder(state.data);
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

    final resolvedErrorInfo = _resolveErrorInfo(context, errorState.errorInfo);

    return errorBuilder != null
        ? errorBuilder(
            resolvedErrorInfo,
            errorState.error,
            errorState.stackTrace,
            effectiveOnRetry,
            isSliver,
          )
        : context.errorStateWidget(
            resolvedErrorInfo,
            errorState.error,
            errorState.stackTrace,
            effectiveOnRetry,
            isSliver,
          );
  }

  static ErrorInfo _resolveErrorInfo(
    BuildContext context,
    ErrorInfo errorInfo,
  ) {
    final resolvedMessage =
        context.resolveViewStateMessage(errorInfo.message) ?? errorInfo.message;

    if (resolvedMessage == errorInfo.message) {
      return errorInfo;
    }

    return ErrorInfo(message: resolvedMessage, code: errorInfo.code);
  }

  static void handleListener<T>({
    required BuildContext context,
    required ViewState<T> state,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    DataStateListener<T>? dataStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
  }) {
    state.when(
      initialState: () {
        initialStateListener?.call();
      },
      loadingState: (message, progress) {
        loadingStateListener?.call(
          context.resolveViewStateMessage(message),
          progress,
        );
      },
      dataState: (data) {
        dataStateListener?.call(data);
      },
      emptyState: (message) {
        emptyStateListener?.call(context.resolveViewStateMessage(message));
      },
      errorState: (errorInfo, error, stackTrace, onRetry) {
        errorStateListener?.call(
          _resolveErrorInfo(context, errorInfo),
          error,
          stackTrace,
          onRetry,
        );
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
