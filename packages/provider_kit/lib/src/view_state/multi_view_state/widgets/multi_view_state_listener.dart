part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state_listener.description}
/// A widget that listens to multiple providers and handles their combined
/// ViewState.
/// {@endtemplate}
///
/// {@macro provider_kit.multi_state.provider_param}
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
///   retry callback for all currently errored providers.
/// - **[initialStateListener]** — Handles the combined initial state.
/// - **[loadingStateListener]** — Handles the combined loading state and
///   receives the first loading message and the average of the available
///   loading progress values.
/// - **[emptyStateListener]** — Handles the combined empty state.
/// - **[dataStateListener]** — Handles the combined data state and receives
///   the exact value returned by [providers].
/// - **[emptyBehavior]** — Determines when the combined state is considered
///   empty. Defaults to [EmptyStateBehavior.allEmpty].
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
class MultiViewStateListener<T> extends MultiStateListenerBase<T> {
  /// {@macro provider_kit.multi_view_state_listener.description}
  ///
  /// {@macro provider_kit.multi_state.provider_param}
  /// {@macro provider_kit.multi_view_state.provider_requirement}
  /// {@macro provider_kit.multi_view_state.aggregation}
  /// {@macro provider_kit.multi_view_state_listener.details}
  factory MultiViewStateListener({
    Key? key,
    required MultiStateProviders<T> providers,
    ErrorStateListener? errorStateListener,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    DataStateListener<T>? dataStateListener,
    EmptyStateBehavior emptyBehavior = EmptyStateBehavior.allEmpty,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return MultiViewStateListener._withDelegate(
      key: key,
      providers: providers,
      errorStateListener: errorStateListener,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      emptyStateListener: emptyStateListener,
      dataStateListener: dataStateListener,
      emptyBehavior: emptyBehavior,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      delegate: _MultiViewStateDependencyDelegate(),
      child: child,
    );
  }

  MultiViewStateListener._withDelegate({
    super.key,
    required super.providers,
    required _MultiViewStateDependencyDelegate delegate,
    this.errorStateListener,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.dataStateListener,
    this.emptyBehavior = EmptyStateBehavior.allEmpty,
    super.listenWhen,
    super.callListenerOnInit,
    required super.child,
  }) : _delegate = delegate,
       super._internal(onDependenciesUpdate: delegate.updateDependencies);

  final _MultiViewStateDependencyDelegate _delegate;

  /// {@template provider_kit.multi_view_state.error_listener}
  /// Handles the first error state when the combined state contains an
  /// [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, and a
  /// retry callback.
  ///
  /// The retry callback retries every watched provider that is currently in
  /// [ErrorState].
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

  /// {@template provider_kit.multi_view_state.empty_behavior}
  /// Determines when the combined state is considered [EmptyState].
  ///
  /// Defaults to [EmptyStateBehavior.allEmpty].
  /// {@endtemplate}
  final EmptyStateBehavior emptyBehavior;

  @override
  void onStateChange(BuildContext context, T state) {
    MultiViewStateWidgetUtils.handleListener(
      state,
      _delegate.providers,
      errorStateListener,
      initialStateListener,
      loadingStateListener,
      emptyStateListener,
      dataStateListener,
      emptyBehavior: emptyBehavior,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
      ..add(
        EnumProperty<EmptyStateBehavior>(
          'emptyBehavior',
          emptyBehavior,
          defaultValue: EmptyStateBehavior.allEmpty,
        ),
      );
  }
}
