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
    super.disableEmptyState,
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
  bool disableEmptyState = false,
}) {
  return _TestAsyncViewStateNotifier<T>(
    loadingMessage: loadingMessage,
    emptyMessage: emptyMessage,
    disableEmptyState: disableEmptyState,
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
