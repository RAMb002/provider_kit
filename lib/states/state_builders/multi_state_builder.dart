import 'package:flutter/widgets.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/state_listeners/multi_state_listener.dart';
import 'package:provider_kit/utils/type_definitions.dart';

typedef MultiStateWidgetBuilder<T> = Widget Function(
    BuildContext context, T states, Widget? child);

class MultiStateBuilder<T> extends MultiStateBuilderBase<T> {
  const MultiStateBuilder(
      {super.key,
      required super.providers,
      required this.builder,
      super.rebuildWhen,
      super.child});

  final MultiStateWidgetBuilder<List<T>> builder;

  @override
  Widget build(BuildContext context, List<T> states, Widget? child) =>
      builder(context, states, child);
}

abstract class MultiStateBuilderBase<T> extends StatefulWidget {
  const MultiStateBuilderBase(
      {super.key, required this.providers, this.rebuildWhen, this.child});

  final List<StateNotifier<T>> providers;
  final RebuildWhen<List<T>>? rebuildWhen;
  final Widget? child;

  Widget build(BuildContext context, List<T> states, Widget? child);

  @override
  State<MultiStateBuilderBase> createState() =>
      _MultiStateBuilderBaseState<T>();
}

class _MultiStateBuilderBaseState<T> extends State<MultiStateBuilderBase<T>> {
  late List<T> _states;
  late List<StateNotifier<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = widget.providers;
    _states = _currentStates;
  }

  @override
  void didUpdateWidget(MultiStateBuilderBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.providers != oldWidget.providers) {
      _providers = widget.providers;
      _states = _currentStates;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_providers != widget.providers) _providers = widget.providers;
  }

  List<T> get _currentStates =>
      _providers.map((notifier) => notifier.state).toList();

  @override
  Widget build(BuildContext context) => MultiStateListener<T>(
        providers: _providers,
        listenWhen: widget.rebuildWhen,
        listener: (context, states) => setState(() => _states = states),
        child: widget.build(context, _states, widget.child),
      );
}
