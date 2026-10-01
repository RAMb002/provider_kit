import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/view_state/notifiers/async_view_state_notifier.dart';
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
    return loadingBuilder != null
        ? loadingBuilder(message, progress, isSliver)
        : context.loadingStateWidget(message, progress, isSliver);
  }

  static Widget buildEmptyWidget(
    BuildContext context,
    EmptyStateBuilder? emptyBuilder,
    String? message,
    bool isSliver,
  ) {
    return emptyBuilder != null
        ? emptyBuilder(message, isSliver)
        : context.emptyStateWidget(message, isSliver);
  }

  static Widget buildStateWidget<P, T>(
    BuildContext context,
    P? provider,
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
          provider,
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
    P? provider,
    ErrorState<T> errorState,
    BuildContext context,
    ErrorStateBuilder? errorBuilder,
    bool isSliver,
  ) {
    final effectiveOnRetry =
        errorState.onRetry ?? _getOnRetryFromProvider<P, T>(context, provider);
    return errorBuilder != null
        ? errorBuilder(
            errorState.errorInfo,
            errorState.error,
            errorState.stackTrace,
            effectiveOnRetry,
            isSliver,
          )
        : context.errorStateWidget(
            errorState.errorInfo,
            errorState.error,
            errorState.stackTrace,
            effectiveOnRetry,
            isSliver,
          );
  }

  static VoidCallback? _getOnRetryFromProvider<P, T>(
    BuildContext context,
    P? providerParam,
  ) {
    final provider = providerParam ?? context.read<P>();
    if (provider is AsyncViewStateNotifier<T>) {
      return provider.refresh;
    }
    return null;
  }
}
