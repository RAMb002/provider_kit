// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/core/provider_kit_core.dart';
import 'package:provider_kit/src/mutation/mutation.dart';
import 'package:provider_kit/src/observer/change.dart';
import 'package:provider_kit/src/observer/notifier_observer.dart';

void main() {
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
      setUp(() {
        ProviderKit.resetForTesting();
      });
      test('observes mutation lifecycle events on success', () async {
        final observer = _TestNotifierObserver();
        ProviderKit.configure(
          observer: observer,
        );

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
      });

      test('observes mutation lifecycle events on error', () async {
        final observer = _TestNotifierObserver();
        ProviderKit.configure(
          observer: observer,
        );

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
      });
      test(
        'reports errors thrown while publishing mutation state',
        () async {
          final observer = _TestNotifierObserver();
          ProviderKit.configure(
            observer: observer,
          );

          final mutation = Mutation<int>();

          observer.throwOnChange = true;

          await expectLater(
            mutation.run(() async => 42),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'observer onChange failed',
              ),
            ),
          );

          expect(observer.errors, hasLength(1));
          expect(
            observer.errors.single,
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'observer onChange failed',
            ),
          );

          mutation.dispose();
        },
      );
    });
  });
}

class _TestNotifierObserver extends NotifierObserver {
  final created = <NotifierBase>[];
  final changes = <Change<dynamic>>[];
  final errors = <Object>[];
  final disposed = <NotifierBase>[];
  bool throwOnChange = false;

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
    if (throwOnChange) {
      throw StateError('observer onChange failed');
    }
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
