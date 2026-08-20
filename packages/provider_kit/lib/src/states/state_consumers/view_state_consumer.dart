import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/states/state_builders/view_state_builder.dart';
import 'package:provider_kit/src/states/state_consumers/state_consumer.dart';
import 'package:provider_kit/src/states/view_states.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template provider_kit.viewStateConsumer}
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
/// ### Parameters:
/// - **`provider`** (*Required*) **:** The [ViewStateNotifier] whose state you want to listen to.
/// - **`initialBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `InitialState`.
/// - **`loadingBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `LoadingState`.
/// - **`emptyBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `EmptyState`.
/// - **`errorBuilder`** (*Optional*) **:** A builder function that is invoked when the state is `ErrorState`.
/// - **`dataBuilder`** (*Required*) **:** A builder function that is invoked when the state is `DataState<DataType>`.
/// - **`initialStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `InitialState`.
/// - **`loadingStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `LoadingState`.
/// - **`emptyStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `EmptyState`.
/// - **`errorStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `ErrorState`.
/// - **`dataStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `DataState<DataType>`.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current state. Defaults to calling the builder when `previous != current`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current state. Defaults to calling the listener when `previous != current`.
/// - **`callListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
///
/// ### Example Usage:
/// ```dart
/// ViewStateConsumer<DataType>(
///   provider: provider,
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress) {
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
///   loadingBuilder: (message, progress) {
///     return ...;
///   },
/// )
/// ```
/// {@endtemplate}
class ViewStateConsumer<T>
    extends ViewStateConsumerBase<ViewStateNotifier<T>, T> {
  /// {@macro provider_kit.viewStateConsumer}
  ViewStateConsumer({
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
  _ViewStateConsumerOf({
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
  final InitialStateBuilder? initialBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final ErrorStateBuilder? errorBuilder;
  final DataStateBuilder<T> dataBuilder;
  final bool isSliver;

  final InitialStateListener? initialStateListener;
  final LoadingStateListener? loadingStateListener;
  final EmptyStateListener? emptyStateListener;
  final ErrorStateListener? errorStateListener;
  final DataStateListener<T>? dataStateListener;

  ViewStateConsumerBase({
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
  }) : super(
          builder: (context, state, child) {
            return ViewStateBuilderBase.buildStateWidget<P, T>(
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
          listener: (context, state) {
            state.when(
              initialState: () => initialStateListener?.call(),
              loadingState: (message, progress) =>
                  loadingStateListener?.call(message, progress),
              dataState: (data) => dataStateListener?.call(data),
              emptyState: (message) => emptyStateListener?.call(message),
              errorState: (errorMessage, onRetry, exception, stackTrace) =>
                  errorStateListener?.call(
                errorMessage,
                onRetry,
                exception,
                stackTrace,
              ),
            );
          },
        );

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
          DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false))
      ..add(ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener', initialStateListener))
      ..add(ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener', loadingStateListener))
      ..add(ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener', emptyStateListener))
      ..add(ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener', errorStateListener))
      ..add(ObjectFlagProperty<DataStateListener<T>?>.has(
          'dataStateListener', dataStateListener));
  }
}
