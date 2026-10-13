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
class TestProvider<T> extends FutureNotifier<T> {
  final FutureOr<T> Function() fetchDataImpl;
  final FutureOr<void> Function()? initOverride;

  TestProvider({
    required this.fetchDataImpl,
    this.initOverride,
    super.disableEmptyState,
    super.initialState,
  });

  @override
  Future<T> fetchData() async => fetchDataImpl();

  @override
  Future<void> init() async {
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
      error,
      stackTrace,
      errorInfo: ErrorInfo(message: 'Custom: $error'),
      onRetry: null,
    );
  }
}

/// A provider that overrides `emptyStateObject`.
class CustomEmptyProvider extends TestProvider<List<int>> {
  CustomEmptyProvider()
    : super(fetchDataImpl: () => [], disableEmptyState: false);

  @override
  EmptyState<List<int>> emptyStateObject() {
    return const EmptyState<List<int>>('Custom empty message');
  }
}

class ThrowingOnErrorProvider extends TestProvider<String> {
  ThrowingOnErrorProvider()
    : super(fetchDataImpl: () => throw Exception('Fetch failed'));

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    throw StateError('onError failed');
  }
}

class ConstructorDependentProvider extends FutureNotifier<String> {
  ConstructorDependentProvider() {
    _value = 'initialized';
  }

  late final String _value;

  @override
  Future<void> init() async {
    // This accesses a field initialized in the subclass constructor body.
    state = DataState(_value);
  }

  @override
  Future<String> fetchData() async => 'unused';
}

Future<void> flushImmediateBuild() {
  return Future<void>.delayed(Duration.zero);
}

// -----------------------------------------------------------------------------
// Test suite
// -----------------------------------------------------------------------------

void main() {
  group('FutureNotifier', () {
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
        ProviderKit.configure(observer: spy);

        TestProvider<String>(
          fetchDataImpl: () => 'data',
          initialState: const DataState('custom'),
        );
        expect(spy.capturedInitialState, const DataState('custom'));

        ProviderKit.resetForTesting();
      },
    );

    // -----------------------------------------------------------------------
    // 2. _build() flow – success
    // -----------------------------------------------------------------------
    test('_build() sets DataState on successful fetch', () async {
      final provider = TestProvider<String>(fetchDataImpl: () => 'success');
      await flushImmediateBuild();
      expect(provider.state, const DataState('success'));
    });

    // -----------------------------------------------------------------------
    // 3. _build() flow – error
    // -----------------------------------------------------------------------
    test('_build() sets ErrorState on exception', () async {
      final provider = TestProvider<String>(
        fetchDataImpl: () => throw Exception('Test error'),
      );
      await flushImmediateBuild();
      final state = provider.state;
      expect(state, isA<ErrorState<String>>());
      final errorState = state as ErrorState<String>;
      expect(errorState.message, 'Exception: Test error');
      expect(errorState.error, isA<Exception>());
      expect(errorState.onRetry, provider.refresh);
    });

    test('default error retry callback refreshes the data', () async {
      var fetchCount = 0;

      final provider = TestProvider<String>(
        fetchDataImpl: () {
          fetchCount++;

          if (fetchCount == 1) {
            throw Exception('Temporary failure');
          }

          return 'recovered';
        },
      );
      addTearDown(provider.dispose);

      await flushImmediateBuild();

      expect(fetchCount, 1);
      expect(provider.state, isA<ErrorState<String>>());

      final errorState = provider.state as ErrorState<String>;
      expect(errorState.onRetry, isNotNull);

      final recovered = Completer<void>();

      void listener() {
        if (provider.state is DataState<String> && !recovered.isCompleted) {
          recovered.complete();
        }
      }

      provider.addListener(listener);

      try {
        errorState.onRetry!.call();

        await recovered.future;
      } finally {
        provider.removeListener(listener);
      }

      expect(fetchCount, 2);
      expect(provider.state, const DataState('recovered'));
    });

    test('reports errors escaping the initial build', () async {
      final previousHandler = FlutterError.onError;
      final reported = Completer<FlutterErrorDetails>();

      FlutterError.onError = (details) {
        if (!reported.isCompleted) {
          reported.complete(details);
        }
      };

      final provider = ThrowingOnErrorProvider();

      try {
        final details = await reported.future;

        expect(details.exception, isA<StateError>());
        expect(details.exception.toString(), contains('onError failed'));
      } finally {
        FlutterError.onError = previousHandler;
        provider.dispose();
      }
    });

    // -----------------------------------------------------------------------
    // 4. _build() flow – empty state
    // -----------------------------------------------------------------------
    test('_build() sets EmptyState when data is an empty Iterable', () async {
      final provider = TestProvider<List<int>>(fetchDataImpl: () => []);
      await flushImmediateBuild();
      expect(provider.state, isA<EmptyState<List<int>>>());
    });

    test(
      '_build() does NOT set EmptyState when disableEmptyState is true',
      () async {
        final provider = TestProvider<List<int>>(
          fetchDataImpl: () => [],
          disableEmptyState: true,
        );
        await flushImmediateBuild();
        expect(provider.state, isA<DataState<List<int>>>());
        final dataState = provider.state as DataState<List<int>>;
        expect(dataState.data, []);
      },
    );

    test('non-empty Iterable produces DataState', () async {
      final provider = TestProvider<List<int>>(fetchDataImpl: () => [1, 2, 3]);
      addTearDown(provider.dispose);

      await flushImmediateBuild();

      expect(provider.state, isA<DataState<List<int>>>());
      expect((provider.state as DataState<List<int>>).data, [1, 2, 3]);
    });

    test('fetchData supports synchronous results', () async {
      final provider = TestProvider<String>(fetchDataImpl: () => 'sync data');

      await flushImmediateBuild();

      expect(provider.state, const DataState('sync data'));
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
      await flushImmediateBuild();
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
      await flushImmediateBuild();
      expect(provider.state, const DataState('data'));

      await provider.refresh();
      expect(provider.state, isA<ErrorState<String>>());
      final errorState = provider.state as ErrorState<String>;
      expect(errorState.message, 'Exception: Refresh error');
    });

    test(
      'concurrent refresh calls reuse the current build operation',
      () async {
        final completer = Completer<String>();
        int fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;
            return completer.future;
          },
        );

        final firstRefresh = provider.refresh();
        final secondRefresh = provider.refresh();
        final thirdRefresh = provider.refresh();

        expect(fetchCount, 1);
        expect(provider.state, isA<LoadingState<String>>());

        completer.complete('data');

        await Future.wait([firstRefresh, secondRefresh, thirdRefresh]);

        expect(fetchCount, 1);
        expect(provider.state, const DataState('data'));
      },
    );

    test(
      'refresh starts a new operation after the current one completes',
      () async {
        int fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;
            return 'data$fetchCount';
          },
        );

        await flushImmediateBuild();

        expect(fetchCount, 1);
        expect(provider.state, const DataState('data1'));

        await provider.refresh();

        expect(fetchCount, 2);
        expect(provider.state, const DataState('data2'));

        await provider.refresh();

        expect(fetchCount, 3);
        expect(provider.state, const DataState('data3'));
      },
    );

    test(
      'concurrent refresh calls complete when the shared operation completes',
      () async {
        final completer = Completer<String>();
        int fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;
            return completer.future;
          },
        );

        final firstRefresh = provider.refresh();
        final secondRefresh = provider.refresh();

        var firstCompleted = false;
        var secondCompleted = false;

        firstRefresh.then((_) => firstCompleted = true);
        secondRefresh.then((_) => secondCompleted = true);

        await flushImmediateBuild();

        expect(fetchCount, 1);
        expect(firstCompleted, false);
        expect(secondCompleted, false);

        completer.complete('data');

        await Future.wait([firstRefresh, secondRefresh]);

        expect(firstCompleted, true);
        expect(secondCompleted, true);
        expect(provider.state, const DataState('data'));
      },
    );

    test('concurrent refresh calls share the same error operation', () async {
      final completer = Completer<String>();
      int fetchCount = 0;

      final provider = TestProvider<String>(
        fetchDataImpl: () {
          fetchCount++;
          return completer.future;
        },
      );

      final firstRefresh = provider.refresh();
      final secondRefresh = provider.refresh();

      expect(fetchCount, 1);

      completer.completeError(Exception('Refresh failed'));

      await Future.wait([firstRefresh, secondRefresh]);

      expect(fetchCount, 1);
      expect(provider.state, isA<ErrorState<String>>());

      final errorState = provider.state as ErrorState<String>;
      expect(errorState.message, 'Exception: Refresh failed');
    });

    test('refresh can run again after a failed operation', () async {
      int fetchCount = 0;

      final provider = TestProvider<String>(
        fetchDataImpl: () {
          fetchCount++;

          if (fetchCount == 1) {
            throw Exception('First failure');
          }

          return 'success';
        },
      );

      await flushImmediateBuild();

      expect(provider.state, isA<ErrorState<String>>());
      expect(fetchCount, 1);

      await provider.refresh();

      expect(fetchCount, 2);
      expect(provider.state, const DataState('success'));
    });

    test(
      'refresh reuses the initial build operation when it is still running',
      () async {
        final completer = Completer<String>();
        final fetchStarted = Completer<void>();
        int fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;
            if (!fetchStarted.isCompleted) {
              fetchStarted.complete();
            }
            return completer.future;
          },
        );
        addTearDown(provider.dispose);
        await fetchStarted.future;
        expect(fetchCount, 1);
        expect(provider.state, isA<LoadingState<String>>());

        final refreshFuture = provider.refresh();

        expect(fetchCount, 1);

        completer.complete('data');

        await refreshFuture;

        expect(fetchCount, 1);
        expect(provider.state, const DataState('data'));
      },
    );

    test(
      'refreshSilently preserves existing data until fetch completes',
      () async {
        final refreshCompleter = Completer<String>();
        final refreshStarted = Completer<void>();
        var fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;

            if (fetchCount == 1) {
              return 'initial';
            }

            if (!refreshStarted.isCompleted) {
              refreshStarted.complete();
            }

            return refreshCompleter.future;
          },
        );

        addTearDown(provider.dispose);

        await flushImmediateBuild();

        expect(fetchCount, 1);
        expect(provider.state, const DataState('initial'));

        final refreshFuture = provider.refreshSilently();

        await refreshStarted.future;

        expect(fetchCount, 2);
        expect(provider.state, const DataState('initial'));

        refreshCompleter.complete('updated');
        await refreshFuture;

        expect(provider.state, const DataState('updated'));
      },
    );

    test(
      'refreshSilently transitions to ErrorState when fetch fails',
      () async {
        final refreshCompleter = Completer<String>();
        final refreshStarted = Completer<void>();
        var fetchCount = 0;

        final provider = TestProvider<String>(
          fetchDataImpl: () {
            fetchCount++;

            if (fetchCount == 1) {
              return 'initial';
            }

            if (!refreshStarted.isCompleted) {
              refreshStarted.complete();
            }

            return refreshCompleter.future;
          },
        );

        addTearDown(provider.dispose);

        await flushImmediateBuild();

        expect(provider.state, const DataState('initial'));

        final refreshFuture = provider.refreshSilently();

        await refreshStarted.future;

        expect(provider.state, const DataState('initial'));

        refreshCompleter.completeError(Exception('Silent refresh failed'));

        await refreshFuture;

        expect(provider.state, isA<ErrorState<String>>());

        final errorState = provider.state as ErrorState<String>;
        expect(errorState.message, 'Exception: Silent refresh failed');
      },
    );

    // -----------------------------------------------------------------------
    // 6. Customization overrides
    // -----------------------------------------------------------------------
    test('custom errorStateObject is used', () async {
      final provider = CustomErrorProvider(
        fetchDataImpl: () => throw Exception('Forced error'),
      );
      await flushImmediateBuild();
      final state = provider.state;
      expect(state, isA<ErrorState<String>>());
      expect(
        (state as ErrorState<String>).message,
        'Custom: Exception: Forced error',
      );
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
      await flushImmediateBuild();
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
      await flushImmediateBuild();
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
      await flushImmediateBuild();
      expect(provider.state, const DataState('auto'));
    });

    test(
      'defers initial build until the subclass constructor completes',
      () async {
        final provider = ConstructorDependentProvider();
        addTearDown(provider.dispose);

        // The initial build must not have executed yet.
        expect(provider.state, isA<LoadingState<String>>());

        // Allow the scheduled initial build to execute.
        await flushImmediateBuild();

        // init() can now safely access the subclass's initialized field.
        expect(provider.state, const DataState('initialized'));
      },
    );

    // -----------------------------------------------------------------------
    // 8. Dispose behaviour with pending async operations
    // -----------------------------------------------------------------------

    group('dispose', () {
      test('dispose can be called multiple times', () {
        final provider = TestProvider<String>(fetchDataImpl: () => 'data');

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
          final fetchStarted = Completer<void>();

          final provider = TestProvider<String>(
            fetchDataImpl: () {
              if (!fetchStarted.isCompleted) {
                fetchStarted.complete();
              }

              return completer.future;
            },
          );

          await fetchStarted.future;
          expect(provider.state, isA<LoadingState<String>>());
          provider.dispose();
          completer.complete('data');

          await flushImmediateBuild();
          expect(provider.state, isA<LoadingState<String>>());
          expect(provider.state, isNot(isA<DataState<String>>()));
          expect(provider.state, isNot(isA<ErrorState<String>>()));
        },
      );

      test(
        'dispose while fetchData is pending prevents error state update',
        () async {
          final completer = Completer<String>();
          final fetchStarted = Completer<void>();

          final provider = TestProvider<String>(
            fetchDataImpl: () {
              if (!fetchStarted.isCompleted) {
                fetchStarted.complete();
              }

              return completer.future;
            },
          );

          await fetchStarted.future;

          expect(provider.state, isA<LoadingState<String>>());

          provider.dispose();

          completer.completeError(Exception('Delayed error'));

          await flushImmediateBuild();

          expect(provider.state, isA<LoadingState<String>>());
          expect(provider.state, isNot(isA<ErrorState<String>>()));
          expect(provider.state, isNot(isA<DataState<String>>()));
        },
      );

      test('refresh after dispose does nothing', () async {
        final provider = TestProvider<String>(fetchDataImpl: () => 'data');

        await flushImmediateBuild();

        expect(provider.state, const DataState('data'));

        provider.dispose();

        await provider.refresh();

        expect(provider.state, const DataState('data'));
      });

      test(
        'setting state after dispose throws FlutterError in debug mode',
        () {
          final notifier = StateNotifier<int>(0);

          notifier.dispose();

          expect(() => notifier.state = 1, throwsFlutterError);
        },
        skip: kReleaseMode,
      );
    });

    test(
      'notifyListeners after dispose throws FlutterError in debug mode',
      () {
        final notifier = StateNotifier<int>(0);

        notifier.dispose();

        expect(() => notifier.notifyListeners(), throwsFlutterError);
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

        await flushImmediateBuild();

        expect(provider.state, isA<LoadingState<String>>());
        expect(provider.state, isNot(isA<DataState<String>>()));
      },
    );
  });
}
