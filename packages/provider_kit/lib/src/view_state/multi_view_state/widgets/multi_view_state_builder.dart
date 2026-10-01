part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state_builder.description}
/// A widget that builds its UI from the combined ViewState of multiple
/// providers.
/// {@endtemplate}
///
/// {@macro provider_kit.multi_state.provider_param}
///
/// {@macro provider_kit.multi_view_state.provider_requirement}
///
/// {@macro provider_kit.multi_view_state.aggregation}
///
/// {@template provider_kit.multi_view_state_builder.details}
/// ### Parameters
///
/// - **[providers]** — Builds the combined state from one or more providers.
/// - **[initialBuilder]** — Builds the UI when the combined state is initial.
/// - **[loadingBuilder]** — Builds the UI when the combined state is loading.
/// - **[emptyBuilder]** — Builds the UI when the combined state is empty.
/// - **[errorBuilder]** — Builds the UI when the combined state contains an
///   error and receives a retry callback for all currently errored providers.
/// - **[dataBuilder]** — Builds the UI when the combined state is data and
///   receives the exact value returned by [providers].
/// - **[emptyBehavior]** — Determines when the combined state is considered
///   empty. Defaults to [EmptyStateBehavior.allEmpty].
/// - **[rebuildWhen]** — Determines whether the widget should rebuild when the
///   combined state changes.
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
/// MultiViewStateBuilder(
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
/// );
/// ```
///
/// A list can be used when the combined state should be a list:
///
/// ```dart
/// MultiViewStateBuilder(
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
/// );
/// ```
///
/// A custom object can be used when you want a dedicated combined state type:
///
/// ```dart
/// MultiViewStateBuilder(
///   providers: () => CombinedState(
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///   ),
///   dataBuilder: (state) {
///     return Text(state.user.toString());
///   },
/// );
/// ```
/// {@endtemplate}
class MultiViewStateBuilder<T> extends MultiStateBuilderBase<T> {
  /// {@macro provider_kit.multi_view_state_builder.description}
  ///
  /// {@macro provider_kit.multi_state.provider_param}
  /// {@macro provider_kit.multi_view_state.provider_requirement}
  /// {@macro provider_kit.multi_view_state.aggregation}
  /// {@macro provider_kit.multi_view_state_builder.details}
  factory MultiViewStateBuilder({
    Key? key,
    required MultiStateProviders<T> providers,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    ErrorStateBuilder? errorBuilder,
    required DataStateBuilder<T> dataBuilder,
    EmptyStateBehavior emptyBehavior = EmptyStateBehavior.allEmpty,
    RebuildWhen<T>? rebuildWhen,
    bool isSliver = false,
    Widget? child,
  }) {
    return MultiViewStateBuilder._withDelegate(
      key: key,
      providers: providers,
      initialBuilder: initialBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      dataBuilder: dataBuilder,
      emptyBehavior: emptyBehavior,
      rebuildWhen: rebuildWhen,
      isSliver: isSliver,
      delegate: _MultiViewStateDependencyDelegate(),
      child: child,
    );
  }

  MultiViewStateBuilder._withDelegate({
    super.key,
    required super.providers,
    required _MultiViewStateDependencyDelegate delegate,
    required this.initialBuilder,
    required this.loadingBuilder,
    required this.emptyBuilder,
    required this.errorBuilder,
    required this.dataBuilder,
    required this.emptyBehavior,
    required this.isSliver,
    super.rebuildWhen,
    super.child,
  }) : _delegate = delegate,
       super._internal(onDependenciesUpdate: delegate.updateDependencies);

  final _MultiViewStateDependencyDelegate _delegate;

  /// {@template provider_kit.multi_view_state.initial_builder}
  /// Builds the UI when the combined state is [InitialState].
  ///
  /// The callback receives whether the widget is being built for use in a
  /// sliver.
  /// {@endtemplate}
  final InitialStateBuilder? initialBuilder;

  /// {@template provider_kit.multi_view_state.loading_builder}
  /// Builds the UI when the combined state is [LoadingState].
  ///
  /// The callback receives the loading message, the average loading progress
  /// from the available progress values, and whether the widget is being built
  /// for use in a sliver.
  /// {@endtemplate}
  final LoadingStateBuilder? loadingBuilder;

  /// {@template provider_kit.multi_view_state.empty_builder}
  /// Builds the UI when the combined state is [EmptyState].
  ///
  /// The callback receives the empty-state message and whether the widget is
  /// being built for use in a sliver.
  /// {@endtemplate}
  final EmptyStateBuilder? emptyBuilder;

  /// {@template provider_kit.multi_view_state.error_builder}
  /// Builds the UI when the combined state contains an [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, a retry
  /// callback, and whether the widget is being built for use in a sliver.
  ///
  /// The retry callback retries every watched provider that is currently in
  /// [ErrorState].
  /// {@endtemplate}
  final ErrorStateBuilder? errorBuilder;

  /// {@template provider_kit.multi_view_state.data_builder}
  /// Builds the UI when the combined state is data.
  /// The callback receives the exact value returned by [providers].
  /// {@endtemplate}
  final DataStateBuilder<T> dataBuilder;

  /// {@macro provider_kit.multi_view_state.empty_behavior}
  final EmptyStateBehavior emptyBehavior;

  /// {@template provider_kit.multi_view_state.is_sliver}
  /// Whether the default state widgets are built for use in a sliver.
  /// {@endtemplate}
  final bool isSliver;

  @override
  Widget build(BuildContext context, T state, Widget? child) {
    return MultiViewStateWidgetUtils.handleBuilder(
      state,
      _delegate.providers,
      errorBuilder,
      context,
      isSliver,
      initialBuilder,
      loadingBuilder,
      emptyBuilder,
      dataBuilder,
      emptyBehavior: emptyBehavior,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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
        ObjectFlagProperty<EmptyStateBehavior>.has(
          'emptyBehavior',
          emptyBehavior,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }
}
