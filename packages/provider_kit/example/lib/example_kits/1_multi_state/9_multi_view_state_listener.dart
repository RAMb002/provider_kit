import 'package:example/example_kits/providers/2_async_view_state_notifier.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateListenerExample extends StatefulWidget {
  const MultiViewStateListenerExample({super.key});

  @override
  State<MultiViewStateListenerExample> createState() =>
      _MultiViewStateListenerExampleState();
}

class _MultiViewStateListenerExampleState
    extends State<MultiViewStateListenerExample> {
  late MovieProvider movieProvider;
  late SimilarMoviesProvider similarMoviesProvider;
  late TrailersProvider trailersProvider;

  @override
  void initState() {
    super.initState();

    movieProvider = MovieProvider();
    similarMoviesProvider = SimilarMoviesProvider();
    trailersProvider = TrailersProvider();
  }

  @override
  void dispose() {
    movieProvider.dispose();
    similarMoviesProvider.dispose();
    trailersProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithButton(
      title: 'Multi View State Listener',
      child: MultiViewStateListener(
        callListenerOnInit: true,
        providers: () => (
          movie: movieProvider.watch,
          similarMovies: similarMoviesProvider.watch,
          trailers: trailersProvider.watch,
        ),
        initialStateListener: () => context.showToast('Initial state'),
        emptyStateListener: (message) => context.showToast('Empty state'),
        loadingStateListener: (message, progress) =>
            context.showToast('Loading state'),
        dataStateListener: (state) {
          context.showToast(
            'Movie: ${state.movie.data.title}\n'
            'Similar movies: ${state.similarMovies.data.length}\n'
            'Trailers: ${state.trailers.data.length}',
          );
        },
        errorStateListener: (errorMessage, onRetry, exception, stackTrace) =>
            context.showToast(
          'Error state: $errorMessage',
        ),
        child: const Text('Listening to movie details'),
      ),
    );
  }
}
