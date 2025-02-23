import 'package:flutter/widgets.dart';
// ignore: depend_on_referenced_packages
import 'package:nested/nested.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/utils/equality_check.dart';
import 'package:provider_kit/utils/type_definitions.dart';

/// A widget that listens to changes in the states of multiple [StateNotifier]s and triggers callbacks.
///
/// The [MultiStateListener] widget is used to perform actions in response to state changes
/// in multiple [StateNotifier]s. It ensures that the listener function is called only when
/// the states change.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [StateNotifier]s that supply the states.
/// - **`listener`** (*Required*) **:** A callback function that is invoked when the states change.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current states. Defaults to calling the listener when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
/// - **`child`** (*Optional*) **:** A widget that is part of the widget tree.
///
/// ### Example Usage:
/// ```dart
/// MultiStateListener<State>(
///   providers: [provider1, provider2], // Required
///   listener: (context, states) {
///     final state1 = states[0];
///     final state2 = states[1];
///     // Perform actions based on the states
///   },
///   listenWhen: (previous, current) {
///     // Return true/false to control listener invocation based on state changes
///   },
///   shouldCallListenerOnInit: true, // Optional, default is false
///   child: SomeWidget(), // Optional
/// )
/// ```
class MultiStateListener<T> extends MultiStateListenerBase<T> {
  const MultiStateListener({
    super.key,
    required super.providers,
    required super.listener,
    super.listenWhen,
    super.shouldcallListenerOnInit,
    super.child,
  });
}

abstract class MultiStateListenerBase<T> extends SingleChildStatefulWidget {
  const MultiStateListenerBase({
    super.key,
    required this.providers,
    required this.listener,
    this.listenWhen,
    super.child,
    bool? shouldcallListenerOnInit,
  }) : shouldcallListenerOnInit = shouldcallListenerOnInit ?? false;

  /// A list of [StateNotifier]s that supply the states.
  final List<StateNotifier<T>> providers;

  /// The listener function that is called when the states change.
  final MultiListenerCallback<List<T>> listener;

  /// A function that determines whether the listener should be called based on
  /// the previous and current states.
  final ListenWhen<List<T>>? listenWhen;

  /// Whether the listener should be called when the widget is first initialized.
  final bool shouldcallListenerOnInit;

  @override
  State<StatefulWidget> createState() => _StateListenerState<T>();
}

class _StateListenerState<T>
    extends SingleChildState<MultiStateListenerBase<T>> {
  late List<T> _previousStates;
  late List<StateNotifier<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = widget.providers;
    _previousStates = _currentStates;
    _attachListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldcallListenerOnInit) {
        widget.listener(
          context,
          _currentStates,
        );
      }
    });
  }

  @override
  void didUpdateWidget(MultiStateListenerBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.providers != oldWidget.providers) _update();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_providers != widget.providers) _update();
  }

  void _update() {
    _detachListeners(_providers);
    _providers = widget.providers;
    _previousStates = _currentStates;
    _attachListeners();
  }

  @override
  void dispose() {
    _detachListeners();
    super.dispose();
  }

  void _listener() {
    if (!mounted) return;

    if (ObjectKit.isNotEqual<List<T>>(
        widget.listenWhen, _previousStates, _currentStates)) {
      _previousStates = _currentStates;
      widget.listener.call(context, _currentStates);
    }
  }

  void _attachListeners([List<StateNotifier<T>>? providers]) {
    for (var provider in providers ?? widget.providers) {
      provider.addListener(_listener);
    }
  }

  void _detachListeners([List<StateNotifier<T>>? providers]) {
    for (var provider in providers ?? widget.providers) {
      provider.removeListener(_listener);
    }
  }

  List<T> get _currentStates =>
      _providers.map((notifier) => notifier.state).toList();

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of ProviderCombinedStateListener must specify a child''',
    );
    return child!;
  }
}
