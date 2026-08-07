import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/states/state_listeners/multi_state_listener.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template providerkit-multistatebuilder}

/// A widget that builds its UI based on the states of multiple [StateValueListenable]s.
///
/// The [MultiStateBuilder] listens to a list of [StateValueListenable]s and rebuilds the builder function
/// based on the combined states. It ensures that the `builder` is called only once per state change.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [StateValueListenable]s that supply the states.
/// - **`builder`** (*Required*) **:** A function that constructs the widget tree based on the current states.
/// - **`rebuildWhen`** (*Optional*) **:** A function that determines whether the builder should be called based on changes between the previous and current states. Defaults to calling the builder when `previous != current`.
/// - **`child`** (*Optional*) **:** A widget that does not depend on the states. It will be preserved across rebuilds, preventing unnecessary re-renders.
///
/// ### Example Usage:
/// ```dart
/// MultiStateBuilder<State>(
///   providers: [provider1, provider2], // Required
///   rebuildWhen: (previous, current) {
///     // Return true/false to control rebuilding based on state changes
///   },
///   builder: (context, states, child) {
///     final state1 = states[0];
///     final state2 = states[1];
///     // Build your widget tree based on the states
///     return Container();
///   },
///   child: SomeStaticWidget(), // Optional
/// )
/// ```
/// {@endtemplate}

class MultiStateBuilder<T> extends MultiStateBuilderBase<T> {
  /// {@macro providerkit-multistatebuilder}
  const MultiStateBuilder({
    super.key,
    required super.providers,
    required this.builder,
    super.rebuildWhen,
    super.child,
  });

  /// The function that builds the widget tree based on the current states.
  final MultiStateWidgetBuilder<List<T>> builder;

  @override
  Widget build(BuildContext context, List<T> states, Widget? child) =>
      builder(context, states, child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<MultiStateWidgetBuilder<List<T>>>.has(
          'builder', builder),
    );
  }
}

/// An abstract base class for [MultiStateBuilder] that provides common functionality.
abstract class MultiStateBuilderBase<T> extends StatefulWidget {
  const MultiStateBuilderBase({
    super.key,
    required this.providers,
    this.rebuildWhen,
    this.child,
  });

  /// A list of [StateValueListenable]s that supply the states.
  final List<StateValueListenable<T>> providers;

  /// A function that determines whether the builder should be called based on
  /// the previous and current states.
  final RebuildWhen<List<T>>? rebuildWhen;

  /// An optional child widget that does not depend on the states and will not be rebuilt.
  final Widget? child;

  /// The function that builds the widget tree based on the current states.
  Widget build(BuildContext context, List<T> states, Widget? child);

  @override
  State<MultiStateBuilderBase> createState() =>
      _MultiStateBuilderBaseState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RebuildWhen<List<T>>?>.has(
          'rebuildWhen',
          rebuildWhen,
        ),
      )
      ..add(DiagnosticsProperty<List<StateValueListenable<T>>>(
          'providers', providers))
      ..add(DiagnosticsProperty<Widget?>('child', child, defaultValue: null));
  }
}

class _MultiStateBuilderBaseState<T> extends State<MultiStateBuilderBase<T>> {
  late List<T> _states;
  late List<StateValueListenable<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = List<StateValueListenable<T>>.from(widget.providers);
    _states = _currentStates;
  }

  @override
  void didUpdateWidget(MultiStateBuilderBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_areProviderListsEqual(_providers, widget.providers)) {
      _update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_areProviderListsEqual(_providers, widget.providers)) {
      _update();
    }
  }

  void _update() {
    _providers = List<StateValueListenable<T>>.from(widget.providers);
    _states = _currentStates;
  }

  bool _areProviderListsEqual(
      List<StateValueListenable<T>> a, List<StateValueListenable<T>> b) {
    return ObjectKit.areProviderListsEqual(a, b);
  }

  List<T> get _currentStates =>
      List<T>.unmodifiable(_providers.map((notifier) => notifier.state));

  @override
  Widget build(BuildContext context) => MultiStateListener<T>(
        providers: _providers,
        listenWhen: widget.rebuildWhen,
        listener: (context, states) => setState(() => _states = states),
        child: widget.build(context, _states, widget.child),
      );
}
