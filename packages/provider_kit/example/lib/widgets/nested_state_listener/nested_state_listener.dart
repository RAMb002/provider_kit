import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/counter_notifier.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:example/widgets/shared/notifiers/step_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Groups StateListener and ViewStateListener under one NestedStateListener.
class NestedStateListenerExample extends StatefulWidget {
  const NestedStateListenerExample({super.key});

  @override
  State<NestedStateListenerExample> createState() =>
      _NestedStateListenerExampleState();
}

class _NestedStateListenerExampleState
    extends State<NestedStateListenerExample> {
  late final _counter = CounterNotifier();
  late final _step = StepNotifier();
  late final _movies = MoviesNotifier();

  @override
  void dispose() {
    _movies.dispose();
    _step.dispose();
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NestedStateListener(
      listeners: [
        StateListener<int>(
          listenable: _counter,
          listener: (context, count) {
            context.showSnackBar(
              'Counter changed to $count',
            );
          },
        ),
        StateListener<int>(
          listenable: _step,
          listener: (context, step) {
            context.showSnackBar(
              'Step changed to $step',
            );
          },
        ),
        ViewStateListener<List<String>>(
          listenable: _movies,
          dataStateListener: (context, movies) {
            context.showSnackBar(
              '${movies.length} movies loaded',
            );
          },
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Listening to multiple notifiers'),
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
      ),
    );
  }
}
