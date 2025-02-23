import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/state_listeners/state_listener.dart';
import 'package:provider_kit/utils/type_definitions.dart';

typedef StateWidgetBuilder<T> = Widget Function(
    BuildContext context, T state, Widget? child);

class StateBuilder<P extends StateNotifier<T>, T>
    extends StateBuilderBase<P, T> {
  const StateBuilder({
    super.key,
    super.provider,
    required this.builder,
    super.rebuildWhen,
    super.child,
  });

  final StateWidgetBuilder<T> builder;

  @override
  Widget build(BuildContext context, T state, Widget? child) =>
      builder(context, state, child);
}

abstract class StateBuilderBase<P extends StateNotifier<T>, T>
    extends StatefulWidget {
  const StateBuilderBase(
      {super.key, this.provider, this.rebuildWhen, this.child});

  final P? provider;
  final RebuildWhen<T>? rebuildWhen;
  final Widget? child;

  Widget build(BuildContext context, T state, Widget? child);

  @override
  State<StateBuilderBase> createState() => _StateBuilderBaseState<P, T>();
}

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

  P get _readProvider => context.read<P>();

  T get _currentState => _provider.state;

  @override
  Widget build(BuildContext context) => StateListener<P, T>(
        provider: _provider,
        listenWhen: widget.rebuildWhen,
        listener: (context, state) => setState(() => _state = state),
        child: widget.build(context, _state, widget.child),
      );
}
