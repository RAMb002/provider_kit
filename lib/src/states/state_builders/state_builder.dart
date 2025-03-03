import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/notifiers/state_notifier.dart';
import 'package:provider_kit/src/states/state_listeners/state_listener.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template providerkit-statebuilder}
/// A widget that rebuilds its UI based on the state of a [StateNotifier].
///
/// The [StateBuilder] listens to a [StateNotifier] and **rebuilds the builder function**.
/// It ensures that the `builder` is called only once per state change.
///
/// ### Parameters:
/// - **`builder`** (*Required*) **:** A function that constructs the widget tree based on the current state.
/// - **`provider`** (*Optional*) **:** A provider that supplies the state. If not specified,
///   the provider will be read from the context.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder
///   should be called based on changes between the previous and current state. By default,
///   the builder is triggered when `previous != current`.
/// - **`child`** (*Optional*) **:** A widget that does not depend on the state. It will
///   be preserved across rebuilds, preventing unnecessary re-renders.
///
/// ### Example Usage:
/// ```dart
/// StateBuilder<Provider, State>(
///   provider: provider, // Optional
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   builder: (context, state, child) {
///     // Build your widget tree based on the state
///     return Container();
///   },
///   child: SomeStaticWidget(), // Preserved across rebuilds
/// )
/// ```
/// This ensures optimal performance by rebuilding only when necessary and 
/// preserving static UI elements passed as `child`.
/// {@endtemplate}
class StateBuilder<P extends StateNotifier<T>, T>
    extends StateBuilderBase<P, T> {
  /// {@macro providerkit-statebuilder}
  const StateBuilder({
    super.key,
    super.provider,
    required this.builder,
    super.rebuildWhen,
    super.child,
  });

  /// The function that builds the widget tree based on the current state.
  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) =>
      builder(context, state, child);
}

/// An abstract base class for [StateBuilder] that provides common functionality.
abstract class StateBuilderBase<P extends StateNotifier<T>, T>
    extends StatefulWidget {
  const StateBuilderBase({
    super.key,
    this.provider,
    this.rebuildWhen,
    this.child,
  });

  /// The provider that supplies the state. If null, the provider will be read from the context.
  final P? provider;

  /// A function that determines whether the builder should be called based on
  /// the previous and current state.
  final RebuildWhen<T>? rebuildWhen;

  /// An optional child widget that does not depend on the state and will not be rebuilt.
  final Widget? child;

  /// The function that builds the widget tree based on the current state.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase> createState() => _StateBuilderBaseState<P, T>();
}

/// The state class for [StateBuilderBase].
class _StateBuilderBaseState<P extends StateNotifier<T>, T>
    extends State<StateBuilderBase<P, T>> {
  late T _state;
  late P _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    _state = _currentState;
  }

  @override
  void didUpdateWidget(StateBuilderBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? oldProvider;
    if (oldProvider != currentProvider) {
      _provider = widget.provider ?? _readProvider;
      _state = _currentState;
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

  /// Gets the current state from the provider.
  T get _currentState => _provider.state;

  @override
  Widget build(BuildContext context) => StateListener<P, T>(
        provider: _provider,
        listenWhen: widget.rebuildWhen,
        listener: (context, state) => setState(() => _state = state),
        child: widget.build(context, _state, widget.child),
      );
}
