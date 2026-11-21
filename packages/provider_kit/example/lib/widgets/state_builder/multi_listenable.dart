import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Combine two directly owned listenables into one typed record.
class StateBuilderMultiExample extends StatefulWidget {
  const StateBuilderMultiExample({super.key});

  @override
  State<StateBuilderMultiExample> createState() =>
      _StateBuilderMultiExampleState();
}

class _StateBuilderMultiExampleState extends State<StateBuilderMultiExample> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StateBuilder.multi(
          listenables: () => (
            count: _counter.watch,
            step: _step.watch,
          ),
          builder: (context, state, child) => Column(
            children: [
              Text(
                'Count: ${state.count}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text('Step size: ${state.step}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _countControls(),
        const SizedBox(height: 8),
        _stepControls(),
      ],
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
