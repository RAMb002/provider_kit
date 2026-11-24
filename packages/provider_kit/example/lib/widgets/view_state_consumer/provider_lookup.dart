import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates resolving a Provider-managed notifier with .of.
class ViewStateConsumerProviderExample extends StatelessWidget {
  const ViewStateConsumerProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoviesNotifier(),
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ViewStateConsumer.of<MoviesNotifier, List<String>>(
            dataStateListener: (context, movies) {
              context.showSnackBar(
                'Provider loaded ${movies.length} movies.',
              );
            },
            dataBuilder: (context, movies, child) => SizedBox(
              height: 240,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: movies.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.movie_outlined),
                  title: Text(movies[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
