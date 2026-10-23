import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiViewStateEngine, MultiViewStateAggregate, MultiViewStateUtils;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_engine.dart';
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
/// - Use [ViewStateBuilder] to build UI from a single view-state notifier.
/// - Use [ViewStateBuilder.of] to retrieve a view-state notifier from the widget tree.
/// - Use [ViewStateBuilder.multi] to build UI from multiple view-state notifiers
///   and handle their combined view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder(
///   listenable: myViewStateNotifier,
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
/// If the view-state notifier is available in the widget tree (e.g., exposed through
/// `Provider`), you can use [ViewStateBuilder.of] to retrieve it:
///
/// ```dart
/// ViewStateBuilder.of<MyViewStateNotifier, DataType>(
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress) {
///     return ...;
///   },
/// ```
///
/// ### Building from Multiple View-State Notifiers
///
/// Use [ViewStateBuilder.multi] when the UI depends on multiple
/// view-state notifiers. Their values are read through `.watch` and
/// automatically tracked by ProviderKit.
///
/// ```dart
/// ViewStateBuilder.multi(
///   listenables: () => (
///     user: userNotifier.watch,
///     profile: profileNotifier.watch,
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
/// The `dataBuilder` receives the combined value returned by the `listenables`
/// callback. Each value is a [ViewState] in the data state, so its `.data`
/// getter provides the contained data.
///
/// The other state builders handle the combined initial, loading, empty, and
/// error states.
///
/// See [ViewStateBuilder.multi] for details on building from multiple
/// view-state notifiers and handling their combined state.
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
  /// Builds the UI when the view-state notifier is in [InitialState].
  ///
  /// The callback receives whether the widget is being built for use in a
  /// sliver.
  /// {@endtemplate}
  final InitialStateBuilder? initialBuilder;

  /// {@template provider_kit.view_state.data_builder}
  /// Builds the UI when the view-state notifier is in [DataState].
  ///
  /// The callback receives the data contained in the [DataState].
  /// {@endtemplate}
  final DataStateBuilder<T> dataBuilder;

  /// {@template provider_kit.view_state.error_builder}
  /// Builds the UI when the view-state notifier is in [ErrorState].
  ///
  /// The callback receives the error information, error, stack trace, a retry
  /// callback, and whether the widget is being built for use in a sliver.
  ///
  /// The retry callback retries the view-state notifier.
  /// {@endtemplate}
  final ErrorStateBuilder? errorBuilder;

  /// {@template provider_kit.view_state.loading_builder}
  /// Builds the UI when the view-state notifier is in [LoadingState].
  ///
  /// The callback receives the loading message, progress, and whether the
  /// widget is being built for use in a sliver.
  /// {@endtemplate}
  final LoadingStateBuilder? loadingBuilder;

  /// {@template provider_kit.view_state.empty_builder}
  /// Builds the UI when the view-state notifier is in [EmptyState].
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
  /// Builds the UI from the provided [ViewStateNotifier].
  const factory ViewStateBuilder({
    Key? key,
    required ViewStateNotifier<T> listenable,
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
  /// view-state notifiers.
  /// {@endtemplate}
  ///
  /// {@macro provider_kit.multi_view_state.listenables_param}
  ///
  /// {@macro provider_kit.multi_view_state.aggregation}
  ///
  /// {@template provider_kit.multi_view_state_builder.details}
  /// ### Parameters
  ///
  /// - **[listenables]** — Builds the combined state from one or more view-state
  ///   notifiers..
  /// - **[initialBuilder]** — Builds the UI when the combined state is initial.
  /// - **[loadingBuilder]** — Builds the UI when the combined state is loading.
  /// - **[emptyBuilder]** — Builds the UI when the combined state is empty.
  /// - **[errorBuilder]** — Builds the UI when the combined state contains an
  ///   error and receives a retry callback for all currently errored view states
  ///   that have a retry operation available.
  /// - **[dataBuilder]** — Builds the UI when the combined state is data and
  ///   receives the exact value returned by [listenables].
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
  /// A record can be used when combining view-state notifiers of different types:
  ///
  /// ```dart
  /// ViewStateBuilder.multi(
  ///   listenables: () => (
  ///     user: userNotifier.watch,
  ///     profile: profileNotifier.watch,
  ///     settings: settingsNotifier.watch,
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
  ///   listenables: () => [
  ///     firstNotifier.watch,
  ///     secondNotifier.watch,
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
  ///   listenables: () => CombinedState(
  ///     user: userNotifier.watch,
  ///     profile: profileNotifier.watch,
  ///   ),
  ///   dataBuilder: (state) {
  ///     return Text(state.user.data.toString());
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory ViewStateBuilder.multi({
    Key? key,
    required MultiStateListenables<T> listenables,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    ErrorStateBuilder? errorBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    RebuildWhen<T>? rebuildWhen,
    bool isSliver,
  }) = _MultiViewStateBuilder<T>;

  /// {@macro provider_kit.view_state_widget.of}
  ///
  /// ```dart
  /// ViewStateBuilder.of<MyViewStateNotifier, DataType>(
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
