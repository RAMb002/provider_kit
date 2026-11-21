import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Watch dependencies directly inside the WatchBuilder callback.
class WatchBuilderExample extends StatefulWidget {
  const WatchBuilderExample({super.key});

  @override
  State<WatchBuilderExample> createState() => _WatchBuilderExampleState();
}

class _WatchBuilderExampleState extends State<WatchBuilderExample> {
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
    return WatchBuilder(
      builder: (context, child) {
        final count = _counter.watch;
        final step = _step.watch;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Count: $count',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('Step size: $step'),
            const SizedBox(height: 16),
            Row(
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
            ),
            Row(
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
            ),
          ],
        );
      },
    );
  }
}
