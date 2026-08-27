part of '../view_state_widgets.dart';

/// {@template provider_kit.multi_view_state_listener}
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

  /// {@macro provider_kit.multi_view_state_listener}
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
    final errorStates = _ViewStateBase.getErrorStates(states);

    if (errorStates.isNotEmpty) {
      final errorState = errorStates.first;
      onRetry() => _ViewStateBase.onRetry(providers);
      errorStateListener?.call(errorState.message, onRetry,
          errorState.exception, errorState.stackTrace);
      return;
    }
    if (_ViewStateBase.hasInitialState(states)) {
      initialStateListener?.call();
      return;
    }
    final loadingStates = _ViewStateBase.getLoadingStates(states);
    if (loadingStates.isNotEmpty) {
      loadingStateListener?.call(loadingStates.first.message,
          _ViewStateBase.getCombinedLoadingProgress(loadingStates));
      return;
    }
    final emptyStates = _ViewStateBase.getEmptyStates(states);
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
