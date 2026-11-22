import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates resolving multiple Provider-managed notifiers inside .multi.
class ViewStateBuilderMultiProviderExample extends StatelessWidget {
  const ViewStateBuilderMultiProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoviesNotifier()),
        ChangeNotifierProvider(create: (_) => RecommendationsNotifier()),
      ],
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ViewStateBuilder.multi(
              listenables: () => (
                movies: of<MoviesNotifier>().watch,
                recommendations: of<RecommendationsNotifier>().watch,
              ),
              dataBuilder: (context, state, child) {
                final movies = [
                  ...state.movies.data,
                  ...state.recommendations.data,
                ];

                return SizedBox(
                  height: 240,
                  child: ListView.separated(
                    itemCount: movies.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) => ListTile(
                      leading: const Icon(Icons.movie_outlined),
                      title: Text(movies[index]),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
