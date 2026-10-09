import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/internal/listener_queue.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiStateBase;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/builder/state_builder.dart';
import 'package:provider_kit/src/utils/equality_check.dart';

part 'multi_state_consumer.dart';
part 'state_consumer_base.dart';
part 'state_consumer_impl.dart';
part 'state_consumer_of.dart';

/// {@template provider_kit.state_consumer}
/// A widget that both listens to state changes and rebuilds its UI.
///
/// - Use [StateConsumer] to read state from a single provider.
/// - Use [StateConsumer.of] to read a provider from the widget tree.
/// - Use [StateConsumer.multi] to read and combine state from multiple
///   providers.
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
///   provider: provider,
///   callListenerOnInit: false, // Default is false
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   listener: (context, state) {
///     // Perform side effects based on the provider's state
///   },
///   rebuildWhen: (previous, current) {
///     // Return true/false to control when the widget should rebuild
///   },
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return MyWidget(state);
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [StateConsumer.of] to resolve it from the widget tree:
///
/// ```dart
/// StateConsumer.of<MyProvider, MyState>(
///   listener: (context, state) {
///     // Handle side effects.
///   },
///   builder: (context, state, child) {
///     return MyWidget(state);
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
///
/// For multiple providers, use [StateConsumer.multi].
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
    required StateValueListenable<T> provider,
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
  /// Use [StateConsumer.multi] when the builder and listener depend on
  /// multiple providers.
  ///
  /// The [providers] callback builds a single combined state by reading
  /// provider values through `.watch`. ProviderKit automatically tracks every
  /// watched provider and re-evaluates the combined state whenever any of
  /// those providers change.
  ///
  /// The combined state returned by [providers] is passed to [builder],
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
  /// StateConsumer.multi(
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
  /// StateConsumer.multi(
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
  const factory StateConsumer.multi({
    Key? key,
    required MultiStateProviders<T> providers,
    required StateWidgetBuilder<T> builder,
    required ListenerCallback<T> listener,
    RebuildWhen<T>? rebuildWhen,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _MultiStateConsumer<T>;

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
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
  static Widget of<P extends StateValueListenable<T>, T>({
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
