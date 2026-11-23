import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve the notifier from Provider with StateConsumer.of.
class StateConsumerProviderExample extends StatelessWidget {
  const StateConsumerProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterNotifier(),
      builder: (context, _) {
        final counter = context.read<CounterNotifier>();

        return StateConsumer.of<CounterNotifier, int>(
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
              const SizedBox(height: 20),
              Row(
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
              ),
            ],
          ),
        );
      },
    );
  }
}
