import 'package:example/widgets/shared/notifiers/counter_field_notifier.dart';
import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates watching multiple dependencies directly inside
/// a WatchBuilder callback.
class WatchBuilderExample extends StatefulWidget {
  const WatchBuilderExample({super.key});

  @override
  State<WatchBuilderExample> createState() => _WatchBuilderExampleState();
}

class _WatchBuilderExampleState extends State<WatchBuilderExample> {
  late final _counter = CounterNotifier();
  late final _movies = MoviesNotifier();

  @override
  void dispose() {
    _movies.dispose();
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CounterFieldNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => StepNotifier(),
        ),
      ],
      child: WatchBuilder(
        builder: (context, child) {
          // Direct Listenable dependencies.
          final count = _counter.watch;
          final movies = _movies.watch;

          // Provider dependencies.
          final step = of<StepNotifier>().watch;
          final fieldCount = of<CounterFieldNotifier>().count.watch;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Multiple Dependencies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Watch multiple notifiers in a single builder. '
                  'Changes to any dependency rebuild this widget.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // CounterNotifier
                _WatchSection(
                  title: 'Direct Listenable',
                  description: 'CounterNotifier.watch',
                  value: 'Count: $count',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _counter.decrement,
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton.filled(
                        onPressed: _counter.decrement,
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        onPressed: _counter.reset,
                        icon: const Icon(Icons.restart_alt),
                      ),
                    ],
                  ),
                ),

                // StepNotifier
                _WatchSection(
                  title: 'Provider Dependency',
                  description: 'context.watch<StepNotifier>()',
                  value: 'Step size: $step',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: context.read<StepNotifier>().decrement,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        onPressed: context.read<StepNotifier>().increment,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),

                // CounterFieldNotifier
                _WatchSection(
                  title: 'Provider Dependency',
                  description: 'context.watch<CounterFieldNotifier>()',
                  value: 'Field count: $fieldCount',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            context.read<CounterFieldNotifier>().increment,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),

                // MoviesNotifier
                _WatchSection(
                  title: 'Direct ViewState Dependency',
                  description: 'MoviesNotifier.watch',
                  value: 'Movies: ${movies.dataOrNull}',
                  child: FilledButton.tonalIcon(
                    // ignore: invalid_use_of_protected_member
                    onPressed: _movies.rebuild,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh movies'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WatchSection extends StatelessWidget {
  const _WatchSection({
    required this.title,
    required this.description,
    required this.value,
    required this.child,
  });

  final String title;
  final String description;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
