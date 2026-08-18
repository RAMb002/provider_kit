import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/src/base/state_value_listenable.dart';
import 'package:provider_kit/src/utils/equality_check.dart';
import 'package:provider_kit/src/utils/type_definitions.dart';

/// {@template provider_kit.stateListener}
/// A widget that listens to a [StateValueListenable] and invokes a callback
/// whenever its state changes.
///
/// The [StateListener] is typically used for performing side effects in response
/// to state changes, such as navigation, showing a SnackBar, or displaying a Dialog.
/// It ensures that the `listener` callback is called only once per state change.
///
/// ### Parameters:
/// - **`provider`** (*Required*) **:** The [StateValueListenable] whose state you want to listen to.
/// - **`listener`** (*Required*) **:** A callback function that is invoked when the state changes.
/// - **`listenWhen`** (*Optional*) **:** A function that determines whether the `listener` should be triggered based on the previous and current state. By default, the listener is called when `previous != current`.
/// - **`shouldCallListenerOnInit`** (*Optional*, default: `false`) **:** Determines whether the `listener` should be called when the widget is first initialized.
/// - **`child`** (*Required*) **:** The child widget that remains in the widget tree and is not affected by state changes.
///
/// ### Example Usage:
/// ```dart
/// StateListener<MyState>(
///   provider: provider,
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
///
/// This widget helps separate **state-dependent side effects** from the UI
/// ensuring that actions such as navigation and notifications are triggered
/// appropriately without unnecessary UI rebuilds.
/// {@endtemplate}
class StateListener<T> extends StateListenerBase<StateValueListenable<T>, T> {
  /// {@macro provider_kit.stateListener}
  const StateListener({
    super.key,
    required super.listener,
    required StateValueListenable<T> provider,
    super.listenWhen,
    super.shouldCallListenerOnInit,
    super.child,
  }) : super(provider: provider);

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
    bool shouldCallListenerOnInit = false,
    Widget? child,
  }) {
    return _StateListenerOf<P, T>(
      key: key,
      listener: listener,
      listenWhen: listenWhen,
      shouldCallListenerOnInit: shouldCallListenerOnInit,
      child: child,
    );
  }
}

class _StateListenerOf<P extends StateValueListenable<T>, T>
    extends StateListenerBase<P, T> {
  const _StateListenerOf({
    super.key,
    required super.listener,
    super.listenWhen,
    super.shouldCallListenerOnInit,
    super.child,
  }) : super(provider: null);
}

/// An abstract base class for [StateListener] that provides common functionality.
abstract class StateListenerBase<P extends StateValueListenable<T>, T>
    extends SingleChildStatefulWidget {
  const StateListenerBase({
    super.key,
    this.provider,
    required this.listener,
    this.listenWhen,
    super.child,
    bool? shouldCallListenerOnInit,
  }) : shouldCallListenerOnInit = shouldCallListenerOnInit ?? false;

  /// The provider whose state should be listened to.
  ///
  /// When null, the provider is resolved from the current [BuildContext].
  final P? provider;

  /// The listener function that is called when the state changes.
  final ListenerCallback<T> listener;

  /// A function that determines whether the listener should be called based on
  /// the previous and current state.
  final ListenWhen<T>? listenWhen;

  /// Whether the listener should be called when the widget is first initialized.
  final bool shouldCallListenerOnInit;

  @override
  State<StatefulWidget> createState() => _StateListenerState<P, T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<P?>('provider', provider, defaultValue: null))
      ..add(ObjectFlagProperty<ListenerCallback<T>>.has('listener', listener))
      ..add(
        ObjectFlagProperty<ListenWhen<T>?>.has(
          'listenWhen',
          listenWhen,
        ),
      )
      ..add(DiagnosticsProperty<bool>(
        'shouldCallListenerOnInit',
        shouldCallListenerOnInit,
        defaultValue: false,
      ));
  }
}

/// The state class for [StateListenerBase].
class _StateListenerState<P extends StateValueListenable<T>, T>
    extends SingleChildState<StateListenerBase<P, T>> {
  late T _previousState;
  late P _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    _previousState = _currentState;
    _attachListener();
    if (widget.shouldCallListenerOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.listener(
          context,
          _currentState,
        );
      });
    }
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
    final shouldCallListener = ObjectKit.isNotEqual<T>(
      widget.listenWhen,
      _previousState,
      _currentState,
    );

    _previousState = _currentState;

    if (shouldCallListener) {
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

    if (widget.provider == null) {
      context.select<P, bool>(
        (provider) => identical(_provider, provider),
      );
    }

    return child!;
  }
}
