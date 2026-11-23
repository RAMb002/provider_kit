import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Listen to changes from multiple directly owned listenables.
class StateListenerMultiExample extends StatefulWidget {
  const StateListenerMultiExample({super.key});

  @override
  State<StateListenerMultiExample> createState() =>
      _StateListenerMultiExampleState();
}

class _StateListenerMultiExampleState extends State<StateListenerMultiExample> {
  late final _counter = CounterNotifier();
  late final _step = StepNotifier();

  @override
  void dispose() {
    _counter.dispose();
    _step.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateListener.multi(
      listenables: () => (
        count: _counter.watch,
        step: _step.watch,
      ),
      listener: (context, state) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Count: ${state.count} · Step: ${state.step}'),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Change either value to trigger the listener.'),
          const SizedBox(height: 16),
          _countControls(),
          _stepControls(),
        ],
      ),
    );
  }

  Row _stepControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Step'),
        IconButton(
          onPressed: _step.decrement,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: _step.increment,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
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
