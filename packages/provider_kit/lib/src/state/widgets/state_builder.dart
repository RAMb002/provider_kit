import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/state/internal/rebuild_scheduler.dart';
import 'package:provider_kit/src/state/type_defs/state_callbacks.dart';
import 'package:provider_kit/src/state/widgets/state_listener.dart';

/// {@template provider_kit.stateBuilder}
/// A widget that rebuilds its UI based on the state of a [StateValueListenable].
///
/// The [StateBuilder] listens to a [StateValueListenable] and **rebuilds the builder function**.
/// It ensures that the `builder` is called only once per state change.
///
/// ### Parameters:
/// - **`provider`** (*Required*) **:** The [StateValueListenable] whose state you want to listen to.
/// - **`builder`** (*Required*) **:** A function that constructs the widget tree based on the current state.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder
///   should be called based on changes between the previous and current state. By default,
///   the builder is triggered when `previous != current`.
/// - **`child`** (*Optional*) **:** A widget that does not depend on the state. It will
///   be preserved across rebuilds, preventing unnecessary re-renders.
///
/// ### Example Usage:
/// ```dart
/// StateBuilder<MyState>(
///   provider: provider,
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
///
/// If the provider is available through the current [BuildContext] (e.g., via [Provider]),
/// you can use [StateBuilder.of] to resolve it from the widget tree:
///
/// ```dart
/// StateBuilder.of<MyProvider, MyState>(
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
class StateBuilder<T> extends StateBuilderBase<StateValueListenable<T>, T> {
  /// {@macro provider_kit.stateBuilder}
  const StateBuilder({
    super.key,
    required StateValueListenable<T> provider,
    required this.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: provider);

  /// Resolves the provider from the current [BuildContext] (e.g., via [Provider]).
  ///
  /// Use this when the provider is available in the widget tree:
  ///
  /// ```dart
  /// StateBuilder.of<MyProvider, MyState>(
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
    Widget? child,
  }) {
    return _StateBuilderOf<P, T>(
      key: key,
      builder: builder,
      rebuildWhen: rebuildWhen,
      child: child,
    );
  }

  /// {@template provider_kit.state_builder.builder}
  /// Builds the widget tree whenever the state changes and
  /// [rebuildWhen] allows the rebuild.
  ///
  /// The [child] is an optional widget that is not rebuilt when the state
  /// changes.
  /// {@endtemplate}
  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) =>
      builder(context, state, child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder),
    );
  }
}

class _StateBuilderOf<P extends StateValueListenable<T>, T>
    extends StateBuilderBase<P, T> {
  const _StateBuilderOf({
    super.key,
    required this.builder,
    super.rebuildWhen,
    super.child,
  }) : super(provider: null);

  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) =>
      builder(context, state, child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<StateWidgetBuilder<T>>.has('builder', builder),
    );
  }
}

/// An abstract base class for [StateBuilder] that provides common functionality.
abstract class StateBuilderBase<P extends StateValueListenable<T>, T>
    extends StatefulWidget {
  const StateBuilderBase({
    super.key,
    this.provider,
    this.rebuildWhen,
    this.child,
  });

  /// {@macro provider_kit.state_listener.provider}
  final P? provider;

  /// {@template provider_kit.state_builder.rebuild_when}
  /// Determines whether the builder should be called when the state changes.
  ///
  /// The callback receives the previous and current states.
  ///
  /// When omitted, ProviderKit uses the state's `!=` comparison to determine
  /// whether the state has changed.
  /// {@endtemplate}
  final RebuildWhen<T>? rebuildWhen;

  /// {@template provider_kit.state_builder.child}
  /// An optional widget that is passed to [builder] and is not rebuilt when the
  /// state changes.
  /// {@endtemplate}
  final Widget? child;

  /// The function that builds the widget tree based on the current state.
  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase> createState() => _StateBuilderBaseState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<RebuildWhen<T>?>.has('rebuildWhen', rebuildWhen))
      ..add(DiagnosticsProperty<P?>('provider', provider))
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}

/// The state class for [StateBuilderBase].
class _StateBuilderBaseState<P extends StateValueListenable<T>, T>
    extends State<StateBuilderBase<P, T>> {
  late T _state;
  late P _provider;

  /// Whether a rebuild has already been scheduled for the current frame.
  ///
  /// This prevents multiple deferred rebuild callbacks from being registered
  /// when several dependency notifications occur during the same build phase.
  final RebuildScheduler _rebuildScheduler = RebuildScheduler();

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
    if (_provider != provider) {
      _provider = provider;
      _state = _currentState;
    }
  }

  /// Requests a rebuild of this widget.
  ///
  /// If a rebuild is requested while the widget tree is being built, the
  /// rebuild is deferred until after the current frame to avoid marking the
  /// widget dirty during the build phase. Multiple rebuild requests during the
  /// same build phase are coalesced into a single deferred rebuild.
  ///
  /// Otherwise, the rebuild is requested immediately.
  void _requestRebuild(T state) {
    _state = state;

    _rebuildScheduler.request(
      isMounted: () => mounted,
      rebuild: () => setState(() {}),
    );
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  /// Gets the current state from the provider.
  T get _currentState => _provider.state;

  @override
  Widget build(BuildContext context) {
    if (widget.provider == null) {
      context.select<P, bool>((provider) => identical(_provider, provider));
    }
    return StateListener<T>(
      provider: _provider,
      listenWhen: widget.rebuildWhen,
      listener: (context, state) => _requestRebuild(state),
      child: widget.build(context, _state, widget.child),
    );
  }
}
