import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates building UI and reacting to data changes with one notifier.
class ViewStateConsumerDirectExample extends StatefulWidget {
  const ViewStateConsumerDirectExample({super.key});

  @override
  State<ViewStateConsumerDirectExample> createState() =>
      _ViewStateConsumerDirectExampleState();
}

class _ViewStateConsumerDirectExampleState
    extends State<ViewStateConsumerDirectExample> {
  late final _movies = MoviesNotifier();

  @override
  void dispose() {
    _movies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ViewStateConsumer<List<String>>(
          listenable: _movies,
          dataStateListener: (context, movies) {
            context.showSnackBar('Loaded ${movies.length} movies.');
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
          child: const Text('Static child passed to dataBuilder.'),
        ),
      ],
    );
  }
}
