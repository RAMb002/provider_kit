import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Build the UI and listen for side effects from one directly owned listenable.
class StateConsumerDirectExample extends StatefulWidget {
  const StateConsumerDirectExample({super.key});

  @override
  State<StateConsumerDirectExample> createState() =>
      _StateConsumerDirectExampleState();
}

class _StateConsumerDirectExampleState
    extends State<StateConsumerDirectExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateConsumer<int>(
      listenable: _counter,
      listener: (context, count) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Counter changed to $count')),
        );
      },
      builder: (context, count, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Count: $count',
              style: Theme.of(context).textTheme.headlineMedium),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
          const SizedBox(height: 20),
          _countControls(),
        ],
      ),
      child: const Chip(label: Text('Static child')),
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
