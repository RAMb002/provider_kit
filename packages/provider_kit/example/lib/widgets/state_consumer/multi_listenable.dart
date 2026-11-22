import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Build and listen to a combined record from directly owned listenables.
class StateConsumerMultiExample extends StatefulWidget {
  const StateConsumerMultiExample({super.key});

  @override
  State<StateConsumerMultiExample> createState() =>
      _StateConsumerMultiExampleState();
}

class _StateConsumerMultiExampleState extends State<StateConsumerMultiExample> {
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
    return StateConsumer.multi(
      listenables: () => (
        count: _counter.watch,
        step: _step.watch,
      ),
      listener: (context, state) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Count: ${state.count} · Step: ${state.step}')),
        );
      },
      builder: (context, state, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Count: ${state.count}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text('Step size: ${state.step}'),
          const SizedBox(height: 16),
          _countControls(),
          _stepControls(),
          if (child != null) child,
        ],
      ),
      child: const Chip(label: Text('Combined state is a typed record')),
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
          onPressed: () => _counter.add(-_step.state),
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: () => _counter.add(_step.state),
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
