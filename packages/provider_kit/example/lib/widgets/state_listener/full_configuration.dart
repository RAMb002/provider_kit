import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates StateListener's filtering and initialization options.
class StateListenerFullConfigurationExample extends StatefulWidget {
  const StateListenerFullConfigurationExample({super.key});

  @override
  State<StateListenerFullConfigurationExample> createState() =>
      _StateListenerFullConfigurationExampleState();
}

class _StateListenerFullConfigurationExampleState
    extends State<StateListenerFullConfigurationExample> {
  late final _counter = CounterNotifier();

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StateListener<int>(
      listenable: _counter,
      listenWhen: (previous, current) => current > previous,
      callListenerOnInit: true,
      listener: (context, count) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Count increased to $count')),
        );
      },
      child: _countControls(),
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
