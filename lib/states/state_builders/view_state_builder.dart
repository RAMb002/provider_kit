import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/notifiers/provider_kit.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/states.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/view_state_widgets_provider.dart';

class ViewStateBuilder<P extends ViewStateNotifier<T>, T>
    extends StateBuilder<P, ViewState<T>> {
  final InitialStateBuilder? initialBuilder;
  final DataStateBuilder<T> dataBuilder;
  final ErrorStateBuilder? errorBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final bool isSliver;

  ViewStateBuilder({
    super.provider,
    super.rebuildWhen,
    required this.dataBuilder,
    this.initialBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.isSliver = false,
    super.key,
  }) : super(
          builder: (context, state, child) {
            return buildStateWidget<P, T>(
              context,
              provider,
              state,
              initialBuilder,
              dataBuilder,
              errorBuilder,
              loadingBuilder,
              emptyBuilder,
              isSliver,
            );
          },
        );

  static Widget buildStateWidget<P, T>(
    BuildContext context,
    P? provider,
    ViewState<T> state,
    InitialStateBuilder? initialBuilder,
    DataStateBuilder<T> dataBuilder,
    ErrorStateBuilder? failureBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    bool isSliver,
  ) {
    switch (state) {
      case InitialState<T>():
        return ViewStateBase.buildInitialWidget(
            context, initialBuilder, isSliver);

      case LoadingState<T>():
        return ViewStateBase.buildLoadingWidget(
            context, loadingBuilder, state.message, state.progress, isSliver);

      case EmptyState<T>():
        return ViewStateBase.buildEmptyWidget(
            context, emptyBuilder, state.message, isSliver);

      case ErrorState<T>():
        return _buildErrorState<P, T>(
          provider,
          state,
          context,
          failureBuilder,
          isSliver,
        );

      case DataState<T>():
        return dataBuilder(state.dataObject);
    }
  }

  static Widget _buildErrorState<P, T>(
    P? provider,
    ErrorState<T> errorState,
    BuildContext context,
    ErrorStateBuilder? failureBuilder,
    bool isSliver,
  ) {
    final effectiveOnRetry =
        errorState.onRetry ?? _getOnRetryFromProvider<P, T>(context, provider);
    return failureBuilder != null
        ? failureBuilder(errorState.message, effectiveOnRetry,
            errorState.exception, errorState.stackTrace, isSliver)
        : context.errorStateWidget(errorState.message, effectiveOnRetry,
            errorState.exception, errorState.stackTrace, isSliver);
  }

  static VoidCallback? _getOnRetryFromProvider<P, T>(
      BuildContext context, P? providerParam) {
    final provider = providerParam ?? context.read<P>();
    if (provider is ProviderKit<T>) {
      return provider.refresh;
    }
    return null;
  }
}
