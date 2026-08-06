import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

/// A spy observer that records the initial state via `onCreate`.
class SpyObserver extends StateObserver {
  ViewState? capturedInitialState;
  StateNotifierBase? lastNotifier;

  @override
  void onCreate(StateNotifierBase notifier) {
    super.onCreate(notifier);
    lastNotifier = notifier;
    // Capture the initial state.
    capturedInitialState = (notifier as dynamic).state;
  }
}

/// A test provider that allows controlling `fetchData` and optionally
/// overriding `init` behaviour.
class TestProvider<T> extends AsyncViewStateNotifier<T> {
  final FutureOr<T> Function() fetchDataImpl;
  final FutureOr<void> Function()? initOverride;

  TestProvider({
    required this.fetchDataImpl,
    this.initOverride,
    super.disableEmptyState,
    super.initialState,
  });

  @override
  FutureOr<T> fetchData() => fetchDataImpl();

  @override
  FutureOr<void> init() {
    if (initOverride != null) {
      return initOverride!();
    }
    return super.init();
  }
}

/// A provider that overrides `loadingStateObject`.
class CustomLoadingProvider<T> extends TestProvider<T> {
  CustomLoadingProvider({required super.fetchDataImpl});

  @override
  LoadingState<T> loadingStateObject() {
    return LoadingState<T>('Custom loading', 0.8);
  }
}

/// A provider that overrides `errorStateObject`.
class CustomErrorProvider extends TestProvider<String> {
  CustomErrorProvider({FutureOr<String> Function()? fetchDataImpl})
      : super(fetchDataImpl: fetchDataImpl ?? (() => 'data'));

  @override
  ErrorState<String> errorStateObject(Object error, StackTrace stackTrace) {
    return ErrorState<String>(
      'Custom: $error',
      error,
      stackTrace,
      null,
    );
  }
}

/// A provider that overrides `emptyStateObject`.
class CustomEmptyProvider extends TestProvider<List<int>> {
  CustomEmptyProvider()
      : super(
          fetchDataImpl: () => [],
          disableEmptyState: false,
        );

  @override
  EmptyState<List<int>> emptyStateObject() {
    return const EmptyState<List<int>>('Custom empty message');
  }
}

// -----------------------------------------------------------------------------
// Test suite
// -----------------------------------------------------------------------------

void main() {
  group('AsyncViewStateNotifier', () {
    // -----------------------------------------------------------------------
    // 1. Initial state
    // -----------------------------------------------------------------------
    test('default initial state is LoadingState', () {
      final provider = TestProvider<String>(fetchDataImpl: () => 'data');
      expect(provider.state, isA<LoadingState<String>>());
    });

    test(
        'initial state can be overridden via constructor (verified via observer)',
        () {
      final spy = SpyObserver();
      final original = StateNotifier.observer;
      StateNotifier.observer = spy;

      TestProvider<String>(
        fetchDataImpl: () => 'data',
        initialState: const DataState('custom'),
      );
      expect(spy.capturedInitialState, const DataState('custom'));

      StateNotifier.observer = original;
    });

    // -----------------------------------------------------------------------
    // 2. _build() flow – success
    // -----------------------------------------------------------------------
    test('_build() sets DataState on successful fetch', () async {
      final provider = TestProvider<String>(fetchDataImpl: () => 'success');
      await Future.microtask(() {});
      expect(provider.state, const DataState('success'));
    });

    // -----------------------------------------------------------------------
    // 3. _build() flow – error
    // -----------------------------------------------------------------------
    test('_build() sets ErrorState on exception', () async {
      final provider = TestProvider<String>(
        fetchDataImpl: () => throw Exception('Test error'),
      );
      await Future.microtask(() {});
      final state = provider.state;
      expect(state, isA<ErrorState<String>>());
      final errorState = state as ErrorState<String>;
      expect(errorState.message, 'Exception: Test error');
      expect(errorState.exception, isA<Exception>());
      expect(errorState.onRetry, provider.refresh);
    });

    // -----------------------------------------------------------------------
    // 4. _build() flow – empty state
    // -----------------------------------------------------------------------
    test('_build() sets EmptyState when data is an empty Iterable', () async {
      final provider = TestProvider<List<int>>(
        fetchDataImpl: () => [],
      );
      await Future.microtask(() {});
      expect(provider.state, isA<EmptyState<List<int>>>());
    });

    test('_build() does NOT set EmptyState when disableEmptyState is true',
        () async {
      final provider = TestProvider<List<int>>(
        fetchDataImpl: () => [],
        disableEmptyState: true,
      );
      await Future.microtask(() {});
      expect(provider.state, isA<DataState<List<int>>>());
      final dataState = provider.state as DataState<List<int>>;
      expect(dataState.data, []);
    });

    // -----------------------------------------------------------------------
    // 5. refresh() method
    // -----------------------------------------------------------------------
    test('refresh() sets LoadingState and re-executes _build()', () async {
      int callCount = 0;
      final provider = TestProvider<String>(
        fetchDataImpl: () {
          callCount++;
          return 'data$callCount';
        },
      );
      await Future.microtask(() {});
      expect(provider.state, const DataState('data1'));

      await provider.refresh();
      expect(provider.state, const DataState('data2'));
    });

    test('refresh() handles errors and sets ErrorState', () async {
      int callCount = 0;
      final provider = TestProvider<String>(
        fetchDataImpl: () {
          callCount++;
          if (callCount == 2) {
            throw Exception('Refresh error');
          }
          return 'data';
        },
      );
      await Future.microtask(() {});
      expect(provider.state, const DataState('data'));

      await provider.refresh();
      expect(provider.state, isA<ErrorState<String>>());
      final errorState = provider.state as ErrorState<String>;
      expect(errorState.message, 'Exception: Refresh error');
    });

    // -----------------------------------------------------------------------
    // 6. Customization overrides
    // -----------------------------------------------------------------------
    test('custom errorStateObject is used', () async {
      final provider = CustomErrorProvider(
        fetchDataImpl: () => throw Exception('Forced error'),
      );
      await Future.microtask(() {});
      final state = provider.state;
      expect(state, isA<ErrorState<String>>());
      expect((state as ErrorState<String>).message,
          'Custom: Exception: Forced error');
    });

    test('custom loadingStateObject is used during refresh', () async {
      int callCount = 0;
      final completer = Completer<String>();
      final provider = CustomLoadingProvider<String>(
        fetchDataImpl: () {
          callCount++;
          if (callCount == 1) return 'initial';
          return completer.future;
        },
      );
      // Wait for initial _build to complete.
      await Future.microtask(() {});
      expect(provider.state, const DataState('initial'));

      // Call refresh – it will use the second fetch which returns the completer.
      final refreshFuture = provider.refresh();
      // Now the state should be the custom loading state.
      expect(provider.state, isA<LoadingState<String>>());
      final loadingState = provider.state as LoadingState<String>;
      expect(loadingState.message, 'Custom loading');
      expect(loadingState.progress, 0.8);
      // Complete the future to finish refresh.
      completer.complete('refreshed');
      await refreshFuture;
      expect(provider.state, const DataState('refreshed'));
    });

    test('custom emptyStateObject is used', () async {
      final provider = CustomEmptyProvider();
      await Future.microtask(() {});
      final state = provider.state;
      expect(state, isA<EmptyState<List<int>>>());
      expect((state as EmptyState<List<int>>).message, 'Custom empty message');
    });

    // -----------------------------------------------------------------------
    // 7. Constructor triggers _build automatically
    // -----------------------------------------------------------------------
    test('constructor triggers _build automatically', () async {
      final provider = TestProvider<String>(fetchDataImpl: () => 'auto');
      expect(provider.state, isA<LoadingState<String>>());
      await Future.microtask(() {});
      expect(provider.state, const DataState('auto'));
    });
  });
}
