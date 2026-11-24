import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve the listenable from Provider with StateListener.of.
class StateListenerProviderExample extends StatelessWidget {
  const StateListenerProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CounterNotifier(),
      builder: (context, _) {
        final counter = context.read<CounterNotifier>();

        return StateListener.of<CounterNotifier, int>(
          listener: (context, count) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Counter changed to $count')),
            );
          },
          child: _countControls(counter),
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
