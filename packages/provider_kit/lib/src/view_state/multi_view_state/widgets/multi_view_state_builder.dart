part of '../../../state/multi_state/multi_state.dart';

/// {@template provider_kit.multi_view_state_builder.description}
/// A widget that builds its UI from the combined ViewState of multiple
/// providers.
/// {@endtemplate}
///
/// {@macro provider_kit.multi_view_state.provider_param}
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
/// - **[rebuildWhen]** — Determines whether the widget should rebuild when the
///   combined state changes.
/// - **[isSliver]** — Determines whether the default state widgets are built
///   for use in a sliver.
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
class MultiViewStateBuilder<T> extends StatelessWidget {
  /// {@macro provider_kit.multi_view_state_builder.description}
  ///
  /// {@macro provider_kit.multi_view_state.provider_param}
  /// {@macro provider_kit.multi_view_state.provider_requirement}
  /// {@macro provider_kit.multi_view_state.aggregation}
  /// {@macro provider_kit.multi_view_state_builder.details}
  const MultiViewStateBuilder({
    super.key,
    required this.providers,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    required this.dataBuilder,
    this.rebuildWhen,
    this.isSliver = false,
  });

  /// {@macro provider_kit.multi_view_state.provider_param}
  final MultiStateProviders<T> providers;

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

  /// {@template provider_kit.multi_view_state.rebuild_when}
  /// Determines whether the widget should rebuild after ProviderKit detects
  /// that the combined ViewState has changed.
  ///
  /// The callback receives the previous and current combined states returned
  /// by [providers].
  ///
  /// Returning `true` allows the widget to rebuild. Returning `false` skips
  /// the rebuild for that change.
  ///
  /// When omitted, the widget rebuilds whenever ProviderKit detects a
  /// combined ViewState change.
  /// {@endtemplate}
  final RebuildWhen<T>? rebuildWhen;

  /// {@template provider_kit.multi_view_state.is_sliver}
  /// Whether the default state widgets are built for use in a sliver.
  /// {@endtemplate}
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
      ..add(ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen))
      ..add(
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiViewStateBase<T>(
      providers: providers,
      widgetName: runtimeType.toString(),
      rebuildWhen: rebuildWhen,
      builder: _buildState,
    );
  }

  Widget _buildState(
    BuildContext context,
    T state,
    MultiViewStateAggregate aggregate,
    Widget? child,
  ) {
    return MultiViewStateUtils.handleBuilder(
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
}
