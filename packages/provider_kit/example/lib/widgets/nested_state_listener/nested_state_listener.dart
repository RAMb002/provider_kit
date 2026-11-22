import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/counter_field_notifier.dart';
import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates composing multiple StateListener and ViewStateListener
/// instances using NestedStateListener.
class NestedStateListenerExample extends StatefulWidget {
  const NestedStateListenerExample({super.key});

  @override
  State<NestedStateListenerExample> createState() =>
      _NestedStateListenerExampleState();
}

class _NestedStateListenerExampleState
    extends State<NestedStateListenerExample> {
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
      builder: (context, child) => NestedStateListener(
        listeners: [
          // 1. Direct Listenable
          StateListener<int>(
            listenable: _counter,
            listener: (context, count) {
              context.showSnackBar('Counter changed to $count');
            },
          ),

          // 2. Provider-based listener
          StateListener.of<StepNotifier, int>(
            listener: (context, step) {
              context.showSnackBar('Step changed to $step');
            },
          ),

          // 3. Provider-based selected value
          StateListener.select(
            selector: (CounterFieldNotifier notifier) => notifier.count,
            listener: (context, count) {
              context.showSnackBar('Count field changed to $count');
            },
          ),

          // 4. ViewState listener
          ViewStateListener<List<String>>(
            listenable: _movies,
            dataStateListener: (context, movies) {
              context.showSnackBar('${movies.length} movies loaded');
            },
          ),
        ],
        child: _child(context),
      ),
    );
  }

  SingleChildScrollView _child(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nested State Listeners',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Each section triggers a different listener. '
            'All listeners are composed in one NestedStateListener.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // CounterNotifier
          _ExampleSection(
            title: 'Direct Listenable',
            description: 'StateListener.listenable',
            child: Row(
              children: [
                const Expanded(child: Text('CounterNotifier')),
                IconButton(
                  onPressed: _counter.decrement,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: _counter.increment,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),

          // StepNotifier
          _ExampleSection(
            title: 'Provider Listener',
            description: 'StateListener.of',
            child: Row(
              children: [
                const Expanded(child: Text('StepNotifier')),
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
          _ExampleSection(
            title: 'Nested listenable Listener',
            description: 'StateListener.select',
            child: Row(
              children: [
                const Expanded(child: Text('CounterFieldNotifier')),
                IconButton(
                  onPressed: context.read<CounterFieldNotifier>().decrement,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: context.read<CounterFieldNotifier>().increment,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),

          // MoviesNotifier
          _ExampleSection(
            title: 'ViewState Listener',
            description: 'ViewStateListener.dataStateListener',
            child: Row(
              children: [
                const Expanded(child: Text('MoviesNotifier')),
                FilledButton.tonalIcon(
                  onPressed: _movies.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleSection extends StatelessWidget {
  const _ExampleSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
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
            child,
          ],
        ),
      ),
    );
  }
}
