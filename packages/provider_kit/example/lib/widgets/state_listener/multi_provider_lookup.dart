import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve multiple listenables from Provider inside StateListener.multi.
class StateListenerMultiProviderExample extends StatelessWidget {
  const StateListenerMultiProviderExample({super.key});

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

        return StateListener.multi(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Change either value to trigger the listener.'),
              const SizedBox(height: 16),
              _countControls(counter),
              _stepControls(step),
            ],
          ),
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

  Row _countControls(CounterNotifier counter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: counter.decrement,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: counter.increment,
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
