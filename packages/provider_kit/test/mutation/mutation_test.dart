// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('Mutation', () {
    group('initial state', () {
      test('starts in idle state', () {
        final mutation = Mutation<int>();

        expect(mutation.state, isA<MutationIdle<int>>());

        expect(mutation.isIdle, isTrue);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.isError, isFalse);
        expect(mutation.data, isNull);
        expect(mutation.hasListeners, isFalse);

        mutation.dispose();
      });

      test('starts mounted', () {
        final mutation = Mutation<int>();

        expect(mutation.mounted, isTrue);

        mutation.dispose();

        expect(mutation.mounted, isFalse);
      });
    });

    group('run', () {
      test('transitions to loading before executor starts', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        var executorStarted = false;
        final states = <MutationState<int>>[];

        mutation.addListener(() {
          states.add(mutation.state);
        });

        final future = mutation.run(() {
          executorStarted = true;
          return completer.future;
        });

        expect(executorStarted, isTrue);
        expect(mutation.state, isA<MutationLoading<int>>());

        expect(states, hasLength(1));
        expect(states.single, isA<MutationLoading<int>>());

        completer.complete(42);

        final result = await future;

        expect(result, 42);
        expect(mutation.state, isA<MutationSuccess<int>>());
        expect(mutation.data, 42);

        expect(mutation.isIdle, isFalse);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.isError, isFalse);

        expect(states, hasLength(2));
        expect(states[1], isA<MutationSuccess<int>>());

        mutation.dispose();
      });

      test('returns executor result on success', () async {
        final mutation = Mutation<String>();

        final result = await mutation.run(() async => 'result');

        expect(result, 'result');
        expect(mutation.data, 'result');
        expect(mutation.state, isA<MutationSuccess<String>>());

        mutation.dispose();
      });

      test('stores the successful result in MutationSuccess', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 123);

        final state = mutation.state;

        expect(state, isA<MutationSuccess<int>>());

        final success = state as MutationSuccess<int>;

        expect(success.data, 123);
        expect(mutation.data, 123);

        mutation.dispose();
      });

      test('supports nullable success values', () async {
        final mutation = Mutation<int?>();

        final result = await mutation.run(() async => null);

        expect(result, isNull);
        expect(mutation.state, isA<MutationSuccess<int?>>());
        expect(mutation.data, isNull);
        expect(mutation.isSuccess, isTrue);

        mutation.dispose();
      });

      test('supports void mutations', () async {
        final mutation = Mutation<void>();

        var executed = false;

        await mutation.run(() async {
          executed = true;
        });

        expect(executed, isTrue);
        expect(mutation.state, isA<MutationSuccess<void>>());
        expect(mutation.isSuccess, isTrue);

        mutation.dispose();
      });

      test('transitions to error when executor throws', () async {
        final mutation = Mutation<int>();
        final exception = StateError('something went wrong');

        final future = mutation.run(() async {
          throw exception;
        });

        await expectLater(future, throwsA(same(exception)));

        expect(mutation.state, isA<MutationError<int>>());

        final state = mutation.state as MutationError<int>;

        expect(state.error, same(exception));
        expect(state.stackTrace.toString(), isNotEmpty);

        expect(mutation.isIdle, isFalse);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.isError, isTrue);
        expect(mutation.data, isNull);

        mutation.dispose();
      });

      test('rethrown error preserves the original error instance', () async {
        final mutation = Mutation<int>();
        final exception = Exception('failure');

        Object? caughtError;

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (error) {
          caughtError = error;
        }

        expect(caughtError, same(exception));

        mutation.dispose();
      });

      test('captures a stack trace in MutationError', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {
          // Expected.
        }

        final state = mutation.state as MutationError<int>;

        expect(state.stackTrace.toString(), isNotEmpty);

        mutation.dispose();
      });

      test('supports synchronous executor throws', () async {
        final mutation = Mutation<int>();
        final exception = ArgumentError('invalid argument');

        final future = mutation.run(() {
          throw exception;
        });

        await expectLater(future, throwsA(same(exception)));

        expect(mutation.isError, isTrue);

        final state = mutation.state as MutationError<int>;
        expect(state.error, same(exception));

        mutation.dispose();
      });

      test('can be reused after success', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 1);
        expect(mutation.data, 1);

        await mutation.run(() async => 2);

        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        mutation.dispose();
      });

      test('can be reused after error', () async {
        final mutation = Mutation<int>();

        try {
          await mutation.run(() async {
            throw StateError('first failure');
          });
        } catch (_) {}

        expect(mutation.isError, isTrue);

        final result = await mutation.run(() async => 10);

        expect(result, 10);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 10);

        mutation.dispose();
      });

      test('latest concurrent execution wins', () async {
        final mutation = Mutation<int>();

        final first = Completer<int>();
        final second = Completer<int>();

        final firstFuture = mutation.run(() => first.future);
        final secondFuture = mutation.run(() => second.future);

        expect(mutation.isLoading, isTrue);

        second.complete(2);

        expect(await secondFuture, 2);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        first.complete(1);

        expect(await firstFuture, 1);

        // The stale first execution must not overwrite the latest result.
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        mutation.dispose();
      });

      test('does not notify for stale concurrent completion', () async {
        final mutation = Mutation<int>();
        final states = <MutationState<int>>[];

        mutation.addListener(() {
          states.add(mutation.state);
        });

        final first = Completer<int>();
        final second = Completer<int>();

        final firstFuture = mutation.run(() => first.future);
        final secondFuture = mutation.run(() => second.future);

        expect(states, hasLength(1));
        expect(states.single, isA<MutationLoading<int>>());

        second.complete(2);
        await secondFuture;

        expect(states, hasLength(2));
        expect(states.last, isA<MutationSuccess<int>>());

        first.complete(1);
        await firstFuture;

        // No additional state change from stale run.
        expect(states, hasLength(2));
        expect(mutation.data, 2);

        mutation.dispose();
      });
      test('stale concurrent error cannot overwrite latest success', () async {
        final mutation = Mutation<int>();

        final first = Completer<int>();
        final second = Completer<int>();

        final firstFuture = mutation.run(() => first.future);
        final secondFuture = mutation.run(() => second.future);

        second.complete(2);

        expect(await secondFuture, 2);
        expect(mutation.data, 2);

        final exception = StateError('stale failure');
        first.completeError(exception);

        await expectLater(
          firstFuture,
          throwsA(same(exception)),
        );

        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);
        expect(mutation.isError, isFalse);

        mutation.dispose();
      });
    });

    group('listeners', () {
      test('notifies listeners for distinct state transitions', () async {
        final mutation = Mutation<int>();
        final states = <MutationState<int>>[];

        void listener() {
          states.add(mutation.state);
        }

        mutation.addListener(listener);

        await mutation.run(() async => 42);

        expect(states, hasLength(2));
        expect(states[0], isA<MutationLoading<int>>());
        expect(states[1], isA<MutationSuccess<int>>());

        mutation.removeListener(listener);
        mutation.dispose();
      });

      test('notifies listener when reset changes state', () async {
        final mutation = Mutation<int>();
        var notificationCount = 0;

        mutation.addListener(() {
          notificationCount++;
        });

        await mutation.run(() async => 42);

        expect(notificationCount, 2);

        mutation.reset();

        expect(notificationCount, 3);
        expect(mutation.isIdle, isTrue);

        mutation.dispose();
      });

      test('does not notify when reset is called while already idle', () {
        final mutation = Mutation<int>();
        var notificationCount = 0;

        mutation.addListener(() {
          notificationCount++;
        });

        mutation.reset();

        expect(notificationCount, 0);
        expect(mutation.isIdle, isTrue);

        mutation.dispose();
      });

      test('supports multiple listeners', () async {
        final mutation = Mutation<int>();

        var firstListenerCount = 0;
        var secondListenerCount = 0;

        void firstListener() {
          firstListenerCount++;
        }

        void secondListener() {
          secondListenerCount++;
        }

        mutation
          ..addListener(firstListener)
          ..addListener(secondListener);

        await mutation.run(() async => 1);

        expect(firstListenerCount, 2);
        expect(secondListenerCount, 2);

        mutation
          ..removeListener(firstListener)
          ..removeListener(secondListener)
          ..dispose();
      });

      test('does not notify removed listeners', () async {
        final mutation = Mutation<int>();

        var notificationCount = 0;

        void listener() {
          notificationCount++;
        }

        mutation.addListener(listener);
        mutation.removeListener(listener);

        await mutation.run(() async => 1);

        expect(notificationCount, 0);

        mutation.dispose();
      });
    });

    group('reset', () {
      test('resets success state to idle', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        expect(mutation.isSuccess, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);
        expect(mutation.isLoading, isFalse);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.isError, isFalse);
        expect(mutation.data, isNull);

        mutation.dispose();
      });

      test('resets error state to idle', () async {
        final mutation = Mutation<int>();

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        expect(mutation.isError, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);
        expect(mutation.data, isNull);

        mutation.dispose();
      });

      test('reset invalidates an active execution', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        expect(mutation.isLoading, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);

        completer.complete(42);

        expect(await future, 42);

        // The stale execution must not restore Success.
        expect(mutation.isIdle, isTrue);
        expect(mutation.isSuccess, isFalse);
        expect(mutation.data, isNull);

        mutation.dispose();
      });
      test(
          'reset success state to idle does not retain the mutation as success',
          () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final mutation = group('key');

        await mutation.run(() async => 42);

        expect(mutation.mounted, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('reset error state to idle removes error retention', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.error,
          },
        );

        final mutation = group('key');

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        expect(mutation.mounted, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });
      test('reset invalidates an active execution that fails', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        mutation.reset();

        expect(mutation.isIdle, isTrue);

        final exception = StateError('failure');

        completer.completeError(exception);

        await expectLater(
          future,
          throwsA(same(exception)),
        );

        // The stale execution must not publish MutationError.
        expect(mutation.isIdle, isTrue);
        expect(mutation.isError, isFalse);

        mutation.dispose();
      });

      test('run started during reset notification remains valid', () async {
        final mutation = Mutation<int>();

        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();

        Future<int>? secondFuture;

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

        expect(await secondFuture!, 2);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        firstCompleter.complete(1);

        expect(await firstFuture, 1);

        // First run is stale and must not overwrite the second run.
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        mutation.removeListener(listener);
        mutation.dispose();
      });
    });

    group('data and convenience getters', () {
      test('data is null in idle state', () {
        final mutation = Mutation<int>();

        expect(mutation.data, isNull);

        mutation.dispose();
      });

      test('data is null while loading', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        expect(mutation.data, isNull);
        expect(mutation.isLoading, isTrue);

        completer.complete(42);

        await future;

        mutation.dispose();
      });

      test('data is null in error state', () async {
        final mutation = Mutation<int>();

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        expect(mutation.data, isNull);
        expect(mutation.isError, isTrue);

        mutation.dispose();
      });

      test('getter flags always match the current state', () async {
        final mutation = Mutation<String>();
        final completer = Completer<String>();

        expect(mutation.isIdle, isTrue);

        final future = mutation.run(() => completer.future);

        expect(mutation.isLoading, isTrue);

        completer.complete('success');
        await future;

        expect(mutation.isSuccess, isTrue);

        mutation.reset();

        expect(mutation.isIdle, isTrue);

        mutation.dispose();
      });
    });

    group('dispose', () {
      test('marks mutation as unmounted after dispose', () {
        final mutation = Mutation<int>();

        expect(mutation.mounted, isTrue);

        mutation.dispose();

        expect(mutation.mounted, isFalse);
      });

      test('run throws after disposal', () {
        final mutation = Mutation<int>();

        mutation.dispose();

        expect(
          () => mutation.run(() async => 1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('reset throws after disposal', () {
        final mutation = Mutation<int>();

        mutation.dispose();

        expect(
          mutation.reset,
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('execution completes after disposal', () {
      test('successful execution does not update state after disposal',
          () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        expect(mutation.isLoading, isTrue);

        mutation.dispose();

        completer.complete(42);

        expect(await future, 42);

        expect(mutation.mounted, isFalse);
        expect(mutation.state, isA<MutationLoading<int>>());
      });

      test('failed execution does not update state after disposal', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        mutation.dispose();

        final exception = StateError('failure');
        completer.completeError(exception);

        await expectLater(future, throwsA(same(exception)));

        expect(mutation.mounted, isFalse);
        expect(mutation.state, isA<MutationLoading<int>>());
      });
    });
  });
}
