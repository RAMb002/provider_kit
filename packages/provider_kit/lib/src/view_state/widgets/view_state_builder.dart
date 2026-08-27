part of '../view_state_widgets.dart';

/// {@template provider_kit.view_state_builder}
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
/// - **`provider`** (*Required*) **:** The [ViewStateNotifier] whose state you want to listen to.
/// - **`initialBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `InitialState`.
/// - **`loadingBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `LoadingState`.
/// - **`emptyBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `EmptyState`.
/// - **`errorBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `ErrorState`.
/// - **`dataBuilder`** (*Required*) **:** A builder function that is invoked when the state is `DataState<DataType>`.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current state. Defaults to calling the builder when `previous != current`.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
/// - **`key`** (*Optional*) **:** An optional key for the widget.
///
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder<DataType>(
///   provider: provider,
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   initialBuilder: () {
///     // Build your widget tree for InitialState
///     return Container();
///   },
///   loadingBuilder: (message, progress) {
///     // Build your widget tree for LoadingState
///     return Container();
///   },
///   emptyBuilder: (message) {
///     // Build your widget tree for EmptyState
///     return Container();
///   },
///   errorBuilder: (message, onRetry, exception, stackTrace) {
///     // Build your widget tree for ErrorState
///     return Container();
///   },
///   dataBuilder: (data) {
///     // Build your widget tree for DataState<DataType>
///     return Container();
///   },
///   isSliver: false, // Optional, default is false
/// )
/// ```
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [ViewStateBuilder.of] to resolve it from the widget tree:
///
/// ```dart
/// ViewStateBuilder.of<MyProvider, DataType>(
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress) {
///     return ...;
///   },
/// ```
/// {@endtemplate}
class ViewStateBuilder<T>
    extends _ViewStateBuilderBase<ViewStateNotifier<T>, T> {
  /// {@macro provider_kit.view_state_builder}
  const ViewStateBuilder({
    super.key,
    required ViewStateNotifier<T> provider,
    super.rebuildWhen,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.isSliver = false,
  }) : super(provider: provider);

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// ViewStateBuilder.of<MyProvider, DataType>(
  ///   dataBuilder: (data) {
  ///     return ...;
  ///   },
  ///   loadingBuilder: (message, progress) {
  ///     return ...;
  ///   },
  /// )
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    bool isSliver = false,
  }) {
    return _ViewStateBuilderOf<P, T>(
      key: key,
      dataBuilder: dataBuilder,
      initialBuilder: initialBuilder,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      rebuildWhen: rebuildWhen,
      isSliver: isSliver,
    );
  }
}

class _ViewStateBuilderOf<P extends ViewStateNotifier<T>, T>
    extends _ViewStateBuilderBase<P, T> {
  const _ViewStateBuilderOf({
    super.key,
    required super.dataBuilder,
    super.initialBuilder,
    super.errorBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.rebuildWhen,
    super.isSliver,
  }) : super(provider: null);
}

abstract class _ViewStateBuilderBase<P extends ViewStateNotifier<T>, T>
    extends StateBuilderBase<P, ViewState<T>> {
  final InitialStateBuilder? initialBuilder;
  final DataStateBuilder<T> dataBuilder;
  final ErrorStateBuilder? errorBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final bool isSliver;

  const _ViewStateBuilderBase({
    super.provider,
    super.rebuildWhen,
    required this.dataBuilder,
    this.initialBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.isSliver = false,
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    ViewState<T> state,
    Widget? child,
  ) {
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
        return _ViewStateBase.buildInitialWidget(
            context, initialBuilder, isSliver);

      case LoadingState<T>():
        return _ViewStateBase.buildLoadingWidget(
            context, loadingBuilder, state.message, state.progress, isSliver);

      case EmptyState<T>():
        return _ViewStateBase.buildEmptyWidget(
            context, emptyBuilder, state.message, isSliver);

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
        ? errorBuilder(errorState.message, effectiveOnRetry,
            errorState.exception, errorState.stackTrace, isSliver)
        : context.errorStateWidget(errorState.message, effectiveOnRetry,
            errorState.exception, errorState.stackTrace, isSliver);
  }

  static VoidCallback? _getOnRetryFromProvider<P, T>(
      BuildContext context, P? providerParam) {
    final provider = providerParam ?? context.read<P>();
    if (provider is AsyncViewStateNotifier<T>) {
      return provider.refresh;
    }
    return null;
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
      ..add(ObjectFlagProperty<DataStateBuilder<T>>.has(
          'dataBuilder', dataBuilder))
      ..add(
          DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false));
  }
}
