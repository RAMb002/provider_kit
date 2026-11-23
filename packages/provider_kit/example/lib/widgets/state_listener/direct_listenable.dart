import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Listen to a directly owned listenable without rebuilding this widget.
class StateListenerDirectExample extends StatefulWidget {
  const StateListenerDirectExample({super.key});

  @override
  State<StateListenerDirectExample> createState() =>
      _StateListenerDirectExampleState();
}

class _StateListenerDirectExampleState
    extends State<StateListenerDirectExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateListener<int>(
      listenable: _counter,
      listener: (context, count) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Counter changed to $count')),
        );
      },
      child: _countControls(),
    );
  }

  Row _countControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: _counter.decrement,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: _counter.increment,
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: _counter.reset,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }
}
