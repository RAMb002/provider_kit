import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates StateConsumer's listener, rebuild filters, and static child.
class StateConsumerFullConfigurationExample extends StatefulWidget {
  const StateConsumerFullConfigurationExample({super.key});

  @override
  State<StateConsumerFullConfigurationExample> createState() =>
      _StateConsumerFullConfigurationExampleState();
}

class _StateConsumerFullConfigurationExampleState
    extends State<StateConsumerFullConfigurationExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateConsumer<int>(
      listenable: _counter,
      listenWhen: (previous, current) => current > previous,
      callListenerOnInit: true,
      listener: (context, count) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Count increased to $count')),
        );
      },
      rebuildWhen: (previous, current) => previous ~/ 2 != current ~/ 2,
      builder: (context, count, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Count: $count',
              style: Theme.of(context).textTheme.headlineMedium),
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
          const SizedBox(height: 18),
          _countControls(),
        ],
      ),
      child: const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Static child passed to the builder.'),
        ),
      ),
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
