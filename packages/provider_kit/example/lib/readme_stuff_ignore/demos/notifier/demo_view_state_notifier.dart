import 'dart:async';

import 'package:provider_kit/provider_kit.dart';

class DemoViewStateNotifier extends ViewStateNotifier<String> {
  DemoViewStateNotifier() : super(const LoadingState<String>());

  Timer? _timer;

  void startInitialLoad() {
    _timer?.cancel();

    _timer = Timer(
      const Duration(milliseconds: 1300),
      () {
        state = ErrorState<String>(
          'Something went wrong',
          StateError('Demo error'),
          null,
          retry,
        );
      },
    );
  }

  Future<void> retry() async {
    _timer?.cancel();

    state = const LoadingState<String>(
      'Retrying...',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );

    if (state is LoadingState<String>) {
      state = const EmptyState<String>(
        'No data found ',
      );
    }
  }

  Future<void> refresh() async {
    _timer?.cancel();

    state = const LoadingState<String>(
      'Refreshing...',
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 1200),
    );

    if (state is LoadingState<String>) {
      state = const DataState<String>(
        'Data loaded',
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
