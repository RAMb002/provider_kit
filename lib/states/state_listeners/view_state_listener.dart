import 'package:provider_kit/notifiers/view_state_notifier.dart';
import 'package:provider_kit/states/state_listeners/state_listener.dart';
import 'package:provider_kit/states/view_states.dart';
import 'package:provider_kit/utils/type_definitions.dart';

/// A widget that listens to changes in a [ViewStateNotifier] and triggers callbacks
/// based on the specific [ViewState].
///
/// The [ViewStateListener] is used to perform actions in response to different view states
/// such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate callback is called based on the current view state.
///
/// ### Parameters:
/// - **`initialStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `InitialState`.
/// - **`loadingStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `LoadingState`.
/// - **`emptyStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `EmptyState`.
/// - **`errorStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `ErrorState`.
/// - **`dataStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `DataState<DataType>`.
/// - **`provider`** (*Optional*) **:** Specify the [provider] if the state provider is not accessible via [Provider] and the current `BuildContext`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current state. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`child`** (*Required*) **:** Your child widget goes here.
///
/// ### Example Usage:
/// ```dart
/// ViewStateListener<Provider, DataType                    >(
///   provider: provider, // Optional
///   shouldCallListenerOnInit: false, // Optional, default is false
///   initialStateListener: () {
///     // Handle initial state
///   },
///   loadingStateListener: (message, progress) {
///     // Handle loading state
///   },
///   emptyStateListener: (message) {
///     // Handle empty state
///   },
///   errorStateListener: (errorMessage, onRetry, exception, stackTrace) {
///     // Handle error state
///   },
///   dataStateListener: (data) {
///     // Handle data state
///   },
///   child: SomeWidget(), // Optional
/// )
/// ```
class ViewStateListener<P extends ViewStateNotifier<T>, T>
    extends StateListener<P, ViewState<T>> {
  ViewStateListener({
    super.key,
    super.provider,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    super.listenWhen,
    super.shouldcallListenerOnInit,
    super.child,
  }) : super(
          listener: (context, state) {
            state.when(
              initialState: () => initialStateListener?.call(),
              loadingState: (message, progress) =>
                  loadingStateListener?.call(message, progress),
              dataState: (data) => dataStateListener?.call(data),
              emptyState: (message) => emptyStateListener?.call(message),
              errorState: (errorMessage, onRetry, exception, stackTrace) =>
                  errorStateListener?.call(
                      errorMessage, onRetry, exception, stackTrace),
            );
          },
        );
}
