import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve and combine multiple Provider-managed listenables.
class StateConsumerMultiProviderExample extends StatelessWidget {
  const StateConsumerMultiProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterNotifier()),
        ChangeNotifierProvider(create: (_) => StepNotifier()),
      ],
      builder: (context, _) {
        final counter = context.read<CounterNotifier>();
        final step = context.read<StepNotifier>();

        return StateConsumer.multi(
          listenables: () => (
            count: of<CounterNotifier>().watch,
            step: of<StepNotifier>().watch,
          ),
          listener: (context, state) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Count: ${state.count} · Step: ${state.step}'),
              ),
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
              _countControls(counter, step),
              _stepControls(step),
              if (child != null) child,
            ],
          ),
          child: const Chip(label: Text('Provider-managed combined state')),
        );
      },
    );
  }

  Row _stepControls(StepNotifier step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Step'),
        IconButton(
          onPressed: step.decrement,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: step.increment,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Row _countControls(CounterNotifier counter, StepNotifier step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: () => counter.add(-step.state),
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: () => counter.add(step.state),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: counter.reset,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }
}
