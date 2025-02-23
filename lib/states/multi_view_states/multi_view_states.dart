// ignore_for_file: unnecessary_import

import 'package:flutter/widgets.dart';
import 'package:provider_kit/notifiers/notifiers.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/states.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/view_state_widgets_provider.dart';

enum _AggregatedViewState {
  error,
  initial,
  loading,
  empty,
  data,
  unknown,
}
/// A widget that combines both listening to and building based on the states of multiple [ViewStateNotifier]s.
///
/// The [MultiViewStateConsumer] widget is used to perform actions and build its child widget
/// in response to state changes in multiple [ViewStateNotifier]s. It ensures that the appropriate
/// listener and builder are called based on the current states.
///
/// ### Logic:
/// - If there is at least one `ErrorState` in the list of providers, the listener and builder will be set to `ErrorState`. This means that if any of the states in the list is an `ErrorState`, the `errorStateListener` and `errorBuilder` will be invoked.
/// - If none of the states is an `ErrorState`, the listener and builder will check for `InitialState`. If any of the states is an `InitialState`, the `initialStateListener` and `initialBuilder` will be invoked.
/// - If none of the states is an `InitialState`, the listener and builder will check for `LoadingState`. If any of the states is a `LoadingState`, the `loadingStateListener` and `loadingBuilder` will be invoked.
/// - If none of the states is a `LoadingState`, the listener and builder will check for `EmptyState`. If any of the states is an `EmptyState`, the `emptyStateListener` and `emptyBuilder` will be invoked.
/// - If all states are `DataState<DataType>`, the listener and builder will be set to `DataState`. This means that if all the states in the list are `DataState<DataType>`, the `dataStateListener` and `dataBuilder` will be invoked.
/// - If the user wants to avoid showing `EmptyState` just because one of them is empty while the others are `DataState`, the user should not use `EmptyState` in their provider logic and handle empty states manually inside the `DataState` builder.
///
/// If the user does not supply a builder or listener for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [ViewStateNotifier]s that supply the states.
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
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current states. Defaults to calling the builder when `previous != current`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current states. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
///
/// ### Example Usage:
/// ```dart
/// MultiViewStateConsumer<DataType>(
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
///   initialStateListener: () {
///     // Handle InitialState
///   },
///   loadingStateListener: (message, progress) {
///     // Handle LoadingState
///   },
///   emptyStateListener: (message) {
///     // Handle EmptyState
///   },
///   errorStateListener: (errorMessage, onRetry, exception, stackTrace) {
///     // Handle ErrorState
///   },
///   dataStateListener: (data) {
///     // Handle DataState<DataType>
///   },
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   shouldCallListenerOnInit: true, // Optional, default is false
///   isSliver: false, // Optional, default is false
/// )
/// ```
class MultiViewStateConsumer<T> extends MultiStateConsumer<ViewState<T>> {
  MultiViewStateConsumer(
      {super.key,
      required super.providers,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? failureBuilder,
      required DataStateBuilder<List<DataState<T>>> dataBuilder,
      super.rebuildWhen,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      ErrorStateListener? errorStateListener,
      DataStateListener<List<DataState<T>>>? dataStateListener,
      ListenWhen<List<ViewState<T>>>? listenWhen,
      super.shouldcallListenerOnInit,
      bool isSliver = false})
      : super(
          builder: (context, states, child) =>
              MultiViewStateBuilder._multiViewStateBuilder(
                  states,
                  providers,
                  failureBuilder,
                  context,
                  isSliver,
                  initialBuilder,
                  loadingBuilder,
                  emptyBuilder,
                  dataBuilder),
          listenWhen: (previous, next) =>
              MultiViewStateListener._listenWhen(listenWhen, previous, next),
          listener: (context, states) =>
              MultiViewStateListener._multiStateListener(
                  states,
                  providers,
                  errorStateListener,
                  initialStateListener,
                  loadingStateListener,
                  emptyStateListener,
                  dataStateListener),
        );
}

/// A widget that listens to changes in the states of multiple [ViewStateNotifier]s and triggers callbacks.
///
/// The [MultiViewStateListener] widget is used to perform actions in response to state changes
/// in multiple [ViewStateNotifier]s. It ensures that the listener function is called only when
/// the states change.
///
/// ### Logic:
/// - If there is at least one `ErrorState` in the list of providers, the listener will be set to `ErrorState`. This means that if any of the states in the list is an `ErrorState`, the `errorStateListener` will be invoked.
/// - If none of the states is an `ErrorState`, the listener will check for `InitialState`. If any of the states is an `InitialState`, the `initialStateListener` will be invoked.
/// - If none of the states is an `InitialState`, the listener will check for `LoadingState`. If any of the states is a `LoadingState`, the `loadingStateListener` will be invoked.
/// - If none of the states is a `LoadingState`, the listener will check for `EmptyState`. If any of the states is an `EmptyState`, the `emptyStateListener` will be invoked.
/// - If all states are `DataState<DataType>`, the listener will be set to `DataState`. This means that if all the states in the list are `DataState<DataType>`, the `dataStateListener` will be invoked.
/// - If the user wants to avoid showing `EmptyState` just because one of them is empty while the others are `DataState`, the user should not use `EmptyState` in their provider logic and handle empty states manually inside the `DataState` builder.
///
/// If the user does not supply a listener for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [ViewStateNotifier]s that supply the states.
/// - **`initialStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `InitialState`.
/// - **`loadingStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `LoadingState`.
/// - **`emptyStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `EmptyState`.
/// - **`errorStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `ErrorState`.
/// - **`dataStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `DataState<DataType>`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current states. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`child`** (*Optional*) **:** A widget that is part of the widget tree.
///
/// ### Example Usage:
/// ```dart
/// MultiViewStateListener<DataType>(
///   providers: [provider1, provider2], // Required
///   initialStateListener: () {
///     // Handle InitialState
///   },
///   loadingStateListener: (message, progress) {
///     // Handle LoadingState
///   },
///   emptyStateListener: (message) {
///     // Handle EmptyState
///   },
///   errorStateListener: (errorMessage, onRetry, exception, stackTrace) {
///     // Handle ErrorState
///   },
///   dataStateListener: (data) {
///     // Handle DataState<DataType>
///   },
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   shouldCallListenerOnInit: true, // Optional, default is false
///   child: SomeWidget(), // Optional
/// )
/// ```
class MultiViewStateListener<T> extends MultiStateListener<ViewState<T>> {
  MultiViewStateListener({
    super.key,
    required super.providers,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<List<DataState<T>>>? dataStateListener,
    ListenWhen<List<ViewState<T>>>? listenWhen,
    super.shouldcallListenerOnInit,
    super.child,
  }) : super(
          listenWhen: (previous, next) =>
              _listenWhen(listenWhen, previous, next),
          listener: (context, states) {
            _multiStateListener(
              states,
              providers,
              errorStateListener,
              initialStateListener,
              loadingStateListener,
              emptyStateListener,
              dataStateListener,
            );
          },
        );

  static bool _listenWhen<T>(ListenWhen<List<ViewState<T>>>? listenWhen,
      List<ViewState<T>> previous, List<ViewState<T>> next) {
    if (listenWhen != null) return listenWhen.call(previous, next);
    final previousState = _combinedState(previous);
    final nextState = _combinedState(next);
    return previousState != nextState;
  }

  static void _multiStateListener<T>(
      List<ViewState<T>> states,
      List<StateNotifier<ViewState<T>>> providers,
      ErrorStateListener? errorStateListener,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      DataStateListener<List<DataState<T>>>? dataStateListener) {
    final errorStates = ViewStateBase.getErrorStates(states);

    if (errorStates.isNotEmpty) {
      final errorState = errorStates.first;
      onRetry() => ViewStateBase.onRetry(providers);
      errorStateListener?.call(errorState.message, onRetry,
          errorState.exception, errorState.stackTrace);
      return;
    }
    if (ViewStateBase.hasInitialState(states)) {
      initialStateListener?.call();
      return;
    }
    final loadingStates = ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      loadingStateListener?.call(loadingStates.first.message,
          ViewStateBase.getCombinedLoadingProgress(loadingStates));
      return;
    }
    final emptyStates = ViewStateBase.getEmptyStates(states);
    if (emptyStates.isNotEmpty) {
      emptyStateListener?.call(emptyStates.first.message);
      return;
    }
    dataStateListener?.call(states.cast<DataState<T>>().toList());
    return;
  }

  static _AggregatedViewState _combinedState<T>(List<ViewState<T>> states) {
    if (ViewStateBase.hasErrorState(states)) return _AggregatedViewState.error;
    if (ViewStateBase.hasInitialState(states)) {
      return _AggregatedViewState.initial;
    }
    if (ViewStateBase.hasLoadingState(states)) {
      return _AggregatedViewState.loading;
    }
    if (ViewStateBase.hasEmptyState(states)) return _AggregatedViewState.empty;
    if (ViewStateBase.allAreDataState(states)) return _AggregatedViewState.data;
    return _AggregatedViewState.unknown;
  }
}

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
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current states. Defaults to calling the builder when `previous != current`.
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
class MultiViewStateBuilder<T> extends MultiStateBuilder<ViewState<T>> {
  MultiViewStateBuilder(
      {super.key,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      ErrorStateBuilder? failureBuilder,
      required DataStateBuilder<List<DataState<T>>> dataBuilder,
      super.rebuildWhen,
      bool isSliver = false,
      required super.providers})
      : super(
          builder: (context, states, child) {
            return _multiViewStateBuilder(
                states,
                providers,
                failureBuilder,
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
      List<StateNotifier<ViewState<T>>> providers,
      ErrorStateBuilder? failureBuilder,
      BuildContext context,
      bool isSliver,
      InitialStateBuilder? initialBuilder,
      LoadingStateBuilder? loadingBuilder,
      EmptyStateBuilder? emptyBuilder,
      DataStateBuilder<List<DataState<T>>> dataBuilder) {
    if (ViewStateBase.hasErrorState(states)) {
      return _buildErrorWidget(
          providers, failureBuilder, states, context, isSliver);
    }
    if (ViewStateBase.hasInitialState(states)) {
      return ViewStateBase.buildInitialWidget(
          context, initialBuilder, isSliver);
    }
    final loadingStates = ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      return ViewStateBase.buildLoadingWidget(
          context,
          loadingBuilder,
          loadingStates.first.message,
          ViewStateBase.getCombinedLoadingProgress(loadingStates),
          isSliver);
    }
    final emptyStates = ViewStateBase.getEmptyStates(states);
    if (emptyStates.isNotEmpty) {
      return ViewStateBase.buildEmptyWidget(
          context, emptyBuilder, emptyStates.first.message, isSliver);
    }
    return dataBuilder(states.cast<DataState<T>>().toList());
  }

  static Widget _buildErrorWidget<T>(
    List<StateNotifier<ViewState<T>>> providers,
    ErrorStateBuilder? errorBuilder,
    List<ViewState<T>> states,
    BuildContext context,
    bool isSliver,
  ) {
    final errorStates = states.whereType<ErrorState<T>>().toList();

    void onRetry() {
      ViewStateBase.onRetry(providers);
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
}
