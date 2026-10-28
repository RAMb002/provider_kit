// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

const Duration _testTimeout = Duration(seconds: 5);

/// A controllable FutureNotifier for lifecycle and race-condition tests.
///
/// The initial build is scheduled by AsyncViewStateNotifier after construction,
/// so [buildImpl] can safely reference the notifier after its constructor ends.
class TestFutureNotifier<T> extends FutureNotifier<T> {
  TestFutureNotifier({
    required this.buildImpl,
    super.initialState,
    super.disableEmptyState,
    super.loadingMessage,
    super.emptyMessage,
  });

  final Future<T> Function(int buildNumber) buildImpl;

  // A fixed set keeps each build-start signal available even when a test calls
  // waitForBuildStart after the scheduled build has already started.
  final List<Completer<void>> _buildStarts = List<Completer<void>>.generate(
    64,
    (_) => Completer<void>(),
  );

  int buildCount = 0;

  @override
  Future<T> build() {
    final buildNumber = ++buildCount;
    if (buildNumber <= _buildStarts.length) {
      _buildStarts[buildNumber - 1].complete();
    }
    return buildImpl(buildNumber);
  }

  Future<void> waitForBuildStart(int buildNumber) {
    if (buildNumber < 1 || buildNumber > _buildStarts.length) {
      throw RangeError.range(
        buildNumber,
        1,
        _buildStarts.length,
        'buildNumber',
      );
    }
    return _buildStarts[buildNumber - 1].future.timeout(
      _testTimeout,
      onTimeout: () => throw TimeoutException(
        'FutureNotifier build $buildNumber did not start within $_testTimeout.',
      ),
    );
  }

  /// Exposes the protected framework operation to test rebuild behavior.
  Future<void> requestRebuild() => rebuild();

  /// Exposes the protected staleness guard for assertions in tests.
  bool Function() captureStaleness() => checkStaleness();

  /// Performs a state assignment through the normal public setter.
  void writeState(ViewState<T> value) => state = value;
}

class ConstructorDependentFutureNotifier extends FutureNotifier<String> {
  ConstructorDependentFutureNotifier() {
    _value = 'initialized after super';
  }

  late final String _value;

  @override
  Future<String> build() async => _value;
}

class RecordingErrorFutureNotifier<T> extends TestFutureNotifier<T> {
  RecordingErrorFutureNotifier({
    required super.buildImpl,
    super.initialState,
    super.disableEmptyState,
  });

  final List<Object> hookErrors = <Object>[];

  @override
  void onError(Object error, StackTrace stackTrace) {
    hookErrors.add(error);
  }
}

class ThrowingErrorHookFutureNotifier<T> extends TestFutureNotifier<T> {
  ThrowingErrorHookFutureNotifier({
    required super.buildImpl,
    super.initialState,
    super.disableEmptyState,
  });

  @override
  void onError(Object error, StackTrace stackTrace) {
    throw StateError('onError hook failed');
  }
}

/// Requests a replacement build when an error is reported through onError.
class RebuildingErrorHookFutureNotifier<T> extends TestFutureNotifier<T> {
  RebuildingErrorHookFutureNotifier({required super.buildImpl});

  @override
  void onError(Object error, StackTrace stackTrace) {
    unawaited(requestRebuild());
  }
}

class _CapturedFailure {
  const _CapturedFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

Future<_CapturedFailure> captureFailure(Future<void> future) {
  final captured = future.then<_CapturedFailure>(
    (_) {
      fail('Expected the Future to fail, but it completed successfully.');
    },
    onError: (Object error, StackTrace stackTrace) =>
        _CapturedFailure(error, stackTrace),
  );

  return captured.timeout(
    _testTimeout,
    onTimeout: () => throw TimeoutException(
      'The Future did not complete within $_testTimeout.',
    ),
  );
}

Future<void> expectFutureFailure(
  Future<void> future,
  Object expectedError, {
  StackTrace? expectedStackTrace,
}) async {
  final failure = await captureFailure(future);
  expect(failure.error, same(expectedError));
  if (expectedStackTrace != null) {
    expect(failure.stackTrace, same(expectedStackTrace));
  }
}

Future<void> waitForState<T>(
  FutureNotifier<T> notifier,
  bool Function(ViewState<T> state) predicate,
) async {
  if (!predicate(notifier.state)) {
    final completer = Completer<void>();
    void listener() {
      if (!completer.isCompleted && predicate(notifier.state)) {
        completer.complete();
      }
    }

    notifier.addListener(listener);
    // Re-check after registering so this helper remains safe if its
    // implementation later gains a synchronous scheduling boundary.
    listener();

    try {
      await completer.future.timeout(
        _testTimeout,
        onTimeout: () => throw TimeoutException(
          'FutureNotifier did not reach the expected state within '
          '$_testTimeout.',
        ),
      );
    } finally {
      notifier.removeListener(listener);
    }
  }

  // State notification happens just before the build operation itself is
  // fully settled. Let pending microtasks finish before a test starts another
  // operation, so it cannot accidentally join the just-finishing operation.
  await flushPendingTasks();
}

Future<void> flushPendingTasks() =>
    Future<void>.delayed(Duration.zero).timeout(_testTimeout);

VoidCallback captureFlutterErrors(List<FlutterErrorDetails> destination) {
  final previousHandler = FlutterError.onError;
  FlutterError.onError = destination.add;
  return () {
    FlutterError.onError = previousHandler;
  };
}

void main() {
  group('FutureNotifier', () {
    late List<FlutterErrorDetails> unexpectedFlutterErrors;

    setUp(() {
      unexpectedFlutterErrors = <FlutterErrorDetails>[];
      addTearDown(captureFlutterErrors(unexpectedFlutterErrors));
    });

    tearDown(() {
      expect(
        unexpectedFlutterErrors,
        isEmpty,
        reason:
            'Unexpected errors were reported through '
            'FlutterError.reportError.',
      );
    });

    group('initial build and state mapping', () {
      test(
        'defaults to LoadingState and runs the initial build automatically',
        () async {
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) async => 'loaded',
          );
          addTearDown(notifier.dispose);

          expect(notifier.state, isA<LoadingState<String>>());
          expect(notifier.buildCount, 0);
          await notifier.waitForBuildStart(1);
          await waitForState(notifier, (state) => state is DataState<String>);

          expect(notifier.buildCount, 1);
          expect(notifier.state, const DataState<String>('loaded'));
        },
      );

      test(
        'uses configured messages for generated loading and empty states',
        () async {
          final rebuildGate = Completer<List<int>>();

          final notifier = TestFutureNotifier<List<int>>(
            loadingMessage: 'products.loading',
            emptyMessage: 'products.empty',
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                return Future<List<int>>.value(<int>[]);
              }

              return rebuildGate.future;
            },
          );
          addTearDown(notifier.dispose);

          // Initial loading state uses the configured message.
          expect(notifier.state, isA<LoadingState<List<int>>>());
          expect(
            (notifier.state as LoadingState<List<int>>).message,
            'products.loading',
          );

          // An empty build result uses the configured empty message.
          await waitForState(
            notifier,
            (state) => state is EmptyState<List<int>>,
          );

          expect(
            (notifier.state as EmptyState<List<int>>).message,
            'products.empty',
          );

          // A rebuild transitions back to loading with the same message.
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);

          expect(notifier.state, isA<LoadingState<List<int>>>());
          expect(
            (notifier.state as LoadingState<List<int>>).message,
            'products.loading',
          );

          // The next empty result also uses the configured empty message.
          rebuildGate.complete(<int>[]);
          await rebuildFuture.timeout(_testTimeout);

          expect(notifier.state, isA<EmptyState<List<int>>>());
          expect(
            (notifier.state as EmptyState<List<int>>).message,
            'products.empty',
          );
        },
      );

      test(
        'respects initialState before the scheduled initial build',
        () async {
          final notifier = TestFutureNotifier<String>(
            initialState: const DataState<String>('provided'),
            buildImpl: (_) async => 'loaded',
          );
          addTearDown(notifier.dispose);

          expect(notifier.state, const DataState<String>('provided'));
          await notifier.waitForBuildStart(1);
          await waitForState(
            notifier,
            (state) => state is DataState<String> && state.data == 'loaded',
          );
          expect(notifier.state, const DataState<String>('loaded'));
        },
      );

      test('waits until the subclass constructor body has completed', () async {
        final notifier = ConstructorDependentFutureNotifier();
        addTearDown(notifier.dispose);

        expect(notifier.state, isA<LoadingState<String>>());
        await waitForState(notifier, (state) => state is DataState<String>);
        expect(
          notifier.state,
          const DataState<String>('initialized after super'),
        );
      });

      test('publishes a successful build result as DataState', () async {
        final notifier = TestFutureNotifier<int>(buildImpl: (_) async => 42);
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<int>);
        expect(notifier.state, const DataState<int>(42));
      });

      test('maps an empty Iterable to EmptyState by default', () async {
        final notifier = TestFutureNotifier<List<int>>(
          buildImpl: (_) async => <int>[],
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is EmptyState<List<int>>);
        expect(notifier.state, isA<EmptyState<List<int>>>());
      });

      test('publishes an empty Iterable as DataState when disabled', () async {
        final notifier = TestFutureNotifier<List<int>>(
          disableEmptyState: true,
          buildImpl: (_) async => <int>[],
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<List<int>>);
        expect(notifier.state, isA<DataState<List<int>>>());
        expect((notifier.state as DataState<List<int>>).data, isEmpty);
      });

      test('a non-empty Iterable is published as DataState', () async {
        final notifier = TestFutureNotifier<List<int>>(
          buildImpl: (_) async => <int>[1, 2, 3],
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<List<int>>);
        expect((notifier.state as DataState<List<int>>).data, <int>[1, 2, 3]);
      });

      test('an empty Map is published as DataState', () async {
        final notifier = TestFutureNotifier<Map<String, int>>(
          buildImpl: (_) async => <String, int>{},
        );
        addTearDown(notifier.dispose);

        await waitForState(
          notifier,
          (state) => state is DataState<Map<String, int>>,
        );
        expect((notifier.state as DataState<Map<String, int>>).data, isEmpty);
      });

      test('an empty String is published as DataState', () async {
        final notifier = TestFutureNotifier<String>(buildImpl: (_) async => '');
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        expect((notifier.state as DataState<String>).data, '');
      });

      test('a nullable null result is published as DataState(null)', () async {
        final notifier = TestFutureNotifier<String?>(
          buildImpl: (_) async => null,
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String?>);
        expect((notifier.state as DataState<String?>).data, isNull);
      });

      test('an initial asynchronous failure becomes ErrorState', () async {
        final error = Exception('initial failure');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (_) async =>
              Future<String>.error(error, StackTrace.current),
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is ErrorState<String>);
        final state = notifier.state as ErrorState<String>;
        expect(state.error, same(error));
        expect(state.message, contains('initial failure'));
        expect(state.onRetry, isNotNull);
      });

      test(
        'a synchronous throw from build is handled as a build failure',
        () async {
          final error = StateError('synchronous build failure');
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) => throw error,
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          await waitForState(notifier, (state) => state is ErrorState<String>);
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );
    });

    group('error handling and retry', () {
      test('retry callback runs another build and can recover', () async {
        var buildCount = 0;
        final notifier = TestFutureNotifier<String>(
          buildImpl: (_) async {
            buildCount++;
            if (buildCount == 1) throw Exception('temporary failure');
            return 'recovered';
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is ErrorState<String>);
        final errorState = notifier.state as ErrorState<String>;
        expect(errorState.onRetry, isNotNull);

        errorState.onRetry!.call();
        await waitForState(
          notifier,
          (state) => state is DataState<String> && state.data == 'recovered',
        );

        expect(buildCount, 2);
        expect(notifier.state, const DataState<String>('recovered'));
      });

      test('default retry absorbs a failed fire-and-forget refresh', () async {
        final initialError = Exception('initial failure');
        final retryError = StateError('retry refresh failed');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) throw initialError;
            throw retryError;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(
          notifier,
          (state) =>
              state is ErrorState<String> &&
              identical(state.error, initialError),
        );

        final retry = (notifier.state as ErrorState<String>).onRetry;
        expect(retry, isNotNull);

        // The default retry callback intentionally does not expose or await
        // the Future returned by refresh(). A second build failure must be
        // absorbed rather than surfacing as an unhandled asynchronous error.
        retry!.call();

        await notifier.waitForBuildStart(2);
        await waitForState(
          notifier,
          (state) =>
              state is ErrorState<String> && identical(state.error, retryError),
        );

        expect(notifier.buildCount, 2);
        expect((notifier.state as ErrorState<String>).error, same(retryError));
      });

      test(
        'default empty-state refresh absorbs a failed fire-and-forget refresh',
        () async {
          final refreshError = StateError('empty refresh failed');

          final notifier = TestFutureNotifier<List<int>>(
            buildImpl: (buildNumber) async {
              if (buildNumber == 1) return <int>[];
              throw refreshError;
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(
            notifier,
            (state) => state is EmptyState<List<int>>,
          );

          final emptyState = notifier.state as EmptyState<List<int>>;
          final onRefresh = emptyState.onRefresh;

          expect(onRefresh, isNotNull);

          // The generated UI callback is fire-and-forget.
          onRefresh!.call();

          await notifier.waitForBuildStart(2);

          await waitForState(
            notifier,
            (state) =>
                state is ErrorState<List<int>> &&
                identical(state.error, refreshError),
          );

          expect(notifier.buildCount, 2);
          expect(
            (notifier.state as ErrorState<List<int>>).error,
            same(refreshError),
          );
        },
      );

      test('an onError hook that rebuilds lets a refresh waiter follow '
          'the replacement', () async {
        final initialGate = Completer<String>();
        final initialError = StateError('initial build failed');
        final notifier = RebuildingErrorHookFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return initialGate.future;
            return Future<String>.value('replacement');
          },
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final refreshFuture = notifier.refresh();
        initialGate.completeError(initialError, StackTrace.current);

        await refreshFuture.timeout(
          _testTimeout,
          onTimeout: () => throw TimeoutException(
            'Refresh did not follow the replacement build.',
          ),
        );

        expect(notifier.buildCount, 2);
        expect(notifier.state, const DataState<String>('replacement'));
      });

      test('refresh without usable data propagates its error and publishes '
          'ErrorState', () async {
        final initialError = Exception('initial error');
        final refreshError = Exception('refresh error');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) throw initialError;
            throw refreshError;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is ErrorState<String>);
        await expectFutureFailure(notifier.refresh(), refreshError);
        expect(
          (notifier.state as ErrorState<String>).error,
          same(refreshError),
        );
        expect(notifier.buildCount, 2);
      });

      test('preserves existing data when a refresh fails', () async {
        final refreshError = Exception('remote refresh failed');
        final notifier = RecordingErrorFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) return 'cached data';
            throw refreshError;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        await expectFutureFailure(notifier.refresh(), refreshError);

        expect(notifier.state, const DataState<String>('cached data'));
        // With usable data retained, the notifier reports to the observer
        // without invoking the overridable onError hook.
        expect(notifier.hookErrors, isEmpty);
      });

      test(
        'invokes onError when a failure cannot preserve usable data',
        () async {
          final error = Exception('no data available');
          final notifier = RecordingErrorFutureNotifier<String>(
            buildImpl: (_) async => throw error,
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is ErrorState<String>);
          expect(notifier.hookErrors, hasLength(1));
          expect(notifier.hookErrors.single, same(error));
        },
      );

      test(
        'preserves initial cached data when the initial build fails',
        () async {
          final error = Exception('revalidation failed');
          final notifier = RecordingErrorFutureNotifier<String>(
            initialState: const DataState<String>('cached value'),
            buildImpl: (_) async => throw error,
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          await flushPendingTasks();

          expect(notifier.state, const DataState<String>('cached value'));
          expect(notifier.hookErrors, isEmpty);
        },
      );

      test(
        'preserves intermediate cached data when a remote build fails',
        () async {
          final error = Exception('remote request failed');
          late RecordingErrorFutureNotifier<String> notifier;
          notifier = RecordingErrorFutureNotifier<String>(
            buildImpl: (_) async {
              notifier.writeState(
                const DataState<String>('intermediate cache'),
              );
              throw error;
            },
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          await flushPendingTasks();

          expect(notifier.state, const DataState<String>('intermediate cache'));
          expect(notifier.hookErrors, isEmpty);
        },
      );

      test('an explicit ErrorState assignment overrides data-preservation '
          'behavior', () async {
        final error = Exception('explicit error state');
        late TestFutureNotifier<String> notifier;
        notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) return 'cached';
            notifier.writeState(ErrorState<String>(error, StackTrace.current));
            throw error;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        await expectFutureFailure(notifier.refresh(), error);

        expect(notifier.state, isA<ErrorState<String>>());
        expect((notifier.state as ErrorState<String>).error, same(error));
      });

      test(
        'preserves the original error and stack trace from refresh',
        () async {
          final error = StateError('trace preservation');
          final stackTrace = StackTrace.current;
          final gate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) return Future<String>.value('ready');
              return gate.future;
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is DataState<String>);
          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          final failureFuture = captureFailure(refreshFuture);
          gate.completeError(error, stackTrace);

          final failure = await failureFuture;
          expect(failure.error, same(error));
          expect(failure.stackTrace, same(stackTrace));
          expect(notifier.state, const DataState<String>('ready'));
        },
      );

      test('an onError hook exception is reported without replacing the '
          'build error', () async {
        final reported = <FlutterErrorDetails>[];
        addTearDown(captureFlutterErrors(reported));

        final originalError = Exception('original failure');
        final notifier = ThrowingErrorHookFutureNotifier<String>(
          buildImpl: (_) async => throw originalError,
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is ErrorState<String>);

        expect(
          (notifier.state as ErrorState<String>).error,
          same(originalError),
        );
        expect(reported, hasLength(1));
        expect(reported.single.exception, isA<StateError>());
        expect(
          reported.single.exception.toString(),
          contains('onError hook failed'),
        );

        // A hook failure must not replace the original error propagated by an
        // explicitly awaited operation.
        await expectFutureFailure(notifier.refresh(), originalError);
        expect(
          (notifier.state as ErrorState<String>).error,
          same(originalError),
        );
        expect(reported, hasLength(2));
        expect(
          reported.every(
            (details) =>
                details.exception is StateError &&
                details.exception.toString().contains('onError hook failed'),
          ),
          isTrue,
        );
      });
    });

    group('refresh', () {
      test('starts a new build after the previous build completed', () async {
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async => 'data$buildNumber',
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        expect(notifier.state, const DataState<String>('data1'));

        await notifier.refresh().timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('data2'));
        await notifier.refresh().timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('data3'));
        expect(notifier.buildCount, 3);
      });

      test('preserves data until the refresh succeeds', () async {
        final gate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<String>.value('before');
            return gate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        final refreshFuture = notifier.refresh();
        await notifier.waitForBuildStart(2);

        expect(notifier.state, const DataState<String>('before'));
        gate.complete('after');
        await refreshFuture.timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('after'));
      });

      test('refresh from EmptyState shows LoadingState while the refresh '
          'is pending', () async {
        final refreshGate = Completer<List<int>>();
        final notifier = TestFutureNotifier<List<int>>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<List<int>>.value(<int>[]);
            return refreshGate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is EmptyState<List<int>>);

        final refreshFuture = notifier.refresh();
        await notifier.waitForBuildStart(2);
        expect(notifier.state, isA<LoadingState<List<int>>>());

        refreshGate.complete(<int>[1]);
        await refreshFuture.timeout(_testTimeout);
        expect(notifier.state, isA<DataState<List<int>>>());
        expect((notifier.state as DataState<List<int>>).data, <int>[1]);
      });

      test('refresh joins an initial build that is still running', () async {
        final gate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (_) => gate.future,
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final refreshFuture = notifier.refresh();
        expect(notifier.buildCount, 1);

        gate.complete('initial result');
        await refreshFuture.timeout(_testTimeout);
        expect(notifier.buildCount, 1);
        expect(notifier.state, const DataState<String>('initial result'));
      });

      test(
        'refresh invalidates staleness even when it joins a running build',
        () async {
          final gate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) => gate.future,
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          final isStale = notifier.captureStaleness();
          expect(isStale(), isFalse);

          final refreshFuture = notifier.refresh();
          expect(notifier.buildCount, 1);
          expect(isStale(), isTrue);

          gate.complete('result');
          await refreshFuture.timeout(_testTimeout);
          expect(notifier.state, const DataState<String>('result'));
        },
      );

      test(
        'concurrent refresh calls join the same in-flight refresh',
        () async {
          final gate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) return Future<String>.value('initial');
              return gate.future;
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is DataState<String>);
          final first = notifier.refresh();
          await notifier.waitForBuildStart(2);
          final second = notifier.refresh();
          final third = notifier.refresh();

          expect(notifier.buildCount, 2);
          expect(notifier.state, const DataState<String>('initial'));

          gate.complete('updated');
          await Future.wait<void>(<Future<void>>[
            first,
            second,
            third,
          ]).timeout(_testTimeout);

          expect(notifier.state, const DataState<String>('updated'));
          expect(notifier.buildCount, 2);
        },
      );

      test(
        'concurrent refresh callers receive the same current failure',
        () async {
          final gate = Completer<String>();
          final error = StateError('shared refresh failure');
          final stackTrace = StackTrace.current;
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) return Future<String>.value('initial');
              return gate.future;
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is DataState<String>);
          final first = notifier.refresh();
          await notifier.waitForBuildStart(2);
          final second = notifier.refresh();
          final firstFailure = captureFailure(first);
          final secondFailure = captureFailure(second);

          gate.completeError(error, stackTrace);
          final failures = await Future.wait<_CapturedFailure>(
            <Future<_CapturedFailure>>[firstFailure, secondFailure],
          );

          expect(failures[0].error, same(error));
          expect(failures[0].stackTrace, same(stackTrace));
          expect(failures[1].error, same(error));
          expect(failures[1].stackTrace, same(stackTrace));
          expect(notifier.state, const DataState<String>('initial'));
          expect(notifier.buildCount, 2);
        },
      );

      test(
        'a later refresh can recover after an earlier refresh failure',
        () async {
          final refreshError = Exception('first refresh failed');
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) async {
              if (buildNumber == 1) return 'initial';
              if (buildNumber == 2) throw refreshError;
              return 'recovered';
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is DataState<String>);
          await expectFutureFailure(notifier.refresh(), refreshError);
          expect(notifier.state, const DataState<String>('initial'));

          await notifier.refresh().timeout(_testTimeout);
          expect(notifier.state, const DataState<String>('recovered'));
          expect(notifier.buildCount, 3);
        },
      );

      test(
        'fire-and-forget refresh absorbs a build failure while preserving data',
        () async {
          final refreshError = StateError('unawaited refresh failed');
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) async {
              if (buildNumber == 1) return 'cached value';
              throw refreshError;
            },
          );
          addTearDown(notifier.dispose);

          await waitForState(notifier, (state) => state is DataState<String>);

          // Intentionally do not await the Future. The notifier's refresh
          // contract must prevent this failure from becoming unhandled.
          unawaited(notifier.refresh());

          await notifier.waitForBuildStart(2);
          await flushPendingTasks();

          expect(notifier.buildCount, 2);
          expect(notifier.state, const DataState<String>('cached value'));
        },
      );

      test('staleness callbacks are invalidated when refresh starts', () async {
        final gate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<String>.value('initial');
            return gate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        final isStale = notifier.captureStaleness();
        expect(isStale(), isFalse);

        final refreshFuture = notifier.refresh();
        await notifier.waitForBuildStart(2);
        expect(isStale(), isTrue);

        gate.complete('updated');
        await refreshFuture.timeout(_testTimeout);
      });
    });

    group('rebuild and stale operation protection', () {
      test('rebuild clears data while loading different inputs', () async {
        final gate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<String>.value('old inputs');
            return gate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);

        expect(notifier.state, isA<LoadingState<String>>());
        gate.complete('new inputs');
        await rebuildFuture.timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('new inputs'));
      });

      test('failed rebuild publishes LoadingState before ErrorState', () async {
        final failureGate = Completer<String>();
        final error = StateError('rebuild failed');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<String>.value('initial');
            return failureGate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        final emittedStates = <ViewState<String>>[];
        void recordState() => emittedStates.add(notifier.state);
        notifier.addListener(recordState);
        addTearDown(() => notifier.removeListener(recordState));

        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);
        expect(notifier.state, isA<LoadingState<String>>());

        final failureFuture = captureFailure(rebuildFuture);
        failureGate.completeError(error, StackTrace.current);
        final failure = await failureFuture;

        expect(failure.error, same(error));
        expect(emittedStates, contains(isA<LoadingState<String>>()));
        expect(emittedStates, contains(isA<ErrorState<String>>()));
        final loadingIndex = emittedStates.indexWhere(
          (state) => state is LoadingState<String>,
        );
        final errorIndex = emittedStates.indexWhere(
          (state) => state is ErrorState<String>,
        );
        expect(loadingIndex, greaterThanOrEqualTo(0));
        expect(errorIndex, greaterThan(loadingIndex));
      });

      test('fire-and-forget rebuild absorbs a build failure', () async {
        final rebuildError = StateError('unawaited rebuild failed');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) return 'initial value';
            throw rebuildError;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);

        // Intentionally do not await the returned Future. The failed rebuild
        // should update notifier state, not leak an unhandled Future error.
        unawaited(notifier.requestRebuild());

        await waitForState(
          notifier,
          (state) =>
              state is ErrorState<String> &&
              identical(state.error, rebuildError),
        );

        expect(notifier.buildCount, 2);
        expect(
          (notifier.state as ErrorState<String>).error,
          same(rebuildError),
        );
      });

      test(
        'a stale build result cannot replace a newer build result',
        () async {
          final oldGate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) return oldGate.future;
              return Future<String>.value('new result');
            },
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await rebuildFuture.timeout(_testTimeout);
          expect(notifier.state, const DataState<String>('new result'));

          oldGate.complete('stale result');
          await flushPendingTasks();
          expect(notifier.state, const DataState<String>('new result'));
          expect(notifier.buildCount, 2);
        },
      );

      test('a stale build cannot assign state after an await', () async {
        final oldGate = Completer<void>();
        final oldWriteAttempted = Completer<void>();
        late TestFutureNotifier<String> notifier;

        notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async {
            if (buildNumber == 1) {
              await oldGate.future;
              notifier.writeState(
                const DataState<String>('stale manual write'),
              );
              oldWriteAttempted.complete();
              return 'stale returned value';
            }
            return 'current value';
          },
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);
        await rebuildFuture.timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('current value'));

        oldGate.complete();
        await oldWriteAttempted.future;
        await flushPendingTasks();
        expect(notifier.state, const DataState<String>('current value'));
      });

      test(
        'a timer created by a superseded build cannot overwrite current state',
        () async {
          final obsoleteGate = Completer<String>();
          final timerAttempted = Completer<void>();
          late TestFutureNotifier<String> notifier;

          notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                Timer.run(() {
                  notifier.writeState(
                    const DataState<String>('stale timer write'),
                  );
                  if (!timerAttempted.isCompleted) timerAttempted.complete();
                });
                return obsoleteGate.future;
              }
              return Future<String>.value('replacement result');
            },
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await rebuildFuture.timeout(_testTimeout);
          expect(notifier.state, const DataState<String>('replacement result'));

          await timerAttempted.future.timeout(
            _testTimeout,
            onTimeout: () => throw TimeoutException('Stale timer did not run.'),
          );
          expect(notifier.state, const DataState<String>('replacement result'));

          // Release the obsolete operation so this test leaves no pending work.
          obsoleteGate.complete('obsolete result');
          await flushPendingTasks();
        },
      );

      test(
        'a current build may publish an intermediate state after an await',
        () async {
          final gate = Completer<void>();
          final intermediateWritten = Completer<void>();
          late TestFutureNotifier<String> notifier;
          final observedStates = <ViewState<String>>[];

          notifier = TestFutureNotifier<String>(
            buildImpl: (_) async {
              await gate.future;
              notifier.writeState(const DataState<String>('intermediate'));
              intermediateWritten.complete();
              return 'final';
            },
          );
          addTearDown(notifier.dispose);
          notifier.addListener(() => observedStates.add(notifier.state));

          await notifier.waitForBuildStart(1);
          gate.complete();
          await intermediateWritten.future;
          await waitForState(
            notifier,
            (state) => state is DataState<String> && state.data == 'final',
          );

          expect(
            observedStates,
            contains(const DataState<String>('intermediate')),
          );
          expect(notifier.state, const DataState<String>('final'));
        },
      );

      test('a rebuild requested synchronously after construction runs '
          'only one build', () async {
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) async => 'build$buildNumber',
        );
        addTearDown(notifier.dispose);

        final rebuildFuture = notifier.requestRebuild();
        await rebuildFuture.timeout(
          _testTimeout,
          onTimeout: () =>
              throw TimeoutException('Immediate rebuild did not complete.'),
        );
        await flushPendingTasks();

        expect(notifier.buildCount, 1);
        expect(notifier.state, const DataState<String>('build1'));
      });

      test('multiple pending rebuild requests coalesce', () async {
        final initialGate = Completer<String>();
        final replacementGate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return initialGate.future;
            if (buildNumber == 2) return replacementGate.future;
            return Future<String>.value('unexpected build $buildNumber');
          },
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final firstRebuild = notifier.requestRebuild();
        final secondRebuild = notifier.requestRebuild();

        await notifier.waitForBuildStart(2);
        expect(notifier.buildCount, 2);
        replacementGate.complete('replacement');
        await Future.wait<void>(<Future<void>>[
          firstRebuild,
          secondRebuild,
        ]).timeout(_testTimeout);
        expect(notifier.state, const DataState<String>('replacement'));

        initialGate.complete('obsolete initial result');
        await flushPendingTasks();
        expect(notifier.state, const DataState<String>('replacement'));
        expect(notifier.buildCount, 2);
      });

      test(
        'refresh waiter follows a replacement rebuild instead of obsolete work',
        () async {
          final oldGate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) return oldGate.future;
              return Future<String>.value('replacement result');
            },
          );
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          final refreshFuture = notifier.refresh();
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await rebuildFuture.timeout(_testTimeout);

          // The waiter must finish with the replacement even though the old
          // build is still awaiting oldGate.
          await refreshFuture.timeout(_testTimeout);
          expect(notifier.state, const DataState<String>('replacement result'));
          expect(notifier.buildCount, 2);

          oldGate.complete('obsolete result');
          await flushPendingTasks();
        },
      );

      test('an obsolete build error does not fail a waiter following '
          'its replacement', () async {
        final oldGate = Completer<String>();
        final obsoleteError = Exception('obsolete failure');
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return oldGate.future;
            return Future<String>.value('replacement result');
          },
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final refreshFuture = notifier.refresh();
        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);
        await rebuildFuture.timeout(_testTimeout);

        // The waiter must resolve before obsolete work finishes or errors.
        await refreshFuture.timeout(_testTimeout);

        oldGate.completeError(obsoleteError, StackTrace.current);
        await flushPendingTasks();
        expect(notifier.state, const DataState<String>('replacement result'));
        expect(notifier.buildCount, 2);
      });

      test('failure from the latest rebuild propagates with its original '
          'stack trace', () async {
        final obsoleteGate = Completer<String>();
        final currentGate = Completer<String>();
        final currentError = StateError('current rebuild failed');
        final currentStack = StackTrace.current;
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return obsoleteGate.future;
            return currentGate.future;
          },
        );
        addTearDown(notifier.dispose);

        await notifier.waitForBuildStart(1);
        final refreshFuture = notifier.refresh();
        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);

        final rebuildFailureFuture = captureFailure(rebuildFuture);
        final refreshFailureFuture = captureFailure(refreshFuture);
        currentGate.completeError(currentError, currentStack);
        final rebuildFailure = await rebuildFailureFuture;
        final refreshFailure = await refreshFailureFuture;
        expect(rebuildFailure.error, same(currentError));
        expect(rebuildFailure.stackTrace, same(currentStack));
        expect(refreshFailure.error, same(currentError));
        expect(refreshFailure.stackTrace, same(currentStack));
        expect(
          (notifier.state as ErrorState<String>).error,
          same(currentError),
        );

        // Release the superseded build so the test leaves no in-flight work.
        obsoleteGate.complete('obsolete');
        await flushPendingTasks();
      });

      test('a staleness callback is invalidated when rebuild starts', () async {
        final gate = Completer<String>();
        final notifier = TestFutureNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) return Future<String>.value('initial');
            return gate.future;
          },
        );
        addTearDown(notifier.dispose);

        await waitForState(notifier, (state) => state is DataState<String>);
        final isStale = notifier.captureStaleness();
        expect(isStale(), isFalse);

        final rebuildFuture = notifier.requestRebuild();
        await notifier.waitForBuildStart(2);
        expect(isStale(), isTrue);
        gate.complete('rebuilt');
        await rebuildFuture.timeout(_testTimeout);
      });

      test('listener-triggered state assignment is not rejected as a '
          'stale build write', () async {
        final notifier = TestFutureNotifier<String>(
          buildImpl: (_) async => 'build result',
        );
        addTearDown(notifier.dispose);

        var wroteFromListener = false;
        void listener() {
          if (!wroteFromListener &&
              notifier.state is DataState<String> &&
              (notifier.state as DataState<String>).data == 'build result') {
            wroteFromListener = true;
            notifier.writeState(const DataState<String>('listener result'));
          }
        }

        notifier.addListener(listener);
        addTearDown(() => notifier.removeListener(listener));

        await waitForState(
          notifier,
          (state) =>
              state is DataState<String> && state.data == 'listener result',
        );
        expect(notifier.state, const DataState<String>('listener result'));
      });
    });

    group('disposal', () {
      test(
        'dispose while a build is pending prevents a later data update',
        () async {
          final gate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) => gate.future,
          );
          await notifier.waitForBuildStart(1);

          var notifications = 0;
          notifier.addListener(() => notifications++);
          notifier.dispose();
          gate.complete('too late');
          await flushPendingTasks();

          expect(notifier.state, isA<LoadingState<String>>());
          expect(notifications, 0);
        },
      );

      test(
        'dispose while a build is pending prevents a later error state update',
        () async {
          final gate = Completer<String>();
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) => gate.future,
          );
          await notifier.waitForBuildStart(1);
          notifier.dispose();

          gate.completeError(Exception('late failure'), StackTrace.current);
          await flushPendingTasks();
          expect(notifier.state, isA<LoadingState<String>>());
        },
      );

      test('staleness callbacks become stale when disposed', () async {
        final notifier = TestFutureNotifier<String>(
          buildImpl: (_) async => 'ready',
        );
        await waitForState(notifier, (state) => state is DataState<String>);
        final isStale = notifier.captureStaleness();
        expect(isStale(), isFalse);

        notifier.dispose();
        expect(isStale(), isTrue);
      });

      test(
        'refresh after disposal completes without starting another build',
        () async {
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) async => 'ready',
          );
          await waitForState(notifier, (state) => state is DataState<String>);
          expect(notifier.buildCount, 1);

          notifier.dispose();
          await notifier.refresh().timeout(_testTimeout);

          expect(notifier.buildCount, 1);
          expect(notifier.state, const DataState<String>('ready'));
        },
      );

      test(
        'rebuild after disposal completes without starting another build',
        () async {
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) async => 'should not run',
          );
          notifier.dispose();

          await notifier.requestRebuild().timeout(
            _testTimeout,
            onTimeout: () => throw TimeoutException(
              'Rebuild after disposal did not complete.',
            ),
          );
          await flushPendingTasks();

          expect(notifier.buildCount, 0);
          expect(notifier.state, isA<LoadingState<String>>());
        },
      );

      test(
        'disposing before the scheduled initial build prevents it from running',
        () async {
          final notifier = TestFutureNotifier<String>(
            buildImpl: (_) async => 'should not run',
          );
          notifier.dispose();
          await flushPendingTasks();

          expect(notifier.buildCount, 0);
          expect(notifier.state, isA<LoadingState<String>>());
        },
      );
    });
  });
}
