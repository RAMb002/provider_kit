import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Pass a stable listenable directly when this widget owns it.
class StateBuilderDirectExample extends StatefulWidget {
  const StateBuilderDirectExample({super.key});

  @override
  State<StateBuilderDirectExample> createState() =>
      _StateBuilderDirectExampleState();
}

class _StateBuilderDirectExampleState extends State<StateBuilderDirectExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
    // This State created the notifier, so it is responsible for disposing it.
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StateBuilder<int>(
          listenable: _counter,
          builder: (context, count, child) => Column(
            children: [
              Text('Count: $count',
                  style: Theme.of(context).textTheme.headlineMedium),
              if (child != null) ...[
                const SizedBox(height: 12),
                child,
              ],
            ],
          ),
          child: const Chip(label: Text('This child is not rebuilt')),
        ),
        const SizedBox(height: 20),
        _countControls(),
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
