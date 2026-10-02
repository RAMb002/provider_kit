import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/internal/listener_queue.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_builder.dart';
import 'package:provider_kit/src/utils/equality_check.dart';

/// {@template provider_kit.stateConsumer}
/// A widget that both listens to and rebuilds based on the state of a [StateValueListenable].
///
/// The [StateConsumer] listens to a [StateValueListenable] and **invokes the listener callback**
/// while also **rebuilding the builder function** when necessary.
/// It ensures that the `listener` and `builder` are called only once per state change.
///
/// ### Parameters:
/// - `provider`: **(Required)** The [StateValueListenable] whose state you want to listen to.
/// - `builder`: **(Required)** A function that constructs the widget tree based on the current state.
/// - `listener`: **(Required)** A callback function that is invoked when the state changes.
/// - `rebuildWhen`: **(Optional)** A function that determines whether the `builder`
///   should be called based on changes between the previous and current state.
///   By default, the builder is triggered when `previous != current`.
/// - `listenWhen`: **(Optional)** A function that determines whether the `listener`
///   should be triggered based on the previous and current state. Defaults to
///   listening when `previous != current`.
/// - `callListenerOnInit`: **(Optional, default: `false`)** Determines whether
///   the `listener` should be called when the widget is first initialized.
/// - `child`: **(Optional)** A widget that does not depend on the state. It will
///   be preserved across rebuilds, preventing unnecessary re-renders.
///
/// ### Example Usage:
/// ```dart
/// StateConsumer<MyState>(
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
///     return Container();
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
///     // Perform side effects based on the provider's state.
///   },
///   builder: (context, state, child) {
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
/// This ensures optimal performance by **invoking side effects when needed** and
/// **rebuilding only when necessary**, while preserving static UI elements passed as `child`.
/// {@endtemplate}
class StateConsumer<T> extends StateConsumerBase<StateValueListenable<T>, T> {
  /// {@macro provider_kit.stateConsumer}
  const StateConsumer({
    super.key,
    required StateValueListenable<T> provider,
    required this.builder,
    super.rebuildWhen,
    required this.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: provider);

  /// {@macro provider_kit.state_builder.builder}
  final StateWidgetBuilder<T> builder;

  /// {@macro provider_kit.state_listener.listener}
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
    RebuildWhen<T>? rebuildWhen,
    required ListenerCallback<T> listener,
    ListenWhen<T>? listenWhen,
    bool callListenerOnInit = false,
    Widget? child,
  }) {
    return _StateConsumerOf<P, T>(
      key: key,
      builder: builder,
      rebuildWhen: rebuildWhen,
      listener: listener,
      listenWhen: listenWhen,
      callListenerOnInit: callListenerOnInit,
      child: child,
    );
  }
}

class _StateConsumerOf<P extends StateValueListenable<T>, T>
    extends StateConsumerBase<P, T> {
  const _StateConsumerOf({
    super.key,
    required this.builder,
    super.rebuildWhen,
    required this.listener,
    super.listenWhen,
    super.callListenerOnInit,
    super.child,
  }) : super(provider: null);

  final StateWidgetBuilder<T> builder;
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

abstract class StateConsumerBase<P extends StateValueListenable<T>, T>
    extends StatefulWidget {
  const StateConsumerBase({
    super.key,
    this.rebuildWhen,
    this.listenWhen,
    this.provider,
    this.callListenerOnInit = false,
    this.child,
  });

  /// {@macro provider_kit.state_listener.provider}
  final P? provider;

  /// {@macro provider_kit.state_builder.rebuild_when}
  final RebuildWhen<T>? rebuildWhen;

  /// {@macro provider_kit.state_listener.listen_when}
  final ListenWhen<T>? listenWhen;

  /// {@macro provider_kit.state_listener.call_listener_on_init}
  final bool callListenerOnInit;

  /// {@macro provider_kit.state_builder.child}
  final Widget? child;

  /// Builds the widget tree using the current state.
  Widget build(BuildContext context, T state, Widget? child);

  /// Handles a state change after [listenWhen] allows the notification.
  void onStateChange(BuildContext context, T state);

  @override
  State<StateConsumerBase<P, T>> createState() =>
      _StateConsumerBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<P?>('provider', provider))
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

class _StateConsumerBaseState<P extends StateValueListenable<T>, T>
    extends State<StateConsumerBase<P, T>> {
  late P _provider;
  final ListenerQueue _listenerQueue = ListenerQueue();

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    if (widget.callListenerOnInit) {
      if (widget.callListenerOnInit) {
        final T initialState = _provider.state;
        final ListenerCallback<T> initialListener = widget.onStateChange;
        _listenerQueue.scheduleInitialListener(
          initialCallback: () => initialListener(context, initialState),
          isMounted: () => mounted,
        );
      }
    }
  }

  @override
  void didUpdateWidget(StateConsumerBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? _readProvider;
    if (oldProvider != currentProvider) {
      _provider = widget.provider ?? _readProvider;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) _provider = provider;
  }

  @override
  void dispose() {
    _listenerQueue.clear();
    super.dispose();
  }

  bool _handleStateChange(T previous, T current) {
    final shouldListen = ObjectKit.isNotEqual<T>(
      widget.listenWhen,
      previous,
      current,
    );

    if (shouldListen) {
      _listenerQueue.dispatch(() => widget.onStateChange(context, current));
    }

    return ObjectKit.isNotEqual<T>(widget.rebuildWhen, previous, current);
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  @override
  Widget build(BuildContext context) {
    if (widget.provider == null) {
      context.select<P, bool>((provider) => identical(_provider, provider));
    }
    return StateBuilder<T>(
      provider: _provider,
      builder: widget.build,
      rebuildWhen: _handleStateChange,
      child: widget.child,
    );
  }
}
