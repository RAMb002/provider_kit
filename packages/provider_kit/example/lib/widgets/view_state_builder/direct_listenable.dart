import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates passing a locally owned notifier to ViewStateBuilder.
class ViewStateBuilderDirectExample extends StatefulWidget {
  const ViewStateBuilderDirectExample({super.key});

  @override
  State<ViewStateBuilderDirectExample> createState() =>
      _ViewStateBuilderDirectExampleState();
}

class _ViewStateBuilderDirectExampleState
    extends State<ViewStateBuilderDirectExample> {
  late final _movies = MoviesNotifier();

  @override
  void dispose() {
    _movies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewStateBuilder<List<String>>(
      listenable: _movies,
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
    );
  }
}
