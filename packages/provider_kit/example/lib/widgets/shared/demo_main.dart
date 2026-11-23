import 'package:example/widgets/shared/repositories/movies_repository.dart';
import 'package:example/widgets/shared/view_state_widgets/empty_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/error_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/initial_state_widget.dart';
import 'package:example/widgets/shared/view_state_widgets/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  ProviderKit.configure(
    errorInfoMapper: (error, stackTrace) {
      if (error is MoviesException) {
        return const ErrorInfo(
          message: 'Failed to load movies.',
          code: 'movies_load_failed',
        );
      }
      return ErrorInfo(
        message: error.toString(),
      );
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewStateWidgetsProvider(
      initialStateBuilder: (context, isSliver) => InitialStateWidget(
        isSliver: isSliver,
      ),
      loadingStateBuilder: (context, details, isSliver) => LoadingStateWidget(
        isSliver: isSliver,
        message: details.message,
      ),
      emptyStateBuilder: (context, details, isSliver) => EmptyStateWidget(
        message: details.message,
        onTap: details.onRefresh,
        isSliver: isSliver,
      ),
      errorStateBuilder: (context, details, isSliver) => ErrorStateWidget(
        message: details.message,
        onTap: details.onRetry,
        isSliver: isSliver,
      ),
      child: const MaterialApp(
        home: SizedBox(),
      ),
    );
  }
}
