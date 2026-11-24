import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates combining two locally owned ViewState listenables.
class ViewStateBuilderMultiExample extends StatefulWidget {
  const ViewStateBuilderMultiExample({super.key});

  @override
  State<ViewStateBuilderMultiExample> createState() =>
      _ViewStateBuilderMultiExampleState();
}

class _ViewStateBuilderMultiExampleState
    extends State<ViewStateBuilderMultiExample> {
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
        ViewStateBuilder.multi(
          listenables: () => (
            movies: _movies.watch,
            recommendations: _recommendations.watch,
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
  }
}
