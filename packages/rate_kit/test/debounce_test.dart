import 'package:fake_async/fake_async.dart';
import 'package:rate_kit/rate_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Debounce', () {
    test('debounces calls and executes the latest operation', () {
      fakeAsync((async) {
        final debounce = Debounce();
        String? value;

        debounce.run(
          () => value = 'first',
          // duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        debounce.run(
          () => value = 'second',
          duration: const Duration(milliseconds: 100),
        );

        expect(value, isNull);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 99));

        expect(value, isNull);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 1));

        expect(value, 'second');
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('uses the provided duration', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () => called = true,
          duration: const Duration(milliseconds: 500),
        );

        async.elapse(const Duration(milliseconds: 499));

        expect(called, isFalse);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 1));

        expect(called, isTrue);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('uses the instance duration and allows a per-call override', () {
      fakeAsync((async) {
        final debounce = Debounce(duration: const Duration(milliseconds: 500));

        var callCount = 0;

        debounce.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 499));

        expect(callCount, 0);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 1));

        expect(callCount, 1);
        expect(debounce.isPending(), isFalse);

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 2);

        debounce.dispose();
      });
    });

    test('isPending reflects the debounce cycle', () {
      fakeAsync((async) {
        final debounce = Debounce();

        expect(debounce.isPending(), isFalse);

        debounce.run(() {}, duration: const Duration(milliseconds: 100));

        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('leading executes immediately', () {
      fakeAsync((async) {
        final debounce = Debounce(leading: true);
        var callCount = 0;

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        expect(callCount, 1);

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        expect(callCount, 1);

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);

        debounce.dispose();
      });
    });

    test('leading and trailing execute on both edges', () {
      fakeAsync((async) {
        final debounce = Debounce(leading: true, trailing: true);

        final values = <String>[];

        debounce.run(
          () => values.add('first'),
          duration: const Duration(milliseconds: 100),
        );

        expect(values, ['first']);

        debounce.run(
          () => values.add('second'),
          duration: const Duration(milliseconds: 100),
        );

        expect(values, ['first']);

        async.elapse(const Duration(milliseconds: 100));

        expect(values, ['first', 'second']);

        debounce.dispose();
      });
    });

    test('leading and trailing do not execute twice for a single call', () {
      fakeAsync((async) {
        final debounce = Debounce(leading: true, trailing: true);

        var callCount = 0;

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        expect(callCount, 1);

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);

        debounce.dispose();
      });
    });

    test(
      'leading and trailing execute the latest operation on the trailing edge',
      () {
        fakeAsync((async) {
          final debounce = Debounce(leading: true, trailing: true);

          final values = <String>[];

          debounce.run(
            () => values.add('first'),
            duration: const Duration(milliseconds: 100),
          );

          async.elapse(const Duration(milliseconds: 30));

          debounce.run(
            () => values.add('second'),
            duration: const Duration(milliseconds: 100),
          );

          async.elapse(const Duration(milliseconds: 30));

          debounce.run(
            () => values.add('third'),
            duration: const Duration(milliseconds: 100),
          );

          async.elapse(const Duration(milliseconds: 100));

          expect(values, ['first', 'third']);

          debounce.dispose();
        });
      },
    );

    test('cancel stops the current cycle and keeps the debounce reusable', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var callCount = 0;

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending(), isTrue);

        debounce.cancel();

        expect(debounce.isPending(), isFalse);

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 0);

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);

        debounce.dispose();
      });
    });

    test('cancel is safe when no cycle is active', () {
      final debounce = Debounce();

      expect(debounce.cancel, returnsNormally);

      debounce.dispose();
    });

    test('flush executes the pending trailing operation immediately', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var callCount = 0;

        debounce.run(() => callCount++, duration: const Duration(seconds: 1));

        expect(callCount, 0);
        expect(debounce.isPending(), isTrue);

        debounce.flush();

        expect(callCount, 1);
        expect(debounce.isPending(), isFalse);

        async.elapse(const Duration(seconds: 1));

        expect(callCount, 1);

        debounce.dispose();
      });
    });

    test('flush respects leading and trailing behavior', () {
      fakeAsync((async) {
        final debounce = Debounce(leading: true, trailing: true);

        var callCount = 0;

        debounce.run(() => callCount++, duration: const Duration(seconds: 1));

        expect(callCount, 1);

        debounce.run(() => callCount++, duration: const Duration(seconds: 1));

        debounce.flush();

        expect(callCount, 2);
        expect(debounce.isPending(), isFalse);

        async.elapse(const Duration(seconds: 1));

        expect(callCount, 2);

        debounce.dispose();
      });
    });

    test('flush cancels the maxWait timer', () {
      fakeAsync((async) {
        final debounce = Debounce(maxWait: const Duration(seconds: 1));

        var callCount = 0;

        debounce.run(() => callCount++, duration: const Duration(seconds: 5));

        debounce.flush();

        expect(callCount, 1);
        expect(debounce.isPending(), isFalse);

        async.elapse(const Duration(seconds: 2));

        expect(callCount, 1);

        debounce.dispose();
      });
    });

    test('flush is safe when no cycle is active', () {
      final debounce = Debounce();

      expect(debounce.flush, returnsNormally);

      debounce.dispose();
    });

    test('maxWait forces execution while calls continue', () {
      fakeAsync((async) {
        final debounce = Debounce(maxWait: const Duration(milliseconds: 500));

        String? value;

        debounce.run(
          () => value = 'first',
          duration: const Duration(milliseconds: 300),
        );

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(
          () => value = 'second',
          duration: const Duration(milliseconds: 300),
        );

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(
          () => value = 'third',
          duration: const Duration(milliseconds: 300),
        );

        expect(value, isNull);

        // maxWait started with the first call and was not restarted.
        async.elapse(const Duration(milliseconds: 100));

        expect(value, 'third');
        expect(debounce.isPending(), isFalse);

        // The cancelled debounce timer must not execute again.
        async.elapse(const Duration(seconds: 1));

        expect(value, 'third');

        debounce.dispose();
      });
    });

    test('maxWait is not affected by later duration changes', () {
      fakeAsync((async) {
        final debounce = Debounce(maxWait: const Duration(milliseconds: 500));

        var callCount = 0;

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 300),
        );

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(() => callCount++, duration: const Duration(seconds: 2));

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(() => callCount++, duration: const Duration(seconds: 2));

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('starts a new cycle after maxWait completes', () {
      fakeAsync((async) {
        final debounce = Debounce(maxWait: const Duration(milliseconds: 500));

        var callCount = 0;

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 300),
        );

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 300),
        );

        async.elapse(const Duration(milliseconds: 200));

        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 300),
        );

        // maxWait reaches 500ms from the first call.
        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);
        expect(debounce.isPending(), isFalse);

        // This must start a completely new cycle.
        debounce.run(
          () => callCount++,
          duration: const Duration(milliseconds: 300),
        );

        expect(callCount, 1);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 300));

        expect(callCount, 2);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });
    test('maxWait can be shorter than the debounce duration', () {
      fakeAsync((async) {
        final debounce = Debounce(maxWait: const Duration(milliseconds: 200));

        var called = false;

        debounce.run(() => called = true, duration: const Duration(seconds: 1));

        async.elapse(const Duration(milliseconds: 200));

        expect(called, isTrue);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('allows a zero duration', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(() => called = true, duration: Duration.zero);

        expect(called, isFalse);
        expect(debounce.isPending(), isTrue);

        async.elapse(Duration.zero);

        expect(called, isTrue);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('throws when the duration is negative', () {
      final debounce = Debounce();

      expect(
        () => debounce.run(() {}, duration: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );

      debounce.dispose();
    });

    test('throws when the instance duration is negative', () {
      expect(
        () => Debounce(duration: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );
    });

    test('throws when both leading and trailing are false', () {
      expect(
        () => Debounce(leading: false, trailing: false),
        throwsArgumentError,
      );
    });

    test('throws when maxWait is negative', () {
      expect(
        () => Debounce(maxWait: const Duration(milliseconds: -1)),
        throwsArgumentError,
      );
    });

    test('handles re-entrant calls safely', () {
      fakeAsync((async) {
        late Debounce debounce;
        var callCount = 0;

        debounce = Debounce(leading: true, trailing: true);

        debounce.run(() {
          callCount++;

          debounce.run(
            () => callCount++,
            duration: const Duration(milliseconds: 100),
          );
        }, duration: const Duration(milliseconds: 100));

        expect(callCount, 1);

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 2);

        debounce.dispose();
      });
    });

    test('handles re-entrant trailing calls safely', () {
      fakeAsync((async) {
        late Debounce debounce;
        var callCount = 0;

        debounce = Debounce();

        debounce.run(() {
          callCount++;

          debounce.run(
            () => callCount++,
            duration: const Duration(milliseconds: 100),
          );
        }, duration: const Duration(milliseconds: 100));

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 1);
        expect(debounce.isPending(), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(callCount, 2);
        expect(debounce.isPending(), isFalse);

        debounce.dispose();
      });
    });

    test('keyed operations are independent', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var usersCount = 0;
        var moviesCount = 0;

        debounce.run(
          () => usersCount++,
          key: 'users',
          duration: const Duration(milliseconds: 100),
        );

        debounce.run(
          () => moviesCount++,
          key: 'movies',
          duration: const Duration(milliseconds: 200),
        );

        expect(debounce.isPending(key: 'users'), isTrue);
        expect(debounce.isPending(key: 'movies'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(usersCount, 1);
        expect(moviesCount, 0);
        expect(debounce.isPending(key: 'users'), isFalse);
        expect(debounce.isPending(key: 'movies'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(moviesCount, 1);
        expect(debounce.isPending(key: 'movies'), isFalse);

        debounce.dispose();
      });
    });

    test('unKeyed and keyed operations are independent', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var unKeyedCount = 0;
        var keyedCount = 0;

        debounce.run(
          () => unKeyedCount++,
          duration: const Duration(milliseconds: 100),
        );

        debounce.run(
          () => keyedCount++,
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(unKeyedCount, 1);
        expect(keyedCount, 1);

        debounce.dispose();
      });
    });

    test('same key replaces the pending operation', () {
      fakeAsync((async) {
        final debounce = Debounce();
        String? value;

        debounce.run(
          () => value = 'first',
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        debounce.run(
          () => value = 'second',
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(value, 'second');

        debounce.dispose();
      });
    });

    test('removes keyed debounce after natural completion', () {
      fakeAsync((async) {
        final debounce = Debounce();

        var count = 0;

        debounce.run(
          () => count++,
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending(key: 'search'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(count, 1);
        expect(debounce.isPending(key: 'search'), isFalse);
      });
    });

    test('recreates keyed debounce after completion', () {
      fakeAsync((async) {
        final debounce = Debounce();

        var count = 0;

        debounce.run(
          () => count++,
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        debounce.run(
          () => count++,
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending(key: 'search'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(count, 2);
        expect(debounce.isPending(key: 'search'), isFalse);
      });
    });

    test('cancel only affects the specified key', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var usersCount = 0;
        var moviesCount = 0;

        debounce.run(
          () => usersCount++,
          key: 'users',
          duration: const Duration(milliseconds: 100),
        );

        debounce.run(
          () => moviesCount++,
          key: 'movies',
          duration: const Duration(milliseconds: 100),
        );

        debounce.cancel(key: 'users');

        expect(debounce.isPending(key: 'users'), isFalse);
        expect(debounce.isPending(key: 'movies'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(usersCount, 0);
        expect(moviesCount, 1);

        debounce.dispose();
      });
    });

    test('removes keyed debounce when cancelled', () {
      fakeAsync((async) {
        final debounce = Debounce();

        debounce.run(
          () {},
          key: 'search',
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending(key: 'search'), isTrue);

        debounce.cancel(key: 'search');

        expect(debounce.isPending(key: 'search'), isFalse);

        async.elapse(const Duration(milliseconds: 100));
      });
    });

    test('flush only affects the specified key', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var usersCount = 0;
        var moviesCount = 0;

        debounce.run(
          () => usersCount++,
          key: 'users',
          duration: const Duration(seconds: 1),
        );

        debounce.run(
          () => moviesCount++,
          key: 'movies',
          duration: const Duration(seconds: 1),
        );

        debounce.flush(key: 'users');

        expect(usersCount, 1);
        expect(moviesCount, 0);

        expect(debounce.isPending(key: 'users'), isFalse);
        expect(debounce.isPending(key: 'movies'), isTrue);

        async.elapse(const Duration(seconds: 1));

        expect(moviesCount, 1);

        debounce.dispose();
      });
    });

    test('dispose removes only the specified key', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var usersCount = 0;
        var recreatedUsersCount = 0;
        var moviesCount = 0;

        debounce.run(
          () => usersCount++,
          key: 'users',
          duration: const Duration(milliseconds: 100),
        );

        debounce.run(
          () => moviesCount++,
          key: 'movies',
          duration: const Duration(milliseconds: 100),
        );

        debounce.dispose(key: 'users');

        expect(debounce.isPending(key: 'users'), isFalse);
        expect(debounce.isPending(key: 'movies'), isTrue);

        // The disposed key can be created again.
        debounce.run(
          () => recreatedUsersCount++,
          key: 'users',
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(usersCount, 0);
        expect(recreatedUsersCount, 1);
        expect(moviesCount, 1);

        debounce.dispose();
      });
    });

    test('unknown keys are safe', () {
      final debounce = Debounce();

      expect(debounce.isPending(key: 'unknown'), isFalse);
      expect(() => debounce.cancel(key: 'unknown'), returnsNormally);
      expect(() => debounce.flush(key: 'unknown'), returnsNormally);
      expect(() => debounce.dispose(key: 'unknown'), returnsNormally);

      debounce.dispose();
    });

    test('dispose cancels all operations', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var unKeyedCount = 0;
        var keyedCount = 0;

        debounce.run(
          () => unKeyedCount++,
          duration: const Duration(seconds: 1),
        );

        debounce.run(
          () => keyedCount++,
          key: 'search',
          duration: const Duration(seconds: 1),
        );

        expect(debounce.isPending(), isTrue);
        expect(debounce.isPending(key: 'search'), isTrue);

        debounce.dispose();

        expect(debounce.isPending(), isFalse);
        expect(debounce.isPending(key: 'search'), isFalse);

        async.elapse(const Duration(seconds: 2));

        expect(unKeyedCount, 0);
        expect(keyedCount, 0);

        expect(debounce.dispose, returnsNormally);
        expect(debounce.cancel, returnsNormally);
        expect(debounce.flush, returnsNormally);
      });
    });

    test('cannot be run after being disposed', () {
      final debounce = Debounce();

      debounce.dispose();

      assert(() {
        expect(
          () => debounce.run(() {}),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('used after being disposed'),
            ),
          ),
        );

        return true;
      }());
    });
  });
}
