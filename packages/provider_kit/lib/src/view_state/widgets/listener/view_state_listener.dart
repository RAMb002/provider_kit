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
/// - Use [ViewStateListener] to listen to a single provider.
/// - Use [ViewStateListener.of] to resolve a provider from the widget tree.
/// - Use [ViewStateListener.multi] to listen to multiple providers and handle
///   their combined view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateListener(
///   provider: provider,
///   callListenerOnInit: false, // Optional, default is false
///   initialStateListener: () {
///     // Handle initial state
///   },
///   loadingStateListener: (message, progress) {
///     // Handle loading state
///   },
///   emptyStateListener: (message) {
///     // Handle empty state
///   },
///   errorStateListener: (errorInfo, error, stackTrace, onRetry) {
///     // Handle error state
///   },
///   dataStateListener: (data) {
///     // Handle data state
///   },
///   child: SomeWidget(),
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [ViewStateListener.of] to resolve it from the widget tree:
///
/// ```dart
/// ViewStateListener.of<MyProvider, DataType>(
///   loadingStateListener: (message, progress) {
///     // Handle loading state.
///   },
///   dataStateListener: (data) {
///     // Handle data state.
///   },
///   child: SomeWidget(),
/// )
/// ```
/// ### Listening to Multiple Providers
///
/// Use [ViewStateListener.multi] when a listener depends on multiple
/// [ViewStateNotifier] providers. Providers are read through `.watch` and
/// automatically tracked by ProviderKit.
///
/// ```dart
/// ViewStateListener.multi(
///   providers: () => (
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///   ),
///   dataStateListener: (state) {
///     // state.user.data
///     // state.profile.data
///   },
///   child: const MyPage(),
/// )
/// ```
///
/// The `dataStateListener` receives the combined value returned by the
/// `providers` callback. Each value is a [ViewState] in the data state, so
/// its `.data` getter provides the contained data.
///
/// See [ViewStateListener.multi] for details on listening to multiple
/// providers and handling their combined state.
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
  /// Called when the provider is in [InitialState].
  /// {@endtemplate}
  final InitialStateListener? initialStateListener;

  /// {@template provider_kit.view_state.loading_listener}
  /// Called when the provider is in [LoadingState].
  ///
  /// The callback receives the loading message and progress.
  /// {@endtemplate}
  final LoadingStateListener? loadingStateListener;

  /// {@template provider_kit.view_state.empty_listener}
  /// Called when the provider is in [EmptyState].
  ///
  /// The callback receives the empty-state message.
  /// {@endtemplate}
  final EmptyStateListener? emptyStateListener;

  /// {@template provider_kit.view_state.error_listener}
  /// Called when the provider is in [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, and a
  /// retry callback.
  /// {@endtemplate}
  final ErrorStateListener? errorStateListener;

  /// {@template provider_kit.view_state.data_listener}
  /// Called when the provider is in [DataState].
  ///
  /// The callback receives the data contained in the [DataState].
  /// {@endtemplate}
  final DataStateListener<T>? dataStateListener;

  /// {@macro provider_kit.state_listener.call_listener_on_init}
  final bool callListenerOnInit;

  /// {@macro provider_kit.view_state_listener}
  const factory ViewStateListener({
    Key? key,
    required ViewStateNotifier<T> provider,
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
  /// A widget that listens to multiple providers and handles their combined
  /// ViewState.
  /// {@endtemplate}
  ///
  /// {@macro provider_kit.multi_view_state.provider_param}
  ///
  /// {@macro provider_kit.multi_view_state.aggregation}
  ///
  /// {@template provider_kit.multi_view_state_listener.details}
  /// ### Parameters
  ///
  /// - **[providers]** — Builds the combined state from one or more providers.
  /// - **[errorStateListener]** — Handles the first error state and receives a
  ///   retry callback for all currently errored providers that have a retry
  ///   operation available.
  /// - **[initialStateListener]** — Handles the combined initial state.
  /// - **[loadingStateListener]** — Handles the combined loading state and
  ///   receives the first loading message and the average of the available
  ///   loading progress values.
  /// - **[emptyStateListener]** — Handles the combined empty state.
  /// - **[dataStateListener]** — Handles the combined data state and receives
  ///   the exact value returned by [providers].
  /// - **[listenWhen]** — Determines whether the listener should be called when
  ///   the combined state changes.
  /// - **[callListenerOnInit]** — Determines whether the listener should be
  ///   called after initialization.
  /// - **[child]** — The child widget displayed by this listener.
  ///
  /// ### Usage
  ///
  /// A record can be used when providers have different state types:
  ///
  /// ```dart
  /// ViewStateListener.multi(
  ///   providers: () => (
  ///     user: userProvider.watch,
  ///     profile: profileProvider.watch,
  ///     settings: settingsProvider.watch,
  ///   ),
  ///   dataStateListener: (state) {
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
  ///   providers: () => [
  ///     firstProvider.watch,
  ///     secondProvider.watch,
  ///   ],
  ///   dataStateListener: (state) {
  ///     // Handle the combined list.
  ///   },
  /// );
  /// ```
  ///
  /// A custom object can be used when you want a dedicated combined state type:
  ///
  /// ```dart
  /// ViewStateListener.multi(
  ///   providers: () => CombinedState(
  ///     user: userProvider.watch,
  ///     profile: profileProvider.watch,
  ///   ),
  ///   dataStateListener: (state) {
  ///     // Handle the combined state.
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory ViewStateListener.multi({
    Key? key,
    required MultiStateProviders<T> providers,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _MultiViewStateListener<T>;

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// ViewStateListener.of<MyProvider, DataType>(
  ///   loadingStateListener: (message, progress) {
  ///     // Handle loading state.
  ///   },
  ///   dataStateListener: (data) {
  ///     // Handle data state.
  ///   },
  ///   child: SomeWidget(),
  /// )
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
