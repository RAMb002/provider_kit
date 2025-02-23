import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/utils/type_definitions.dart';
import 'package:provider_kit/notifiers/state_notifier.dart';
import 'package:provider_kit/states/state_builders/state_builder.dart';
import 'package:provider_kit/states/state_listeners/state_listener.dart';
import 'package:provider_kit/utils/equality_check.dart';

class StateConsumer<P extends StateNotifier<T>, T> extends StatefulWidget {
  const StateConsumer({
    super.key,
    required this.builder,
    this.rebuildWhen,
    required this.listener,
    this.listenWhen,
    this.provider,
    this.shouldcallListenerOnInit = false,
    this.child,
  });
  final P? provider;
  final StateWidgetBuilder<T> builder;
  final RebuildWhen<T>? rebuildWhen;
  final ListenWhen<T>? listenWhen;
  final ListenerCallback<T> listener;
  final bool shouldcallListenerOnInit;
  final Widget? child;

  @override
  State<StateConsumer<P, T>> createState() => _StateConsumerState<P, T>();
}

class _StateConsumerState<P extends StateNotifier<T>, T>
    extends State<StateConsumer<P, T>> {
  late P _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? _readProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldcallListenerOnInit) {
        widget.listener(
          context,
          _provider.state,
        );
      }
    });
  }

  @override
  void didUpdateWidget(StateConsumer<P, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldProvider = oldWidget.provider ?? _readProvider;
    final currentProvider = widget.provider ?? _readProvider;
    if (oldProvider != currentProvider) {
      _provider = widget.provider ?? _readProvider;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = widget.provider ?? _readProvider;
    if (_provider != provider) _provider = provider;
  }

  P get _readProvider => context.read<P>();

  @override
  Widget build(BuildContext context) {
    return StateBuilder<P, T>(
      provider: _provider,
      builder: widget.builder,
      child: widget.child,
      rebuildWhen: (previous, next) {
        if ((ObjectKit.isNotEqual<T>(widget.listenWhen, previous, next))) {
          widget.listener(context, next);
        }
        return (ObjectKit.isNotEqual<T>(widget.rebuildWhen, previous, next));
      },
    );
  }
}
