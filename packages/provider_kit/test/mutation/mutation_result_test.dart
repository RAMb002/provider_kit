import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/errors/error_info.dart';
import 'package:provider_kit/src/mutation/mutation.dart';

void main() {
  group('MutationResult', () {
    late _MutationResultFixtures fixtures;

    setUp(() async {
      ProviderKit.resetForTesting();
      fixtures = await _createFixtures();
    });

    group('outcomes', () {
      test('MutationSucceeded contains the returned data', () {
        expect(fixtures.succeeded.data, 42);
      });

      test('MutationSucceeded supports nullable data', () async {
        final result = await _createSucceeded<int?>(null);

        expect(result, isA<MutationSucceeded<int?>>());
        expect(result.data, isNull);
      });

      test(
        'MutationErrored contains the original error, stack trace and ErrorInfo',
        () {
          final result = fixtures.errored;

          expect(result.error, same(fixtures.error));
          expect(result.stackTrace.toString(), isNotEmpty);
          expect(result.errorInfo.message, fixtures.error.toString());
          expect(result.errorInfo.code, isNull);
          expect(result.message, fixtures.error.toString());
        },
      );

      test('MutationIgnored contains its ignore reason', () {
        expect(fixtures.ignored.reason, MutationIgnoreReason.busy);
      });

      test('creates ignored results for every ignore reason', () async {
        for (final reason in MutationIgnoreReason.values) {
          final result = await _createIgnored(reason);

          expect(result, isA<MutationIgnored<int>>());
          expect(result.reason, reason);
        }
      });
    });

    group('when', () {
      test('invokes succeeded callback and passes data', () {
        final result = fixtures.succeeded.when(
          succeeded: (data) => 'success:$data',
          errored: (_, _, _) => 'unexpected error',
          ignored: (_) => 'unexpected ignored',
        );

        expect(result, 'success:42');
      });

      test('invokes errored callback with all error information', () {
        final result = fixtures.errored.when(
          succeeded: (_) => 'unexpected success',
          errored: (errorInfo, error, stackTrace) {
            expect(error, same(fixtures.error));
            expect(errorInfo.message, fixtures.error.toString());
            expect(stackTrace.toString(), isNotEmpty);

            return 'error:${errorInfo.message}';
          },
          ignored: (_) => 'unexpected ignored',
        );

        expect(result, 'error:${fixtures.error}');
      });

      test('invokes ignored callback with its reason', () {
        final result = fixtures.ignored.when(
          succeeded: (_) => 'unexpected success',
          errored: (_, _, _) => 'unexpected error',
          ignored: (reason) => 'ignored:$reason',
        );

        expect(result, 'ignored:${MutationIgnoreReason.busy}');
      });
    });

    group('maybeWhen', () {
      test('invokes matching succeeded callback', () {
        final result = fixtures.succeeded.maybeWhen(
          succeeded: (data) => data,
          orElse: () => -1,
        );

        expect(result, 42);
      });

      test('invokes matching errored callback', () {
        final result = fixtures.errored.maybeWhen(
          errored: (errorInfo, error, stackTrace) => errorInfo.message,
          orElse: () => 'fallback',
        );

        expect(result, fixtures.error.toString());
      });

      test('invokes matching ignored callback', () {
        final result = fixtures.ignored.maybeWhen(
          ignored: (reason) => reason,
          orElse: () => MutationIgnoreReason.disposed,
        );

        expect(result, MutationIgnoreReason.busy);
      });

      test('invokes orElse when the matching callback is absent', () {
        var fallbackCount = 0;

        String fallback() {
          fallbackCount++;
          return 'fallback';
        }

        final successResult = fixtures.succeeded.maybeWhen(
          errored: (_, _, _) => 'error',
          orElse: fallback,
        );

        final errorResult = fixtures.errored.maybeWhen(
          succeeded: (_) => 'success',
          orElse: fallback,
        );

        final ignoredResult = fixtures.ignored.maybeWhen(
          succeeded: (_) => 'success',
          orElse: fallback,
        );

        expect(successResult, 'fallback');
        expect(errorResult, 'fallback');
        expect(ignoredResult, 'fallback');
        expect(fallbackCount, 3);
      });
    });

    group('whenOrNull', () {
      test('invokes matching succeeded callback', () {
        final result = fixtures.succeeded.whenOrNull(
          succeeded: (data) => 'success:$data',
        );

        expect(result, 'success:42');
      });

      test('invokes matching errored callback', () {
        final result = fixtures.errored.whenOrNull(
          errored: (errorInfo, error, stackTrace) {
            expect(error, same(fixtures.error));
            expect(stackTrace.toString(), isNotEmpty);

            return errorInfo.message;
          },
        );

        expect(result, fixtures.error.toString());
      });

      test('invokes matching ignored callback', () {
        final result = fixtures.ignored.whenOrNull(
          ignored: (reason) => 'ignored:$reason',
        );

        expect(result, 'ignored:${MutationIgnoreReason.busy}');
      });

      test('returns null when no callback matches', () {
        expect(
          fixtures.succeeded.whenOrNull(
            errored: (_, _, _) => 'error',
            ignored: (_) => 'ignored',
          ),
          isNull,
        );

        expect(
          fixtures.errored.whenOrNull(
            succeeded: (_) => 'success',
            ignored: (_) => 'ignored',
          ),
          isNull,
        );

        expect(
          fixtures.ignored.whenOrNull(
            succeeded: (_) => 'success',
            errored: (_, _, _) => 'error',
          ),
          isNull,
        );
      });

      test('returns null when the matching callback returns null', () {
        final result = fixtures.succeeded.whenOrNull<String?>(
          succeeded: (_) => null,
        );

        expect(result, isNull);
      });
    });

    group('map', () {
      test('passes the complete MutationSucceeded object', () {
        final result = fixtures.succeeded.map(
          succeeded: (result) => identical(result, fixtures.succeeded),
          errored: (_) => false,
          ignored: (_) => false,
        );

        expect(result, isTrue);
      });

      test('passes the complete MutationErrored object', () {
        final result = fixtures.errored.map(
          succeeded: (_) => false,
          errored: (result) {
            expect(result.error, same(fixtures.error));
            expect(result.errorInfo.message, fixtures.error.toString());

            return identical(result, fixtures.errored);
          },
          ignored: (_) => false,
        );

        expect(result, isTrue);
      });

      test('passes the complete MutationIgnored object', () {
        final result = fixtures.ignored.map(
          succeeded: (_) => false,
          errored: (_) => false,
          ignored: (result) => identical(result, fixtures.ignored),
        );

        expect(result, isTrue);
      });
    });

    group('maybeMap', () {
      test('invokes matching succeeded mapper', () {
        final result = fixtures.succeeded.maybeMap(
          succeeded: (result) => result.data,
          orElse: () => -1,
        );

        expect(result, 42);
      });

      test('invokes matching errored mapper', () {
        final result = fixtures.errored.maybeMap(
          errored: (result) => result.error,
          orElse: () => StateError('fallback'),
        );

        expect(result, same(fixtures.error));
      });

      test('invokes matching ignored mapper', () {
        final result = fixtures.ignored.maybeMap(
          ignored: (result) => result.reason,
          orElse: () => MutationIgnoreReason.disposed,
        );

        expect(result, MutationIgnoreReason.busy);
      });

      test('invokes orElse when the matching mapper is absent', () {
        var fallbackCount = 0;

        String fallback() {
          fallbackCount++;
          return 'fallback';
        }

        final successResult = fixtures.succeeded.maybeMap(
          errored: (_) => 'error',
          orElse: fallback,
        );

        final errorResult = fixtures.errored.maybeMap(
          succeeded: (_) => 'success',
          orElse: fallback,
        );

        final ignoredResult = fixtures.ignored.maybeMap(
          succeeded: (_) => 'success',
          orElse: fallback,
        );

        expect(successResult, 'fallback');
        expect(errorResult, 'fallback');
        expect(ignoredResult, 'fallback');
        expect(fallbackCount, 3);
      });
    });

    group('mapOrNull', () {
      test('invokes matching succeeded mapper', () {
        final result = fixtures.succeeded.mapOrNull(
          succeeded: (result) => result.data,
        );

        expect(result, 42);
      });

      test('invokes matching errored mapper', () {
        final result = fixtures.errored.mapOrNull(
          errored: (result) => result.errorInfo.message,
        );

        expect(result, fixtures.error.toString());
      });

      test('invokes matching ignored mapper', () {
        final result = fixtures.ignored.mapOrNull(
          ignored: (result) => result.reason,
        );

        expect(result, MutationIgnoreReason.busy);
      });

      test('returns null when no mapper matches', () {
        expect(
          fixtures.succeeded.mapOrNull(
            errored: (_) => 'error',
            ignored: (_) => 'ignored',
          ),
          isNull,
        );

        expect(
          fixtures.errored.mapOrNull(
            succeeded: (_) => 'success',
            ignored: (_) => 'ignored',
          ),
          isNull,
        );

        expect(
          fixtures.ignored.mapOrNull(
            succeeded: (_) => 'success',
            errored: (_) => 'error',
          ),
          isNull,
        );
      });

      test('returns null when the matching mapper returns null', () {
        final result = fixtures.succeeded.mapOrNull<String?>(
          succeeded: (_) => null,
        );

        expect(result, isNull);
      });
    });

    group('result flags', () {
      test('succeeded flags are correct', () {
        expect(fixtures.succeeded.isSucceeded, isTrue);
        expect(fixtures.succeeded.isErrored, isFalse);
        expect(fixtures.succeeded.isIgnored, isFalse);
      });

      test('errored flags are correct', () {
        expect(fixtures.errored.isSucceeded, isFalse);
        expect(fixtures.errored.isErrored, isTrue);
        expect(fixtures.errored.isIgnored, isFalse);
      });

      test('ignored flags are correct', () {
        expect(fixtures.ignored.isSucceeded, isFalse);
        expect(fixtures.ignored.isErrored, isFalse);
        expect(fixtures.ignored.isIgnored, isTrue);
      });
    });

    group('equality', () {
      test('succeeded results with equal data are equal', () async {
        final first = await _createSucceeded<int>(42);
        final second = await _createSucceeded<int>(42);

        expect(first, second);
        expect(first.hashCode, second.hashCode);
      });

      test('succeeded results with different data are not equal', () async {
        final first = await _createSucceeded<int>(1);
        final second = await _createSucceeded<int>(2);

        expect(first, isNot(equals(second)));
      });

      test('errored results with equal values are equal', () async {
        const errorInfo = ErrorInfo(
          message: 'Something went wrong.',
          code: 'test_error',
        );

        ProviderKit.configure(errorInfoMapper: (_, _) => errorInfo);

        final error = StateError('failure');
        final stackTrace = StackTrace.current;

        final first = await _createErrored<int>(error, stackTrace: stackTrace);

        final second = await _createErrored<int>(error, stackTrace: stackTrace);

        expect(first, second);
        expect(first.hashCode, second.hashCode);
      });

      test('errored results with different errors are not equal', () async {
        const errorInfo = ErrorInfo(message: 'failure');

        ProviderKit.configure(errorInfoMapper: (_, _) => errorInfo);

        final stackTrace = StackTrace.current;

        final first = await _createErrored<int>(
          StateError('first'),
          stackTrace: stackTrace,
        );

        final second = await _createErrored<int>(
          StateError('second'),
          stackTrace: stackTrace,
        );

        expect(first, isNot(equals(second)));
      });

      test(
        'errored results with different stack traces are not equal',
        () async {
          const errorInfo = ErrorInfo(message: 'failure');

          ProviderKit.configure(errorInfoMapper: (_, _) => errorInfo);

          final error = StateError('same error');
          final firstStackTrace = StackTrace.current;
          final secondStackTrace = StackTrace.current;

          final first = await _createErrored<int>(
            error,
            stackTrace: firstStackTrace,
          );

          final second = await _createErrored<int>(
            error,
            stackTrace: secondStackTrace,
          );

          expect(first, isNot(equals(second)));
        },
      );

      test('errored results with different ErrorInfo are not equal', () async {
        var mapperCallCount = 0;

        ProviderKit.configure(
          errorInfoMapper: (_, _) {
            mapperCallCount++;

            return ErrorInfo(message: 'mapped error $mapperCallCount');
          },
        );

        final error = StateError('same error');
        final stackTrace = StackTrace.current;

        final first = await _createErrored<int>(error, stackTrace: stackTrace);

        final second = await _createErrored<int>(error, stackTrace: stackTrace);

        expect(first, isNot(equals(second)));
      });

      test('ignored results with the same reason are equal', () async {
        final first = await _createIgnored(MutationIgnoreReason.busy);
        final second = await _createIgnored(MutationIgnoreReason.busy);

        expect(first, second);
        expect(first.hashCode, second.hashCode);
      });

      test('ignored results with different reasons are not equal', () async {
        final first = await _createIgnored(MutationIgnoreReason.busy);
        final second = await _createIgnored(MutationIgnoreReason.replaced);

        expect(first, isNot(equals(second)));
      });

      test('results with different generic types are not equal', () async {
        final intResult = await _createSucceeded<int>(42);
        final stringResult = await _createSucceeded<String>('42');

        expect(intResult, isNot(equals(stringResult)));
      });
    });

    group('toString', () {
      test('MutationSucceeded toString', () {
        expect(fixtures.succeeded.toString(), 'MutationSucceeded { data: 42 }');
      });

      test('MutationErrored toString', () {
        final result = fixtures.errored;
        final value = result.toString();

        expect(value, contains('MutationErrored'));
        expect(value, contains('errorInfo: ${result.errorInfo}'));
        expect(value, contains('error: ${result.error}'));
        expect(value, contains('stackTrace: ${result.stackTrace}'));
      });

      test('MutationIgnored toString', () {
        expect(
          fixtures.ignored.toString(),
          'MutationIgnored { reason: ${MutationIgnoreReason.busy} }',
        );
      });
    });
  });
}

class _MutationResultFixtures {
  const _MutationResultFixtures({
    required this.succeeded,
    required this.errored,
    required this.ignored,
    required this.error,
    required this.stackTrace,
  });

  final MutationSucceeded<int> succeeded;
  final MutationErrored<int> errored;
  final MutationIgnored<int> ignored;

  final Object error;
  final StackTrace stackTrace;
}

Future<_MutationResultFixtures> _createFixtures() async {
  final error = StateError('request failed');
  final stackTrace = StackTrace.current;

  return _MutationResultFixtures(
    succeeded: await _createSucceeded<int>(42),
    errored: await _createErrored<int>(error, stackTrace: stackTrace),
    ignored: await _createIgnored(MutationIgnoreReason.busy),
    error: error,
    stackTrace: stackTrace,
  );
}

Future<MutationSucceeded<T>> _createSucceeded<T>(T data) async {
  final mutation = Mutation<T>();

  try {
    final result = await mutation.run(() async => data);

    return result as MutationSucceeded<T>;
  } finally {
    mutation.dispose();
  }
}

Future<MutationErrored<T>> _createErrored<T>(
  Object error, {
  StackTrace? stackTrace,
}) async {
  final mutation = Mutation<T>();

  try {
    final result = await mutation.run(() async {
      Error.throwWithStackTrace(error, stackTrace ?? StackTrace.current);
    });

    return result as MutationErrored<T>;
  } finally {
    mutation.dispose();
  }
}

Future<MutationIgnored<int>> _createIgnored(MutationIgnoreReason reason) async {
  final concurrency = switch (reason) {
    MutationIgnoreReason.busy => MutationConcurrency.ignoreIfBusy,
    MutationIgnoreReason.replaced => MutationConcurrency.latestOnly,
    MutationIgnoreReason.reset ||
    MutationIgnoreReason.disposed => MutationConcurrency.parallel,
  };

  final mutation = Mutation<int>(concurrency: concurrency);
  final completer = Completer<int>();

  try {
    final activeFuture = mutation.run(() => completer.future);

    late final MutationIgnored<int> ignored;

    switch (reason) {
      case MutationIgnoreReason.busy:
        final result = await mutation.run(() async => 2);

        ignored = result as MutationIgnored<int>;

        completer.complete(1);
        await activeFuture;
        break;

      case MutationIgnoreReason.replaced:
        final latestFuture = mutation.run(() async => 2);

        await latestFuture;

        completer.complete(1);

        final result = await activeFuture;
        ignored = result as MutationIgnored<int>;
        break;

      case MutationIgnoreReason.reset:
        mutation.reset();
        completer.complete(1);

        final result = await activeFuture;
        ignored = result as MutationIgnored<int>;
        break;

      case MutationIgnoreReason.disposed:
        mutation.dispose();
        completer.complete(1);

        final result = await activeFuture;
        ignored = result as MutationIgnored<int>;
        break;
    }

    return ignored;
  } finally {
    mutation.dispose();
  }
}
