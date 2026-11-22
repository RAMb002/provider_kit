import 'package:example/widgets/shared/notifiers/movies_notifier.dart';
import 'package:example/widgets/shared/view_state_widgets/empty_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/error_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/initial_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates the state-specific builders and filtering options.
class ViewStateBuilderFullConfigurationExample extends StatefulWidget {
  const ViewStateBuilderFullConfigurationExample({super.key});

  @override
  State<ViewStateBuilderFullConfigurationExample> createState() =>
      _ViewStateBuilderFullConfigurationExampleState();
}

class _ViewStateBuilderFullConfigurationExampleState
    extends State<ViewStateBuilderFullConfigurationExample> {
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
        ViewStateBuilder<List<String>>(
          listenable: _movies,
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
          isSliver: false,
          child: const Text('Static child passed to dataBuilder.'),
        ),
      ],
    );
  }
}
