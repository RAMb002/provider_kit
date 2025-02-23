import 'package:flutter/widgets.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/state_builders/multi_state_builder.dart';
import 'package:provider_kit/states/state_listeners/multi_state_listener.dart';
import 'package:provider_kit/utils/equality_check.dart';

class MultiStateConsumer<T> extends StatefulWidget {
  const MultiStateConsumer({
    super.key,
    required this.builder,
    this.rebuildWhen,
    required this.listener,
    this.listenWhen,
    required this.providers,
    this.shouldcallListenerOnInit = false,
    this.child,
  });

  final List<StateNotifier<T>> providers;
  final MultiStateWidgetBuilder<List<T>> builder;
  final RebuildWhen<List<T>>? rebuildWhen;
  final ListenWhen<List<T>>? listenWhen;
  final MultiListenerCallback<List<T>> listener;
  final Widget? child;
  final bool shouldcallListenerOnInit;

  @override
  State<MultiStateConsumer<T>> createState() => _MultiStateConsumerState<T>();
}

class _MultiStateConsumerState<T> extends State<MultiStateConsumer<T>> {
  late List<StateNotifier<T>> _providers;

  @override
  void initState() {
    super.initState();
    _providers = widget.providers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldcallListenerOnInit) {
        widget.listener(
          context,
          _providers.map((e) => e.state).toList(),
        );
      }
    });
  }

  @override
  void didUpdateWidget(MultiStateConsumer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providers != widget.providers) {
      _providers = widget.providers;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_providers != widget.providers) _providers = widget.providers;
  }

  @override
  Widget build(BuildContext context) {
    return MultiStateBuilder<T>(
      providers: _providers,
      builder: widget.builder,
      child: widget.child,
      rebuildWhen: (previous, next) {
        if ((ObjectKit.isNotEqual<List<T>>(
            widget.listenWhen, previous, next))) {
          widget.listener(context, next);
        }
        return (ObjectKit.isNotEqual<List<T>>(
            widget.rebuildWhen, previous, next));
      },
    );
  }
}
