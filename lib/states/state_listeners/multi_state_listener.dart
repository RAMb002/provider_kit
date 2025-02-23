import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/utils/equality_check.dart';

typedef MultiListenerCallback<T> = void Function(
    BuildContext context, T states);

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

  final List<StateNotifier<T>> providers;
  final MultiListenerCallback<List<T>> listener;
  final ListenWhen<List<T>>? listenWhen;
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
