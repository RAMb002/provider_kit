import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve the notifier from Provider with StateBuilder.of.
class StateBuilderProviderExample extends StatelessWidget {
  const StateBuilderProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterNotifier(),
      builder: (context, _) {
        final counter = context.read<CounterNotifier>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBuilder.of<CounterNotifier, int>(
              builder: (context, count, child) => Text(
                'Count: $count',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 20),
            _countControls(counter),
          ],
        );
      },
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
