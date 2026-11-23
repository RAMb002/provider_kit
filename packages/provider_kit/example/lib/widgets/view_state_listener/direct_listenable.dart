import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates side effects from a locally owned ViewState notifier.
class ViewStateListenerDirectExample extends StatefulWidget {
  const ViewStateListenerDirectExample({super.key});

  @override
  State<ViewStateListenerDirectExample> createState() =>
      _ViewStateListenerDirectExampleState();
}

class _ViewStateListenerDirectExampleState
    extends State<ViewStateListenerDirectExample> {
  late final _movies = MoviesNotifier();

  @override
  void dispose() {
    _movies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewStateListener<List<String>>(
      listenable: _movies,
      loadingStateListener: (context, details) {
        context.showSnackBar(
          'loading movies.',
        );
      },
      dataStateListener: (context, movies) {
        context.showSnackBar(
          'Loaded ${movies.length} movies.',
        );
      },
      child: const Text("Listening to movies notifier"),
    );
  }
}
