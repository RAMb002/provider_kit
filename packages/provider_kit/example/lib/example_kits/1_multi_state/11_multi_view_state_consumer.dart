import 'package:example/example_kits/providers/2_async_view_state_notifier.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateConsumerExample extends StatelessWidget {
  const MultiViewStateConsumerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MovieProvider()),
        ChangeNotifierProvider(create: (_) => SimilarMoviesProvider()),
        ChangeNotifierProvider(create: (_) => TrailersProvider()),
      ],
      builder: (context, child) {
        final movieProvider = context.read<MovieProvider>();
        final similarMoviesProvider = context.read<SimilarMoviesProvider>();
        final trailersProvider = context.read<TrailersProvider>();

        return ScaffoldWithButton(
          title: 'Multi View State Consumer',
          child: ViewStateConsumer.multi(
            callListenerOnInit: true,
            providers: () => (
              movie: movieProvider.watch,
              similarMovies: similarMoviesProvider.watch,
              trailers: trailersProvider.watch,
            ),
            initialStateListener: () => context.showToast('Initial state'),
            loadingStateListener: (message, progress) =>
                context.showToast('Loading state'),
            emptyStateListener: (message) => context.showToast('Empty state'),
            dataStateListener: (state) {
              context.showToast(
                'Movie: ${state.movie.data.title}\n'
                'Similar movies: ${state.similarMovies.data.length}\n'
                'Trailers: ${state.trailers.data.length}',
              );
            },
            errorStateListener:
                (errorMessage, onRetry, exception, stackTrace) =>
                    context.showToast(
              'Error state: $errorMessage',
            ),
            dataBuilder: (state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Movie: ${state.movie.data.title}'),
                  Text(
                    'Similar movies: '
                    '${state.similarMovies.data.length}',
                  ),
                  Text(
                    'Trailers: ${state.trailers.data.length}',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
