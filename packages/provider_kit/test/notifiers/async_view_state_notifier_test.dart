import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

/// A spy observer that records the initial state via `onCreate`.
class SpyObserver extends NotifierObserver {
  ViewState? capturedInitialState;
  NotifierBase? lastNotifier;

  @override
  void onCreate(NotifierBase notifier) {
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
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      TestProvider<String>(
        fetchDataImpl: () => 'data',
        initialState: const DataState('custom'),
      );
      expect(spy.capturedInitialState, const DataState('custom'));

      NotifierBase.observer = original;
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

    // -----------------------------------------------------------------------
    // 8. Dispose behaviour with pending async operations
    // -----------------------------------------------------------------------

    group('dispose', () {
      test('dispose can be called multiple times', () {
        final provider = TestProvider<String>(
          fetchDataImpl: () => 'data',
        );

        expect(() {
          provider.dispose();
          provider.dispose();
          provider.dispose();
        }, returnsNormally);
      });

      test(
        'dispose while fetchData is pending prevents state update',
        () async {
          final completer = Completer<String>();

          final provider = TestProvider<String>(
            fetchDataImpl: () => completer.future,
          );

          provider.dispose();

          completer.complete('data');

          await Future.microtask(() {});

          expect(provider.state, isA<LoadingState<String>>());
          expect(provider.state, isNot(isA<DataState<String>>()));
          expect(provider.state, isNot(isA<ErrorState<String>>()));
        },
      );

      test(
        'dispose while fetchData is pending prevents error state update',
        () async {
          final completer = Completer<String>();

          final provider = TestProvider<String>(
            fetchDataImpl: () => completer.future,
          );

          provider.dispose();

          completer.completeError(Exception('Delayed error'));

          await Future.microtask(() {});

          expect(provider.state, isA<LoadingState<String>>());
          expect(provider.state, isNot(isA<ErrorState<String>>()));
        },
      );

      test(
        'refresh after dispose does nothing',
        () async {
          final provider = TestProvider<String>(
            fetchDataImpl: () => 'data',
          );

          await Future.microtask(() {});

          expect(provider.state, const DataState('data'));

          provider.dispose();

          await provider.refresh();

          expect(provider.state, const DataState('data'));
        },
      );

      test(
        'setting state after dispose throws FlutterError in debug mode',
        () {
          final notifier = StateNotifier<int>(0);

          notifier.dispose();

          expect(
            () => notifier.state = 1,
            throwsFlutterError,
          );
        },
        skip: kReleaseMode,
      );
    });

    test(
      'notifyListeners after dispose throws FlutterError in debug mode',
      () {
        final notifier = StateNotifier<int>(0);

        notifier.dispose();

        expect(
          () => notifier.notifyListeners(),
          throwsFlutterError,
        );
      },
      skip: kReleaseMode,
    );

    test(
      'dispose while custom init is pending prevents further execution',
      () async {
        final completer = Completer<void>();

        late TestProvider<String> provider;

        provider = TestProvider<String>(
          fetchDataImpl: () => 'unused',
          initOverride: () async {
            await completer.future;
            // ignore: invalid_use_of_protected_member
            if (!provider.mounted) return;
            provider.state = const DataState('completed');
          },
        );

        provider.dispose();

        completer.complete();

        await Future.microtask(() {});

        expect(provider.state, isA<LoadingState<String>>());
        expect(provider.state, isNot(isA<DataState<String>>()));
      },
    );
  });
}
