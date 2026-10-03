import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/state/index.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/view_state_widget_utils.dart';

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
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder<DataType>(
///   provider: provider,
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   initialBuilder: (isSliver) {
///     // Build your widget tree for InitialState
///     return Container();
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     // Build your widget tree for LoadingState
///     return Container();
///   },
///   emptyBuilder: (message, isSliver) {
///     // Build your widget tree for EmptyState
///     return Container();
///   },
///   errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
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
    extends ViewStateBuilderBase<ViewStateNotifier<T>, T> {
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
    extends ViewStateBuilderBase<P, T> {
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

abstract class ViewStateBuilderBase<P extends ViewStateNotifier<T>, T>
    extends StateBuilderBase<P, ViewState<T>> {
  /// {@template provider_kit.view_state.initial_builder}
  /// Builds the UI when the provider is in [InitialState].
  ///
  /// The callback receives whether the widget is being built for use in a
  /// sliver.
  /// {@endtemplate}
  final InitialStateBuilder? initialBuilder;

  /// {@template provider_kit.view_state.data_builder}
  /// Builds the UI when the provider is in [DataState].
  ///
  /// The callback receives the data contained in the [DataState].
  /// {@endtemplate}
  final DataStateBuilder<T> dataBuilder;

  /// {@template provider_kit.view_state.error_builder}
  /// Builds the UI when the provider is in [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, a retry
  /// callback, and whether the widget is being built for use in a sliver.
  ///
  /// The retry callback retries the provider.
  /// {@endtemplate}
  final ErrorStateBuilder? errorBuilder;

  /// {@template provider_kit.view_state.loading_builder}
  /// Builds the UI when the provider is in [LoadingState].
  ///
  /// The callback receives the loading message, progress, and whether the
  /// widget is being built for use in a sliver.
  /// {@endtemplate}
  final LoadingStateBuilder? loadingBuilder;

  /// {@template provider_kit.view_state.empty_builder}
  /// Builds the UI when the provider is in [EmptyState].
  ///
  /// The callback receives the empty-state message and whether the widget is
  /// being built for use in a sliver.
  /// {@endtemplate}
  final EmptyStateBuilder? emptyBuilder;

  /// {@template provider_kit.view_state.is_sliver}
  /// Whether the default state widgets are built for use in a sliver.
  /// {@endtemplate}
  final bool isSliver;

  const ViewStateBuilderBase({
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
  Widget build(BuildContext context, ViewState<T> state, Widget? child) {
    return ViewStateWidgetUtils.buildStateWidget<P, T>(
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<InitialStateBuilder?>.has(
          'initialBuilder',
          initialBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<LoadingStateBuilder?>.has(
          'loadingBuilder',
          loadingBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<EmptyStateBuilder?>.has(
          'emptyBuilder',
          emptyBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<ErrorStateBuilder?>.has(
          'errorBuilder',
          errorBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<DataStateBuilder<T>>.has('dataBuilder', dataBuilder),
      )
      ..add(
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }
}
