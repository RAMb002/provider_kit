import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

const _testTimeout = Duration(seconds: 3);

Future<T> _within<T>(Future<T> future, String operation) {
  return future.timeout(
    _testTimeout,
    onTimeout: () => throw TimeoutException(
      'Timed out waiting for $operation.',
      _testTimeout,
    ),
  );
}

class TestStreamNotifier<T> extends StreamNotifier<T> {
  TestStreamNotifier({
    required this.buildImpl,
    super.initialState,
    super.disableEmptyState,
    super.emptyMessage,
    super.loadingMessage,
  });

  final Stream<T> Function(int buildNumber) buildImpl;

  final List<Completer<void>> _buildStarts = List<Completer<void>>.generate(
    64,
    (_) => Completer<void>(),
  );

  int buildCount = 0;

  @override
  Stream<T> build() {
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
    return _within(_buildStarts[buildNumber - 1].future, 'build $buildNumber');
  }

  Future<void> requestRebuild() => rebuild();

  bool Function() captureStaleness() => checkStaleness();

  void writeState(ViewState<T> value) => state = value;
}

class _CapturedFailure {
  const _CapturedFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

Future<_CapturedFailure> _captureFailure(Future<void> future) async {
  try {
    await _within(future, 'future to fail or complete');
  } catch (error, stackTrace) {
    return _CapturedFailure(error, stackTrace);
  }
  fail('Expected the Future to fail, but it completed successfully.');
}

Future<void> _expectFutureFailure(
  Future<void> future,
  Object expectedError, {
  StackTrace? expectedStackTrace,
}) async {
  final failure = await _captureFailure(future);
  expect(failure.error, same(expectedError));
  if (expectedStackTrace != null) {
    expect(failure.stackTrace, same(expectedStackTrace));
  }
}

Future<void> _flushPendingTasks() =>
    _within(Future<void>.delayed(Duration.zero), 'pending microtasks');

Future<void> _waitForState<T>(
  StreamNotifier<T> notifier,
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
      await _within(completer.future, description);
    } finally {
      notifier.removeListener(listener);
    }
  }

  // State notification can precede settlement of the setup operation by a
  // microtask. Drain that boundary before starting another operation.
  await _flushPendingTasks();
}

Future<void> _waitUntil(
  bool Function() condition, {
  required String description,
}) async {
  final deadline = DateTime.now().add(_testTimeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Timed out waiting for $description.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

void _addCleanup<T>(
  TestStreamNotifier<T> notifier,
  List<StreamController<T>> controllers,
) {
  addTearDown(() async {
    notifier.dispose();
    for (final controller in controllers) {
      if (!controller.isClosed) {
        await _within(controller.close(), 'stream controller to close');
      }
    }
  });
}

Stream<T> _synchronousStream<T>(Iterable<T> values) {
  return Stream<T>.multi((controller) {
    for (final value in values) {
      controller.addSync(value);
    }
    controller.closeSync();
  });
}

void main() {
  late List<FlutterErrorDetails> unexpectedFlutterErrors;
  late void Function(FlutterErrorDetails)? previousFlutterErrorHandler;

  setUp(() {
    unexpectedFlutterErrors = <FlutterErrorDetails>[];
    previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = unexpectedFlutterErrors.add;
  });

  tearDown(() {
    final unexpected = List<FlutterErrorDetails>.of(unexpectedFlutterErrors);
    FlutterError.onError = previousFlutterErrorHandler;
    expect(
      unexpected,
      isEmpty,
      reason: 'Unexpected Flutter errors were reported during this test.',
    );
  });

  group('StreamNotifier', () {
    group('initial build and state mapping', () {
      test('defaults to LoadingState and subscribes automatically', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);

        expect(notifier.state, isA<LoadingState<String>>());
        expect(notifier.buildCount, 0);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'initial stream subscription',
          ),
          'initial stream listener',
        );

        expect(notifier.buildCount, 1);
        expect(notifier.state, isA<LoadingState<String>>());
      });

      test('respects initialState before the scheduled subscription', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          initialState: const DataState<String>('provided'),
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);

        expect(notifier.state, const DataState<String>('provided'));
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'initial stream subscription',
          ),
          'initial stream listener',
        );
        expect(notifier.state, const DataState<String>('provided'));
      });

      test('each emitted value becomes the current DataState', () async {
        final controllers = <StreamController<int>>[];
        final notifier = TestStreamNotifier<int>(
          buildImpl: (_) {
            final controller = StreamController<int>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.add(1);
        expect(notifier.state, const DataState<int>(1));
        controllers.single.add(2);
        expect(notifier.state, const DataState<int>(2));
      });

      test('maps an empty Iterable event to EmptyState by default', () async {
        final controllers = <StreamController<List<int>>>[];
        final notifier = TestStreamNotifier<List<int>>(
          buildImpl: (_) {
            final controller = StreamController<List<int>>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.add(<int>[]);
        expect(notifier.state, isA<EmptyState<List<int>>>());
      });

      test(
        'uses configured messages for generated loading and empty states',
        () async {
          final controllers = <StreamController<List<int>>>[];

          final notifier = TestStreamNotifier<List<int>>(
            loadingMessage: 'products.loading',
            emptyMessage: 'products.empty',
            buildImpl: (_) {
              final controller = StreamController<List<int>>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);

          // The initial LoadingState uses the configured message.
          expect(notifier.state, isA<LoadingState<List<int>>>());
          expect(
            (notifier.state as LoadingState<List<int>>).message,
            'products.loading',
          );

          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'initial stream listener',
            ),
            'initial stream listener',
          );

          // An empty Iterable event uses the configured empty message.
          controllers[0].add(<int>[]);

          expect(notifier.state, isA<EmptyState<List<int>>>());
          expect(
            (notifier.state as EmptyState<List<int>>).message,
            'products.empty',
          );

          // Rebuilding transitions back to LoadingState with the same message.
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await _within(rebuildFuture, 'replacement subscription setup');

          expect(notifier.state, isA<LoadingState<List<int>>>());
          expect(
            (notifier.state as LoadingState<List<int>>).message,
            'products.loading',
          );

          // The replacement stream's empty event also uses the configured message.
          controllers[1].add(<int>[]);

          expect(notifier.state, isA<EmptyState<List<int>>>());
          expect(
            (notifier.state as EmptyState<List<int>>).message,
            'products.empty',
          );
        },
      );

      test(
        'publishes an empty Iterable event as DataState when disabled',
        () async {
          final controllers = <StreamController<List<int>>>[];
          final notifier = TestStreamNotifier<List<int>>(
            disableEmptyState: true,
            buildImpl: (_) {
              final controller = StreamController<List<int>>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );

          controllers.single.add(<int>[]);
          expect(notifier.state, isA<DataState<List<int>>>());
          expect((notifier.state as DataState<List<int>>).data, isEmpty);
        },
      );

      test('a non-empty Iterable event becomes DataState', () async {
        final controllers = <StreamController<List<int>>>[];
        final notifier = TestStreamNotifier<List<int>>(
          buildImpl: (_) {
            final controller = StreamController<List<int>>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.add(<int>[1, 2, 3]);
        expect((notifier.state as DataState<List<int>>).data, <int>[1, 2, 3]);
      });

      test('empty Map and empty String events remain DataState', () async {
        final mapControllers = <StreamController<Map<String, int>>>[];
        final mapNotifier = TestStreamNotifier<Map<String, int>>(
          buildImpl: (_) {
            final controller = StreamController<Map<String, int>>(sync: true);
            mapControllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(mapNotifier, mapControllers);
        await mapNotifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => mapControllers.single.hasListener,
            description: 'map listener',
          ),
          'map listener attached',
        );
        mapControllers.single.add(<String, int>{});
        expect(mapNotifier.state, isA<DataState<Map<String, int>>>());

        final stringControllers = <StreamController<String>>[];
        final stringNotifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            stringControllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(stringNotifier, stringControllers);
        await stringNotifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => stringControllers.single.hasListener,
            description: 'string listener',
          ),
          'string listener attached',
        );
        stringControllers.single.add('');
        expect(stringNotifier.state, const DataState<String>(''));
      });

      test(
        'a null event is published as DataState for a nullable type',
        () async {
          final controllers = <StreamController<String?>>[];
          final notifier = TestStreamNotifier<String?>(
            buildImpl: (_) {
              final controller = StreamController<String?>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );

          controllers.single.add(null);
          expect(notifier.state, isA<DataState<String?>>());
          expect((notifier.state as DataState<String?>).data, isNull);
        },
      );

      test(
        'a synchronous stream can emit and complete during listen',
        () async {
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) => _synchronousStream<String>(<String>['sync']),
          );
          addTearDown(notifier.dispose);

          await _waitForState(
            notifier,
            (state) => state is DataState<String> && state.data == 'sync',
            description: 'synchronous stream data',
          );
          expect(notifier.state, const DataState<String>('sync'));
        },
      );

      test('an empty synchronous stream completes as EmptyState', () async {
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) => _synchronousStream<String>(const <String>[]),
        );
        addTearDown(notifier.dispose);

        await _waitForState(
          notifier,
          (state) => state is EmptyState<String>,
          description: 'empty synchronous stream completion',
        );
        expect(notifier.state, isA<EmptyState<String>>());
      });

      test('completion without data transitions to EmptyState', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        await _within(controllers.single.close(), 'empty stream completion');
        await _waitForState(
          notifier,
          (state) => state is EmptyState<String>,
          description: 'EmptyState after completion',
        );
      });

      test('completion after data preserves the last data value', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.add('last value');
        await _within(controllers.single.close(), 'stream completion');
        expect(notifier.state, const DataState<String>('last value'));
      });

      test(
        'completion preserves an initial DataState when no events arrive',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            initialState: const DataState<String>('cached'),
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );

          await _within(controllers.single.close(), 'empty stream completion');
          expect(notifier.state, const DataState<String>('cached'));
        },
      );
    });

    group('stream error handling', () {
      test('an error before data becomes ErrorState', () async {
        final controllers = <StreamController<String>>[];
        final error = StateError('early stream error');
        final stackTrace = StackTrace.current;
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.addError(error, stackTrace);
        expect(notifier.state, isA<ErrorState<String>>());
        final errorState = notifier.state as ErrorState<String>;
        expect(errorState.error, same(error));
        expect(errorState.stackTrace, same(stackTrace));
        expect(errorState.onRetry, isNotNull);
      });

      test('an error after data preserves existing DataState', () async {
        final controllers = <StreamController<String>>[];
        final error = StateError('error after data');
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.add('cached');
        controllers.single.addError(error, StackTrace.current);
        expect(notifier.state, const DataState<String>('cached'));
      });

      test(
        'stream completion after an error does not replace ErrorState',
        () async {
          final controllers = <StreamController<String>>[];
          final error = Exception('stream failed then completed');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );

          controllers.single.addError(error, StackTrace.current);
          await _within(
            controllers.single.close(),
            'stream completion after error',
          );
          expect(notifier.state, isA<ErrorState<String>>());
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );

      test('data emitted after an error becomes the new DataState', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'listener',
          ),
          'listener attached',
        );

        controllers.single.addError(
          Exception('recoverable'),
          StackTrace.current,
        );
        expect(notifier.state, isA<ErrorState<String>>());
        controllers.single.add('recovered event');
        expect(notifier.state, const DataState<String>('recovered event'));
      });

      test(
        'the default retry callback refreshes and recovers from a stream error',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );

          controllers[0].addError(
            Exception('temporary stream failure'),
            StackTrace.current,
          );
          expect(notifier.state, isA<ErrorState<String>>());
          await _flushPendingTasks();
          final retry = (notifier.state as ErrorState<String>).onRetry;
          expect(retry, isNotNull);
          retry!();

          await notifier.waitForBuildStart(2);
          await _within(
            _waitUntil(
              () => controllers[1].hasListener,
              description: 'retry subscription',
            ),
            'retry subscription',
          );
          controllers[1].add('recovered');
          expect(notifier.state, const DataState<String>('recovered'));
          expect(notifier.buildCount, 2);
        },
      );

      test(
        'the default empty refresh callback restarts the stream and recovers',
        () async {
          final controllers = <StreamController<String>>[];

          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );

          _addCleanup(notifier, controllers);

          await notifier.waitForBuildStart(1);

          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'initial subscription',
            ),
            'initial stream listener',
          );

          // Complete without emitting any values to generate EmptyState.
          await _within(
            controllers[0].close(),
            'initial empty stream completion',
          );

          await _waitForState(
            notifier,
            (state) => state is EmptyState<String>,
            description: 'initial EmptyState',
          );

          final emptyState = notifier.state as EmptyState<String>;
          final onRefresh = emptyState.onRefresh;

          expect(onRefresh, isNotNull);

          // Invoke the generated fire-and-forget UI callback.
          onRefresh!();

          await notifier.waitForBuildStart(2);

          await _within(
            _waitUntil(
              () => controllers[1].hasListener,
              description: 'replacement subscription',
            ),
            'replacement stream listener',
          );

          expect(notifier.buildCount, 2);
          controllers[1].add('refreshed');
          expect(notifier.state, const DataState<String>('refreshed'));
        },
      );

      test(
        'default empty refresh absorbs a synchronous setup failure',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('empty refresh setup failed');

          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }

              throw error;
            },
          );

          _addCleanup(notifier, controllers);

          await notifier.waitForBuildStart(1);

          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'initial subscription',
            ),
            'initial stream listener',
          );

          // Generate EmptyState by completing without data or errors.
          await _within(
            controllers[0].close(),
            'initial empty stream completion',
          );

          await _waitForState(
            notifier,
            (state) => state is EmptyState<String>,
            description: 'initial EmptyState',
          );

          final onRefresh = (notifier.state as EmptyState<String>).onRefresh;
          expect(onRefresh, isNotNull);

          // The callback deliberately does not expose or await refresh's Future.
          onRefresh!();

          await notifier.waitForBuildStart(2);
          await _waitForState(
            notifier,
            (state) =>
                state is ErrorState<String> && identical(state.error, error),
            description: 'ErrorState after failed fire-and-forget refresh',
          );

          expect(notifier.buildCount, 2);
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );

      test('a synchronous throw from build becomes ErrorState', () async {
        final error = StateError('build threw');
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) => throw error,
        );
        addTearDown(notifier.dispose);

        await _waitForState(
          notifier,
          (state) => state is ErrorState<String>,
          description: 'ErrorState after synchronous build throw',
        );
        expect((notifier.state as ErrorState<String>).error, same(error));
      });

      test('a stream whose listen throws becomes ErrorState', () async {
        final error = StateError('listen failed');
        final stackTrace = StackTrace.current;
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) => _ThrowingListenStream<String>(error, stackTrace),
        );
        addTearDown(notifier.dispose);

        await _waitForState(
          notifier,
          (state) => state is ErrorState<String>,
          description: 'ErrorState after listen failure',
        );
        expect((notifier.state as ErrorState<String>).error, same(error));
      });

      test(
        'a refresh setup failure without usable data propagates and publishes ErrorState',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('refresh setup failed');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }
              throw error;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );
          await _within(
            controllers.single.close(),
            'initial empty stream completion',
          );
          await _waitForState(
            notifier,
            (state) => state is EmptyState<String>,
            description: 'initial EmptyState',
          );

          await _expectFutureFailure(notifier.refresh(), error);
          expect(notifier.state, isA<ErrorState<String>>());
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );

      test(
        'a refresh setup failure preserves existing data and propagates',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('refresh failed with cached data');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }
              throw error;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );
          controllers.single.add('cached');
          await _flushPendingTasks();

          await _expectFutureFailure(notifier.refresh(), error);
          expect(notifier.state, const DataState<String>('cached'));
        },
      );

      test(
        'fire-and-forget refresh absorbs a synchronous setup failure',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('unawaited refresh setup failed');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }
              throw error;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('cached');
          await _flushPendingTasks();

          unawaited(notifier.refresh());
          await notifier.waitForBuildStart(2);
          await _flushPendingTasks();
          expect(notifier.state, const DataState<String>('cached'));
          expect(notifier.buildCount, 2);
        },
      );

      test(
        'a later stream error is handled by the stream callback, not refresh Future',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('event-time error');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);

          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'listener',
            ),
            'listener attached',
          );
          // A stream subscription is established even though the stream itself
          // remains open. Its setup future does not wait for later events.
          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(refreshFuture, 'refresh subscription setup');
          controllers[1].addError(error, StackTrace.current);

          await _waitForState(
            notifier,
            (state) => state is ErrorState<String>,
            description: 'ErrorState from later stream event',
          );
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );
    });

    group('refresh', () {
      test(
        'restarts subscription and preserves current data while waiting',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('before refresh');
          await _flushPendingTasks();

          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(refreshFuture, 'replacement subscription setup');

          expect(notifier.state, const DataState<String>('before refresh'));
          expect(controllers[0].hasListener, isFalse);
          expect(controllers[1].hasListener, isTrue);

          controllers[1].add('after refresh');
          expect(notifier.state, const DataState<String>('after refresh'));
        },
      );

      test(
        'refresh from EmptyState shows LoadingState until a value arrives',
        () async {
          final controllers = <StreamController<List<int>>>[];
          final notifier = TestStreamNotifier<List<int>>(
            buildImpl: (_) {
              final controller = StreamController<List<int>>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          await _within(controllers[0].close(), 'initial empty completion');
          await _waitForState(
            notifier,
            (state) => state is EmptyState<List<int>>,
            description: 'initial EmptyState',
          );

          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(refreshFuture, 'replacement subscription setup');
          expect(notifier.state, isA<LoadingState<List<int>>>());

          controllers[1].add(<int>[7]);
          expect(notifier.state, isA<DataState<List<int>>>());
          expect((notifier.state as DataState<List<int>>).data, <int>[7]);
        },
      );

      test(
        'refresh from ErrorState shows LoadingState while replacement is pending',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].addError(
            Exception('initial event error'),
            StackTrace.current,
          );
          expect(notifier.state, isA<ErrorState<String>>());
          await _flushPendingTasks();

          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(refreshFuture, 'replacement subscription setup');
          expect(notifier.state, isA<LoadingState<String>>());

          controllers[1].add('recovered');
          expect(notifier.state, const DataState<String>('recovered'));
        },
      );

      test(
        'refresh returns after subscription setup, not stream completion',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );

          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(
            refreshFuture,
            'subscription setup while stream remains open',
          );
          expect(controllers[1].hasListener, isTrue);
          expect(controllers[1].isClosed, isFalse);
          expect(notifier.state, isA<LoadingState<String>>());
        },
      );

      test(
        'concurrent refreshes join a setup waiting for old cancellation',
        () async {
          final cancelStarted = Completer<void>();
          final cancelGate = Completer<void>();
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              final controller = StreamController<String>(
                sync: true,
                onCancel: buildNumber == 1
                    ? () {
                        if (!cancelStarted.isCompleted) {
                          cancelStarted.complete();
                        }
                        return cancelGate.future;
                      }
                    : null,
              );
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('cached');

          final firstRefresh = notifier.refresh();
          await _within(cancelStarted.future, 'first cancellation to start');
          final secondRefresh = notifier.refresh();
          expect(notifier.buildCount, 1);

          cancelGate.complete();
          await notifier.waitForBuildStart(2);
          await _within(
            Future.wait<void>(<Future<void>>[firstRefresh, secondRefresh]),
            'both refresh callers to complete',
          );
          expect(notifier.buildCount, 2);
          expect(notifier.state, const DataState<String>('cached'));
        },
      );

      test(
        'refresh that joins a running setup invalidates independent staleness checks',
        () async {
          final cancelStarted = Completer<void>();
          final cancelGate = Completer<void>();
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              final controller = StreamController<String>(
                sync: true,
                onCancel: buildNumber == 1
                    ? () {
                        if (!cancelStarted.isCompleted) {
                          cancelStarted.complete();
                        }
                        return cancelGate.future;
                      }
                    : null,
              );
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          final firstRefresh = notifier.refresh();
          await _within(cancelStarted.future, 'first cancellation to start');
          final isStaleBeforeJoin = notifier.captureStaleness();
          expect(isStaleBeforeJoin(), isFalse);

          final secondRefresh = notifier.refresh();
          expect(isStaleBeforeJoin(), isTrue);
          cancelGate.complete();
          await notifier.waitForBuildStart(2);
          await _within(
            Future.wait<void>(<Future<void>>[firstRefresh, secondRefresh]),
            'joined refresh callers',
          );
          expect(notifier.buildCount, 2);
        },
      );
    });

    group('subscription cancellation', () {
      test(
        'a cancellation failure is reported but does not block replacement setup',
        () async {
          final reported = <FlutterErrorDetails>[];
          final previousHandler = FlutterError.onError;
          FlutterError.onError = reported.add;

          final controllers = <StreamController<String>>[];
          final cancelError = StateError('subscription cancellation failed');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              final controller = StreamController<String>(
                sync: true,
                onCancel: buildNumber == 1
                    ? () => Future<void>.error(cancelError)
                    : null,
              );
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('cached');
          await _flushPendingTasks();

          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(
            refreshFuture,
            'replacement setup after cancellation failure',
          );
          expect(notifier.state, const DataState<String>('cached'));
          expect(controllers[1].hasListener, isTrue);
          expect(
            reported.any(
              (details) => identical(details.exception, cancelError),
            ),
            isTrue,
          );
          FlutterError.onError = previousHandler;
        },
      );
    });

    group('rebuild and stale operation protection', () {
      test(
        'rebuild clears existing data while replacement stream is idle',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('old data');
          await _flushPendingTasks();

          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await _within(rebuildFuture, 'replacement subscription setup');
          expect(notifier.state, isA<LoadingState<String>>());
          expect(controllers[0].hasListener, isFalse);
          expect(controllers[1].hasListener, isTrue);
        },
      );

      test(
        'a failed rebuild publishes LoadingState before ErrorState',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('replacement build failed');
          final states = <ViewState<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }
              throw error;
            },
          );
          _addCleanup(notifier, controllers);
          notifier.addListener(() => states.add(notifier.state));
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('old data');
          await _flushPendingTasks();
          states.clear();

          await _expectFutureFailure(notifier.requestRebuild(), error);
          expect(notifier.state, isA<ErrorState<String>>());
          expect(
            states.indexWhere((state) => state is LoadingState<String>),
            greaterThanOrEqualTo(0),
          );
          expect(
            states.indexWhere((state) => state is ErrorState<String>),
            greaterThan(
              states.indexWhere((state) => state is LoadingState<String>),
            ),
          );
        },
      );

      test(
        'fire-and-forget rebuild absorbs a synchronous setup failure',
        () async {
          final controllers = <StreamController<String>>[];
          final error = StateError('unawaited rebuild failed');
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                final controller = StreamController<String>(sync: true);
                controllers.add(controller);
                return controller.stream;
              }
              throw error;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('before rebuild');
          await _flushPendingTasks();

          unawaited(notifier.requestRebuild());
          await _waitForState(
            notifier,
            (state) =>
                state is ErrorState<String> && identical(state.error, error),
            description: 'ErrorState after fire-and-forget rebuild',
          );
          expect((notifier.state as ErrorState<String>).error, same(error));
        },
      );

      test(
        'a queued event from a superseded stream cannot overwrite new data',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>();
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('initial');
          await _waitForState(
            notifier,
            (state) => state is DataState<String> && state.data == 'initial',
            description: 'initial event',
          );

          // Async controller delivery is queued. Refresh invalidates the old token
          // before this queued event is delivered.
          controllers[0].add('obsolete queued event');
          final refreshFuture = notifier.refresh();
          await notifier.waitForBuildStart(2);
          await _within(refreshFuture, 'replacement subscription setup');
          controllers[1].add('replacement');
          await _waitForState(
            notifier,
            (state) =>
                state is DataState<String> && state.data == 'replacement',
            description: 'replacement event',
          );
          expect(notifier.state, const DataState<String>('replacement'));
        },
      );

      test(
        'a timer created in an old build cannot assign stale state',
        () async {
          final timerRan = Completer<void>();
          final controllers = <StreamController<String>>[];
          late TestStreamNotifier<String> notifier;
          notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                Timer.run(() {
                  notifier.writeState(
                    const DataState<String>('stale timer write'),
                  );
                  if (!timerRan.isCompleted) timerRan.complete();
                });
              }
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await _within(rebuildFuture, 'replacement setup');
          controllers[1].add('current');
          await _waitForState(
            notifier,
            (state) => state is DataState<String> && state.data == 'current',
            description: 'current event',
          );
          await _within(timerRan.future, 'stale timer callback');
          expect(notifier.state, const DataState<String>('current'));
        },
      );

      test(
        'multiple pending rebuild requests coalesce during cancellation',
        () async {
          final cancelStarted = Completer<void>();
          final cancelGate = Completer<void>();
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              final controller = StreamController<String>(
                sync: true,
                onCancel: buildNumber == 1
                    ? () {
                        if (!cancelStarted.isCompleted) {
                          cancelStarted.complete();
                        }
                        return cancelGate.future;
                      }
                    : null,
              );
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('old data');
          await _flushPendingTasks();

          final first = notifier.requestRebuild();
          await _within(cancelStarted.future, 'old subscription cancellation');
          final second = notifier.requestRebuild();
          final third = notifier.requestRebuild();
          cancelGate.complete();

          await notifier.waitForBuildStart(2);
          await _within(
            Future.wait<void>(<Future<void>>[first, second, third]),
            'coalesced rebuild callers',
          );
          expect(notifier.buildCount, 2);
          expect(controllers[1].hasListener, isTrue);
        },
      );

      test(
        'refresh waiter follows rebuild replacement while old cancellation hangs',
        () async {
          final cancelStarted = Completer<void>();
          final cancelGate = Completer<void>();
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              final controller = StreamController<String>(
                sync: true,
                onCancel: buildNumber == 1
                    ? () {
                        if (!cancelStarted.isCompleted) {
                          cancelStarted.complete();
                        }
                        return cancelGate.future;
                      }
                    : null,
              );
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);
          await notifier.waitForBuildStart(1);
          await _within(
            _waitUntil(
              () => controllers[0].hasListener,
              description: 'first subscription',
            ),
            'first subscription',
          );
          controllers[0].add('initial');
          await _flushPendingTasks();

          final refreshFuture = notifier.refresh();
          await _within(cancelStarted.future, 'old subscription cancellation');
          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(2);
          await _within(rebuildFuture, 'replacement rebuild setup');
          controllers[1].add('replacement');
          await _waitForState(
            notifier,
            (state) =>
                state is DataState<String> && state.data == 'replacement',
            description: 'replacement event',
          );
          await _within(refreshFuture, 'refresh waiter to follow replacement');
          expect(notifier.buildCount, 2);

          cancelGate.complete();
          await _flushPendingTasks();
          expect(notifier.state, const DataState<String>('replacement'));
        },
      );

      test(
        'an async* generator retains the current build Zone after await',
        () async {
          final gate = Completer<void>();
          final generatorEntered = Completer<void>();
          final intermediateWritten = Completer<void>();
          final allowYield = Completer<void>();

          late TestStreamNotifier<String> notifier;

          notifier = TestStreamNotifier<String>(
            buildImpl: (_) => (() async* {
              generatorEntered.complete();

              await gate.future;

              notifier.writeState(
                const DataState<String>('intermediate after await'),
              );

              intermediateWritten.complete();

              await allowYield.future;

              yield 'stream result';
            })(),
          );

          addTearDown(notifier.dispose);

          await notifier.waitForBuildStart(1);
          await _within(generatorEntered.future, 'generator to start');

          gate.complete();
          await _within(intermediateWritten.future, 'intermediate state write');

          expect(
            notifier.state,
            const DataState<String>('intermediate after await'),
          );

          allowYield.complete();

          await _waitForState(
            notifier,
            (state) =>
                state is DataState<String> && state.data == 'stream result',
            description: 'final stream result',
          );

          expect(notifier.state, const DataState<String>('stream result'));
        },
      );

      test(
        'listener-triggered rebuild during synchronous stream delivery is safe',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (buildNumber) {
              if (buildNumber == 1) {
                return _synchronousStream<String>(<String>['first']);
              }
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);

          var requested = false;
          void listener() {
            if (!requested &&
                notifier.state is DataState<String> &&
                (notifier.state as DataState<String>).data == 'first') {
              requested = true;
              unawaited(notifier.requestRebuild());
            }
          }

          notifier.addListener(listener);
          addTearDown(() => notifier.removeListener(listener));

          await notifier.waitForBuildStart(2);
          await _within(
            _waitUntil(
              () => controllers.single.hasListener,
              description: 'replacement listener',
            ),
            'replacement listener',
          );
          controllers.single.add('replacement');
          expect(notifier.state, const DataState<String>('replacement'));
          expect(notifier.buildCount, 2);
        },
      );

      test(
        'rebuild immediately after construction does not duplicate initial build',
        () async {
          final controllers = <StreamController<String>>[];
          final notifier = TestStreamNotifier<String>(
            buildImpl: (_) {
              final controller = StreamController<String>(sync: true);
              controllers.add(controller);
              return controller.stream;
            },
          );
          _addCleanup(notifier, controllers);

          final rebuildFuture = notifier.requestRebuild();
          await notifier.waitForBuildStart(1);
          await _within(rebuildFuture, 'initial/rebuild coalescing');
          await _flushPendingTasks();
          expect(notifier.buildCount, 1);
        },
      );
    });

    group('disposal', () {
      test('dispose cancels the active subscription', () async {
        final cancelled = Completer<void>();
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(
              sync: true,
              onCancel: () {
                if (!cancelled.isCompleted) cancelled.complete();
              },
            );
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'active subscription',
          ),
          'active subscription',
        );

        notifier.dispose();
        await _within(cancelled.future, 'active subscription cancellation');
        expect(controllers.single.hasListener, isFalse);
      });

      test('events after disposal cannot update state', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'active subscription',
          ),
          'active subscription',
        );
        controllers.single.add('before dispose');
        notifier.dispose();
        expect(notifier.state, const DataState<String>('before dispose'));
        expect(controllers.single.hasListener, isFalse);
        controllers.single.add('late event');
        await _flushPendingTasks();
        expect(notifier.state, const DataState<String>('before dispose'));
      });

      test('refresh after disposal does not start another build', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'active subscription',
          ),
          'active subscription',
        );
        controllers.single.add('ready');

        notifier.dispose();
        await _within(notifier.refresh(), 'refresh after disposal');
        expect(notifier.buildCount, 1);
        expect(notifier.state, const DataState<String>('ready'));
      });

      test('rebuild after disposal does not start another build', () async {
        final controllers = <StreamController<String>>[];
        final notifier = TestStreamNotifier<String>(
          buildImpl: (_) {
            final controller = StreamController<String>(sync: true);
            controllers.add(controller);
            return controller.stream;
          },
        );
        _addCleanup(notifier, controllers);
        await notifier.waitForBuildStart(1);
        await _within(
          _waitUntil(
            () => controllers.single.hasListener,
            description: 'active subscription',
          ),
          'active subscription',
        );
        notifier.dispose();

        await _within(notifier.requestRebuild(), 'rebuild after disposal');
        expect(notifier.buildCount, 1);
      });
    });
  });
}

class _ThrowingListenStream<T> extends Stream<T> {
  _ThrowingListenStream(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    Error.throwWithStackTrace(error, stackTrace);
  }
}
