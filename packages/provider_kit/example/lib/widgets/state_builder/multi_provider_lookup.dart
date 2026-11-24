import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Resolve multiple notifiers from Provider inside StateBuilder.multi.
class StateBuilderMultiProviderExample extends StatelessWidget {
  const StateBuilderMultiProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CounterNotifier()),
        ChangeNotifierProvider(create: (_) => StepNotifier()),
      ],
      builder: (context, _) {
        final counter = context.read<CounterNotifier>();
        final step = context.read<StepNotifier>();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBuilder.multi(
              listenables: () => (
                count: of<CounterNotifier>().watch,
                step: of<StepNotifier>().watch,
              ),
              builder: (context, state, child) => Column(
                children: [
                  Text(
                    'Count: ${state.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('Step size: ${state.step}'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _countControls(counter, step),
            const SizedBox(height: 8),
            _stepControls(step),
          ],
        );
      },
    );
  }

  Row _stepControls(StepNotifier step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Step'),
        IconButton(
          onPressed: step.decrement,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          onPressed: step.increment,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Row _countControls(CounterNotifier counter, StepNotifier step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: () => counter.add(-step.state),
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(
          width: 5,
        ),
        IconButton.filled(
          onPressed: () => counter.add(step.state),
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
