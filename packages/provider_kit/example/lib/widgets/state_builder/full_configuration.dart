import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates StateBuilder's filtering and reusable child parameters.
class StateBuilderFullConfigurationExample extends StatefulWidget {
  const StateBuilderFullConfigurationExample({super.key});

  @override
  State<StateBuilderFullConfigurationExample> createState() =>
      _StateBuilderFullConfigurationExampleState();
}

class _StateBuilderFullConfigurationExampleState
    extends State<StateBuilderFullConfigurationExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
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
          rebuildWhen: (previous, current) => previous ~/ 2 != current ~/ 2,
          builder: (context, count, child) => Column(
            children: [
              Text('Count: $count',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              if (child != null) child,
            ],
          ),
          child: const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('Static child: this is passed to the builder.'),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
