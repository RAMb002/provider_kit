import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiViewStateEngine, MultiViewStateAggregate, MultiViewStateUtils;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_engine.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/view_state_widget_utils.dart';

part 'multi_view_state_listener.dart';
part 'view_state_listener_base.dart';
part 'view_state_listener_impl.dart';
part 'view_state_listener_of.dart';

/// {@template provider_kit.view_state_listener}
/// A widget that listens to changes in a [ViewStateNotifier] and triggers callbacks
/// based on the specific [ViewState].
///
/// The [ViewStateListener] is used to perform actions in response to different view states
/// such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate callback is called based on the current view state.
///
/// - Use [ViewStateListener] to listen to a single view-state notifier.
/// - Use [ViewStateListener.of] to retrieve a view-state notifier from the widget tree.
/// - Use [ViewStateListener.multi] to listen to multiple view-state notifiers
///   and handle their combined view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateListener<MyData>(
///   listenable: myViewStateNotifier, // Required
///   callListenerOnInit: false, // Optional; defaults to false
///   listenWhen: (previous, current) => previous != current, // Optional
///   initialStateListener: (context) {
///     // Handle initial state.
///   },
///   loadingStateListener: (context, details) {
///     final message = details.message;
///     final progress = details.progress;
///   },
///   emptyStateListener: (context, details) {
///     final message = details.message;
///   },
///   errorStateListener: (context, details) {
///     final errorInfo = details.errorInfo;
///     final error = details.error;
///     final stackTrace = details.stackTrace;
///     final onRetry = details.onRetry;
///   },
///   dataStateListener: (context, data) {
///     // Handle data state.
///   },
///   child: const MyPage(),
/// );
/// ```
///
/// If the view-state notifier is available in the widget tree (e.g., exposed through
/// `Provider`), you can use [ViewStateListener.of] to retrieve it:
///
/// ```dart
/// ViewStateListener.of<MyViewStateNotifier, MyData>(
///   loadingStateListener: (context, details) {
///     // Use details.message and details.progress.
///   },
///   dataStateListener: (context, data) {
///     // Handle data state.
///   },
///   child: const MyPage(),
/// );
/// ```
/// ### Listening to Multiple View-State Notifiers
///
/// Use [ViewStateListener.multi] when a listener depends on multiple
/// view-state notifiers. Their values are read through `.watch` and
/// automatically tracked by ProviderKit.
///
/// ```dart
/// ViewStateListener.multi(
///   listenables: () => (
///     user: userNotifier.watch,
///     profile: profileNotifier.watch,
///   ),
///   dataStateListener: (context, state) {
///     // state.user.data
///     // state.profile.data
///   },
///   child: const MyPage(),
/// );
/// ```
///
/// The `dataStateListener` receives the combined value returned by the
/// `listenables` callback. Each value is a [ViewState] whose `.data` getter
/// provides the contained data when it is in the data state.
///
/// See [ViewStateListener.multi] for details on listening to multiple
/// view-state notifiers and handling their combined state.
///
/// ### Message localization
///
/// Messages in loading and empty states, and error messages, can be plain text
/// or localization keys. Configure `ViewStateWidgetsProvider.messageResolver`
/// to resolve these messages into localized text. ProviderKit resolves them
/// before passing them to the corresponding listener callback. If no resolver
/// handles a message, the original message is used. Resolving messages does
/// not modify the stored view state or its original error information.
///
/// {@endtemplate}
abstract class ViewStateListener<T> extends SingleChildStatefulWidget {
  const ViewStateListener.base({
    super.key,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    this.callListenerOnInit = false,
    super.child,
  });

  /// {@template provider_kit.view_state.initial_listener}
  /// Called when the view-state notifier is in [InitialState].
  ///
  /// The callback receives the current [BuildContext].
  /// {@endtemplate}
  final InitialStateListener? initialStateListener;

  /// {@template provider_kit.view_state.loading_listener}
  /// Called when the view-state notifier is in [LoadingState].
  ///
  /// The callback receives the current [BuildContext] and a
  /// `LoadingStateDetails` object containing the loading message and progress.
  /// {@endtemplate}
  final LoadingStateListener? loadingStateListener;

  /// {@template provider_kit.view_state.empty_listener}
  /// Called when the view-state notifier is in [EmptyState].
  ///
  /// The callback receives the current [BuildContext] and an
  /// `EmptyStateDetails` object containing the empty-state message.
  /// {@endtemplate}
  final EmptyStateListener? emptyStateListener;

  /// {@template provider_kit.view_state.error_listener}
  /// Called when the view-state notifier is in [ErrorState].
  ///
  /// The callback receives the current [BuildContext] and an
  /// `ErrorStateDetails` object containing the error information, original
  /// error, stack trace, and optional retry callback.
  /// {@endtemplate}
  final ErrorStateListener? errorStateListener;

  /// {@template provider_kit.view_state.data_listener}
  /// Called when the view-state notifier is in [DataState].
  ///
  /// The callback receives the current [BuildContext] and the data contained
  /// in the [DataState].
  /// {@endtemplate}
  final DataStateListener<T>? dataStateListener;

  /// {@macro provider_kit.state_listener.call_listener_on_init}
  final bool callListenerOnInit;

  /// {@macro provider_kit.view_state_listener}
  const factory ViewStateListener({
    Key? key,
    required ViewStateNotifier<T> listenable,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _ViewStateListener<T>;

  /// {@template provider_kit.multi_view_state_listener.description}
  /// A widget that listens to multiple view-state notifiers and handles their combined
  /// ViewState.
  /// {@endtemplate}
  ///
  /// {@macro provider_kit.multi_view_state.listenables_param}
  ///
  /// {@macro provider_kit.multi_view_state.aggregation}
  ///
  /// {@template provider_kit.multi_view_state_listener.details}
  /// ### Parameters
  ///
  /// - **[listenables]** — Builds the combined state from one or more view-state
  ///   notifiers through `.watch`.
  /// - **[errorStateListener]** — Handles the combined error state. Receives the
  ///   context and `ErrorStateDetails` (error information, original error, stack
  ///   trace, and optional retry callback). The retry callback retries all
  ///   errored notifiers that support retrying.
  /// - **[initialStateListener]** — Handles the combined initial state and
  ///   receives the context.
  /// - **[loadingStateListener]** — Handles the combined loading state. Receives
  ///   the context and `LoadingStateDetails` (first loading message and average
  ///   of available progress values).
  /// - **[emptyStateListener]** — Handles the combined empty state. Receives the
  ///   context and `EmptyStateDetails` (first empty-state message).
  /// - **[dataStateListener]** — Handles the combined data state. Receives the
  ///   context and the exact value returned by [listenables].
  /// - **[listenWhen]** — Controls whether the listener is called when the
  ///   combined state changes.
  /// - **[callListenerOnInit]** — Determines whether the listener is called
  ///   after initialization.
  /// - **[child]** — The child widget displayed by this listener.
  ///
  /// ### Usage
  ///
  /// A record can be used when combining view-state notifiers of different types:
  ///
  /// ```dart
  /// ViewStateListener.multi(
  ///   listenables: () => (
  ///     user: userNotifier.watch,
  ///     profile: profileNotifier.watch,
  ///     settings: settingsNotifier.watch,
  ///   ),
  ///   dataStateListener: (context, state) {
  ///     // state.user.data
  ///     // state.profile.data
  ///     // state.settings.data
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  ///
  /// A list can be used when the combined state should be a list:
  ///
  /// ```dart
  /// ViewStateListener.multi(
  ///   listenables: () => [
  ///     firstNotifier.watch,
  ///     secondNotifier.watch,
  ///   ],
  ///   dataStateListener: (context, state) {
  ///     // Handle the combined list.
  ///   },
  /// );
  /// ```
  ///
  /// A custom object can be used when you want a dedicated combined state type:
  ///
  /// ```dart
  /// ViewStateListener.multi(
  ///   listenables: () => CombinedState(
  ///     user: userNotifier.watch,
  ///     profile: profileNotifier.watch,
  ///   ),
  ///   dataStateListener: (context, state) {
  ///     // Handle the combined state.
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory ViewStateListener.multi({
    Key? key,
    required MultiStateListenables<T> listenables,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _MultiViewStateListener<T>;

  /// {@template provider_kit.view_state_widget.of}
  /// Resolves a [ViewStateNotifier] from the current [BuildContext] by its type.
  ///
  /// Use this when a notifier has already been exposed in the widget tree,
  /// for example through `Provider` from the `provider` package.
  ///
  /// {@endtemplate}
  ///
  /// ```dart
  /// ViewStateListener.of<MyViewStateNotifier, DataType>(
  ///   loadingStateListener: (context, details) {
  ///     // Handle loading state.
  ///   },
  ///   dataStateListener: (context, data) {
  ///     // Handle data state.
  ///   },
  ///   child: SomeWidget(),
  /// );
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return _ViewStateListenerOf<P, T>(
      key: key,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
      dataStateListener: dataStateListener,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      )
      ..add(
        DiagnosticsProperty<bool>(
          'callListenerOnInit',
          callListenerOnInit,
          defaultValue: false,
        ),
      );
  }

  /// The public widget name used in diagnostics and assertions.
  String get debugWidgetName => 'ViewStateListener<$T>';
}
