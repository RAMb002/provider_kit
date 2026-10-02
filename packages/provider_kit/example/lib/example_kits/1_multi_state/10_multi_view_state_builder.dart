import 'package:example/example_kits/providers/2_async_view_state_notifier.dart';
import 'package:example/scaffold_with_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiViewStateBuilderExample extends StatelessWidget {
  const MultiViewStateBuilderExample({super.key});

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
          title: 'Multi View State Builder',
          child: MultiViewStateBuilder(
            providers: () => (
              movie: movieProvider.watch,
              similarMovies: similarMoviesProvider.watch,
              trailers: trailersProvider.watch,
            ),
            loadingBuilder: (message, progress, isSliver) {
              return const CircularProgressIndicator();
            },
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
