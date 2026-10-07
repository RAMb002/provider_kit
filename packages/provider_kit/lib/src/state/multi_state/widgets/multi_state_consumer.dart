part of '../multi_state.dart';

/// {@template provider_kit.multi_state_consumer}
/// A widget that both rebuilds its UI and listens to multiple providers
/// using a single combined state.
/// Use the [providers] callback to declare the providers  required by
/// this widget. Access their state through `.watch`.
///
/// The value returned by [providers] becomes the combined state passed to
/// both [builder] and [listener].
///
/// The builder and listener are controlled independently:
///
/// - **[rebuildWhen]** — Determines whether the widget should rebuild.
/// - **[listenWhen]** — Determines whether the listener should be called.
///
/// The combined state can be any Dart type, including a record, list, or
/// custom object.
///
/// - **[providers]** — Builds the combined state from one or more providers.
/// - **[builder]** — Builds the widget tree from the current combined state.
/// - **[listener]** — Handles changes to the current combined state.
/// - **[rebuildWhen]** — Determines whether the widget should rebuild when
///   the combined state changes.
/// - **[listenWhen]** — Determines whether the listener should be called when
///   the combined state changes.
/// - **[callListenerOnInit]** — Determines whether the listener should be
///   called after initialization.
/// - **[child]** — An optional widget that is passed to [builder] and can be
///   preserved across rebuilds.
///
/// ### Usage
///
/// A record can be used when you want named values:
///
/// ```dart
/// MultiStateConsumer(
///   providers: () => (
///     user: userProvider.watch,
///     loading: loadingField.watch,
///     save: saveMutation.watch,
///   ),
///   builder: (context, state, child) {
///     return Column(
///       children: [
///         Text(state.user.name),
///         if (state.loading)
///           const CircularProgressIndicator(),
///         if (state.save.isLoading)
///           const Text('Saving...'),
///         child!,
///       ],
///     );
///   },
///   listener: (context, state) {
///     if (state.save.hasError) {
///       // Handle save error
///     }
///   },
///   child: const MyFooter(),
/// );
/// ```
///
/// A list can be used when working with multiple providers of the same type:
///
/// ```dart
/// MultiStateConsumer(
///   providers: () => mutations
///       .map((mutation) => mutation.watch)
///       .toList(),
///   builder: (context, state, child) {
///     final isLoading = state.any((value) => value.isLoading);
///
///     return isLoading
///         ? const CircularProgressIndicator()
///         : const YourWidget();
///   },
///   listener: (context, state) {
///     if (state.any((value) => value.hasError)) {
///       // Handle error
///     }
///   },
/// );
/// ```
///
/// A custom object can be used when you want a named combined state type:
///
/// ```dart
/// MultiStateConsumer(
///   providers: () => CombinedState(
///     user: userProvider.watch,
///     loading: loadingField.watch,
///   ),
///   builder: (context, state, child) {
///     return Text(state.user.name);
///   },
///   listener: (context, state) {
///     if (state.loading) {
///       // Handle loading
///     }
///   },
/// );
/// ```
/// {@endtemplate}
class MultiStateConsumer<T> extends MultiStateConsumerBase<T> {
  /// {@macro provider_kit.multi_state_consumer}
  const MultiStateConsumer({
    super.key,
    required super.providers,
    required this.builder,
    required this.listener,
    super.rebuildWhen,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  });

  /// {@macro provider_kit.multi_state.builder_param}
  final StateWidgetBuilder<T> builder;

  /// {@macro provider_kit.multi_state.listener_param}
  final ListenerCallback<T> listener;

  @override
  Widget build(BuildContext context, T state, Widget? child) {
    return builder(context, state, child);
  }

  @override
  void onStateChange(BuildContext context, T state) {
    listener(context, state);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder))
      ..add(ObjectFlagProperty<ListenerCallback<T>>.has('listener', listener));
  }
}

/// Base class for multi-state consumers.
///
/// Provides the configuration shared by [MultiStateConsumer] and specialized
/// consumer variants such as `MultiViewStateConsumer`.
///
/// The actual dependency tracking, state collection, subscriptions,
/// equality checks, rebuild handling, and listener invocation are handled by
/// the internal [MultiStateBase] implementation.
abstract class MultiStateConsumerBase<T> extends StatefulWidget {
  const MultiStateConsumerBase({
    super.key,
    required this.providers,
    this.rebuildWhen,
    this.listenWhen,
    this.callListenerOnInit = false,
    this.child,
  });

  /// {@macro provider_kit.multi_state.providers_param}
  ///
  /// The returned value becomes the combined state passed to [builder],
  /// [listener], [rebuildWhen], and [listenWhen].
  final MultiStateProviders<T> providers;

  /// {@macro provider_kit.multi_state.rebuild_when_param}
  final RebuildWhen<T>? rebuildWhen;

  /// {@macro provider_kit.multi_state.listen_when_param}
  final ListenWhen<T>? listenWhen;

  /// {@macro provider_kit.multi_state.call_listener_on_init_param}
  final bool callListenerOnInit;

  /// {@macro provider_kit.multi_state_builder.child_param}
  final Widget? child;

  /// Builds the widget tree from the current combined state.
  Widget build(BuildContext context, T state, Widget? child);

  /// Handles a listener notification for the current combined state.
  void onStateChange(BuildContext context, T state);

  @override
  State<MultiStateConsumerBase<T>> createState() =>
      _MultiStateConsumerBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<MultiStateProviders<T>>.has('providers', providers),
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
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}

class _MultiStateConsumerBaseState<T> extends State<MultiStateConsumerBase<T>> {
  @override
  Widget build(BuildContext context) {
    return MultiStateBase<T>(
      providers: widget.providers,
      builder: widget.build,
      listener: widget.onStateChange,
      rebuildWhen: widget.rebuildWhen,
      listenWhen: widget.listenWhen,
      callListenerOnInit: widget.callListenerOnInit,
      widgetName: widget.runtimeType.toString(),
      child: widget.child,
    );
  }
}
