part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state_listener.description}
/// A widget that listens to multiple providers and handles their combined
/// ViewState.
/// {@endtemplate}
///
/// {@macro provider_kit.multi_view_state.provider_param}
///
/// {@template provider_kit.multi_view_state.provider_requirement}
/// Each provider accessed through `.watch` must be a [ViewStateNotifier] or
/// one of its subclasses, such as [AsyncViewStateNotifier].
/// {@endtemplate}
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
/// MultiViewStateListener(
///   providers: () => (
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///     settings: settingsProvider.watch,
///   ),
///   dataStateListener: (state) {
///     // state.user
///     // state.profile
///     // state.settings
///   },
///   child: const MyPage(),
/// );
/// ```
///
/// A list can be used when the combined state should be a list:
///
/// ```dart
/// MultiViewStateListener(
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
/// MultiViewStateListener(
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
class MultiViewStateListener<T> extends SingleChildStatelessWidget {
  /// {@macro provider_kit.multi_view_state_listener.description}
  ///
  /// {@macro provider_kit.multi_view_state.provider_param}
  /// {@macro provider_kit.multi_view_state.provider_requirement}
  /// {@macro provider_kit.multi_view_state.aggregation}
  /// {@macro provider_kit.multi_view_state_listener.details}
  const MultiViewStateListener({
    super.key,
    required this.providers,
    this.errorStateListener,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.dataStateListener,
    this.listenWhen,
    this.callListenerOnInit = false,
    super.child,
  });

  /// {@template provider_kit.multi_view_state.provider_param}
  /// Builds a combined state from one or more watched [ViewStateNotifier]
  /// providers.
  /// Providers can be watched using `.watch`. Watched providers are
  /// automatically tracked, so the widget updates when any of their states
  /// change.
  ///
  /// Each provider accessed through `.watch` must be a [ViewStateNotifier] or
  /// one of its subclasses, such as [AsyncViewStateNotifier].
  ///
  /// ```dart
  /// providers: () => (
  ///   user: userProvider.watch,
  ///   profile: profileProvider.watch,
  ///   settings: settingsProvider.watch,
  /// )
  /// ```
  ///
  /// The return type can be any Dart type, including a record, list, or custom
  /// object.
  /// {@endtemplate}
  ///
  /// The returned value becomes the combined state passed to [dataStateListener] and
  /// [listenWhen].
  final MultiStateProviders<T> providers;

  /// {@template provider_kit.multi_view_state.error_listener}
  /// Handles the first error state when the combined state contains an
  /// [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, and a
  /// retry callback.
  ///
  /// The retry callback retries every watched provider that is currently in
  /// [ErrorState] and has a retry operation available.
  /// {@endtemplate}
  final ErrorStateListener? errorStateListener;

  /// {@template provider_kit.multi_view_state.initial_listener}
  /// Handles the combined state when it is [InitialState].
  /// {@endtemplate}
  final InitialStateListener? initialStateListener;

  /// {@template provider_kit.multi_view_state.loading_listener}
  /// Handles the combined state when it is [LoadingState].
  ///
  /// The callback receives the first loading message and the average loading
  /// progress from the available progress values.
  /// {@endtemplate}
  final LoadingStateListener? loadingStateListener;

  /// {@template provider_kit.multi_view_state.empty_listener}
  /// Handles the combined state when it is [EmptyState].
  ///
  /// The callback receives the first empty-state message.
  /// {@endtemplate}
  final EmptyStateListener? emptyStateListener;

  /// {@template provider_kit.multi_view_state.data_listener}
  /// Handles the combined state when it is data.
  ///
  /// The callback receives the exact value returned by [providers].
  /// {@endtemplate}
  final DataStateListener<T>? dataStateListener;

  /// {@template provider_kit.multi_view_state.listen_when_param}
  /// Determines whether the listener should be called after ProviderKit
  /// determines that a meaningful Multi View State change has occurred.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [providers].
  ///
  /// Returning `true` allows the listener to be invoked. Returning `false`
  /// suppresses the listener for that change.
  ///
  /// When omitted, the listener is invoked whenever ProviderKit detects a
  /// meaningful Multi View State change.
  /// {@endtemplate}
  final ListenWhen<T>? listenWhen;

  /// {@template provider_kit.multi_view_state.call_listener_on_init_param}
  /// Whether the listener should be called once after the widget is initialized.
  ///
  /// When enabled, the listener receives the initial combined state after the
  /// first frame.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  final bool callListenerOnInit;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
      )
      ..add(
        ObjectFlagProperty<ErrorStateListener?>.has(
          'errorStateListener',
          errorStateListener,
        ),
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
        ObjectFlagProperty<DataStateListener<T>?>.has(
          'dataStateListener',
          dataStateListener,
        ),
      )
      ..add(ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen))
      ..add(
        DiagnosticsProperty<bool>(
          'callListenerOnInit',
          callListenerOnInit,
          defaultValue: false,
        ),
      );
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return _MultiViewStateBase<T>(
      providers: providers,
      widgetName: runtimeType.toString(),
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      listener: _handleStateChange,
      child: child,
    );
  }

  void _handleStateChange(
    BuildContext context,
    T state,
    _MultiViewStateAggregate aggregate,
  ) {
    _MultiViewStateUtils.handleListener(
      state,
      aggregate,
      errorStateListener,
      initialStateListener,
      loadingStateListener,
      emptyStateListener,
      dataStateListener,
    );
  }
}
