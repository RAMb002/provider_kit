import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/notifiers/provider_kit.dart';
import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/states.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/view_state_widgets_provider.dart';

/// A widget that builds its UI based on the specific [ViewState] of a [ViewStateNotifier].
///
/// The [ViewStateBuilder] is used to build different UI components in response to different view states
/// such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate builder is called based on the current view state.
///
/// If the user does not supply a builder for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Parameters:
/// - **`initialBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `InitialState`.
/// - **`loadingBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `LoadingState`.
/// - **`emptyBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `EmptyState`.
/// - **`errorBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `ErrorState`.
/// - **`dataBuilder`** (*Required*) **:** A builder function that is invoked when the state is `DataState<DataType>`.
/// - **`provider`** (*Optional*) **:** Specify the [provider] if the state provider is not accessible via [Provider] and the current `BuildContext`.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current state. Defaults to calling the builder when `previous != current`.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
/// - **`key`** (*Optional*) **:** An optional key for the widget.
///
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder<Provider, DataType>(
///   provider: provider, // Optional
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   initialBuilder: (context) {
///     // Build your widget tree for InitialState
///     return Container();
///   },
///   loadingBuilder: (context, message, progress) {
///     // Build your widget tree for LoadingState
///     return Container();
///   },
///   emptyBuilder: (context, message) {
///     // Build your widget tree for EmptyState
///     return Container();
///   },
///   errorBuilder: (context, message, onRetry, exception, stackTrace) {
///     // Build your widget tree for ErrorState
///     return Container();
///   },
///   dataBuilder: (context, data) {
///     // Build your widget tree for DataState<DataType>
///     return Container();
///   },
///   isSliver: false, // Optional, default is false
///   key: Key('view_state_builder'), // Optional
/// )
/// ```
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
