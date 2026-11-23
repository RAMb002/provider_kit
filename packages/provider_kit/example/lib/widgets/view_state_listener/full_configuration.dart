import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates all state-specific listeners and listenWhen filtering.
class ViewStateListenerFullConfigurationExample extends StatefulWidget {
  const ViewStateListenerFullConfigurationExample({super.key});

  @override
  State<ViewStateListenerFullConfigurationExample> createState() =>
      _ViewStateListenerFullConfigurationExampleState();
}

class _ViewStateListenerFullConfigurationExampleState
    extends State<ViewStateListenerFullConfigurationExample> {
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
      listenWhen: (previous, next) => previous.runtimeType != next.runtimeType,
      callListenerOnInit: true,
      initialStateListener: (context) =>
          context.showSnackBar('Entered initial state.'),
      loadingStateListener: (context, _) =>
          context.showSnackBar('Loading movies...'),
      dataStateListener: (context, movies) => context.showSnackBar(
        'Loaded ${movies.length} movies.',
      ),
      emptyStateListener: (context, _) =>
          context.showSnackBar('No movies were found.'),
      errorStateListener: (context, _) =>
          context.showSnackBar('The movie request failed.'),
      child: const Text("Listening to movies notifier"),
    );
  }
}
