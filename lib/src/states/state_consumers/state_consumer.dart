import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/notifiers/state_notifier.dart';
import 'package:provider_kit/src/states/state_builders/state_builder.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template providerkit-stateconsumer}
/// A widget that both listens to and rebuilds based on the state of a [StateNotifier].
///
/// The [StateConsumer] listens to a [StateNotifier] and **invokes the listener callback**
/// while also **rebuilding the builder function** when necessary.
/// It ensures that the `listener` and `builder` are called only once per state change.
///
/// ### Parameters:
/// - `builder`: **(Required)** A function that constructs the widget tree based on the current state.
/// - `listener`: **(Required)** A callback function that is invoked when the state changes.
/// - `provider`: **(Optional)** Specify the [provider] if the state provider is
///   not accessible via [Provider] and the current `BuildContext`.
/// - `rebuildWhen`: **(Optional)** A function that determines whether the `builder`
///   should be called based on changes between the previous and current state.
///   By default, the builder is triggered when `previous != current`.
/// - `listenWhen`: **(Optional)** A function that determines whether the `listener`
///   should be triggered based on the previous and current state. Defaults to
///   listening when `previous != current`.
/// - `shouldCallListenerOnInit`: **(Optional, default: `false`)** Determines whether
///   the `listener` should be called when the widget is first initialized.
/// - `child`: **(Optional)** A widget that does not depend on the state. It will
///   be preserved across rebuilds, preventing unnecessary re-renders.
///
/// ### Example Usage:
/// ```dart
/// StateConsumer<Provider, State>(
///   provider: provider, // Optional
///   shouldCallListenerOnInit: false, // Default is false
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
/// This ensures optimal performance by **invoking side effects when needed** and
/// **rebuilding only when necessary**, while preserving static UI elements passed as `child`.
/// {@endtemplate}

class StateConsumer<P extends StateNotifier<T>, T> extends StatefulWidget {
  /// {@macro providerkit-stateconsumer}
  const StateConsumer({
    super.key,
    required this.builder,
    this.rebuildWhen,
    required this.listener,
    this.listenWhen,
    this.provider,
    this.shouldCallListenerOnInit = false,
    this.child,
  });

  /// The provider that supplies the state. If null, the provider will be read from the context.
  final P? provider;

  /// The function that builds the widget tree based on the current state.
  final StateWidgetBuilder<T> builder;

  /// A function that determines whether the builder should be called based on
  /// the previous and current state.
  final RebuildWhen<T>? rebuildWhen;

  /// A function that determines whether the listener should be called based on
  /// the previous and current state.
  final ListenWhen<T>? listenWhen;

  /// The listener function that is called when the state changes.
  final ListenerCallback<T> listener;

  /// Whether the listener should be called when the widget is first initialized.
  final bool shouldCallListenerOnInit;

  /// An optional child widget that does not depend on the state and will not be rebuilt.
  final Widget? child;

  @override
  State<StateConsumer<P, T>> createState() => _StateConsumerState<P, T>();
}

class _StateConsumerState<P extends StateNotifier<T>, T>
    extends State<StateConsumer<P, T>> {
  late P _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldCallListenerOnInit) {
        widget.listener(
          context,
          _provider.state,
        );
      }
    });
  }

  @override
  void didUpdateWidget(StateConsumer<P, T> oldWidget) {
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

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  @override
  Widget build(BuildContext context) {
    return StateBuilder<P, T>(
      provider: _provider,
      builder: widget.builder,
      child: widget.child,
      rebuildWhen: (previous, next) {
        if ((ObjectKit.isNotEqual<T>(widget.listenWhen, previous, next))) {
          widget.listener(context, next);
        }
        return (ObjectKit.isNotEqual<T>(widget.rebuildWhen, previous, next));
      },
    );
  }
}
