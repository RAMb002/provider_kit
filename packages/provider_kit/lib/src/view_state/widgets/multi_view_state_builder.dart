part of '../view_state_widgets.dart';

/// {@template provider_kit.multi_view_state_builder}
/// A widget that builds its UI based on the states of multiple [ViewStateNotifier]s.
///
/// The [MultiViewStateBuilder] listens to a list of [ViewStateNotifier]s and rebuilds the builder function
/// based on the combined states. It ensures that the `builder` is called only once per state change.
///
/// ### Logic:
/// - If there is at least one `ErrorState` in the list of providers, the builder will be set to `ErrorState`. This means that if any of the states in the list is an `ErrorState`, the `errorBuilder` will be invoked.
/// - If none of the states is an `ErrorState`, the builder will check for `InitialState`. If any of the states is an `InitialState`, the `initialBuilder` will be invoked.
/// - If none of the states is an `InitialState`, the builder will check for `LoadingState`. If any of the states is a `LoadingState`, the `loadingBuilder` will be invoked.
/// - If none of the states is a `LoadingState`, the builder will check for `EmptyState`. If any of the states is an `EmptyState`, the `emptyBuilder` will be invoked.
/// - If all states are `DataState<DataType>`, the builder will be set to `DataState`. This means that if all the states in the list are `DataState<DataType>`, the `dataBuilder` will be invoked.
/// - If the user wants to avoid showing `EmptyState` just because one of them is empty while the others are `DataState`, the user should not use `EmptyState` in their provider logic and handle empty states manually inside the `DataState` builder.
///
/// If the user does not supply a builder for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [ViewStateNotifier]s that supply the states.
/// - **`initialBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `InitialState`.
/// - **`loadingBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `LoadingState`.
/// - **`emptyBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `EmptyState`.
/// - **`errorBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `ErrorState`.
/// - **`dataBuilder`** (*Required*) **:** A builder function that is invoked when the state is `DataState<DataType>`.
/// - **`rebuildWhen`** (*Optional*) **:** Modifying this overrides the default priority logic, triggering builder whenever any provider's state changes.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
///
/// ### Example Usage:
/// ```dart
/// MultiViewStateBuilder<DataType>(
///   providers: [provider1, provider2], // Required
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
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   isSliver: false, // Optional, default is false
/// )
/// ```
/// {@endtemplate}

class MultiViewStateBuilder<T> extends MultiStateBuilder<ViewState<T>> {
  final InitialStateBuilder? initialBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final ErrorStateBuilder? errorBuilder;
  final MultiDataStateBuilder<List<DataState<T>>> dataBuilder;
  final bool isSliver;

  /// {@macro provider_kit.multi_view_state_builder}
  MultiViewStateBuilder({
    super.key,
    required List<ViewStateNotifier<T>> providers,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    required this.dataBuilder,
    super.rebuildWhen,
    this.isSliver = false,
  }) : super(
          providers: providers,
          builder: (context, states, child) {
            return _multiViewStateBuilder(
                states,
                providers,
                errorBuilder,
                context,
                isSliver,
                initialBuilder,
                loadingBuilder,
                emptyBuilder,
                dataBuilder);
          },
        );

  static Widget _multiViewStateBuilder<T>(
      List<ViewState<T>> states,
      List<ViewStateNotifier<T>> providers,
      ErrorStateBuilder? errorBuilder,
      BuildContext context,
      bool isSliver,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      MultiDataStateBuilder<List<DataState<T>>> dataBuilder) {
    if (_ViewStateBase.hasErrorState(states)) {
      return _buildErrorWidget(
          providers, errorBuilder, states, context, isSliver);
    }
    if (_ViewStateBase.hasInitialState(states)) {
      return _ViewStateBase.buildInitialWidget(
          context, initialBuilder, isSliver);
    }
    final loadingStates = _ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      return _ViewStateBase.buildLoadingWidget(
          context,
          loadingBuilder,
          loadingStates.first.message,
          _ViewStateBase.getCombinedLoadingProgress(loadingStates),
          isSliver);
    }
    final emptyStates = _ViewStateBase.getEmptyStates(states);
    if (emptyStates.isNotEmpty) {
      return _ViewStateBase.buildEmptyWidget(
          context, emptyBuilder, emptyStates.first.message, isSliver);
    }
    return dataBuilder(states.cast<DataState<T>>().toList());
  }

  static Widget _buildErrorWidget<T>(
    List<ViewStateNotifier<T>> providers,
    ErrorStateBuilder? errorBuilder,
    List<ViewState<T>> states,
    BuildContext context,
    bool isSliver,
  ) {
    final errorStates = states.whereType<ErrorState<T>>().toList();

    void onRetry() {
      _ViewStateBase.onRetry(providers);
    }

    final errorMessage = errorStates.first.message;
    final exception = errorStates.first.exception;
    final stackTrace = errorStates.first.stackTrace;
    return errorBuilder?.call(
          errorMessage,
          onRetry,
          exception,
          stackTrace,
          isSliver,
        ) ??
        context.errorStateWidget(
            errorMessage, onRetry, exception, stackTrace, isSliver);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<InitialStateBuilder?>.has(
          'initialBuilder', initialBuilder))
      ..add(ObjectFlagProperty<LoadingStateBuilder?>.has(
          'loadingBuilder', loadingBuilder))
      ..add(ObjectFlagProperty<EmptyStateBuilder?>.has(
          'emptyBuilder', emptyBuilder))
      ..add(ObjectFlagProperty<ErrorStateBuilder?>.has(
          'errorBuilder', errorBuilder))
      ..add(ObjectFlagProperty<MultiDataStateBuilder<List<DataState<T>>>>.has(
          'dataBuilder', dataBuilder))
      ..add(
          DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false));
  }
}
