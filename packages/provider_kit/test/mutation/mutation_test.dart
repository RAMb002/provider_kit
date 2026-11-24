// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('Mutation', () {
    setUp(() {
      ProviderKit.resetForTesting();
    });

    group('Mutation constructor', () {
      test('starts idle and mounted', () {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        expect(mutation.state, isA<MutationIdle<int>>());
        expect(mutation.isIdle, isTrue);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.isError, isFalse);
        expect(mutation.dataOrNull, isNull);
        expect(() => mutation.data, throwsA(isA<StateError>()));
        expect(mutation.hasListeners, isFalse);
        expect(mutation.mounted, isTrue);
      });

      test('runs overlapping executions concurrently by default', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();

        var startedExecutions = 0;

        final firstRun = mutation.run(() {
          startedExecutions++;
          return firstCompleter.future;
        });

        final secondRun = mutation.run(() {
          startedExecutions++;
          return secondCompleter.future;
        });

        expect(startedExecutions, 2);

        firstCompleter.complete(1);
        secondCompleter.complete(2);

        final results = await Future.wait([firstRun, secondRun]);

        expect(results[0], isA<MutationSucceeded<int>>());
        expect(results[1], isA<MutationSucceeded<int>>());

        expect((results[0] as MutationSucceeded<int>).data, 1);
        expect((results[1] as MutationSucceeded<int>).data, 2);
      });

      test('uses the configured default concurrency policy', () async {
        ProviderKit.configure(
          mutationConcurrency: MutationConcurrency.ignoreIfBusy,
        );

        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        final completer = Completer<int>();
        var secondExecutionStarted = false;

        final firstRun = mutation.run(() => completer.future);

        final secondRun = mutation.run(() {
          secondExecutionStarted = true;
          return Future.value(2);
        });

        final secondResult = await secondRun;

        expect(secondExecutionStarted, isFalse);
        expect(secondResult, isA<MutationIgnored<int>>());

        completer.complete(1);

        final firstResult = await firstRun;

        expect(firstResult, isA<MutationSucceeded<int>>());
      });

      test('uses an explicitly supplied concurrency policy', () async {
        final mutation = Mutation<int>(concurrency: MutationConcurrency.queue);
        addTearDown(mutation.dispose);

        final completer = Completer<int>();
        var secondExecutionStarted = false;

        final firstRun = mutation.run(() => completer.future);

        final secondRun = mutation.run(() {
          secondExecutionStarted = true;
          return Future.value(2);
        });

        expect(secondExecutionStarted, isFalse);

        completer.complete(1);

        final firstResult = await firstRun;
        final secondResult = await secondRun;

        expect(firstResult, isA<MutationSucceeded<int>>());
        expect(secondExecutionStarted, isTrue);
        expect(secondResult, isA<MutationSucceeded<int>>());
        expect((secondResult as MutationSucceeded<int>).data, 2);
      });
    });

    group('execution', () {
      test(
        'enters loading before invoking the action and publishes success',
        () async {
          final mutation = Mutation<int>();
          addTearDown(mutation.dispose);
          final actionCompleter = Completer<int>();
          final states = <MutationState<int>>[];
          var actionStarted = false;

          mutation.addListener(() => states.add(mutation.state));

          final future = mutation.run(() {
            actionStarted = true;
            return actionCompleter.future;
          });

          expect(actionStarted, isTrue);
          expect(mutation.state, isA<MutationLoading<int>>());
          expect(mutation.isLoading, isTrue);
          expect(states, hasLength(1));
          expect(states.single, isA<MutationLoading<int>>());

          actionCompleter.complete(42);
          final result = await future;

          expect(result, isA<MutationSucceeded<int>>());
          expect(mutation.state, isA<MutationSuccess<int>>());
          expect(mutation.data, 42);
          expect(mutation.dataOrNull, 42);
          expect(mutation.isSuccess, isTrue);
          expect(mutation.isLoading, isFalse);
          expect(states, hasLength(2));
          expect(states.last, isA<MutationSuccess<int>>());
        },
      );

      test('supports nullable results and void mutations', () async {
        final nullableMutation = Mutation<int?>();
        final voidMutation = Mutation<void>();
        addTearDown(nullableMutation.dispose);
        addTearDown(voidMutation.dispose);

        final nullableResult = await nullableMutation.run(() async => null);
        var voidActionExecuted = false;
        final voidResult = await voidMutation.run(() async {
          voidActionExecuted = true;
        });

        expect(nullableResult, isA<MutationSucceeded<int?>>());
        expect(nullableMutation.state, isA<MutationSuccess<int?>>());
        expect(nullableMutation.data, isNull);
        expect(nullableMutation.isSuccess, isTrue);

        expect(voidActionExecuted, isTrue);
        expect(voidResult, isA<MutationSucceeded<void>>());
        expect(voidMutation.state, isA<MutationSuccess<void>>());
      });

      test('awaits an asynchronous onSuccess callback', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final actionCompleter = Completer<int>();
        final callbackStarted = Completer<void>();
        final callbackCompleter = Completer<void>();

        final future = mutation.run(
          () => actionCompleter.future,
          onSuccess: (_) {
            callbackStarted.complete();
            return callbackCompleter.future;
          },
        );

        actionCompleter.complete(7);
        await callbackStarted.future;

        expect(mutation.state, isA<MutationSuccess<int>>());

        var futureCompleted = false;
        future.then((_) => futureCompleted = true);
        await Future<void>.delayed(Duration.zero);
        expect(futureCompleted, isFalse);

        callbackCompleter.complete();
        expect(await future, isA<MutationSucceeded<int>>());
        expect(futureCompleted, isTrue);
      });

      test('can be reused after success', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        await mutation.run(() async => 1);
        expect(mutation.data, 1);

        final result = await mutation.run(() async => 2);

        expect(result, isA<MutationSucceeded<int>>());
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);
      });

      test('publishes MutationError and returns MutationErrored', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final exception = StateError('request failed');
        Object? callbackError;
        StackTrace? callbackStackTrace;

        final result = await mutation.run(
          () async => throw exception,
          onError: (error, stackTrace) {
            callbackError = error;
            callbackStackTrace = stackTrace;
          },
        );

        expect(result, isA<MutationErrored<int>>());
        expect(mutation.state, isA<MutationError<int>>());

        final state = mutation.state as MutationError<int>;
        final errored = result as MutationErrored<int>;

        expect(state.error, same(exception));
        expect(state.stackTrace.toString(), isNotEmpty);
        expect(state.errorInfo.message, exception.toString());
        expect(state.errorInfo.code, isNull);
        expect(state.message, exception.toString());
        expect(errored.error, same(exception));
        expect(callbackError, same(exception));
        expect(callbackStackTrace, isNotNull);
        expect(callbackStackTrace.toString(), isNotEmpty);
        expect(identical(state.errorInfo, errored.errorInfo), isTrue);

        expect(mutation.isError, isTrue);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.dataOrNull, isNull);
        expect(() => mutation.data, throwsA(isA<StateError>()));
      });

      test('supports synchronous action throws', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final exception = ArgumentError('invalid argument');

        final result = await mutation.run(() => throw exception);

        expect(result, isA<MutationErrored<int>>());
        expect((result as MutationErrored<int>).error, same(exception));
        expect(mutation.isError, isTrue);
        expect((mutation.state as MutationError<int>).error, same(exception));
      });

      test('awaits an asynchronous onError callback', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final callbackStarted = Completer<void>();
        final callbackCompleter = Completer<void>();

        final future = mutation.run(
          () async => throw StateError('failure'),
          onError: (_, _) {
            callbackStarted.complete();
            return callbackCompleter.future;
          },
        );

        await callbackStarted.future;
        expect(mutation.state, isA<MutationError<int>>());

        var futureCompleted = false;
        future.then((_) => futureCompleted = true);
        await Future<void>.delayed(Duration.zero);
        expect(futureCompleted, isFalse);

        callbackCompleter.complete();
        expect(await future, isA<MutationErrored<int>>());
      });

      test(
        'a throwing onSuccess completes the run future with callback error',
        () async {
          final mutation = Mutation<int>();
          addTearDown(mutation.dispose);
          final callbackError = StateError('success callback failed');

          final future = mutation.run(
            () async => 10,
            onSuccess: (_) => throw callbackError,
          );

          await expectLater(future, throwsA(same(callbackError)));
          expect(mutation.state, isA<MutationSuccess<int>>());
          expect(mutation.data, 10);
        },
      );

      test(
        'a throwing onError completes the run future with callback error',
        () async {
          final mutation = Mutation<int>();
          addTearDown(mutation.dispose);
          final actionError = StateError('action failed');
          final callbackError = StateError('error callback failed');

          final future = mutation.run(
            () async => throw actionError,
            onError: (_, _) => throw callbackError,
          );

          await expectLater(future, throwsA(same(callbackError)));
          expect(
            (mutation.state as MutationError<int>).error,
            same(actionError),
          );
        },
      );

      test('can be reused after an error', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        final failed = await mutation.run(
          () async => throw StateError('first failure'),
        );
        expect(failed, isA<MutationErrored<int>>());
        expect(mutation.isError, isTrue);

        final succeeded = await mutation.run(() async => 10);

        expect(succeeded, isA<MutationSucceeded<int>>());
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 10);
      });
    });

    group('concurrency', () {
      test(
        'latestOnly replaces an older execution and ignores its callbacks',
        () async {
          final mutation = Mutation<int>(
            concurrency: MutationConcurrency.latestOnly,
          );
          addTearDown(mutation.dispose);
          final firstCompleter = Completer<int>();
          final secondCompleter = Completer<int>();
          var firstSuccessCount = 0;
          var firstErrorCount = 0;

          final firstFuture = mutation.run(
            () => firstCompleter.future,
            onSuccess: (_) {
              firstSuccessCount++;
            },
            onError: (_, _) {
              firstErrorCount++;
            },
          );
          final secondFuture = mutation.run(() => secondCompleter.future);

          secondCompleter.complete(2);
          expect(await secondFuture, isA<MutationSucceeded<int>>());
          expect(mutation.data, 2);

          firstCompleter.complete(1);
          final firstResult = await firstFuture;

          expectIgnored(firstResult, MutationIgnoreReason.replaced);
          expect(firstSuccessCount, 0);
          expect(firstErrorCount, 0);
          expect(mutation.state, isA<MutationSuccess<int>>());
          expect(mutation.data, 2);
        },
      );

      test('a replaced execution cannot publish a later error', () async {
        final mutation = Mutation<int>(
          concurrency: MutationConcurrency.latestOnly,
        );
        addTearDown(mutation.dispose);
        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();
        var firstErrorCallbackCount = 0;

        final firstFuture = mutation.run(
          () => firstCompleter.future,
          onError: (_, _) {
            firstErrorCallbackCount++;
          },
        );
        final secondFuture = mutation.run(() => secondCompleter.future);

        secondCompleter.complete(2);
        await secondFuture;

        firstCompleter.completeError(StateError('stale failure'));
        expectIgnored(await firstFuture, MutationIgnoreReason.replaced);
        expect(firstErrorCallbackCount, 0);
        expect(mutation.state, isA<MutationSuccess<int>>());
        expect(mutation.data, 2);
      });

      test(
        'does not notify listeners when a replaced execution completes',
        () async {
          final mutation = Mutation<int>(
            concurrency: MutationConcurrency.latestOnly,
          );
          addTearDown(mutation.dispose);
          final states = <MutationState<int>>[];
          mutation.addListener(() => states.add(mutation.state));

          final firstCompleter = Completer<int>();
          final secondCompleter = Completer<int>();
          final firstFuture = mutation.run(() => firstCompleter.future);
          final secondFuture = mutation.run(() => secondCompleter.future);

          expect(states, hasLength(1));
          expect(states.single, isA<MutationLoading<int>>());

          secondCompleter.complete(2);
          await secondFuture;
          expect(states, hasLength(2));
          expect(states.last, isA<MutationSuccess<int>>());

          firstCompleter.complete(1);
          expectIgnored(await firstFuture, MutationIgnoreReason.replaced);
          expect(states, hasLength(2));
          expect(mutation.data, 2);
        },
      );

      test('parallel allows every execution to publish its outcome', () async {
        final mutation = Mutation<int>(
          concurrency: MutationConcurrency.parallel,
        );
        addTearDown(mutation.dispose);
        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();
        final firstFuture = mutation.run(() => firstCompleter.future);
        final secondFuture = mutation.run(() => secondCompleter.future);

        secondCompleter.complete(2);
        expect(await secondFuture, isA<MutationSucceeded<int>>());
        expect(mutation.data, 2);

        firstCompleter.complete(1);
        expect(await firstFuture, isA<MutationSucceeded<int>>());

        // In parallel mode, the last execution to complete owns the state.
        expect(mutation.state, isA<MutationSuccess<int>>());
        expect(mutation.data, 1);
      });

      test(
        'ignoreIfBusy rejects a second execution without starting it',
        () async {
          final mutation = Mutation<int>(
            concurrency: MutationConcurrency.ignoreIfBusy,
          );
          addTearDown(mutation.dispose);
          final firstCompleter = Completer<int>();
          var secondActionStarted = false;

          final firstFuture = mutation.run(() => firstCompleter.future);
          final secondResult = await mutation.run(() {
            secondActionStarted = true;
            return Future<int>.value(2);
          });

          expectIgnored(secondResult, MutationIgnoreReason.busy);
          expect(secondActionStarted, isFalse);
          expect(mutation.isLoading, isTrue);

          firstCompleter.complete(1);
          expect(await firstFuture, isA<MutationSucceeded<int>>());
          expect(mutation.data, 1);
        },
      );

      test(
        'queue runs executions in order and continues after failure',
        () async {
          final mutation = Mutation<int>(
            concurrency: MutationConcurrency.queue,
          );
          addTearDown(mutation.dispose);
          final firstCompleter = Completer<int>();
          final secondCompleter = Completer<int>();
          final thirdCompleter = Completer<int>();
          final started = <int>[];

          final firstFuture = mutation.run(() {
            started.add(1);
            return firstCompleter.future;
          });
          final secondFuture = mutation.run(() {
            started.add(2);
            return secondCompleter.future;
          });
          final thirdFuture = mutation.run(() {
            started.add(3);
            return thirdCompleter.future;
          });

          expect(started, [1]);

          firstCompleter.completeError(StateError('first failed'));
          expect(await firstFuture, isA<MutationErrored<int>>());
          expect(started, [1, 2]);

          secondCompleter.complete(2);
          expect(await secondFuture, isA<MutationSucceeded<int>>());
          expect(started, [1, 2, 3]);

          thirdCompleter.complete(3);
          expect(await thirdFuture, isA<MutationSucceeded<int>>());
          expect(mutation.data, 3);
        },
      );
    });

    group('listeners', () {
      test('notifies for state transitions and stops after removal', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final firstStates = <MutationState<int>>[];
        var secondListenerCount = 0;

        void firstListener() => firstStates.add(mutation.state);
        void secondListener() => secondListenerCount++;

        mutation
          ..addListener(firstListener)
          ..addListener(secondListener);

        await mutation.run(() async => 1);

        expect(firstStates, hasLength(2));
        expect(firstStates[0], isA<MutationLoading<int>>());
        expect(firstStates[1], isA<MutationSuccess<int>>());
        expect(secondListenerCount, 2);

        mutation
          ..removeListener(firstListener)
          ..removeListener(secondListener);

        await mutation.run(() async => 2);
        expect(firstStates, hasLength(2));
        expect(secondListenerCount, 2);
      });

      test('reset notifies only when the state changes', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        var notificationCount = 0;
        mutation.addListener(() => notificationCount++);

        mutation.reset();
        expect(notificationCount, 0);

        await mutation.run(() async => 42);
        expect(notificationCount, 2);

        mutation.reset();
        expect(notificationCount, 3);
        expect(mutation.isIdle, isTrue);
      });
    });

    group('reset', () {
      test('clears success and error states', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        await mutation.run(() async => 42);
        expect(mutation.isSuccess, isTrue);
        mutation.reset();
        expect(mutation.state, isA<MutationIdle<int>>());
        expect(mutation.dataOrNull, isNull);
        expect(() => mutation.data, throwsA(isA<StateError>()));

        await mutation.run(() async => throw StateError('failure'));
        expect(mutation.isError, isTrue);
        mutation.reset();
        expect(mutation.state, isA<MutationIdle<int>>());
        expect(mutation.isIdle, isTrue);
        expect(mutation.dataOrNull, isNull);
      });

      test('invalidates an active execution that later succeeds', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final actionCompleter = Completer<int>();
        var successCallbackCount = 0;

        final future = mutation.run(
          () => actionCompleter.future,
          onSuccess: (_) {
            successCallbackCount++;
          },
        );

        expect(mutation.isLoading, isTrue);
        mutation.reset();
        expect(mutation.isIdle, isTrue);

        actionCompleter.complete(42);
        expectIgnored(await future, MutationIgnoreReason.reset);
        expect(successCallbackCount, 0);
        expect(mutation.isIdle, isTrue);
        expect(mutation.dataOrNull, isNull);
      });

      test('invalidates an active execution that later fails', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final actionCompleter = Completer<int>();
        var errorCallbackCount = 0;

        final future = mutation.run(
          () => actionCompleter.future,
          onError: (_, _) {
            errorCallbackCount++;
          },
        );

        mutation.reset();
        actionCompleter.completeError(StateError('stale failure'));

        expectIgnored(await future, MutationIgnoreReason.reset);
        expect(errorCallbackCount, 0);
        expect(mutation.isIdle, isTrue);
      });

      test('ignores queued executions without starting them', () async {
        final mutation = Mutation<int>(concurrency: MutationConcurrency.queue);
        addTearDown(mutation.dispose);
        final activeCompleter = Completer<int>();
        var queuedActionStarted = false;

        final activeFuture = mutation.run(() => activeCompleter.future);
        final queuedFuture = mutation.run(() {
          queuedActionStarted = true;
          return Future<int>.value(2);
        });

        mutation.reset();

        expectIgnored(await queuedFuture, MutationIgnoreReason.reset);
        expect(queuedActionStarted, isFalse);

        activeCompleter.complete(1);
        expectIgnored(await activeFuture, MutationIgnoreReason.reset);
        expect(mutation.isIdle, isTrue);
      });

      test('a run started by a reset listener remains valid', () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();
        Future<MutationResult<int>>? secondFuture;

        void listener() {
          if (mutation.isIdle && secondFuture == null) {
            secondFuture = mutation.run(() => secondCompleter.future);
          }
        }

        mutation.addListener(listener);
        final firstFuture = mutation.run(() => firstCompleter.future);

        mutation.reset();
        expect(secondFuture, isNotNull);
        expect(mutation.isLoading, isTrue);

        secondCompleter.complete(2);
        expect(await secondFuture!, isA<MutationSucceeded<int>>());
        expect(mutation.data, 2);

        firstCompleter.complete(1);
        expectIgnored(await firstFuture, MutationIgnoreReason.reset);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        mutation.removeListener(listener);
      });

      test(
        'reset after outcome commit does not invalidate its callback',
        () async {
          final mutation = Mutation<int>();
          addTearDown(mutation.dispose);
          final actionCompleter = Completer<int>();
          final callbackStarted = Completer<void>();
          final callbackCompleter = Completer<void>();

          final future = mutation.run(
            () => actionCompleter.future,
            onSuccess: (_) {
              callbackStarted.complete();
              return callbackCompleter.future;
            },
          );

          actionCompleter.complete(5);
          await callbackStarted.future;
          expect(mutation.isSuccess, isTrue);

          mutation.reset();
          expect(mutation.isIdle, isTrue);

          callbackCompleter.complete();
          expect(await future, isA<MutationSucceeded<int>>());
          expect(mutation.isIdle, isTrue);
        },
      );
    });

    group('dispose', () {
      test('unmounts the mutation and is safe to call more than once', () {
        final mutation = Mutation<int>();

        expect(mutation.mounted, isTrue);
        mutation
          ..dispose()
          ..dispose();
        expect(mutation.mounted, isFalse);
      });

      test('run and reset assert after disposal', () async {
        final runMutation = Mutation<int>()..dispose();
        final resetMutation = Mutation<int>()..dispose();

        await expectLater(
          () => runMutation.run(() async => 1),
          throwsA(isA<AssertionError>()),
        );
        expect(resetMutation.reset, throwsA(isA<AssertionError>()));
      });

      test('an active execution completes as ignored after disposal', () async {
        final mutation = Mutation<int>();
        final actionCompleter = Completer<int>();
        var successCallbackCount = 0;

        final future = mutation.run(
          () => actionCompleter.future,
          onSuccess: (_) {
            successCallbackCount++;
          },
        );

        expect(mutation.isLoading, isTrue);
        mutation.dispose();
        expect(mutation.mounted, isFalse);

        actionCompleter.complete(42);
        expectIgnored(await future, MutationIgnoreReason.disposed);
        expect(successCallbackCount, 0);
        expect(mutation.state, isA<MutationLoading<int>>());
      });

      test(
        'queued executions are ignored without starting after disposal',
        () async {
          final mutation = Mutation<int>(
            concurrency: MutationConcurrency.queue,
          );
          final activeCompleter = Completer<int>();
          var queuedActionStarted = false;

          final activeFuture = mutation.run(() => activeCompleter.future);
          final queuedFuture = mutation.run(() {
            queuedActionStarted = true;
            return Future<int>.value(2);
          });

          mutation.dispose();

          expectIgnored(await queuedFuture, MutationIgnoreReason.disposed);
          expect(queuedActionStarted, isFalse);

          activeCompleter.complete(1);
          expectIgnored(await activeFuture, MutationIgnoreReason.disposed);
        },
      );

      test(
        'does not notify listeners when an active execution completes',
        () async {
          final mutation = Mutation<int>();
          final actionCompleter = Completer<int>();
          var notificationCount = 0;
          mutation.addListener(() => notificationCount++);

          final future = mutation.run(() => actionCompleter.future);
          expect(notificationCount, 1);

          mutation.dispose();
          actionCompleter.complete(1);
          expectIgnored(await future, MutationIgnoreReason.disposed);
          expect(notificationCount, 1);
        },
      );

      test('a committed success callback can finish after disposal', () async {
        final mutation = Mutation<int>();
        final actionCompleter = Completer<int>();
        final callbackStarted = Completer<void>();
        final callbackCompleter = Completer<void>();

        final future = mutation.run(
          () => actionCompleter.future,
          onSuccess: (_) {
            callbackStarted.complete();
            return callbackCompleter.future;
          },
        );

        actionCompleter.complete(9);
        await callbackStarted.future;
        mutation.dispose();
        callbackCompleter.complete();

        expect(await future, isA<MutationSucceeded<int>>());
        expect(mutation.mounted, isFalse);
      });
    });

    test(
      'reset during the loading change notification leaves the mutation idle',
      () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);
        final observer = _ResetOnLoadingObserver(mutation);
        ProviderKit.configure(observer: observer);

        final result = await mutation.run(() async => 42);

        expect(observer.resetTriggered, isTrue);
        expectIgnored(result, MutationIgnoreReason.reset);
        expect(mutation.state, isA<MutationIdle<int>>());
      },
    );

    test(
      'does not start an execution when disposed during the loading notification',
      () async {
        final mutation = Mutation<int>();
        addTearDown(mutation.dispose);

        final observer = _DisposeOnLoadingObserver(mutation);
        ProviderKit.configure(observer: observer);

        var actionStarted = false;
        var successCallbackCalled = false;

        final result = await mutation.run(
          () async {
            actionStarted = true;
            return 42;
          },
          onSuccess: (_) {
            successCallbackCalled = true;
          },
        );

        expect(observer.disposeTriggered, isTrue);
        expectIgnored(result, MutationIgnoreReason.disposed);

        expect(actionStarted, isFalse);
        expect(successCallbackCalled, isFalse);
        expect(mutation.mounted, isFalse);
        expect(mutation.state, isA<MutationIdle<int>>());
      },
    );

    group('error information', () {
      test(
        'resolves error information once for state and execution result',
        () async {
          const customMessage = 'Unable to save changes.';
          var mapperCallCount = 0;

          ProviderKit.configure(
            errorInfoMapper: (error, stackTrace) {
              mapperCallCount++;
              return const ErrorInfo(
                message: customMessage,
                code: 'save_failed',
              );
            },
          );

          final mutation = Mutation<int>();
          addTearDown(mutation.dispose);
          final exception = StateError('database failure');

          final result = await mutation.run(() async => throw exception);
          expect(result, isA<MutationErrored<int>>());

          final state = mutation.state as MutationError<int>;
          final errored = result as MutationErrored<int>;

          expect(mapperCallCount, 1);
          expect(state.error, same(exception));
          expect(state.errorInfo.message, customMessage);
          expect(state.errorInfo.code, 'save_failed');
          expect(state.message, customMessage);
          expect(errored.errorInfo.message, customMessage);
          expect(identical(state.errorInfo, errored.errorInfo), isTrue);
        },
      );
    });

    test('falls back when the configured ErrorInfoMapper throws', () async {
      final mapperError = StateError('mapper failed');
      final originalError = StateError('operation failed');

      ProviderKit.configure(
        errorInfoMapper: (error, stackTrace) {
          throw mapperError;
        },
      );

      final mutation = Mutation<int>();
      addTearDown(mutation.dispose);

      var onErrorCalled = false;

      final result = await mutation.run(
        () async => throw originalError,
        onError: (error, stackTrace) {
          onErrorCalled = true;
          expect(error, same(originalError));
        },
      );

      expect(onErrorCalled, isTrue);
      expect(result, isA<MutationErrored<int>>());
      expect(mutation.state, isA<MutationError<int>>());

      final state = mutation.state as MutationError<int>;
      final errored = result as MutationErrored<int>;

      expect(state.error, same(originalError));
      expect(errored.error, same(originalError));

      expect(state.errorInfo.message, originalError.toString());
      expect(errored.errorInfo.message, originalError.toString());

      expect(identical(state.errorInfo, errored.errorInfo), isTrue);
    });
  });
}

void expectIgnored<T>(MutationResult<T> result, MutationIgnoreReason reason) {
  expect(result, isA<MutationIgnored<T>>());
  expect((result as MutationIgnored<T>).reason, reason);
}

class _ResetOnLoadingObserver extends NotifierObserver {
  _ResetOnLoadingObserver(this.mutation);

  final Mutation<int> mutation;
  bool resetTriggered = false;

  @override
  void onChange(NotifierBase notifier, Change change) {
    if (!resetTriggered &&
        identical(notifier, mutation) &&
        change.nextState is MutationLoading<int>) {
      resetTriggered = true;
      mutation.reset();
    }

    super.onChange(notifier, change);
  }
}

class _DisposeOnLoadingObserver extends NotifierObserver {
  _DisposeOnLoadingObserver(this.mutation);

  final Mutation<int> mutation;

  bool disposeTriggered = false;

  @override
  void onChange(NotifierBase notifier, Change change) {
    if (!disposeTriggered &&
        identical(notifier, mutation) &&
        change.nextState is MutationLoading<int>) {
      disposeTriggered = true;
      mutation.dispose();
    }

    super.onChange(notifier, change);
  }
}
