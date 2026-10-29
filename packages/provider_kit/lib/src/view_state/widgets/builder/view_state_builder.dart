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
///
/// - Use [ViewStateBuilder] to build UI from a single view-state notifier.
/// - Use [ViewStateBuilder.of] to retrieve a view-state notifier from the widget tree.
/// - Use [ViewStateBuilder.multi] to build UI from multiple view-state notifiers
///   and handle their combined view state.
///
/// ### Example Usage:
/// ```dart
/// ViewStateBuilder<MyData>(
///   listenable: myViewStateNotifier, // Required
///
///   // Optional: control when the widget rebuilds.
///   rebuildWhen: (previous, current) => true,
///
///   // Optional: defaults to false.
///   isSliver: false,
///
///   // Optional: customize the initial state UI.
///   initialBuilder: (context) =>
///       MyInitialWidget(
///         context: context,
///       ),
///
///   // Optional: customize the loading state UI.
///   loadingBuilder: (context, details) =>
///       MyLoadingWidget(
///         context: context,
///         message: details.message,
///         progress: details.progress,
///       ),
///
///   // Optional: customize the empty state UI.
///   emptyBuilder: (context, details) =>
///       MyEmptyWidget(
///         context: context,
///         message: details.message,
///       ),
///
///   // Optional: customize the error state UI.
///   errorBuilder: (context, details) =>
///       MyErrorWidget(
///         context: context,
///         errorInfo: details.errorInfo,
///         error: details.error,
///         stackTrace: details.stackTrace,
///         onRetry: details.onRetry,
///       ),
///
///   // Optional: reused by dataBuilder.
///   child: const MyStaticWidget(),
///
///   // Required: builds the data state UI.
///   dataBuilder: (context, data, child) =>
///       MyDataWidget(
///         context: context,
///         data: data,
///         child: child,
///       ),
/// );
/// ```
/// If the view-state notifier is available in the widget tree (e.g., exposed through
/// `Provider`), you can use [ViewStateBuilder.of] to retrieve it:
///
/// ```dart
/// ViewStateBuilder.of<MyViewStateNotifier, DataType>(
///   dataBuilder: (context, state, child) {
///     return ...;
///   },
///   loadingBuilder: (context, details) {
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
///   dataBuilder: (context, state, child) {
///     return Column(
///       children: [
///         Text(state.user.data.toString()),
///         Text(state.profile.data.toString()),
///       ],
///     );
///   },
/// );
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
///
/// ### Message localization
///
/// The `message` values in [LoadingState] and [EmptyState], and the message
/// in an error's `ErrorInfo`, can be plain text or localization keys.
/// Configure `ViewStateWidgetsProvider.messageResolver` to resolve these
/// messages into localized text. ProviderKit passes the resolved messages
/// to the corresponding builder callbacks, or to its default widgets when
/// those builders are not provided. If no configured resolver handles a
/// message, the original message is used. Resolving messages does not modify
/// the stored view state or its original error information.
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
    this.child,
  });

  /// {@template provider_kit.view_state.initial_builder}
  /// Builds the UI when the view-state notifier is in [InitialState].
  ///
  /// The callback receives the current [BuildContext].
  /// {@endtemplate}
  final InitialStateBuilder? initialBuilder;

  /// {@template provider_kit.view_state.data_builder}
  /// Builds the UI when the view-state notifier is in [DataState].
  ///
  /// The callback receives the current [BuildContext], the data contained in
  /// the [DataState], and the optional [child] widget.
  /// {@endtemplate}
  final DataStateBuilder<T> dataBuilder;

  /// {@template provider_kit.view_state.error_builder}
  /// Builds the UI when the view-state notifier is in [ErrorState].
  ///
  /// The callback receives the current [BuildContext] and an
  /// `ErrorStateDetails` object containing the error information, original
  /// error, stack trace, and optional retry callback. The retry callback
  /// retries the view-state notifier.
  /// {@endtemplate}
  final ErrorStateBuilder? errorBuilder;

  /// {@template provider_kit.view_state.loading_builder}
  /// Builds the UI when the view-state notifier is in [LoadingState].
  ///
  /// The callback receives the current [BuildContext] and a
  /// `LoadingStateDetails` object containing the loading message and
  /// optional progress value.
  /// {@endtemplate}
  final LoadingStateBuilder? loadingBuilder;

  /// {@template provider_kit.view_state.empty_builder}
  /// Builds the UI when the view-state notifier is in [EmptyState].
  ///
  /// The callback receives the current [BuildContext] and an
  /// `EmptyStateDetails` object containing the empty-state message.
  /// {@endtemplate}
  final EmptyStateBuilder? emptyBuilder;

  /// {@template provider_kit.view_state.is_sliver}
  /// Whether the default state widgets from [ViewStateWidgetsProvider] should
  /// use sliver-compatible layouts. Applies when a custom builder is not
  /// provided for a state. Defaults to `false`.
  /// {@endtemplate}
  final bool isSliver;

  /// {@template provider_kit.view_state_builder.child}
  /// An optional widget that is passed to [dataBuilder] and is not rebuilt when
  /// the state changes.
  /// {@endtemplate}
  final Widget? child;

  /// {@macro provider_kit.view_state_builder}
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
    Widget? child,
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
  ///   notifiers through `.watch`.
  /// - **[initialBuilder]** — Builds the UI for the initial state. Receives the
  ///   context.
  /// - **[loadingBuilder]** — Builds the UI for the loading state. Receives the
  ///   context and `LoadingStateDetails` (message and progress).
  /// - **[emptyBuilder]** — Builds the UI for the empty state. Receives the
  ///   context and `EmptyStateDetails` (message).
  /// - **[errorBuilder]** — Builds the UI for the error state. Receives the
  ///   context and `ErrorStateDetails` (error information, original error, stack
  ///   trace, and optional retry callback). The retry callback retries all
  ///   errored notifiers that support retrying.
  /// - **[dataBuilder]** — Builds the UI when all watched notifiers are in
  ///   [DataState]. Receives the context, the combined value returned by
  ///   [listenables], and the optional [child].
  /// - **[rebuildWhen]** — Controls whether the widget rebuilds when the
  ///   combined state changes.
  /// - **[isSliver]** — Whether the default state widgets from
  ///   [ViewStateWidgetsProvider] should use sliver-compatible layouts.
  ///   Defaults to `false`.
  /// - **[child]** — An optional prebuilt widget passed to [dataBuilder] for
  ///   reuse.
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
  ///   dataBuilder: (context, state, child) {
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
  ///   dataBuilder: (context, state, child) {
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
  ///   dataBuilder: (context, state, child) {
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
    Widget? child,
  }) = _MultiViewStateBuilder<T>;

  /// {@macro provider_kit.view_state_widget.of}
  ///
  /// ```dart
  /// ViewStateBuilder.of<MyViewStateNotifier, DataType>(
  ///   dataBuilder: (context, data, child) {
  ///     return ...;
  ///   },
  ///   loadingBuilder: (context, details) {
  ///     return ...;
  ///   },
  /// );
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
    Widget? child,
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
      child: child,
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
      )
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}
