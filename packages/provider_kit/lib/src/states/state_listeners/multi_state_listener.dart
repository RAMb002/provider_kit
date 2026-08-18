import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template providerkit-multistatelistener}
/// A widget that listens to changes in the states of multiple [StateValueListenable]s and triggers callbacks.
///
/// The [MultiStateListener] widget is used to perform actions in response to state changes
/// in multiple [StateValueListenable]s. It ensures that the listener function is called only when
/// the states change.
///
/// ### Parameters:
/// - **`providers`** (*Required*) **:** A list of [StateValueListenable]s that supply the states.
/// - **`listener`** (*Required*) **:** A callback function that is invoked when the states change.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the listener should be called based on changes between the previous and current states. Defaults to calling the listener when `previous != current`.
/// - **`callListenerOnInit`** (*Optional*, default: `false`) **:** Indicates whether the listener should be called when the widget is first initialized.
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
///   callListenerOnInit: true, // Optional, default is false
///   child: SomeWidget(), // Optional
/// )
/// ```
/// {@endtemplate}
class MultiStateListener<T> extends MultiStateListenerBase<T> {
  /// {@macro providerkit-multistatelistener}
  const MultiStateListener({
    super.key,
    required super.providers,
    required super.listener,
    super.listenWhen,
    super.callListenerOnInit,
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
    bool? callListenerOnInit,
  }) : callListenerOnInit = callListenerOnInit ?? false;

  /// A list of [StateValueListenable]s that supply the states.
  final List<StateValueListenable<T>> providers;

  /// The listener function that is called when the states change.
  final MultiListenerCallback<List<T>> listener;

  /// A function that determines whether the listener should be called based on
  /// the previous and current states.
  final ListenWhen<List<T>>? listenWhen;

  /// Whether the listener should be called when the widget is first initialized.
  final bool callListenerOnInit;

  @override
  State<StatefulWidget> createState() => _StateListenerState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<List<StateValueListenable<T>>>(
          'providers', providers,
          defaultValue: null))
      ..add(ObjectFlagProperty<MultiListenerCallback<List<T>>>.has(
          'listener', listener))
      ..add(
        ObjectFlagProperty<ListenWhen<List<T>>?>.has(
          'listenWhen',
          listenWhen,
        ),
      )
      ..add(DiagnosticsProperty<bool>(
        'callListenerOnInit',
        callListenerOnInit,
        defaultValue: false,
      ));
  }
}

class _StateListenerState<T>
    extends SingleChildState<MultiStateListenerBase<T>> {
  late List<T> _previousStates;
  late List<StateValueListenable<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = List<StateValueListenable<T>>.from(widget.providers);
    _previousStates = _currentStates;
    _attachListeners(_providers);
    if (widget.callListenerOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.listener(
          context,
          _currentStates,
        );
      });
    }
  }

  @override
  void didUpdateWidget(MultiStateListenerBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_areProviderListsEqual(_providers, widget.providers)) {
      _update();
    }
  }

  void _update() {
    _detachListeners(_providers);
    _providers = List<StateValueListenable<T>>.from(widget.providers);
    _previousStates = _currentStates;
    _attachListeners(_providers);
  }

  @override
  void dispose() {
    _detachListeners(_providers);
    super.dispose();
  }

  void _listener() {
    if (!mounted) return;

    final currentStates = _currentStates;

    final shouldCallListener = ObjectKit.isNotEqual<List<T>>(
        widget.listenWhen, _previousStates, currentStates);

    _previousStates = currentStates;

    if (shouldCallListener) {
      widget.listener.call(context, currentStates);
    }
  }

  void _attachListeners(List<StateValueListenable<T>> providers) {
    for (var provider in providers) {
      provider.addListener(_listener);
    }
  }

  void _detachListeners(List<StateValueListenable<T>> providers) {
    for (var provider in providers) {
      provider.removeListener(_listener);
    }
  }

  bool _areProviderListsEqual(
      List<StateValueListenable<T>> a, List<StateValueListenable<T>> b) {
    return ObjectKit.areProviderListsEqual(a, b);
  }

  List<T> get _currentStates =>
      List<T>.unmodifiable(_providers.map((notifier) => notifier.state));

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of MultiStateListener must specify a child''',
    );
    return child!;
  }
}
