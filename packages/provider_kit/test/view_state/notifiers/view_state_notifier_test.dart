import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class TestNotifier extends ViewStateNotifier<int> {
  TestNotifier(super.state);
}

void main() {
  group('ViewStateNotifier', () {
    test('initial state is set correctly', () {
      final notifier = TestNotifier(const InitialState<int>());
      expect(notifier.state, isA<InitialState<int>>());
    });

    test('can update to different ViewState types', () {
      final notifier = TestNotifier(const InitialState<int>());
      notifier.state = const LoadingState<int>();
      expect(notifier.state, isA<LoadingState<int>>());

      notifier.state = const DataState<int>(42);
      expect(notifier.state, isA<DataState<int>>());
      expect((notifier.state as DataState<int>).data, 42);

      final error = StateError('error');

      notifier.state = ErrorState<int>(
        error,
        StackTrace.current,
      );
      expect(notifier.state, isA<ErrorState<int>>());

      notifier.state = const EmptyState<int>();
      expect(notifier.state, isA<EmptyState<int>>());
    });

    test('listeners are notified on state change', () {
      final notifier = TestNotifier(const InitialState<int>());
      int callCount = 0;
      notifier.addListener(() => callCount++);
      notifier.state = const DataState<int>(10);
      expect(callCount, 1);
    });

    test('data returns current data when state is DataState', () {
      final notifier = TestNotifier(
        const DataState<int>(42),
      );

      expect(notifier.data, 42);
    });

    test('data throws StateError when state is not DataState', () {
      final states = <ViewState<int>>[
        const InitialState<int>(),
        const LoadingState<int>(),
        const EmptyState<int>(),
        ErrorState<int>(
          StateError('error'),
          StackTrace.empty,
        ),
      ];

      for (final state in states) {
        final notifier = TestNotifier(state);

        expect(
          () => notifier.data,
          throwsA(isA<StateError>()),
          reason: 'Expected StateError for ${state.runtimeType}',
        );
      }
    });
  });
}
