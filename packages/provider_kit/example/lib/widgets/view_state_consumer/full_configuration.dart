import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/view_state_widgets/empty_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/error_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/initial_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/loading_state_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates state-specific listeners, builders and filtering together.
class ViewStateConsumerFullConfigurationExample extends StatefulWidget {
  const ViewStateConsumerFullConfigurationExample({super.key});

  @override
  State<ViewStateConsumerFullConfigurationExample> createState() =>
      _ViewStateConsumerFullConfigurationExampleState();
}

class _ViewStateConsumerFullConfigurationExampleState
    extends State<ViewStateConsumerFullConfigurationExample> {
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
          listenWhen: (previous, next) =>
              previous.runtimeType != next.runtimeType,
          callListenerOnInit: false,
          initialStateListener: (context) =>
              context.showSnackBar('Entered initial state.'),
          loadingStateListener: (context, _) =>
              context.showSnackBar('Loading movies...'),
          dataStateListener: (context, movies) => context.showSnackBar(
            'Loaded ${movies.length} movies.',
          ),
          emptyStateListener: (context, _) =>
              context.showSnackBar('No movies were found.'),
          errorStateListener: (context, _) =>
              context.showSnackBar('The movie request failed.'),
          rebuildWhen: (previous, next) =>
              previous.runtimeType != next.runtimeType ||
              previous.dataOrNull != next.dataOrNull,
          initialBuilder: (_) =>
              const InitialStateWidget(message: 'Ready to load movie data.'),
          loadingBuilder: (_, details) => const LoadingStateWidget(
            message: 'Loading Data',
          ),
          emptyBuilder: (_, details) => EmptyStateWidget(
              message: "No data found", onTap: details.onRefresh),
          errorBuilder: (_, details) => ErrorStateWidget(
            message: 'Something went wrong',
            onTap: details.onRetry,
          ),
          isSliver: false,
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
