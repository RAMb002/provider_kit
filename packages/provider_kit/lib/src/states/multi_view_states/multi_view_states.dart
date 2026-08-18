// ignore_for_file: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/notifiers/notifiers.dart';
import 'package:provider_kit/src/states/states.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';
import 'package:provider_kit/src/view_state_widgets_provider.dart';

/// {@template providerkit-multiviewstateconsumer}
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
/// - **`rebuildWhen`** (*Optional*) **:** Modifying this overrides the default priority logic, triggering builder whenever any provider's state changes.
/// - **`listenWhen`** (*Optional*) **:** Modifying this overrides the default priority logic, triggering listener whenever any provider's state changes.
/// - **`callListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
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
///   callListenerOnInit: true, // Optional, default is false
///   isSliver: false, // Optional, default is false
/// )
/// ```
/// {@endtemplate}

class MultiViewStateConsumer<T> extends MultiStateConsumer<ViewState<T>> {
  final InitialStateBuilder? initialBuilder;
  final LoadingStateBuilder? loadingBuilder;
  final EmptyStateBuilder? emptyBuilder;
  final ErrorStateBuilder? errorBuilder;
  final MultiDataStateBuilder<List<DataState<T>>> dataBuilder;
  final bool isSliver;

  final InitialStateListener? initialStateListener;
  final LoadingStateListener? loadingStateListener;
  final EmptyStateListener? emptyStateListener;
  final ErrorStateListener? errorStateListener;
  final DataStateListener<List<DataState<T>>>? dataStateListener;

  /// {@macro providerkit-multiviewstateconsumer}
  MultiViewStateConsumer(
      {super.key,
      required List<ViewStateNotifier<T>> providers,
      this.initialBuilder,
      this.loadingBuilder,
      this.emptyBuilder,
      this.errorBuilder,
      required this.dataBuilder,
      super.rebuildWhen,
      this.initialStateListener,
      this.loadingStateListener,
      this.emptyStateListener,
      this.errorStateListener,
      this.dataStateListener,
      super.listenWhen,
      super.callListenerOnInit,
      this.isSliver = false})
      : super(
          providers: providers,
          builder: (context, states, child) =>
              MultiViewStateBuilder._multiViewStateBuilder(
                  states,
                  providers,
                  errorBuilder,
                  context,
                  isSliver,
                  initialBuilder,
                  loadingBuilder,
                  emptyBuilder,
                  dataBuilder),
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
          DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false))
      ..add(ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener', initialStateListener))
      ..add(ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener', loadingStateListener))
      ..add(ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener', emptyStateListener))
      ..add(ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener', errorStateListener))
      ..add(ObjectFlagProperty<DataStateListener<List<DataState<T>>>?>.has(
          'dataStateListener', dataStateListener));
  }
}

/// {@template providerkit-multiviewstatelistener}
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
/// - **`listenWhen`** (*Optional*) **:** Modifying this overrides the default priority logic, triggering listener whenever any provider's state changes.
/// - **`callListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
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
///   callListenerOnInit: true, // Optional, default is false
///   child: SomeWidget(), // Optional
/// )
/// ```
/// {@endtemplate}

class MultiViewStateListener<T> extends MultiStateListener<ViewState<T>> {
  final InitialStateListener? initialStateListener;
  final LoadingStateListener? loadingStateListener;
  final EmptyStateListener? emptyStateListener;
  final ErrorStateListener? errorStateListener;
  final MultiDataStateListener<List<DataState<T>>>? dataStateListener;

  /// {@macro providerkit-multiviewstatelistener}
  MultiViewStateListener({
    super.key,
    required List<ViewStateNotifier<T>> providers,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(
          providers: providers,
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

  static void _multiStateListener<T>(
      List<ViewState<T>> states,
      List<ViewStateNotifier<T>> providers,
      ErrorStateListener? errorStateListener,
      InitialStateListener? initialStateListener,
      LoadingStateListener? loadingStateListener,
      EmptyStateListener? emptyStateListener,
      MultiDataStateListener<List<DataState<T>>>? dataStateListener) {
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<InitialStateListener?>.has(
          'initialStateListener', initialStateListener))
      ..add(ObjectFlagProperty<LoadingStateListener?>.has(
          'loadingStateListener', loadingStateListener))
      ..add(ObjectFlagProperty<EmptyStateListener?>.has(
          'emptyStateListener', emptyStateListener))
      ..add(ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener', errorStateListener))
      ..add(ObjectFlagProperty<MultiDataStateListener<List<DataState<T>>>?>.has(
          'dataStateListener', dataStateListener));
  }
}

/// {@template providerkit-multiviewstatebuilder}
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

  /// {@macro providerkit-multiviewstatebuilder}
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
    if (ViewStateBase.hasErrorState(states)) {
      return _buildErrorWidget(
          providers, errorBuilder, states, context, isSliver);
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
    List<ViewStateNotifier<T>> providers,
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
