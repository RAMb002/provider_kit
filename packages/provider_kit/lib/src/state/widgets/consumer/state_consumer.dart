import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/base/state_listenable.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiStateEngine;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_engine.dart';

part 'multi_state_consumer.dart';
part 'state_consumer_base.dart';
part 'state_consumer_impl.dart';
part 'state_consumer_of.dart';

/// {@template provider_kit.state_consumer}
/// A widget that both listens to state changes and rebuilds its UI.
///
/// - Use [StateConsumer] to listen to and build from a single listenable.
/// - Use [StateConsumer.of] to retrieve a listenable from the widget tree.
/// - Use [StateConsumer.multi] to combine state from multiple listenables.
///
/// The [listener] callback is called when the state changes and [listenWhen]
/// allows the change. The builder is called when the state changes and
/// [rebuildWhen] allows the rebuild.
///
/// The optional [callListenerOnInit] can be used to invoke the listener once
/// after initialization. The [child] is preserved across rebuilds.
///
/// ### Example
///
/// ```dart
/// StateConsumer(
///   listenable: myStateListenable,
///   callListenerOnInit: false, // Default is false
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   listener: (context, state) {
///     // Perform side effects in response to state changes.
///   },
///   rebuildWhen: (previous, current) {
///     // Return true/false to control when the widget should rebuild
///   },
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return MyWidget(state);
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// );
/// ```
///
/// If the listenable is available in the widget tree (e.g., exposed through
/// `Provider`), you can use [StateConsumer.of] to retrieve it:
///
/// ```dart
/// StateConsumer.of<MyStateListenable, MyState>(
///   listener: (context, state) {
///     // Handle side effects.
///   },
///   builder: (context, state, child) {
///     return MyWidget(state);
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// );
/// ```
///
/// For multiple listenables, use [StateConsumer.multi].
/// {@endtemplate}
///
/// {@macro provider_kit.state_consumer.multi}

abstract class StateConsumer<T> extends StatefulWidget {
  const StateConsumer.base({
    super.key,
    this.rebuildWhen,
    this.listenWhen,
    this.callListenerOnInit = false,
    this.child,
  });

  /// {@macro provider_kit.state_builder.rebuild_when}
  final RebuildWhen<T>? rebuildWhen;

  /// {@macro provider_kit.state_listener.listen_when}
  final ListenWhen<T>? listenWhen;

  /// {@macro provider_kit.state_listener.call_listener_on_init}
  final bool callListenerOnInit;

  /// {@macro provider_kit.state_builder.child}
  final Widget? child;

  /// {@macro provider_kit.state_consumer}
  const factory StateConsumer({
    Key? key,
    required StateListenable<T> listenable,
    required StateWidgetBuilder<T> builder,
    required ListenerCallback<T> listener,
    RebuildWhen<T>? rebuildWhen,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _StateConsumer<T>;

  /// {@template provider_kit.state_consumer.multi}
  /// ### Listening to Multiple Providers
  ///
  /// Use [listenables.multi] when the builder and listener depend on
  /// multiple listenables.
  ///
  /// The [listenables] callback builds a single combined state by reading
  /// listenables state through `.watch`. ProviderKit automatically tracks every
  /// watched listenable and re-evaluates the combined state whenever any of
  /// those listenables change.
  ///
  /// The combined state returned by [listenables] is passed to [builder],
  /// [listener], [rebuildWhen], and [listenWhen].
  ///
  /// The combined state can be any Dart type, including a record, list, or
  /// custom object.
  ///
  /// ### Usage
  ///
  /// A record can be used when you want named values:
  ///
  /// ```dart
  /// StateConsumer.multi(
  ///   listenables: () => (
  ///     user: userNotifier.watch,
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
  /// A list can be used when working with multiple listenables of the same type:
  ///
  /// ```dart
  /// StateConsumer.multi(
  ///   listenables: () => mutations
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
  /// StateConsumer.multi(
  ///   listenables: () => CombinedState(
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
  const factory StateConsumer.multi({
    Key? key,
    required MultiStateListenables<T> listenables,
    required StateWidgetBuilder<T> builder,
    required ListenerCallback<T> listener,
    RebuildWhen<T>? rebuildWhen,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _MultiStateConsumer<T>;

  /// {@macro provider_kit.state_widget.of}
  ///
  /// ```dart
  /// StateConsumer.of<MyProvider, MyState>(
  ///   listener: (context, state) {
  ///     // React to state changes.
  ///   },
  ///   builder: (context, state, child) {
  ///     return ...;
  ///   },
  ///   child: SomeWidget(),
  /// )
  /// ```
  static Widget of<P extends StateListenable<T>, T>({
    Key? key,
    required StateWidgetBuilder<T> builder,
    required ListenerCallback<T> listener,
    RebuildWhen<T>? rebuildWhen,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return _StateConsumerOf<P, T>(
      key: key,
      builder: builder,
      listener: listener,
      rebuildWhen: rebuildWhen,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
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

  /// The public widget name used in diagnostics and assertions.
  String get debugWidgetName => 'StateConsumer<$T>';
}
