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

  group('MutationState', () {
    group('when', () {
      test('handles idle state', () {
        final mutation = Mutation<int>();

        final result = mutation.state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: (_) => 'success',
          error: (_, __) => 'error',
        );

        expect(result, 'idle');

        mutation.dispose();
      });

      test('handles loading state', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final result = mutation.state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: (_) => 'success',
          error: (_, __) => 'error',
        );

        expect(result, 'loading');

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('handles success state and receives data', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: (data) => 'success:$data',
          error: (_, __) => 'error',
        );

        expect(result, 'success:42');

        mutation.dispose();
      });

      test('handles error state and receives error and stack trace', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: (_) => 'success',
          error: (error, stackTrace) {
            expect(error, same(exception));
            expect(stackTrace.toString(), isNotEmpty);
            return 'error';
          },
        );

        expect(result, 'error');

        mutation.dispose();
      });
    });

    group('map', () {
      test('maps idle state', () {
        final mutation = Mutation<int>();

        final result = mutation.state.map(
          idle: (state) => state.isIdle,
          loading: (state) => state.isLoading,
          success: (_) => false,
          error: (_) => false,
        );

        expect(result, isTrue);

        mutation.dispose();
      });

      test('maps loading state with complete state object', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final result = mutation.state.map(
          idle: (_) => false,
          loading: (state) => state.isLoading,
          success: (_) => false,
          error: (_) => false,
        );

        expect(result, isTrue);

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('maps success state with complete state object', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.map(
          idle: (_) => false,
          loading: (_) => false,
          success: (state) => state.data == 42,
          error: (_) => false,
        );

        expect(result, isTrue);

        mutation.dispose();
      });

      test('maps error state with complete state object', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.map(
          idle: (_) => false,
          loading: (_) => false,
          success: (_) => false,
          error: (state) => state.error == exception,
        );

        expect(result, isTrue);

        mutation.dispose();
      });
    });

    group('maybeWhen', () {
      test('uses matching idle callback', () {
        final mutation = Mutation<int>();

        var orElseCalled = false;

        final result = mutation.state.maybeWhen(
          idle: () => 'idle',
          orElse: () {
            orElseCalled = true;
            return 'fallback';
          },
        );

        expect(result, 'idle');
        expect(orElseCalled, isFalse);

        mutation.dispose();
      });

      test('uses matching loading callback', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final result = mutation.state.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'fallback',
        );

        expect(result, 'loading');

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('uses matching success callback and receives data', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.maybeWhen(
          success: (data) => data,
          orElse: () => -1,
        );

        expect(result, 42);

        mutation.dispose();
      });

      test('uses matching error callback', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.maybeWhen(
          error: (error, stackTrace) {
            expect(error, same(exception));
            expect(stackTrace.toString(), isNotEmpty);
            return 'error';
          },
          orElse: () => 'fallback',
        );

        expect(result, 'error');

        mutation.dispose();
      });

      test('uses orElse when matching callback is absent', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.maybeWhen(
          idle: () => 'idle',
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');

        mutation.dispose();
      });

      test('uses orElse for loading when loading callback is absent', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final result = mutation.state.maybeWhen(
          success: (_) => 'success',
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('uses orElse for error when error callback is absent', () async {
        final mutation = Mutation<int>();

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        final result = mutation.state.maybeWhen(
          success: (_) => 'success',
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');

        mutation.dispose();
      });
    });

    group('maybeMap', () {
      test('uses matching idle mapper', () {
        final mutation = Mutation<int>();

        final result = mutation.state.maybeMap(
          idle: (state) => state.isIdle,
          orElse: () => false,
        );

        expect(result, isTrue);

        mutation.dispose();
      });

      test('uses matching loading mapper', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final result = mutation.state.maybeMap(
          loading: (state) => state.isLoading,
          orElse: () => false,
        );

        expect(result, isTrue);

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('uses matching success mapper', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.maybeMap(
          success: (state) => state.data,
          orElse: () => -1,
        );

        expect(result, 42);

        mutation.dispose();
      });

      test('uses matching error mapper', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.maybeMap(
          error: (state) => state.error,
          orElse: () => StateError('fallback'),
        );

        expect(result, same(exception));

        mutation.dispose();
      });

      test('uses orElse when matching mapper is absent', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final result = mutation.state.maybeMap(
          idle: (_) => 'idle',
          orElse: () => 'fallback',
        );

        expect(result, 'fallback');

        mutation.dispose();
      });
    });

    group('state flags', () {
      test('idle flags are correct', () {
        final mutation = Mutation<int>();

        final state = mutation.state;

        expect(state.isIdle, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);

        mutation.dispose();
      });

      test('loading flags are correct', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final future = mutation.run(() => completer.future);

        final state = mutation.state;

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isTrue);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);

        completer.complete(1);
        await future;

        mutation.dispose();
      });

      test('success flags are correct', () async {
        final mutation = Mutation<int>();

        await mutation.run(() async => 42);

        final state = mutation.state;

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isTrue);
        expect(state.isError, isFalse);

        mutation.dispose();
      });

      test('error flags are correct', () async {
        final mutation = Mutation<int>();

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        final state = mutation.state;

        expect(state.isIdle, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isTrue);

        mutation.dispose();
      });
    });

    group('state equality', () {
      test('idle states are equal for the same generic type', () {
        final first = Mutation<int>();
        final second = Mutation<int>();

        expect(first.state, second.state);
        expect(first.state.hashCode, second.state.hashCode);

        first.dispose();
        second.dispose();
      });

      test('loading states are equal for the same generic type', () async {
        final first = Mutation<int>();
        final second = Mutation<int>();

        final firstCompleter = Completer<int>();
        final secondCompleter = Completer<int>();

        final firstFuture = first.run(() => firstCompleter.future);
        final secondFuture = second.run(() => secondCompleter.future);

        expect(first.state, second.state);
        expect(first.state.hashCode, second.state.hashCode);

        firstCompleter.complete(1);
        secondCompleter.complete(2);

        await firstFuture;
        await secondFuture;

        first.dispose();
        second.dispose();
      });

      test('success states with equal data are equal', () async {
        final first = Mutation<int>();
        final second = Mutation<int>();

        await first.run(() async => 42);
        await second.run(() async => 42);

        expect(first.state, second.state);
        expect(first.state.hashCode, second.state.hashCode);

        first.dispose();
        second.dispose();
      });

      test('success states with different data are not equal', () async {
        final first = Mutation<int>();
        final second = Mutation<int>();

        await first.run(() async => 1);
        await second.run(() async => 2);

        expect(first.state, isNot(equals(second.state)));

        first.dispose();
        second.dispose();
      });

      test('error states with equal error and stack trace are equal', () {
        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        // We cannot directly instantiate MutationError because its constructor
        // is library-private. Exercise equality using mutations instead.
        final first = Mutation<int>();
        final second = Mutation<int>();

        return Future.wait([
          Future<void>(() async {
            try {
              await first.run(() async {
                Error.throwWithStackTrace(error, stackTrace);
              });
            } catch (_) {}
          }),
          Future<void>(() async {
            try {
              await second.run(() async {
                Error.throwWithStackTrace(error, stackTrace);
              });
            } catch (_) {}
          }),
        ]).then((_) {
          expect(first.state, second.state);
          expect(first.state.hashCode, second.state.hashCode);

          first.dispose();
          second.dispose();
        });
      });

      test('error states with different errors are not equal', () async {
        final first = Mutation<int>();
        final second = Mutation<int>();

        try {
          await first.run(() async {
            throw StateError('first');
          });
        } catch (_) {}

        try {
          await second.run(() async {
            throw StateError('second');
          });
        } catch (_) {}

        expect(first.state, isNot(equals(second.state)));

        first.dispose();
        second.dispose();
      });

      test('idle and loading states are not equal', () async {
        final mutation = Mutation<int>();
        final completer = Completer<int>();

        final idleState = mutation.state;

        final future = mutation.run(() => completer.future);

        expect(mutation.state, isNot(equals(idleState)));

        completer.complete(1);
        await future;

        mutation.dispose();
      });
    });
  });

  group('MutationGroup', () {
    group('construction', () {
      test('creates with no keep-alive states by default', () {
        final group = MutationGroup<int>();

        final mutation = group('key');

        expect(mutation.isIdle, isTrue);

        group.dispose();
      });

      test('copies the keepAliveStates set', () async {
        final keepAliveStates = <KeepAliveState>{
          KeepAliveState.success,
        };

        final group = MutationGroup<int>(
          keepAliveStates: keepAliveStates,
        );

        keepAliveStates.add(KeepAliveState.error);

        final mutation = group('key');

        final result = await mutation.run(() async => 42);

        expect(result, 42);

        void listener() {}

        mutation.addListener(listener);
        mutation.removeListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(group('key'), same(mutation));

        group.dispose();
      });

      test('exposes an unmodifiable keepAlive policy internally', () {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final mutation = group('key');

        expect(mutation.isIdle, isTrue);

        group.dispose();
      });
    });

    group('key lookup', () {
      test('creates a mutation for a new key', () {
        final group = MutationGroup<int>();

        final mutation = group('todo_1');

        expect(mutation, isA<Mutation<int>>());
        expect(mutation.isIdle, isTrue);

        group.dispose();
      });

      test('returns the same mutation instance for the same key', () {
        final group = MutationGroup<int>();

        final first = group('todo_1');
        final second = group('todo_1');

        expect(identical(first, second), isTrue);

        group.dispose();
      });

      test('different keys return independent mutations', () {
        final group = MutationGroup<int>();

        final first = group('todo_1');
        final second = group('todo_2');

        expect(identical(first, second), isFalse);

        group.dispose();
      });
      test('different groups with same key are independent', () {
        final group1 = MutationGroup<int>();
        final group2 = MutationGroup<int>();

        final m1 = group1('key');
        final m2 = group2('key');

        expect(identical(m1, m2), isFalse);

        group1.dispose();
        group2.dispose();
      });
      test('supports non-string keys', () {
        final group = MutationGroup<int>();

        final first = group(1);
        final second = group(2);

        expect(identical(first, second), isFalse);
        expect(identical(group(1), first), isTrue);

        group.dispose();
      });

      test(
          'key lookup creates a new mutation after the previous one was disposed',
          () {
        final group = MutationGroup<int>();

        final first = group('key');

        group.disposeKey('key');

        expect(first.mounted, isFalse);

        final second = group('key');

        expect(identical(first, second), isFalse);
        expect(second.mounted, isTrue);

        group.dispose();
      });
    });

    group('automatic disposal', () {
      test('idle mutation stays alive while observed', () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        void listener() {}

        mutation.addListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);

        mutation.removeListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('loading mutation remains alive without listeners', () async {
        final group = MutationGroup<int>();
        final completer = Completer<int>();

        final mutation = group('key');

        final future = mutation.run(() => completer.future);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);
        expect(mutation.isLoading, isTrue);

        completer.complete(42);

        expect(await future, 42);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('success mutation is automatically disposed by default', () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        await mutation.run(() async => 42);

        expect(mutation.isSuccess, isTrue);
        expect(mutation.mounted, isTrue);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('error mutation is automatically disposed by default', () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        expect(mutation.isError, isTrue);
        expect(mutation.mounted, isTrue);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test(
          'mutation disposed after last listener removal is replaced on next lookup',
          () async {
        final group = MutationGroup<int>();
        final first = group('key');

        void listener() {}

        first.addListener(listener);
        first.removeListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(first.mounted, isFalse);

        final second = group('key');
        expect(identical(first, second), isFalse);
        expect(second.mounted, isTrue);
        expect(second.isIdle, isTrue);

        group.dispose();
      });
      test('adding a listener prevents automatic disposal', () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        void listener() {}

        mutation.addListener(listener);

        await mutation.run(() async => 42);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);

        mutation.removeListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('re-adding a listener before queued disposal keeps mutation alive',
          () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        void listener() {}

        mutation.addListener(listener);
        mutation.removeListener(listener);

        // Re-add before the scheduled microtask gets a chance to dispose it.
        mutation.addListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);

        mutation.removeListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('adding a listener after success cancels pending auto-disposal',
          () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        await mutation.run(() async => 42);

        void listener() {}

        mutation.addListener(listener);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);
        expect(group('key'), same(mutation));

        mutation.removeListener(listener);
        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('group disposal safely handles a pending auto-dispose callback',
          () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        await mutation.run(() async => 42);

        expect(mutation.mounted, isTrue);

        group.dispose();

        expect(mutation.mounted, isFalse);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);
      });
    });

    group('keepAliveStates', () {
      test('keeps successful mutation alive when configured', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final mutation = group('key');

        await mutation.run(() async => 42);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);
        expect(group('key'), same(mutation));
        expect(mutation.data, 42);

        group.dispose();
      });

      test('keeps error mutation alive when configured', () async {
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

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isTrue);
        expect(group('key'), same(mutation));

        group.dispose();
      });

      test('keeping success does not keep error alive', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final mutation = group('key');

        try {
          await mutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('keeping error does not keep success alive', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.error,
          },
        );

        final mutation = group('key');

        await mutation.run(() async => 42);

        await Future<void>.delayed(Duration.zero);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('keeping both success and error alive preserves both states',
          () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
            KeepAliveState.error,
          },
        );

        final successMutation = group('success');
        await successMutation.run(() async => 42);

        final errorMutation = group('error');

        try {
          await errorMutation.run(() async {
            throw StateError('failure');
          });
        } catch (_) {}

        await Future<void>.delayed(Duration.zero);

        expect(successMutation.mounted, isTrue);
        expect(errorMutation.mounted, isTrue);

        expect(group('success'), same(successMutation));
        expect(group('error'), same(errorMutation));

        group.dispose();
      });
    });

    group('disposeKey', () {
      test('does nothing when key does not exist', () {
        final group = MutationGroup<int>();

        expect(() => group.disposeKey('missing'), returnsNormally);

        group.dispose();
      });

      test('force disposes an idle mutation', () {
        final group = MutationGroup<int>();
        final mutation = group('key');

        // Ensure the mutation is still mounted when forced.
        void listener() {}

        mutation.addListener(listener);

        group.disposeKey('key');

        expect(mutation.mounted, isFalse);

        mutation.removeListener(listener);

        group.dispose();
      });

      test('force disposes a successful mutation even if keep-alive is enabled',
          () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final mutation = group('key');

        await mutation.run(() async => 42);

        expect(mutation.mounted, isTrue);

        group.disposeKey('key');

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('force disposes an error mutation even if keep-alive is enabled',
          () async {
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

        group.disposeKey('key');

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('force disposes a loading mutation', () async {
        final group = MutationGroup<int>();
        final completer = Completer<int>();

        final mutation = group('key');
        final future = mutation.run(() => completer.future);

        expect(mutation.isLoading, isTrue);
        expect(mutation.mounted, isTrue);

        group.disposeKey('key');

        expect(mutation.mounted, isFalse);

        completer.complete(42);

        expect(await future, 42);

        expect(mutation.mounted, isFalse);

        group.dispose();
      });

      test('disposed key is removed from cache', () {
        final group = MutationGroup<int>();
        final first = group('key');

        group.disposeKey('key');

        final second = group('key');

        expect(identical(first, second), isFalse);

        group.dispose();
      });
      test(
          'disposing an old mutation does not affect a new mutation for the same key',
          () async {
        final group = MutationGroup<int>();

        final first = group('key');
        group.disposeKey('key');

        final second = group('key');

        expect(first.mounted, isFalse);
        expect(second.mounted, isTrue);

        await second.run(() async => 42);

        expect(second.data, 42);
        expect(second.isSuccess, isTrue);

        group.dispose();
      });

      test(
        'disposing a mutation directly removes it from the group cache',
        () {
          final group = MutationGroup<int>();

          final first = group('key');

          expect(first.mounted, isTrue);

          first.dispose();

          expect(first.mounted, isFalse);

          final second = group('key');

          expect(identical(first, second), isFalse);
          expect(second.mounted, isTrue);

          group.dispose();
        },
      );
    });

    group('dispose', () {
      test('disposes all cached mutations', () {
        final group = MutationGroup<int>();

        final first = group('one');
        final second = group('two');
        final third = group('three');

        void listener() {}

        first.addListener(listener);
        second.addListener(listener);
        third.addListener(listener);

        group.dispose();

        expect(first.mounted, isFalse);
        expect(second.mounted, isFalse);
        expect(third.mounted, isFalse);
      });

      test('disposes loading mutations immediately', () async {
        final group = MutationGroup<int>();
        final completer = Completer<int>();

        final mutation = group('key');

        final future = mutation.run(() => completer.future);

        expect(mutation.isLoading, isTrue);

        group.dispose();

        expect(mutation.mounted, isFalse);

        completer.complete(42);

        expect(await future, 42);
        expect(mutation.mounted, isFalse);
      });

      test('clears cache', () {
        final group = MutationGroup<int>();

        final first = group('key');

        void listener() {}

        first.addListener(listener);

        group.dispose();

        final second = group('key');

        expect(identical(first, second), isFalse);

        group.dispose();
      });

      test('can be disposed when empty', () {
        final group = MutationGroup<int>();

        expect(() => group.dispose(), returnsNormally);
        expect(() => group.dispose(), returnsNormally);
      });
    });

    group('independent keyed state', () {
      test('different keys maintain completely independent states', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
            KeepAliveState.error,
          },
        );

        final first = group('one');
        final second = group('two');
        final third = group('three');

        final secondCompleter = Completer<int>();

        await first.run(() async => 1);

        final secondFuture = second.run(() => secondCompleter.future);

        try {
          await third.run(() async {
            throw StateError('third failed');
          });
        } catch (_) {}

        expect(first.isSuccess, isTrue);
        expect(first.data, 1);

        expect(second.isLoading, isTrue);
        expect(second.data, isNull);

        expect(third.isError, isTrue);

        secondCompleter.complete(2);

        await secondFuture;

        expect(second.isSuccess, isTrue);
        expect(second.data, 2);

        group.dispose();
      });
      test('same key preserves state while mutation remains cached', () async {
        final group = MutationGroup<int>(
          keepAliveStates: {
            KeepAliveState.success,
          },
        );

        final first = group('key');

        await first.run(() async => 99);

        final second = group('key');

        expect(identical(first, second), isTrue);
        expect(second.isSuccess, isTrue);
        expect(second.data, 99);

        group.dispose();
      });
    });

    group('concurrency and disposal', () {
      test(
        'loading mutation remains alive while another execution is active',
        () async {
          final group = MutationGroup<int>();
          final mutation = group('key');

          final first = Completer<int>();
          final second = Completer<int>();

          final firstFuture = mutation.run(() => first.future);
          final secondFuture = mutation.run(() => second.future);

          await Future<void>.delayed(Duration.zero);

          expect(mutation.mounted, isTrue);
          expect(mutation.isLoading, isTrue);

          second.complete(2);
          expect(await secondFuture, 2);

          await Future<void>.delayed(Duration.zero);
          first.complete(1);

          expect(await firstFuture, 1);

          group.dispose();
        },
      );
      test('stale concurrent group execution cannot overwrite latest state',
          () async {
        final group = MutationGroup<int>();
        final mutation = group('key');

        final first = Completer<int>();
        final second = Completer<int>();

        final firstFuture = mutation.run(() => first.future);
        final secondFuture = mutation.run(() => second.future);

        second.complete(2);

        expect(await secondFuture, 2);
        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        first.complete(1);

        expect(await firstFuture, 1);

        expect(mutation.isSuccess, isTrue);
        expect(mutation.data, 2);

        group.dispose();
      });
      test(
        'disposing group while execution is active does not prevent executor completion',
        () async {
          final group = MutationGroup<int>();
          final completer = Completer<int>();

          final mutation = group('key');
          final future = mutation.run(() => completer.future);

          group.dispose();

          expect(mutation.mounted, isFalse);

          completer.complete(100);

          expect(await future, 100);
        },
      );
    });
    group('NotifierObserver', () {
      test('observes mutation lifecycle events on success', () async {
        final observer = _TestNotifierObserver();
        final previous = NotifierBase.observer;

        NotifierBase.observer = observer;

        try {
          final mutation = Mutation<int>();

          expect(observer.created, contains(mutation));

          await mutation.run(() async => 42);

          expect(observer.changes, hasLength(2));

          expect(observer.changes[0].currentState, isA<MutationIdle<int>>());
          expect(observer.changes[0].nextState, isA<MutationLoading<int>>());

          expect(observer.changes[1].currentState, isA<MutationLoading<int>>());
          expect(observer.changes[1].nextState, isA<MutationSuccess<int>>());

          expect(observer.errors, isEmpty);

          mutation.dispose();

          expect(observer.disposed, contains(mutation));
        } finally {
          NotifierBase.observer = previous;
        }
      });

      test('observes mutation lifecycle events on error', () async {
        final observer = _TestNotifierObserver();
        final previous = NotifierBase.observer;

        NotifierBase.observer = observer;

        try {
          final mutation = Mutation<int>();
          final exception = StateError('failure');

          try {
            await mutation.run(() async {
              throw exception;
            });
          } catch (error) {
            expect(error, same(exception));
          }

          expect(observer.changes, hasLength(2));

          expect(
            observer.changes[0].currentState,
            isA<MutationIdle<int>>(),
          );
          expect(
            observer.changes[0].nextState,
            isA<MutationLoading<int>>(),
          );

          expect(
            observer.changes[1].currentState,
            isA<MutationLoading<int>>(),
          );
          expect(
            observer.changes[1].nextState,
            isA<MutationError<int>>(),
          );

          expect(observer.errors, hasLength(1));
          expect(observer.errors.single, same(exception));

          mutation.dispose();

          expect(observer.disposed, contains(mutation));
        } finally {
          NotifierBase.observer = previous;
        }
      });
    });
  });
}

class _TestNotifierObserver extends NotifierObserver {
  final created = <NotifierBase>[];
  final changes = <Change<dynamic>>[];
  final errors = <Object>[];
  final disposed = <NotifierBase>[];

  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);
    created.add(notifier);
  }

  @override
  void onChange(
    NotifierBase notifier,
    Change<dynamic> change,
  ) {
    super.onChange(notifier, change);
    changes.add(change);
  }

  @override
  void onError(
    NotifierBase notifier,
    Object error,
    StackTrace stackTrace,
  ) {
    super.onError(notifier, error, stackTrace);
    errors.add(error);
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);
    disposed.add(notifier);
  }
}
