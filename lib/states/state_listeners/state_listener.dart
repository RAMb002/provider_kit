import 'package:flutter/widgets.dart';
// ignore: depend_on_referenced_packages
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/utils/equality_check.dart';
import 'package:provider_kit/utils/type_definitions.dart';

/// A widget that listens to changes in a [StateNotifier] and triggers a callback 
/// when the state changes.
///
/// The [StateListener] is typically used for performing side effects in response 
/// to state changes, such as navigation, showing a SnackBar, or displaying a Dialog. 
/// It ensures that the `listener` callback is called only once per state change.
///
/// ### Parameters:
/// - **`listener`** (*Required*) **:** A callback function that is invoked when the state changes.
/// - **`provider`** (*Optional*) **:** Specify the [provider] if the state provider is not accessible via [Provider] and the current `BuildContext`.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the `listener` should be triggered based on the previous and current state. By default, the listener is called when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Determines whether the `listener` should be called when the widget is first initialized.
/// - **`child`** (*Required*) **:** The child widget that remains in the widget tree and is not affected by state changes.
///
/// ### Example Usage:
/// ```dart
/// StateListener<Provider, State>(
///   provider: provider, // Optional
///   shouldCallListenerOnInit: false, // Default is false
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
/// This widget helps separate **state-dependent side effects** from the UI, ensuring that actions 
/// such as navigation and notifications are triggered appropriately without unnecessary UI rebuilds.


class StateListener<P extends StateNotifier<T>, T>
    extends StateListenerBase<P, T> {
  /// Creates a [StateListener].
  const StateListener({
    super.key,
    required super.listener,
    super.listenWhen,
    super.provider,
    super.shouldcallListenerOnInit,
    super.child,
  });
}

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateNotifier<T>, T>
    extends SingleChildStatefulWidget {
  const StateListenerBase({
    super.key,
    this.provider,
    required this.listener,
    this.listenWhen,
    super.child,
    bool? shouldcallListenerOnInit,
  }) : shouldcallListenerOnInit = shouldcallListenerOnInit ?? false;

  /// The provider that supplies the state. If null, the provider will be read from the context.
  final P? provider;

  /// The listener function that is called when the state changes.
  final ListenerCallback<T> listener;

  /// A function that determines whether the listener should be called based on
  /// the previous and current state.
  final ListenWhen<T>? listenWhen;

  /// Whether the listener should be called when the widget is first initialized.
  final bool shouldcallListenerOnInit;

  @override
  State<StatefulWidget> createState() => _StateListenerState<P, T>();
}

/// The state class for [StateListenerBase].
class _StateListenerState<P extends StateNotifier<T>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  late T _previousState;
  late P _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    _previousState = _currentState;
    _attachListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldcallListenerOnInit) {
        widget.listener(
          context,
          _currentState,
        );
      }
    });
  }

  @override
  void didUpdateWidget(StateListenerBase<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? oldProvider;
    if (oldProvider != currentProvider) {
      _detachListener(oldProvider);
      _provider = currentProvider;
      _previousState = _currentState;
      _attachListener();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) {
      _detachListener(_provider);
      _provider = provider;
      _previousState = _currentState;
      _attachListener();
    }
  }

  @override
  void dispose() {
    _detachListener(_provider);
    super.dispose();
  }

  /// Gets the provider from the context.
  P get _readProvider => context.read<P>();

  /// Gets the current state from the provider.
  T get _currentState => _provider.state;

  /// The listener function that is called when the state changes.
  void _listener() {
    if (ObjectKit.isNotEqual<T>(
        widget.listenWhen, _previousState, _currentState)) {
      _previousState = _currentState;
      widget.listener.call(context, _currentState);
    }
  }

  /// Attaches the listener to the provider.
  void _attachListener() {
    _provider.addListener(_listener);
  }

  /// Detaches the listener from the provider.
  void _detachListener(P provider) {
    provider.removeListener(_listener);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of StateListener must specify a child''',
    );
    return child!;
  }
}
