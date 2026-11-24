import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates listening to multiple locally owned ViewState listenables.
class ViewStateListenerMultiExample extends StatefulWidget {
  const ViewStateListenerMultiExample({super.key});

  @override
  State<ViewStateListenerMultiExample> createState() =>
      _ViewStateListenerMultiExampleState();
}

class _ViewStateListenerMultiExampleState
    extends State<ViewStateListenerMultiExample> {
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
    return ViewStateListener.multi(
      listenables: () => (
        movies: _movies.watch,
        recommendations: _recommendations.watch,
      ),
      dataStateListener: (context, state) {
        final movieCount = state.movies.data.length;
        final recommendationCount = state.recommendations.data.length;

        context.showSnackBar(
          'Loaded $movieCount movies and $recommendationCount recommendations.',
        );
      },
      child: const Text("Listening to movies and recommendations notifier"),
    );
  }
}
