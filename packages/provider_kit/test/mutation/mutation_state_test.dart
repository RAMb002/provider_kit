import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/mutation/mutation.dart';

void main() {
  group('MutationState', () {
    group('when', () {
      test('handles idle state', () {
        final mutation = Mutation<int>();

        final result = mutation.state.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: (_) => 'success',
          error: (_, __, ___) => 'error',
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
          error: (_, __, ___) => 'error',
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
          error: (_, __, ___) => 'error',
        );

        expect(result, 'success:42');

        mutation.dispose();
      });

      test('handles error state and receives error, stack trace and error info',
          () async {
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
          error: (errorInfo, error, stackTrace) {
            expect(error, same(exception));
            expect(stackTrace.toString(), isNotEmpty);
            expect(errorInfo.message, exception.toString());
            expect(errorInfo.code, isNull);
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
          error: (errorInfo, error, stackTrace) {
            expect(error, same(exception));
            expect(stackTrace.toString(), isNotEmpty);
            expect(errorInfo.message, exception.toString());
            expect(errorInfo.code, isNull);
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

    group('whenOrNull', () {
      test('executes the matching callback and returns its result', () {
        final mutation = Mutation<int>();

        final result = mutation.state.whenOrNull(
          idle: () => 'idle',
        );

        expect(result, 'idle');

        mutation.dispose();
      });

      test('passes the correct parameters for MutationError', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.whenOrNull(
          error: (errorInfo, error, stackTrace) {
            expect(errorInfo.message, exception.toString());
            expect(error, same(exception));
            expect(stackTrace.toString(), isNotEmpty);

            return 'error';
          },
        );

        expect(result, 'error');

        mutation.dispose();
      });

      test('returns null when no callback matches the current state', () {
        final mutation = Mutation<int>();

        final result = mutation.state.whenOrNull(
          success: (_) => 'success',
          error: (_, __, ___) => 'error',
        );

        expect(result, isNull);

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

// -------------------------------------------------------------------------
// mapOrNull
// -------------------------------------------------------------------------
    group('mapOrNull', () {
      test('executes the matching mapper and returns its result', () {
        final mutation = Mutation<int>();

        final result = mutation.state.mapOrNull(
          idle: (state) => state.isIdle,
        );

        expect(result, isTrue);

        mutation.dispose();
      });

      test('passes the complete MutationError to the mapper', () async {
        final mutation = Mutation<int>();
        final exception = StateError('failure');

        try {
          await mutation.run(() async {
            throw exception;
          });
        } catch (_) {}

        final result = mutation.state.mapOrNull(
          error: (state) {
            expect(state.error, same(exception));
            expect(state.errorInfo.message, exception.toString());
            expect(state.stackTrace.toString(), isNotEmpty);

            return state.errorInfo.message;
          },
        );

        expect(result, exception.toString());

        mutation.dispose();
      });

      test('returns null when no mapper matches the current state', () {
        final mutation = Mutation<int>();

        final result = mutation.state.mapOrNull(
          success: (_) => 'success',
          error: (_) => 'error',
        );

        expect(result, isNull);

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
    group('toString()', () {
      test('MutationSuccess toString', () async {
        final mutation = Mutation<String>();

        await mutation.run(() async => 'success');

        final state = mutation.state;

        expect(
          state.toString(),
          'MutationSuccess { data: success }',
        );

        mutation.dispose();
      });
      test('MutationError toString', () async {
        final mutation = Mutation<String>();
        final error = StateError('failure');

        try {
          await mutation.run(() async {
            throw error;
          });
        } catch (_) {
          // Expected.
        }

        final state = mutation.state as MutationError<String>;

        expect(state.toString(), contains('MutationError'));
        expect(state.toString(), contains('errorInfo: ${state.errorInfo}'));
        expect(state.toString(), contains('error: $error'));
        expect(state.toString(), contains('stackTrace: ${state.stackTrace}'));

        mutation.dispose();
      });
    });
  });
}
