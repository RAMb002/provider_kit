import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:example/widgets/shared/notifiers/recommendations_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates Provider lookups inside ViewStateListener.multi.
class ViewStateListenerMultiProviderExample extends StatelessWidget {
  const ViewStateListenerMultiProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoviesNotifier()),
        ChangeNotifierProvider(create: (_) => RecommendationsNotifier()),
      ],
      builder: (context, _) => ViewStateListener.multi(
        listenables: () => (
          movies: of<MoviesNotifier>().watch,
          recommendations: of<RecommendationsNotifier>().watch,
        ),
        dataStateListener: (context, state) {
          final movieCount = state.movies.data.length;
          final recommendationCount = state.recommendations.data.length;

          context.showSnackBar(
            'Loaded $movieCount movies and $recommendationCount recommendations.',
          );
        },
        child: const Text("Listening to movies and recommendations notifier"),
      ),
    );
  }
}
