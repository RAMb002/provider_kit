import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Pass a stable listenable directly when this widget owns it.
class StateFieldDirectExample extends StatefulWidget {
  const StateFieldDirectExample({super.key});

  @override
  State<StateFieldDirectExample> createState() =>
      _StateFieldDirectExampleState();
}

class _StateFieldDirectExampleState extends State<StateFieldDirectExample> {
  late final StateField count = StateField(0);

  @override
  void dispose() {
    count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StateBuilder(
          listenable: count,
          builder: (context, count, child) => Text(
            'Count: $count',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
          onPressed: () => count.state++,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: () => count.state--,
          icon: const Icon(Icons.add),
        ),
        IconButton(
          onPressed: () => count.state = 0,
          icon: const Icon(Icons.restart_alt),
        ),
      ],
    );
  }
}
