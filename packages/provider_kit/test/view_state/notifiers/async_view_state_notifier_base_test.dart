import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

const _testTimeout = Duration(seconds: 3);

/// Uses FutureNotifier only as a concrete test vehicle for the inherited,
/// shared AsyncViewStateNotifier contract. These tests do not test
/// FutureNotifier-specific result or error-propagation behavior.
class _TestAsyncViewStateNotifier<T> extends FutureNotifier<T> {
  _TestAsyncViewStateNotifier({
    required this.buildImpl,
    super.startInitialBuild,
    super.enableEmptyState,
    super.loadingMessage,
    super.emptyMessage,
  });

  final Future<T> Function(int buildNumber) buildImpl;
  final Map<int, Completer<void>> _buildStarts = {};

  int buildCount = 0;
  final List<(Object, StackTrace)> dispatchedErrors = [];

  @override
  Future<T> build() {
    final buildNumber = ++buildCount;
    final started = _buildStarts.putIfAbsent(
      buildNumber,
      () => Completer<void>(),
    );
    if (!started.isCompleted) started.complete();
    return buildImpl(buildNumber);
  }

  Future<void> waitForBuildStart(int buildNumber) {
    final started = _buildStarts.putIfAbsent(
      buildNumber,
      () => Completer<void>(),
    );
    return started.future.timeout(
      _testTimeout,
      onTimeout: () => throw TimeoutException(
        'Async notifier build $buildNumber did not start within $_testTimeout.',
      ),
    );
  }

  void setInitialForTest() => setInitial();

  void setLoadingForTest([String? message, double? progress]) =>
      setLoading(message: message, progress: progress);

  void setDataForTest(T data) => setData(data);

  void setEmptyForTest([String? message]) => setEmpty(message);

  void setErrorForTest(Object error, StackTrace stackTrace) =>
      setError(error, stackTrace);

  bool Function() captureStaleness() => checkStaleness();

  Future<void> rebuildForTest() => rebuild();

  void invalidateBuildForTest() => invalidateBuild();

  void writeStateForTest(ViewState<T> value) => state = value;

  @override
  void onError(Object error, StackTrace stackTrace) {
    dispatchedErrors.add((error, stackTrace));
  }
}

class _ConstructorDependentNotifier extends FutureNotifier<String> {
  _ConstructorDependentNotifier() {
    _value = 'initialized after constructor';
  }

  late final String _value;

  @override
  Future<String> build() async => _value;
}

Future<void> _flushPendingTasks() =>
    Future<void>.delayed(Duration.zero).timeout(_testTimeout);

Future<void> _waitForState<T>(
  FutureNotifier<T> notifier,
  bool Function(ViewState<T> state) predicate, {
  String description = 'expected notifier state',
}) async {
  if (!predicate(notifier.state)) {
    final completer = Completer<void>();

    void listener() {
      if (!completer.isCompleted && predicate(notifier.state)) {
        completer.complete();
      }
    }

    notifier.addListener(listener);
    listener();
    try {
      await completer.future.timeout(
        _testTimeout,
        onTimeout: () =>
            throw TimeoutException('Timed out waiting for $description.'),
      );
    } finally {
      notifier.removeListener(listener);
    }
  }

  // State notification may happen just before the managed operation settles.
  await _flushPendingTasks();
}

_TestAsyncViewStateNotifier<T> _pendingNotifier<T>({
  String? loadingMessage,
  String? emptyMessage,
  bool enableEmptyState = true,
}) {
  return _TestAsyncViewStateNotifier<T>(
    loadingMessage: loadingMessage,
    emptyMessage: emptyMessage,
    enableEmptyState: enableEmptyState,
    buildImpl: (_) => Completer<T>().future,
  );
}

class _InitializingTestNotifier extends _TestAsyncViewStateNotifier<int> {
  _InitializingTestNotifier({
    required super.buildImpl,
    required this.events,
    this.initializationError,
  });

  final List<String> events;
  final Object? initializationError;

  @override
  void onInitialize() {
    events.add('initialize');
    super.onInitialize();

    final error = initializationError;
    if (error != null) {
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  @override
  Future<int> build() {
    events.add('build');
    return super.build();
  }
}

class _CachedInitializingTestNotifier extends _InitializingTestNotifier {
  _CachedInitializingTestNotifier({
    required super.buildImpl,
    required super.events,
  });

  @override
  void onInitialize() {
    super.onInitialize();
    setDataForTest(41);
  }
}

void main() {
  setUp(ProviderKit.resetForTesting);

  group('AsyncViewStateNotifierBase shared behavior', () {
    group('state-setting helpers', () {
      test('setInitial sets InitialState', () async {
        final notifier = _pendingNotifier<String>();
        addTearDown(notifier.dispose);
        await notifier.waitForBuildStart(1);

        notifier.setInitialForTest();

        expect(notifier.state, isA<InitialState<String>>());
      });

      test(
        'setLoading uses defaults and supports message and progress overrides',
        () async {
          final notifier = _pendingNotifier<String>(
            loadingMessage: 'default.loading',
          );
          addTearDown(notifier.dispose);
          await notifier.waitForBuildStart(1);

          notifier.setLoadingForTest();
          expect(
            notifier.state,
            isA<LoadingState<String>>()
                .having((state) => state.message, 'message', 'default.loading')
                .having((state) => state.progress, 'progress', isNull),
          );

          notifier.setLoadingForTest('uploading', 0.6);
          expect(
            notifier.state,
            isA<LoadingState<String>>()
                .having((state) => state.message, 'message', 'uploading')
                .having((state) => state.progress, 'progress', 0.6),
          );
        },
      );

      test('setData sets DataState with the supplied data', () async {
        final notifier = _pendingNotifier<List<int>>();
        addTearDown(notifier.dispose);
        await notifier.waitForBuildStart(1);

        notifier.setDataForTest(<int>[1, 2, 3]);

        expect(
          notifier.state,
          isA<DataState<List<int>>>().having(
            (state) => state.data,
            'data',
            <int>[1, 2, 3],
          ),
        );
      });

      test(
        'setEmpty uses the default message and provides onRefresh',
        () async {
          final notifier = _pendingNotifier<List<int>>(
            emptyMessage: 'default.empty',
          );
          addTearDown(notifier.dispose);
          await notifier.waitForBuildStart(1);

          notifier.setEmptyForTest();

          expect(
            notifier.state,
            isA<EmptyState<List<int>>>()
                .having((state) => state.message, 'message', 'default.empty')
                .having((state) => state.onRefresh, 'onRefresh', isNotNull),
          );

          notifier.setEmptyForTest('custom.empty');
          expect(
            (notifier.state as EmptyState<List<int>>).message,
            'custom.empty',
          );
          expect(
            (notifier.state as EmptyState<List<int>>).onRefresh,
            isNotNull,
          );
        },
      );

      test(
        'setEmpty does not notify when called repeatedly with the same message',
        () async {
          final notifier = _pendingNotifier<List<int>>();
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);

          var notificationCount = 0;

          void listener() => notificationCount++;

          notifier.addListener(listener);
          addTearDown(() => notifier.removeListener(listener));

          notifier.setEmptyForTest('No items');

          expect(notificationCount, 1);

          notifier.setEmptyForTest('No items');

          expect(notificationCount, 1);
        },
      );

      test(
        'setError does not notify when called repeatedly with the same error',
        () async {
          final notifier = _pendingNotifier<String>();
          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);

          var notificationCount = 0;

          void listener() => notificationCount++;

          notifier.addListener(listener);
          addTearDown(() => notifier.removeListener(listener));

          final error = StateError('Something went wrong');
          final stackTrace = StackTrace.current;

          notifier.setErrorForTest(error, stackTrace);

          expect(notificationCount, 1);

          notifier.setErrorForTest(error, stackTrace);

          expect(notificationCount, 1);
        },
      );

      test('setError sets ErrorState and dispatches the error', () async {
        final notifier = _pendingNotifier<String>();
        addTearDown(notifier.dispose);
        await notifier.waitForBuildStart(1);

        final error = StateError('manual failure');
        final stackTrace = StackTrace.current;
        notifier.setErrorForTest(error, stackTrace);

        final state = notifier.state as ErrorState<String>;
        expect(state.error, same(error));
        expect(state.stackTrace, same(stackTrace));
        expect(state.errorInfo.message, contains('manual failure'));
        expect(state.onRetry, isNotNull);
        expect(notifier.dispatchedErrors, hasLength(1));
        expect(notifier.dispatchedErrors.single.$1, same(error));
        expect(notifier.dispatchedErrors.single.$2, same(stackTrace));
      });

      test('state helpers do nothing after disposal', () async {
        var buildImplCalls = 0;
        final notifier = _TestAsyncViewStateNotifier<String>(
          buildImpl: (_) async {
            buildImplCalls++;
            return 'must not build';
          },
        );
        final originalState = notifier.state;

        // Dispose before the scheduled initial-build microtask can run.
        notifier.dispose();

        notifier.setInitialForTest();
        notifier.setLoadingForTest('custom', 0.5);
        notifier.setDataForTest('custom data');
        notifier.setEmptyForTest('custom empty');
        notifier.setErrorForTest(StateError('ignored'), StackTrace.current);

        await _flushPendingTasks();

        expect(notifier.state, same(originalState));
        expect(buildImplCalls, 0);
        expect(notifier.buildCount, 0);
        expect(notifier.dispatchedErrors, isEmpty);
      });
    });
    test('runs onInitialize before the initial build', () async {
      final events = <String>[];

      final notifier = _InitializingTestNotifier(
        events: events,
        buildImpl: (_) async => 42,
      );
      addTearDown(notifier.dispose);

      await _waitForState(notifier, (state) => state is DataState<int>);

      expect(events, ['initialize', 'build']);
      expect(notifier.state, const DataState<int>(42));
    });

    test('preserves cached data while the initial build is pending', () async {
      final events = <String>[];
      final buildResult = Completer<int>();

      final notifier = _CachedInitializingTestNotifier(
        events: events,
        buildImpl: (_) => buildResult.future,
      );
      addTearDown(notifier.dispose);

      await notifier.waitForBuildStart(1);

      // Initialization publishes cached data before the build starts.
      expect(events, ['initialize', 'build']);
      expect(notifier.state, const DataState<int>(41));

      // The fresh build replaces the cached data when it completes.
      buildResult.complete(42);

      await _waitForState(
        notifier,
        (state) => state is DataState<int> && state.data == 42,
        description: 'fresh build data',
      );

      expect(notifier.state, const DataState<int>(42));
    });

    test('starts initial build even when onInitialize throws', () async {
      final events = <String>[];

      final initializationError = StateError('Initialization failed');
      final initializationErrorCaught = Completer<void>();
      final buildResult = Completer<int>();

      final uncaughtErrors = <(Object, StackTrace)>[];

      late final _InitializingTestNotifier notifier;

      runZonedGuarded<void>(
        () {
          notifier = _InitializingTestNotifier(
            events: events,
            initializationError: initializationError,
            buildImpl: (_) => buildResult.future,
          );
        },
        (error, stackTrace) {
          uncaughtErrors.add((error, stackTrace));

          if (identical(error, initializationError) &&
              !initializationErrorCaught.isCompleted) {
            initializationErrorCaught.complete();
          }
        },
      );

      addTearDown(notifier.dispose);

      // Wait for both the initialization error and the initial build.
      await Future.wait([
        initializationErrorCaught.future.timeout(_testTimeout),
        notifier.waitForBuildStart(1),
      ]);

      // The initialization error must not be swallowed.
      expect(uncaughtErrors, hasLength(1));
      expect(uncaughtErrors.single.$1, same(initializationError));

      // The initial build must still have started.
      expect(events, ['initialize', 'build']);

      // Complete the build and verify that its result is published.
      buildResult.complete(42);

      await _waitForState(notifier, (state) => state is DataState<int>);

      expect(notifier.state, const DataState<int>(42));
    });
    test('waits until the subclass constructor body has completed', () async {
      final notifier = _ConstructorDependentNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state, isA<LoadingState<String>>());
      await _waitForState(
        notifier,
        (state) => state is DataState<String>,
        description: 'constructor-dependent data',
      );

      expect(
        notifier.state,
        const DataState<String>('initialized after constructor'),
      );
    });

    test(
      'startInitialBuild false allows an explicit refresh to start a build',
      () async {
        final gate = Completer<String>();

        final notifier = _TestAsyncViewStateNotifier<String>(
          startInitialBuild: false,
          buildImpl: (_) => gate.future,
        );
        addTearDown(notifier.dispose);

        // No initial build should run automatically.
        expect(notifier.state, isA<InitialState<String>>());
        expect(notifier.buildCount, 0);

        await _flushPendingTasks();

        // Still waiting for an explicit request.
        expect(notifier.state, isA<InitialState<String>>());
        expect(notifier.buildCount, 0);

        // Manually start the first build.
        final refreshFuture = notifier.refresh();

        await notifier.waitForBuildStart(1);

        expect(notifier.buildCount, 1);
        expect(notifier.state, isA<LoadingState<String>>());

        // Complete the manually requested build.
        gate.complete('loaded manually');

        await refreshFuture.timeout(_testTimeout);

        expect(notifier.state, const DataState<String>('loaded manually'));
        expect(notifier.buildCount, 1);
      },
    );

    test(
      'startInitialBuild false allows an explicit rebuild to start a build',
      () async {
        final gate = Completer<String>();

        final notifier = _TestAsyncViewStateNotifier<String>(
          startInitialBuild: false,
          buildImpl: (_) => gate.future,
        );
        addTearDown(notifier.dispose);

        expect(notifier.state, isA<InitialState<String>>());
        expect(notifier.buildCount, 0);

        final rebuildFuture = notifier.rebuildForTest();

        await notifier.waitForBuildStart(1);

        expect(notifier.buildCount, 1);
        expect(notifier.state, isA<LoadingState<String>>());

        gate.complete('rebuilt manually');

        await rebuildFuture.timeout(_testTimeout);

        expect(notifier.state, const DataState<String>('rebuilt manually'));
        expect(notifier.buildCount, 1);
      },
    );

    test('a staleness callback becomes stale when disposed', () async {
      final notifier = _TestAsyncViewStateNotifier<String>(
        buildImpl: (_) async => 'ready',
      );
      await _waitForState(notifier, (state) => state is DataState<String>);

      final isStale = notifier.captureStaleness();
      expect(isStale(), isFalse);

      notifier.dispose();
      expect(isStale(), isTrue);
    });

    test('refresh invalidates a captured staleness callback', () async {
      final refreshGate = Completer<String>();
      final notifier = _TestAsyncViewStateNotifier<String>(
        buildImpl: (buildNumber) => buildNumber == 1
            ? Future<String>.value('initial')
            : refreshGate.future,
      );
      addTearDown(notifier.dispose);

      await _waitForState(notifier, (state) => state is DataState<String>);
      final isStale = notifier.captureStaleness();
      expect(isStale(), isFalse);

      final refreshFuture = notifier.refresh();
      await notifier.waitForBuildStart(2);
      expect(isStale(), isTrue);

      refreshGate.complete('refreshed');
      await refreshFuture.timeout(_testTimeout);
    });

    test('rebuild invalidates a captured staleness callback', () async {
      final rebuildGate = Completer<String>();
      final notifier = _TestAsyncViewStateNotifier<String>(
        buildImpl: (buildNumber) => buildNumber == 1
            ? Future<String>.value('initial')
            : rebuildGate.future,
      );
      addTearDown(notifier.dispose);

      await _waitForState(notifier, (state) => state is DataState<String>);
      final isStale = notifier.captureStaleness();
      expect(isStale(), isFalse);

      final rebuildFuture = notifier.rebuildForTest();
      await notifier.waitForBuildStart(2);
      expect(isStale(), isTrue);

      rebuildGate.complete('rebuilt');
      await rebuildFuture.timeout(_testTimeout);
    });

    test('a stale build cannot dispatch an error through setError', () async {
      final staleBuildGate = Completer<void>();
      final staleError = StateError('stale build failure');
      final staleStackTrace = StackTrace.current;

      late _TestAsyncViewStateNotifier<String> notifier;

      notifier = _TestAsyncViewStateNotifier<String>(
        buildImpl: (buildNumber) async {
          if (buildNumber == 1) {
            await staleBuildGate.future;
            notifier.setErrorForTest(staleError, staleStackTrace);
            return 'stale result';
          }

          return 'current result';
        },
      );
      addTearDown(notifier.dispose);

      await notifier.waitForBuildStart(1);

      final rebuildFuture = notifier.rebuildForTest();
      await notifier.waitForBuildStart(2);

      await _waitForState(
        notifier,
        (state) => state is DataState<String> && state.data == 'current result',
        description: 'current build result',
      );

      await rebuildFuture.timeout(_testTimeout);

      staleBuildGate.complete();
      await _flushPendingTasks();

      expect(notifier.state, const DataState<String>('current result'));

      expect(notifier.dispatchedErrors, isEmpty);
    });

    group('build invalidation', () {
      test(
        'completes waiting operations normally without starting a replacement',
        () async {
          final buildGate = Completer<String>();

          final notifier = _TestAsyncViewStateNotifier<String>(
            buildImpl: (_) => buildGate.future,
          );
          addTearDown(notifier.dispose);
          await notifier.waitForBuildStart(1);
          final stateBeforeInvalidation = notifier.state;

          // Refresh joins the currently running initial build.
          final refreshFuture = notifier.refresh();
          notifier.invalidateBuildForTest();

          // Invalidation completes the waiting Future normally,
          // even though the underlying build is still pending.
          await refreshFuture.timeout(_testTimeout);

          expect(notifier.buildCount, 1);
          expect(notifier.state, same(stateBeforeInvalidation));

          // The underlying Future can still complete after invalidation.
          buildGate.complete('late result');
          await _flushPendingTasks();

          // Its outdated result must not change the state.
          expect(notifier.state, same(stateBeforeInvalidation));
          expect(notifier.buildCount, 1);
        },
      );

      test('prevents a pending rebuild from starting', () async {
        final initialBuildGate = Completer<String>();

        final notifier = _TestAsyncViewStateNotifier<String>(
          buildImpl: (buildNumber) {
            if (buildNumber == 1) {
              return initialBuildGate.future;
            }

            return Future<String>.value('unexpected replacement');
          },
        );
        addTearDown(notifier.dispose);
        await notifier.waitForBuildStart(1);

        // Schedules a replacement build.
        final rebuildFuture = notifier.rebuildForTest();
        // Invalidate before the scheduled replacement starts.
        notifier.invalidateBuildForTest();

        // The rebuild waiter should complete normally.
        await rebuildFuture.timeout(_testTimeout);
        await _flushPendingTasks();
        expect(notifier.buildCount, 1);

        // Release the original underlying build.
        initialBuildGate.complete('outdated result');
        await _flushPendingTasks();
        // No replacement should have started.
        expect(notifier.buildCount, 1);
      });

      test('invalidates a captured staleness callback', () async {
        final buildGate = Completer<String>();

        final notifier = _TestAsyncViewStateNotifier<String>(
          buildImpl: (_) => buildGate.future,
        );
        addTearDown(notifier.dispose);
        await notifier.waitForBuildStart(1);
        final isStale = notifier.captureStaleness();
        expect(isStale(), isFalse);

        notifier.invalidateBuildForTest();
        expect(isStale(), isTrue);
        buildGate.complete('outdated result');

        await _flushPendingTasks();
        expect(isStale(), isTrue);
      });
    });

    test(
      'listener-triggered state assignment is not rejected as a stale write',
      () async {
        final notifier = _TestAsyncViewStateNotifier<String>(
          buildImpl: (_) async => 'build result',
        );
        addTearDown(notifier.dispose);

        var wroteFromListener = false;
        void listener() {
          final currentState = notifier.state;
          if (!wroteFromListener &&
              currentState is DataState<String> &&
              currentState.data == 'build result') {
            wroteFromListener = true;
            notifier.writeStateForTest(
              const DataState<String>('listener result'),
            );
          }
        }

        notifier.addListener(listener);
        addTearDown(() => notifier.removeListener(listener));

        await _waitForState(
          notifier,
          (state) =>
              state is DataState<String> && state.data == 'listener result',
          description: 'listener-assigned state',
        );

        expect(notifier.state, const DataState<String>('listener result'));
      },
    );
  });
}
