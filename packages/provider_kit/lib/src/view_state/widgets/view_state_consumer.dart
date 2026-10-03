import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/state/index.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/view_state_widget_utils.dart';

/// {@template provider_kit.view_state_consumer}
/// A widget that combines listening to and building based on the specific
/// [ViewState] of a [ViewStateNotifier].
///
/// The [ViewStateConsumer] can build UI and perform side effects in response
/// to different view states such as `InitialState`, `LoadingState`,
/// `DataState<T>`, `EmptyState`, and `ErrorState`.
///
/// If the provider is available through the current [BuildContext] (e.g.,
/// via [Provider]), use [ViewStateConsumer.of] to resolve it from the
/// widget tree.
///
/// If the user does not supply a builder for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Example Usage:
/// ```dart
/// ViewStateConsumer<DataType>(
///   provider: provider,
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     return ...;
///   },
///   dataStateListener: (data) {
///     // Handle DataState.
///   },
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [ViewStateConsumer.of] to resolve it from the widget tree:
///
/// ```dart
/// ViewStateConsumer.of<MyProvider, DataType>(
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     return ...;
///   },
/// )
/// ```
/// {@endtemplate}
class ViewStateConsumer<T>
    extends ViewStateConsumerBase<ViewStateNotifier<T>, T> {
  /// {@macro provider_kit.view_state_consumer}
  const ViewStateConsumer({
    super.key,
    required ViewStateNotifier<T> provider,
    super.rebuildWhen,
    super.initialBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    required super.dataBuilder,
    super.isSliver,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
  }) : super(provider: provider);

  /// Resolves the provider from the current [BuildContext].
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// ViewStateConsumer.of<MyProvider, DataType>(
  ///   dataBuilder: (data) {
  ///     return ...;
  ///   },
  ///   dataStateListener: (data) {
  ///     // Handle DataState.
  ///   },
  /// )
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    ErrorStateBuilder? errorBuilder,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit = false,
    bool isSliver = false,
  }) {
    return _ViewStateConsumerOf<P, T>(
      key: key,
      dataBuilder: dataBuilder,
      initialBuilder: initialBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
      dataStateListener: dataStateListener,
      rebuildWhen: rebuildWhen,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      isSliver: isSliver,
    );
  }
}

class _ViewStateConsumerOf<P extends ViewStateNotifier<T>, T>
    extends ViewStateConsumerBase<P, T> {
  const _ViewStateConsumerOf({
    super.key,
    required super.dataBuilder,
    super.initialBuilder,
    super.loadingBuilder,
    super.emptyBuilder,
    super.errorBuilder,
    super.initialStateListener,
    super.loadingStateListener,
    super.emptyStateListener,
    super.errorStateListener,
    super.dataStateListener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.isSliver,
  }) : super(provider: null);
}

abstract class ViewStateConsumerBase<P extends ViewStateNotifier<T>, T>
    extends StateConsumerBase<P, ViewState<T>> {
  /// {@macro provider_kit.view_state.initial_builder}
  final InitialStateBuilder? initialBuilder;

  /// {@macro provider_kit.view_state.loading_builder}
  final LoadingStateBuilder? loadingBuilder;

  /// {@macro provider_kit.view_state.empty_builder}
  final EmptyStateBuilder? emptyBuilder;

  /// {@macro provider_kit.view_state.error_builder}
  final ErrorStateBuilder? errorBuilder;

  /// {@macro provider_kit.view_state.data_builder}
  final DataStateBuilder<T> dataBuilder;

  /// {@macro provider_kit.view_state.initial_listener}
  final InitialStateListener? initialStateListener;

  /// {@macro provider_kit.view_state.loading_listener}
  final LoadingStateListener? loadingStateListener;

  /// {@macro provider_kit.view_state.empty_listener}
  final EmptyStateListener? emptyStateListener;

  /// {@macro provider_kit.view_state.error_listener}
  final ErrorStateListener? errorStateListener;

  /// {@macro provider_kit.view_state.data_listener}
  final DataStateListener<T>? dataStateListener;

  /// {@macro provider_kit.view_state.is_sliver}
  final bool isSliver;

  const ViewStateConsumerBase({
    super.key,
    super.provider,
    super.rebuildWhen,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    required this.dataBuilder,
    this.isSliver = false,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
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
  void onStateChange(BuildContext context, ViewState<T> state) {
    state.when(
      initialState: () {
        initialStateListener?.call();
      },
      loadingState: (message, progress) {
        loadingStateListener?.call(message, progress);
      },
      dataState: (data) {
        dataStateListener?.call(data);
      },
      emptyState: (message) {
        emptyStateListener?.call(message);
      },
      errorState: (errorInfo, error, stackTrace, onRetry) {
        errorStateListener?.call(errorInfo, error, stackTrace, onRetry);
      },
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
      )
      ..add(
        ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener',
          initialStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener',
          loadingStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener',
          emptyStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener',
          errorStateListener,
        ),
      )
      ..add(
        ObjectFlagProperty<DataStateListener<T>?>.has(
          'dataStateListener',
          dataStateListener,
        ),
      );
  }
}
