import 'package:provider_kit/src/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/states/state_builders/view_state_builder.dart';
import 'package:provider_kit/src/states/state_consumers/state_consumer.dart';
import 'package:provider_kit/src/states/view_states.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// A widget that combines both listening to and building based on the specific [ViewState] of a [ViewStateNotifier].
///
/// The [ViewStateConsumer] widget is used to perform actions and build its child widget
/// in response to different view states such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate listener and builder are called based on the current view state.
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
/// - **`initialStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `InitialState`.
/// - **`loadingStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `LoadingState`.
/// - **`emptyStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `EmptyState`.
/// - **`errorStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `ErrorState`.
/// - **`dataStateListener`** (*Optional*) **:** A callback function that is invoked when the state is `DataState<DataType>`.
/// - **`provider`** (*Optional*) **:** Specify the [provider] if the state provider is not accessible via [Provider] and the current `BuildContext`.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current state. Defaults to calling the builder when `previous != current`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current state. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`isSliver`** (*Optional*, default: `false`) **:** Indicates whether the widget should be a sliver.
/// - **`key`** (*Optional*) **:** An optional key for the widget.
///
/// ### Example Usage:
/// ```dart
/// ViewStateConsumer<Provider, DataType>(
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
///   isSliver: false, // Optional, default is false
///   key: Key('view_state_consumer'), // Optional
/// )
/// ```
class ViewStateConsumer<P extends ViewStateNotifier<T>, T>
    extends StateConsumer<P, ViewState<T>> {
  ViewStateConsumer({
    super.key,
    super.provider,
    super.rebuildWhen,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    required DataStateBuilder<T> dataBuilder,
    ErrorStateBuilder? errorBuilder,
    super.listenWhen,
    InitialStateListener? initialStateListener,
    DataStateListener<T>? dataStateListener,
    EmptyStateListener? emptyStateListener,
    LoadingStateListener? loadingStateListener,
    ErrorStateListener? errorStateListener,
    super.shouldCallListenerOnInit,
    bool isSliver = false,
  }) : super(
          builder: (context, state, child) {
            return ViewStateBuilder.buildStateWidget<P, T>(
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
                      errorMessage, onRetry, exception, stackTrace),
            );
          },
        );
}
