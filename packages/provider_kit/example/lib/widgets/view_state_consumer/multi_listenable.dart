import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates combining local listenables for both building and listening.
class ViewStateConsumerMultiExample extends StatefulWidget {
  const ViewStateConsumerMultiExample({super.key});

  @override
  State<ViewStateConsumerMultiExample> createState() =>
      _ViewStateConsumerMultiExampleState();
}

class _ViewStateConsumerMultiExampleState
    extends State<ViewStateConsumerMultiExample> {
  late final _movies = MoviesNotifier();
  late final _recommendations = RecommendationsNotifier();

  @override
  void dispose() {
    _recommendations.dispose();
    _movies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ViewStateConsumer.multi(
          listenables: () => (
            movies: _movies.watch,
            recommendations: _recommendations.watch,
          ),
          dataStateListener: (context, state) {
            context.showSnackBar(
              'Both data sources are ready.',
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
    );
  }
}
