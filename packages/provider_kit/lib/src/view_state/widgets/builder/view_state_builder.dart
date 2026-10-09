import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiViewStateBase, MultiViewStateAggregate, MultiViewStateUtils;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/builder/state_builder.dart';
import 'package:provider_kit/src/view_state/notifiers/view_state_notifier.dart';
import 'package:provider_kit/src/view_state/states/view_states.dart';
import 'package:provider_kit/src/view_state/type_defs/view_state_callbacks.dart';
import 'package:provider_kit/src/view_state/utils/view_state_widget_utils.dart';

part 'multi_view_state_builder.dart';
part 'view_state_builder_base.dart';
part 'view_state_builder_impl.dart';
part 'view_state_builder_of.dart';

/// {@template provider_kit.view_state_builder}
/// A widget that builds its UI based on the specific [ViewState] of a [ViewStateNotifier].
///
/// The [ViewStateBuilder] is used to build different UI components in response to different view states
/// such as `InitialState`, `LoadingState`, `DataState<DataType>`, `EmptyState`, and `ErrorState`.
/// It ensures that the appropriate builder is called based on the current view state.
///
/// If the user does not supply a builder for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// - Use [ViewStateBuilder] to build UI from a single provider.
/// - Use [ViewStateBuilder.of] to resolve a provider from the widget tree.
/// - Use [ViewStateBuilder.multi] to build UI from multiple providers and handle
///   their combined view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder(
///   provider: provider,
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   initialBuilder: (isSliver) {
///     // Build your widget tree for InitialState
///     return Container();
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     // Build your widget tree for LoadingState
///     return Container();
///   },
///   emptyBuilder: (message, isSliver) {
///     // Build your widget tree for EmptyState
///     return Container();
///   },
///   errorBuilder: (errorInfo, error, stackTrace, onRetry, isSliver) {
///     // Build your widget tree for ErrorState
///     return Container();
///   },
///   dataBuilder: (data) {
///     // Build your widget tree for DataState<DataType>
///     return Container();
///   },
///   isSliver: false, // Optional, default is false
/// )
/// ```
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [ViewStateBuilder.of] to resolve it from the widget tree:
///
/// ```dart
/// ViewStateBuilder.of<MyProvider, DataType>(
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress) {
///     return ...;
///   },
/// ```
///
/// ### Building from Multiple Providers
///
/// Use [ViewStateBuilder.multi] when the UI depends on multiple
/// [ViewStateNotifier] providers. Providers are read through `.watch` and
/// automatically tracked by ProviderKit.
///
/// ```dart
/// ViewStateBuilder.multi(
///   providers: () => (
///     user: userProvider.watch,
///     profile: profileProvider.watch,
///   ),
///   dataBuilder: (state) {
///     return Column(
///       children: [
///         Text(state.user.data.toString()),
///         Text(state.profile.data.toString()),
///       ],
///     );
///   },
/// )
/// ```
///
/// The `dataBuilder` receives the combined value returned by the `providers`
/// callback. Each value is a [ViewState] in the data state, so its `.data`
/// getter provides the contained data.
///
/// The other state builders handle the combined initial, loading, empty, and
/// error states.
///
/// See [ViewStateBuilder.multi] for details on building from multiple
/// providers and handling their combined state.
/// {@endtemplate}
abstract class ViewStateBuilder<T> extends StatefulWidget {
  const ViewStateBuilder.base({
    super.key,
    required this.dataBuilder,
    this.initialBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.isSliver = false,
  });

  /// {@template provider_kit.view_state.initial_builder}
  /// Builds the UI when the provider is in [InitialState].
  ///
  /// The callback receives whether the widget is being built for use in a
  /// sliver.
  /// {@endtemplate}
  final InitialStateBuilder? initialBuilder;

  /// {@template provider_kit.view_state.data_builder}
  /// Builds the UI when the provider is in [DataState].
  ///
  /// The callback receives the data contained in the [DataState].
  /// {@endtemplate}
  final DataStateBuilder<T> dataBuilder;

  /// {@template provider_kit.view_state.error_builder}
  /// Builds the UI when the provider is in [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, a retry
  /// callback, and whether the widget is being built for use in a sliver.
  ///
  /// The retry callback retries the provider.
  /// {@endtemplate}
  final ErrorStateBuilder? errorBuilder;

  /// {@template provider_kit.view_state.loading_builder}
  /// Builds the UI when the provider is in [LoadingState].
  ///
  /// The callback receives the loading message, progress, and whether the
  /// widget is being built for use in a sliver.
  /// {@endtemplate}
  final LoadingStateBuilder? loadingBuilder;

  /// {@template provider_kit.view_state.empty_builder}
  /// Builds the UI when the provider is in [EmptyState].
  ///
  /// The callback receives the empty-state message and whether the widget is
  /// being built for use in a sliver.
  /// {@endtemplate}
  final EmptyStateBuilder? emptyBuilder;

  /// {@template provider_kit.view_state.is_sliver}
  /// Whether the default state widgets are built for use in a sliver.
  /// {@endtemplate}
  final bool isSliver;

  /// {@macro provider_kit.view_state_builder}
  ///
  /// Listens to the provided [ViewStateNotifier].
  const factory ViewStateBuilder({
    Key? key,
    required ViewStateNotifier<T> provider,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    bool isSliver,
  }) = _ViewStateBuilder<T>;

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
  /// ViewStateBuilder.multi(
  ///   providers: () => (
  ///     user: userProvider.watch,
  ///     profile: profileProvider.watch,
  ///     settings: settingsProvider.watch,
  ///   ),
  ///   dataBuilder: (state) {
  ///     return Column(
  ///       children: [
  ///         Text(state.user.data.toString()),
  ///         Text(state.profile.data.toString()),
  ///         Text(state.settings.data.toString()),
  ///       ],
  ///     );
  ///   },
  /// );
  /// ```
  ///
  /// A list can be used when the combined state should be a list:
  ///
  /// ```dart
  /// ViewStateBuilder.multi(
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
  /// ViewStateBuilder.multi(
  ///   providers: () => CombinedState(
  ///     user: userProvider.watch,
  ///     profile: profileProvider.watch,
  ///   ),
  ///   dataBuilder: (state) {
  ///     return Text(state.user.data.toString());
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory ViewStateBuilder.multi({
    Key? key,
    required MultiStateProviders<T> providers,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    RebuildWhen<T>? rebuildWhen,
    bool isSliver,
  }) = _MultiViewStateBuilder<T>;

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// ViewStateBuilder.of<MyProvider, DataType>(
  ///   dataBuilder: (data) {
  ///     return ...;
  ///   },
  ///   loadingBuilder: (message, progress) {
  ///     return ...;
  ///   },
  /// )
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    bool isSliver = false,
  }) {
    return _ViewStateBuilderOf<P, T>(
      key: key,
      dataBuilder: dataBuilder,
      initialBuilder: initialBuilder,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      rebuildWhen: rebuildWhen,
      isSliver: isSliver,
    );
  }

  /// The public widget name used in diagnostics.
  String get debugWidgetName => 'ViewStateBuilder<$T>';

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
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }
}
