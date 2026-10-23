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

part 'multi_view_state_consumer.dart';
part 'view_state_consumer_base.dart';
part 'view_state_consumer_impl.dart';
part 'view_state_consumer_of.dart';

/// {@template provider_kit.view_state_consumer}
/// A widget that combines listening to and building based on the specific
/// [ViewState] of a [ViewStateNotifier].
///
/// The [ViewStateConsumer] can build UI and perform side effects in response
/// to different view states such as `InitialState`, `LoadingState`,
/// `DataState<T>`, `EmptyState`, and `ErrorState`.
///
/// If the user does not supply a builder for an optional state, the corresponding widget from the
/// `ViewStateWidgetsProvider` inherited widget will be used.
///
/// - Use [ViewStateConsumer] to build UI and listen to a single view-state notifier.
/// - Use [ViewStateConsumer.of] to retrieve a view-state notifier from the widget tree.
/// - Use [ViewStateConsumer.multi] to build UI and listen to multiple view-state
///   notifiers.
///
///
/// ### Example Usage:
/// ```dart
/// ViewStateConsumer(
///   listenable: myViewStateNotifier,
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     return ...;
///   },
///   dataStateListener: (data) {
///     // Handle DataState.
///   },
/// )
/// ```
///
/// If the view-state notifier is available in the widget tree (e.g., exposed through
/// `Provider`), you can use [ViewStateConsumer.of] to retrieve it:
///
/// ```dart
/// ViewStateConsumer.of<MyViewStateNotifier, DataType>(
///   dataBuilder: (data) {
///     return ...;
///   },
///   loadingBuilder: (message, progress, isSliver) {
///     return ...;
///   },
/// )
/// ```
///
/// ### Using Multiple View-State Notifiers
///
/// Use [ViewStateConsumer.multi] when the UI depends on multiple
/// view-state notifiers. Their values are read through `.watch` and
/// automatically tracked by ProviderKit.
///
/// ```dart
/// ViewStateConsumer.multi(
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
///   dataStateListener: (state) {
///     // Handle the combined data state.
///   },
/// )
/// ```
///
/// The data builder and data listener are invoked only when all watched
/// view-state notifiers are in [DataState]. The combined value returned by
/// [listenables] is passed unchanged to both callbacks, preserving its original
/// type. Each value is a [ViewState], and its `.data` getter provides the
/// underlying data.
///
/// See [ViewStateConsumer.multi] for details on building UI and handling
/// callbacks for multiple view-state notifiers.
/// {@endtemplate}
abstract class ViewStateConsumer<T> extends StatefulWidget {
  const ViewStateConsumer.base({
    super.key,
    required this.dataBuilder,
    this.initialBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.initialStateListener,
    this.loadingStateListener,
    this.emptyStateListener,
    this.errorStateListener,
    this.dataStateListener,
    this.callListenerOnInit = false,
    this.isSliver = false,
  });

  /// {@macro provider_kit.view_state.initial_builder}
  final InitialStateBuilder? initialBuilder;

  /// {@macro provider_kit.view_state.loading_builder}
  final LoadingStateBuilder? loadingBuilder;

  /// {@macro provider_kit.view_state.empty_builder}
  final EmptyStateBuilder? emptyBuilder;

  /// {@macro provider_kit.view_state.error_builder}
  final ErrorStateBuilder? errorBuilder;

  /// {@macro provider_kit.view_state.data_builder}
  final DataStateBuilder<T> dataBuilder;

  /// {@macro provider_kit.view_state.initial_listener}
  final InitialStateListener? initialStateListener;

  /// {@macro provider_kit.view_state.loading_listener}
  final LoadingStateListener? loadingStateListener;

  /// {@macro provider_kit.view_state.empty_listener}
  final EmptyStateListener? emptyStateListener;

  /// {@macro provider_kit.view_state.error_listener}
  final ErrorStateListener? errorStateListener;

  /// {@macro provider_kit.view_state.data_listener}
  final DataStateListener<T>? dataStateListener;

  /// {@macro provider_kit.state_listener.call_listener_on_init}
  final bool callListenerOnInit;

  /// {@macro provider_kit.view_state.is_sliver}
  final bool isSliver;

  /// {@macro provider_kit.view_state_consumer}
  ///
  /// Listens to the supplied [ViewStateNotifier] and builds the corresponding UI.
  const factory ViewStateConsumer({
    Key? key,
    required ViewStateNotifier<T> listenable,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    ErrorStateBuilder? errorBuilder,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit,
    bool isSliver,
  }) = _ViewStateConsumer<T>;

  /// {@template provider_kit.multi_view_state_consumer.description}
  /// A widget that builds its UI and listens to multiple view-state notifiers
  /// using their combined ViewState.
  /// {@endtemplate}
  ///
  /// {@macro provider_kit.multi_view_state.listenables_param}
  ///
  /// {@macro provider_kit.multi_view_state.aggregation}
  ///
  /// {@template provider_kit.multi_view_state_consumer.details}
  ///
  /// ### Parameters
  ///
  /// - **[listenables]** — Builds the combined state from one or more view-state
  ///   notifiers.
  /// - **[initialBuilder]** — Builds the UI when the combined state is initial.
  /// - **[loadingBuilder]** — Builds the UI when the combined state is loading.
  /// - **[emptyBuilder]** — Builds the UI when the combined state is empty.
  /// - **[errorBuilder]** — Builds the UI when the combined state contains an
  ///   error and receives a retry callback for all currently errored view-state
  ///   notifiers that have a retry operation available.
  /// - **[dataBuilder]** — Builds the UI when the combined state is data and
  ///   receives the exact value returned by [listenables].
  /// - **[initialStateListener]** — Handles the combined initial state.
  /// - **[loadingStateListener]** — Handles the combined loading state and
  ///   receives the first loading message and the average of the available
  ///   loading progress values.
  /// - **[emptyStateListener]** — Handles the combined empty state.
  /// - **[errorStateListener]** — Handles the first error state and receives a
  ///   retry callback for all currently errored view-state notifiers that have a
  ///   retry operation available.
  /// - **[dataStateListener]** — Handles the combined data state and receives
  ///   the exact value returned by [listenables].
  /// - **[rebuildWhen]** — Determines whether the widget should rebuild when the
  ///   combined state changes.
  /// - **[listenWhen]** — Determines whether the listener should be called when
  ///   the combined state changes.
  /// - **[callListenerOnInit]** — Determines whether the listener should be
  ///   called after initialization.
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
  /// ViewStateConsumer.multi(
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
  ///   dataStateListener: (state) {
  ///     // Handle the combined data state.
  ///   },
  /// );
  /// ```
  ///
  /// A list can be used when the combined state should be a list:
  ///
  /// ```dart
  /// ViewStateConsumer.multi(
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
  ///   dataStateListener: (state) {
  ///     // Handle the combined list.
  ///   },
  /// );
  /// ```
  ///
  /// A custom object can be used when you want a dedicated combined state type:
  ///
  /// ```dart
  /// ViewStateConsumer.multi(
  ///   listenables: () => CombinedState(
  ///     user: userNotifier.watch,
  ///     profile: profileNotifier.watch,
  ///   ),
  ///   dataBuilder: (state) {
  ///     return Text(state.user.data.toString());
  ///   },
  ///   dataStateListener: (state) {
  ///     // Handle the combined state.
  ///   },
  /// );
  /// ```
  /// {@endtemplate}
  const factory ViewStateConsumer.multi({
    Key? key,
    required MultiStateListenables<T> listenables,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    ErrorStateBuilder? errorBuilder,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    RebuildWhen<T>? rebuildWhen,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    bool isSliver,
  }) = _MultiViewStateConsumer<T>;

  /// {@macro provider_kit.view_state_widget.of}
  ///
  /// ```dart
  /// ViewStateConsumer.of<MyViewStateNotifier, User>(
  ///   dataBuilder: (user) => Text(user.name),
  ///   dataStateListener: (user) {
  ///     // Handle the data state.
  ///   },
  /// )
  /// ```
  static Widget of<P extends ViewStateNotifier<T>, T>({
    Key? key,
    required DataStateBuilder<T> dataBuilder,
    InitialStateBuilder? initialBuilder,
    LoadingStateBuilder? loadingBuilder,
    EmptyStateBuilder? emptyBuilder,
    ErrorStateBuilder? errorBuilder,
    InitialStateListener? initialStateListener,
    LoadingStateListener? loadingStateListener,
    EmptyStateListener? emptyStateListener,
    ErrorStateListener? errorStateListener,
    DataStateListener<T>? dataStateListener,
    RebuildWhen<ViewState<T>>? rebuildWhen,
    ListenWhen<ViewState<T>>? listenWhen,
    bool callListenerOnInit = false,
    bool isSliver = false,
  }) {
    return _ViewStateConsumerOf<P, T>(
      key: key,
      dataBuilder: dataBuilder,
      initialBuilder: initialBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      initialStateListener: initialStateListener,
      loadingStateListener: loadingStateListener,
      emptyStateListener: emptyStateListener,
      errorStateListener: errorStateListener,
      dataStateListener: dataStateListener,
      rebuildWhen: rebuildWhen,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      isSliver: isSliver,
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
      )
      ..add(
        DiagnosticsProperty<bool>('isSliver', isSliver, defaultValue: false),
      );
  }

  /// The public widget name used in diagnostics.
  String get debugWidgetName => 'ViewStateConsumer<$T>';
}
