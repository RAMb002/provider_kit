import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/utils/equality_check.dart';

typedef ListenerCallback<T> = void Function(BuildContext context, T state);

class StateListener<P extends StateNotifier<T>, T>
    extends StateListenerBase<P, T> {
  const StateListener({
    super.key,
    required super.listener,
    super.listenWhen,
    super.provider,
    super.shouldcallListenerOnInit,
    super.child,
  });
}

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

  final P? provider;
  final ListenerCallback<T> listener;
  final ListenWhen<T>? listenWhen;
  final bool shouldcallListenerOnInit;

  @override
  State<StatefulWidget> createState() => _StateListenerState<P, T>();
}

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

  P get _readProvider => context.read<P>();

  T get _currentState => _provider.state;

  void _listener() {
    if (ObjectKit.isNotEqual<T>(
        widget.listenWhen, _previousState, _currentState)) {
      _previousState = _currentState;
      widget.listener.call(context, _currentState);
    }
  }

  void _attachListener() {
    _provider.addListener(_listener);
  }

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
