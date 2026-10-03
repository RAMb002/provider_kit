part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state_consumer.description}
/// A widget that both builds its UI and listens to multiple providers using
/// their combined ViewState.
/// {@endtemplate}
///
/// {@macro provider_kit.multi_view_state.provider_param}
///
/// {@macro provider_kit.multi_view_state.provider_requirement}
///
/// {@macro provider_kit.multi_view_state.aggregation}
///
/// {@template provider_kit.multi_view_state_consumer.details}
///
/// ### Parameters
///
/// - **[providers]** — Builds the combined state from one or more providers.
/// - **[initialBuilder]** — Builds the UI when the combined state is initial.
/// - **[loadingBuilder]** — Builds the UI when the combined state is loading.
/// - **[emptyBuilder]** — Builds the UI when the combined state is empty.
/// - **[errorBuilder]** — Builds the UI when the combined state contains an
///   error and receives a retry callback for all currently errored providers
///   that have a retry operation available.
/// - **[dataBuilder]** — Builds the UI when the combined state is data and
///   receives the exact value returned by [providers].
/// - **[initialStateListener]** — Handles the combined initial state.
/// - **[loadingStateListener]** — Handles the combined loading state and
///   receives the first loading message and the average of the available
///   loading progress values.
/// - **[emptyStateListener]** — Handles the combined empty state.
/// - **[errorStateListener]** — Handles the first error state and receives a
///   retry callback for all currently errored providers that have a retry
///   operation available.
/// - **[dataStateListener]** — Handles the combined data state and receives
///   the exact value returned by [providers].
/// - **[rebuildWhen]** — Determines whether the widget should rebuild when the
///   combined state changes.
/// - **[listenWhen]** — Determines whether the listener should be called when
///   the combined state changes.
/// - **[callListenerOnInit]** — Determines whether the listener should be
///   called after initialization.
/// - **[isSliver]** — Determines whether the default state widgets are built
///   for use in a sliver.
/// - **[child]** — An optional widget passed to the builder that can be
///   preserved across rebuilds.
///
/// **Note:** If a builder for a particular state is not provided, ProviderKit
/// uses the corresponding default widget from [ViewStateWidgetsProvider].
///
/// ### Usage
///
/// A record can be used when providers have different state types:
///
/// ```dart
/// MultiViewStateConsumer(
///   providers: () => (
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///     settings: settingsProvider.watch,
///   ),
///   dataBuilder: (state) {
///     return Column(
///       children: [
///         Text(state.user.toString()),
///         Text(state.profile.toString()),
///         Text(state.settings.toString()),
///       ],
///     );
///   },
///   dataStateListener: (state) {
///     // Handle the combined data state.
///   },
/// );
/// ```
///
/// A list can be used when the combined state should be a list:
///
/// ```dart
/// MultiViewStateConsumer(
///   providers: () => [
///     firstProvider.watch,
///     secondProvider.watch,
///   ],
///   dataBuilder: (state) {
///     return Column(
///       children: state
///           .map((value) => Text(value.toString()))
///           .toList(),
///     );
///   },
///   dataStateListener: (state) {
///     // Handle the combined list.
///   },
/// );
/// ```
///
/// A custom object can be used when you want a dedicated combined state type:
///
/// ```dart
/// MultiViewStateConsumer(
///   providers: () => CombinedState(
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///   ),
///   dataBuilder: (state) {
///     return Text(state.user.toString());
///   },
///   dataStateListener: (state) {
///     // Handle the combined state.
///   },
/// );
/// ```
/// {@endtemplate}
class MultiViewStateConsumer<T> extends StatelessWidget {
  /// {@macro provider_kit.multi_view_state_consumer.description}
  ///
  /// {@macro provider_kit.multi_view_state.provider_param}
  /// {@macro provider_kit.multi_view_state.provider_requirement}
  /// {@macro provider_kit.multi_view_state.aggregation}
  /// {@macro provider_kit.multi_view_state_consumer.details}
  const MultiViewStateConsumer({
    super.key,
    required this.providers,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    required this.dataBuilder,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    this.rebuildWhen,
    this.listenWhen,
    this.callListenerOnInit = false,
    this.isSliver = false,
  });

  /// {@macro provider_kit.multi_view_state.provider_param}
  final MultiStateProviders<T> providers;

  /// {@macro provider_kit.multi_view_state.initial_builder}
  final InitialStateBuilder? initialBuilder;

  /// {@macro provider_kit.multi_view_state.loading_builder}
  final LoadingStateBuilder? loadingBuilder;

  /// {@macro provider_kit.multi_view_state.empty_builder}
  final EmptyStateBuilder? emptyBuilder;

  /// {@macro provider_kit.multi_view_state.error_builder}
  final ErrorStateBuilder? errorBuilder;

  /// {@macro provider_kit.multi_view_state.data_builder}
  final DataStateBuilder<T> dataBuilder;

  /// {@macro provider_kit.multi_view_state.initial_listener}
  final InitialStateListener? initialStateListener;

  /// {@macro provider_kit.multi_view_state.loading_listener}
  final LoadingStateListener? loadingStateListener;

  /// {@macro provider_kit.multi_view_state.empty_listener}
  final EmptyStateListener? emptyStateListener;

  /// {@macro provider_kit.multi_view_state.error_listener}
  final ErrorStateListener? errorStateListener;

  /// {@macro provider_kit.multi_view_state.data_listener}
  final DataStateListener<T>? dataStateListener;

  /// {@macro provider_kit.multi_view_state.rebuild_when}
  final RebuildWhen<T>? rebuildWhen;

  /// {@macro provider_kit.multi_view_state.listen_when_param}
  final ListenWhen<T>? listenWhen;

  /// {@macro provider_kit.multi_view_state.call_listener_on_init_param}
  final bool callListenerOnInit;

  /// {@macro provider_kit.multi_view_state.is_sliver}
  final bool isSliver;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
      )
      ..add(
        ObjectFlagProperty<InitialStateBuilder?>.has(
          'initialBuilder',
          initialBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<LoadingStateBuilder?>.has(
          'loadingBuilder',
          loadingBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<EmptyStateBuilder?>.has(
          'emptyBuilder',
          emptyBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<ErrorStateBuilder?>.has(
          'errorBuilder',
          errorBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<DataStateBuilder<T>>.has('dataBuilder', dataBuilder),
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
      ..add(ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen))
      ..add(ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen))
      ..add(
        DiagnosticsProperty<bool>(
          'callListenerOnInit',
          callListenerOnInit,
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }

  @override
  Widget build(BuildContext context) {
    return _MultiViewStateBase<T>(
      providers: providers,
      widgetName: runtimeType.toString(),
      rebuildWhen: rebuildWhen,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      builder: _buildState,
      listener: _handleStateChange,
    );
  }

  Widget _buildState(
    BuildContext context,
    T state,
    _MultiViewStateAggregate aggregate,
    Widget? child,
  ) {
    return _MultiViewStateUtils.handleBuilder(
      state,
      aggregate,
      errorBuilder,
      context,
      isSliver,
      initialBuilder,
      loadingBuilder,
      emptyBuilder,
      dataBuilder,
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
