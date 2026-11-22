import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates Provider lookups inside ViewStateConsumer.multi.
class ViewStateConsumerMultiProviderExample extends StatelessWidget {
  const ViewStateConsumerMultiProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoviesNotifier()),
        ChangeNotifierProvider(create: (_) => RecommendationsNotifier()),
      ],
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ViewStateConsumer.multi(
            listenables: () => (
              movies: of<MoviesNotifier>().watch,
              recommendations: of<RecommendationsNotifier>().watch,
            ),
            dataStateListener: (context, state) {
              context.showSnackBar(
                'Both Provider-managed data sources are ready.',
              );
            },
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
      ),
    );
  }
}
