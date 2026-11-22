import 'package:example/widgets/shared/notifiers/counter_field_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Pass a stable listenable directly when this widget owns it.
class StateFieldSelectExample extends StatelessWidget {
  const StateFieldSelectExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => CounterFieldNotifier(),
        builder: (context, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StateBuilder.select(
                selector: (CounterFieldNotifier notifier) => notifier.count,
                builder: (context, count, child) => Text(
                  'Count: $count',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 20),
              _countControls(
                context.read<CounterFieldNotifier>(),
              ),
            ],
          );
        });
  }

  Row _countControls(CounterFieldNotifier notifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: notifier.decrement,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: notifier.increment,
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: notifier.reset,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }
}
