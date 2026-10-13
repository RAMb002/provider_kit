import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('AsyncViewStateNotifier', () {
    late TestAsyncViewStateNotifier<String> notifier;

    tearDown(() {
      notifier.dispose();
    });

    setUp(() {
      notifier = TestAsyncViewStateNotifier<String>();
    });

    // -------------------------------------------------------------------------
    // Initial state
    // -------------------------------------------------------------------------

    group('initial state', () {
      test('defaults to LoadingState', () {
        expect(notifier.state, isA<LoadingState<String>>());
      });

      test('accepts a custom initial state', () {
        final notifier = TestAsyncViewStateNotifier<String>(
          initialState: const DataState<String>('initial'),
        );

        addTearDown(notifier.dispose);

        expect(notifier.state, const DataState<String>('initial'));
      });
    });

    // -------------------------------------------------------------------------
    // Shared configuration
    // -------------------------------------------------------------------------

    group('disableEmptyState', () {
      test('defaults to false', () {
        expect(notifier.emptyStateDisabled, isFalse);
      });

      test('accepts true through the constructor', () {
        final notifier = TestAsyncViewStateNotifier<List<int>>(
          disableEmptyState: true,
        );

        addTearDown(notifier.dispose);

        expect(notifier.emptyStateDisabled, isTrue);
      });

      test('accepts false through the constructor', () {
        final notifier = TestAsyncViewStateNotifier<List<int>>(
          disableEmptyState: false,
        );

        addTearDown(notifier.dispose);

        expect(notifier.emptyStateDisabled, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // Default state factories
    // -------------------------------------------------------------------------

    group('state factories', () {
      test('loadingStateObject returns LoadingState', () {
        expect(
          notifier.createLoadingState(),
          isA<LoadingState<String>>(),
        );
      });

      test('emptyStateObject returns EmptyState', () {
        expect(
          notifier.createEmptyState(),
          isA<EmptyState<String>>(),
        );
      });

      test('errorStateObject preserves the error and stack trace', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        final errorState = notifier.createErrorState(
          error,
          stackTrace,
        );

        expect(errorState, isA<ErrorState<String>>());
        expect(errorState.error, same(error));
        expect(errorState.stackTrace, same(stackTrace));
      });

      test('errorStateObject assigns refresh as the retry callback', () {
        final errorState = notifier.createErrorState(
          Exception('Test error'),
          StackTrace.current,
        );

        expect(errorState.onRetry, isNotNull);

        errorState.onRetry!.call();

        expect(notifier.refreshCallCount, 1);
      });
    });

    // -------------------------------------------------------------------------
    // Error handling
    // -------------------------------------------------------------------------

    group('onError', () {
      test('updates the current state to ErrorState', () {
        final error = Exception('Request failed');
        final stackTrace = StackTrace.current;

        notifier.reportError(error, stackTrace);

        final state = notifier.state;

        expect(state, isA<ErrorState<String>>());

        final errorState = state as ErrorState<String>;

        expect(errorState.error, same(error));
        expect(errorState.stackTrace, same(stackTrace));
        expect(errorState.onRetry, isNotNull);
      });

      test('notifies listeners when the error state is set', () {
        var notificationCount = 0;

        void listener() {
          notificationCount++;
        }

        notifier.addListener(listener);

        try {
          notifier.reportError(
            Exception('Request failed'),
            StackTrace.current,
          );

          expect(notificationCount, 1);
        } finally {
          notifier.removeListener(listener);
        }
      });

      test('does not update state after disposal', () {
        final notifier = TestAsyncViewStateNotifier<String>(
          initialState: const DataState<String>('existing'),
        );

        notifier.dispose();

        notifier.reportError(
          Exception('Late error'),
          StackTrace.current,
        );

        expect(notifier.state, const DataState<String>('existing'));
      });
    });

    // -------------------------------------------------------------------------
    // Refresh contract
    // -------------------------------------------------------------------------

    group('refresh methods', () {
      test('refresh can be invoked by the default retry callback', () {
        final errorState = notifier.createErrorState(
          Exception('Request failed'),
          StackTrace.current,
        );

        errorState.onRetry!.call();

        expect(notifier.refreshCallCount, 1);
      });

      test('refreshSilently remains independently callable', () async {
        await notifier.refreshSilently();

        expect(notifier.refreshSilentlyCallCount, 1);
        expect(notifier.refreshCallCount, 0);
      });
    });
  });
}

/// Concrete test implementation of the shared asynchronous notifier.
///
/// This class deliberately does not implement a future or stream lifecycle.
/// It exposes the protected state factories and error handler for testing.
class TestAsyncViewStateNotifier<T> extends AsyncViewStateNotifier<T> {
  TestAsyncViewStateNotifier({
    super.initialState,
    super.disableEmptyState,
  });

  int refreshCallCount = 0;
  int refreshSilentlyCallCount = 0;

  bool get emptyStateDisabled => disableEmptyState;

  @override
  Future<void> init() async {}

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  @override
  Future<void> refreshSilently() async {
    refreshSilentlyCallCount++;
  }

  ErrorState<T> createErrorState(
    Object error,
    StackTrace stackTrace,
  ) {
    return errorStateObject(error, stackTrace);
  }

  LoadingState<T> createLoadingState() {
    return loadingStateObject();
  }

  EmptyState<T> createEmptyState() {
    return emptyStateObject();
  }

  void reportError(Object error, StackTrace stackTrace) {
    onError(error, stackTrace);
  }
}