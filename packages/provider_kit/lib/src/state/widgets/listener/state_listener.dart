import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/internal/listener_queue.dart';
import 'package:provider_kit/src/state/multi_state/multi_state.dart'
    show MultiStateBase;
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/utils/equality_check.dart';

part 'multi_state_listener.dart';
part 'state_listener_base.dart';
part 'state_listener_impl.dart';
part 'state_listener_of.dart';

/// {@template provider_kit.stateListener}
/// A widget that listens to state changes and invokes a callback. It is typically
/// used for performing side effects in response to state changes, such as navigation,
/// showing a SnackBar, or displaying a Dialog.
///
/// - Use [StateListener] to listen to state from a single provider.
/// - Use [StateListener.of] to read a provider from the widget tree.
/// - Use [StateListener.multi] to listen to and combine state from multiple providers.
///
/// The [listener] callback is called when the state changes and [listenWhen]
/// allows the change. The optional [callListenerOnInit] can be used to invoke
/// the listener once after initialization.
///
/// ### Example Usage:
/// ```dart
/// StateListener<MyState>(
///   provider: provider,
///   callListenerOnInit: false, // Default is false
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   listener: (context, state) {
///     // Perform side effects based on the provider's state
///   },
///   child: SomeWidget(), // Unaffected by state changes
/// )
/// ```
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [StateListener.of] to resolve it from the widget tree:
///
/// ```dart
/// StateListener.of<MyProvider, MyState>(
///   listener: (context, state) {
///     // Perform side effects based on the provider's state.
///   },
///   child: SomeWidget(),
/// )
/// ```
///{@endtemplate}
///
/// {@macro provider_kit.state_listener.multi}
abstract class StateListener<T> extends SingleChildStatefulWidget {
  const StateListener.base({
    super.key,
    this.listenWhen,
    this.callListenerOnInit = false,
    super.child,
  });

  /// {@template provider_kit.state_listener.listen_when}
  /// Determines whether the listener should be called when the state changes.
  /// The callback receives the previous and current states.
  ///
  /// For [StateListener.multi], the states are the combined values returned
  /// by the `providers` callback.
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final ListenWhen<T>? listenWhen;

  /// {@template provider_kit.state_listener.call_listener_on_init}
  /// Whether the listener should be called once after initialization.
  ///
  /// The callback is invoked after the first frame.
  ///
  /// Defaults to `false`.
  /// {@endtemplate}
  final bool callListenerOnInit;

  /// {@macro provider_kit.stateListener}
  /// {@macro provider_kit.state_listener.multi}
  const factory StateListener({
    Key? key,
    required StateValueListenable<T> provider,
    required ListenerCallback<T> listener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _StateListener<T>;

  /// {@template provider_kit.state_listener.multi}
  /// ### Listening to Multiple Providers
  ///
  /// Use [StateListener.multi] when a listener depends on the state of multiple
  /// providers. The [providers] callback builds a single combined state by
  /// reading provider values through `.watch`. ProviderKit automatically tracks
  /// every watched provider and re-evaluates the combined state whenever any of
  /// those providers change.
  ///
  /// The combined state returned by [providers] is passed to [listener] and
  /// [listenWhen]. It can be any Dart type, including a record, list, or custom
  /// object.
  ///
  /// A record can be used when you want named values:
  ///
  /// ```dart
  /// StateListener.multi(
  ///   providers: () => (
  ///     user: userProvider.watch,
  ///     loading: loadingField.watch,
  ///     save: saveMutation.watch,
  ///   ),
  ///   listener: (context, state) {
  ///     // state.user
  ///     // state.loading
  ///     // state.save
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  ///
  /// A list can be used when working with multiple providers of the same type:
  ///
  /// ```dart
  /// StateListener.multi(
  ///   providers: () => mutations
  ///       .map((mutation) => mutation.watch)
  ///       .toList(),
  ///   listener: (context, state) {
  ///     if (state.any((value) => value.isLoading)) {
  ///       // Handle loading
  ///     }
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  ///
  /// A custom object can be used when you want a named combined state type:
  ///
  /// ```dart
  /// StateListener.multi(
  ///   providers: () => CombinedState(
  ///     user: userProvider.watch,
  ///     loading: loadingField.watch,
  ///   ),
  ///   listener: (context, state) {
  ///     // Handle the combined state
  ///   },
  ///   child: const MyPage(),
  /// );
  /// ```
  /// {@endtemplate}
  const factory StateListener.multi({
    Key? key,
    required MultiStateProviders<T> providers,
    required ListenerCallback<T> listener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit,
    Widget? child,
  }) = _MultiStateListener<T>;

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// StateListener.of<MyProvider, MyState>(
  ///   listener: (context, state) {
  ///     // React to state changes.
  ///   },
  ///   child: SomeWidget(),
  /// )
  /// ```
  static Widget of<P extends StateValueListenable<T>, T>({
    Key? key,
    required ListenerCallback<T> listener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return _StateListenerOf<P, T>(
      key: key,
      listener: listener,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      child: child,
    );
  }

  void debugFillListenWhen(DiagnosticPropertiesBuilder properties) {
    properties.add(
      ObjectFlagProperty<ListenWhen<T>?>.has('listenWhen', listenWhen),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    debugFillListenWhen(properties);
    properties.add(
      DiagnosticsProperty<bool>(
        'callListenerOnInit',
        callListenerOnInit,
        defaultValue: false,
      ),
    );
  }

  /// The public widget name used in diagnostics and assertions.
  String get debugWidgetName => 'StateListener<$T>';
}
