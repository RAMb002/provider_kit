import 'package:fake_async/fake_async.dart';
import 'package:rate_kit/rate_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Throttle', () {
    group('leading', () {
      test('executes immediately and ignores calls during the period', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => callCount++);

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('allows the next call after the throttle period ends', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 100));

          throttle.run(() => callCount++);

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });
    });

    group('trailing', () {
      test('executes the latest operation at the end of the period', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          String? value;

          throttle.run(() => value = 'first');

          expect(value, isNull);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 30));

          throttle.run(() => value = 'second');

          expect(value, isNull);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 30));

          throttle.run(() => value = 'third');

          expect(value, isNull);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 40));

          expect(value, 'third');
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test('replaces the pending operation with the latest call', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          final values = <String>[];

          throttle.run(() => values.add('first'));

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => values.add('second'));

          async.elapse(const Duration(milliseconds: 40));

          throttle.run(() => values.add('third'));

          expect(values, isEmpty);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 10));

          expect(values, ['third']);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });
    });

    group('leading and trailing', () {
      test('executes on both edges when additional calls occur', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            leading: true,
            trailing: true,
          );

          final values = <String>[];

          throttle.run(() => values.add('first'));

          expect(values, ['first']);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 30));

          throttle.run(() => values.add('second'));

          expect(values, ['first']);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 30));

          throttle.run(() => values.add('third'));

          expect(values, ['first']);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 40));

          expect(values, ['first', 'third']);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test('does not execute twice when only one call occurs', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            leading: true,
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          expect(callCount, 1);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });
    });

    group('fixed throttle window', () {
      test('new calls do not restart the throttle timer', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 49));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('trailing execution starts a new throttle period', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 99));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('does not allow a burst immediately after trailing execution', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 300),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 300));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          // Only 1ms has passed since the trailing execution.
          async.elapse(const Duration(milliseconds: 1));

          throttle.run(() => callCount++);

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          // The pending operation must wait for the remaining 299ms.
          async.elapse(const Duration(milliseconds: 299));

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test(
        'does not allow a burst immediately after trailing execution with leading and trailing',
        () {
          fakeAsync((async) {
            final throttle = Throttle(
              duration: const Duration(milliseconds: 300),
              leading: true,
              trailing: true,
            );

            var callCount = 0;

            throttle.run(() => callCount++);

            expect(callCount, 1);

            async.elapse(const Duration(milliseconds: 100));

            throttle.run(() => callCount++);

            expect(callCount, 1);
            expect(throttle.isTrailingPending(), isTrue);

            async.elapse(const Duration(milliseconds: 200));

            expect(callCount, 2);
            expect(throttle.isThrottled(), isTrue);
            expect(throttle.isTrailingPending(), isFalse);

            // A call immediately after the trailing execution must not
            // execute on the leading edge.
            async.elapse(const Duration(milliseconds: 1));

            throttle.run(() => callCount++);

            expect(callCount, 2);
            expect(throttle.isTrailingPending(), isTrue);

            async.elapse(const Duration(milliseconds: 299));

            expect(callCount, 3);
            expect(throttle.isThrottled(), isTrue);
            expect(throttle.isTrailingPending(), isFalse);

            throttle.dispose();
          });
        },
      );
    });

    group('duration', () {
      test('uses the default duration', () {
        fakeAsync((async) {
          final throttle = Throttle();

          throttle.run(() {});

          async.elapse(const Duration(milliseconds: 299));

          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('uses the configured instance duration', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 500),
          );

          throttle.run(() {});

          async.elapse(const Duration(milliseconds: 499));

          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('uses the same duration for every throttle period', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isFalse);

          throttle.run(() => callCount++);

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 99));

          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('allows zero duration without creating a throttle period', () {
        final throttle = Throttle(duration: Duration.zero);

        var callCount = 0;

        throttle.run(() => callCount++);

        expect(callCount, 1);
        expect(throttle.isThrottled(), isFalse);
        expect(throttle.isTrailingPending(), isFalse);

        throttle.run(() => callCount++);

        expect(callCount, 2);
        expect(throttle.isThrottled(), isFalse);
        expect(throttle.isTrailingPending(), isFalse);

        throttle.dispose();
      });
    });

    group('status', () {
      test('isThrottled reflects whether the throttle period is active', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          expect(throttle.isThrottled(), isFalse);

          throttle.run(() {});

          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 99));

          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('trailing remains throttled after the trailing operation', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {});

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });
    });

    group('trailing pending status', () {
      test('is false before any operation is scheduled', () {
        final throttle = Throttle(trailing: true);

        expect(throttle.isTrailingPending(), isFalse);

        throttle.dispose();
      });

      test('is true while a trailing operation is waiting', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {});

          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 99));

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isTrue);

          throttle.dispose();
        });
      });

      test('leading execution is never considered trailing pending', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          throttle.run(() {});

          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() {});

          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 50));

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test(
        'leading and trailing becomes pending only after an additional call',
        () {
          fakeAsync((async) {
            final throttle = Throttle(
              duration: const Duration(milliseconds: 100),
              leading: true,
              trailing: true,
            );

            throttle.run(() {});

            expect(throttle.isTrailingPending(), isFalse);

            async.elapse(const Duration(milliseconds: 50));

            throttle.run(() {});

            expect(throttle.isTrailingPending(), isTrue);

            async.elapse(const Duration(milliseconds: 50));

            expect(throttle.isTrailingPending(), isFalse);
            expect(throttle.isThrottled(), isTrue);

            async.elapse(const Duration(milliseconds: 100));

            expect(throttle.isThrottled(), isFalse);
            expect(throttle.isTrailingPending(), isFalse);

            throttle.dispose();
          });
        },
      );

      test('replacing the pending operation keeps trailing pending', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {});

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() {});

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test('cancel clears trailing pending state', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {});

          expect(throttle.isTrailingPending(), isTrue);
          expect(throttle.isThrottled(), isTrue);

          throttle.cancel();

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isFalse);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('flush clears trailing pending state', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {});

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          throttle.flush();

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('isTrailingPending is independent for different keys', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {}, key: 'users');

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() {}, key: 'movies');

          expect(throttle.isTrailingPending(key: 'users'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(throttle.isTrailingPending(key: 'users'), isFalse);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(throttle.isTrailingPending(key: 'movies'), isFalse);

          throttle.dispose();
        });
      });
    });

    group('cancel', () {
      test('cancels the active period and discards pending trailing work', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => callCount++);

          expect(throttle.isTrailingPending(), isTrue);

          throttle.cancel();

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);
          expect(callCount, 0);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 0);

          throttle.dispose();
        });
      });

      test('cancel keeps the throttle reusable', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          throttle.cancel();

          expect(throttle.isThrottled(), isFalse);

          throttle.run(() => callCount++);

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('cancel ends the post-trailing throttle period', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          throttle.cancel();

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('cancel is safe when no period is active', () {
        final throttle = Throttle();

        expect(throttle.cancel, returnsNormally);
        expect(throttle.isThrottled(), isFalse);
        expect(throttle.isTrailingPending(), isFalse);

        throttle.dispose();
      });
    });

    group('flush', () {
      test('flush executes a pending trailing operation immediately', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(seconds: 1),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          expect(callCount, 0);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          throttle.flush();

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test('flush starts a new throttle period from the flush time', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          async.elapse(const Duration(milliseconds: 50));

          throttle.flush();

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 99));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);

          async.elapse(const Duration(milliseconds: 1));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('flush does nothing without pending trailing work', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++);

          throttle.flush();

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(), isFalse);

          throttle.dispose();
        });
      });

      test('flush is safe when no period is active', () {
        final throttle = Throttle();

        expect(throttle.flush, returnsNormally);
        expect(throttle.isThrottled(), isFalse);
        expect(throttle.isTrailingPending(), isFalse);

        throttle.dispose();
      });
    });

    group('re-entrant calls', () {
      test('leading operation can safely schedule a trailing call', () {
        fakeAsync((async) {
          late Throttle throttle;

          var callCount = 0;

          throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            leading: true,
            trailing: true,
          );

          throttle.run(() {
            callCount++;

            throttle.run(() => callCount++);
          });

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 2);
          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isThrottled(), isTrue);

          throttle.dispose();
        });
      });

      test('trailing operation can safely schedule another call', () {
        fakeAsync((async) {
          late Throttle throttle;

          var callCount = 0;

          throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {
            callCount++;

            throttle.run(() => callCount++);
          });

          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });

      test('flush handles a re-entrant trailing call safely', () {
        fakeAsync((async) {
          late Throttle throttle;

          var callCount = 0;

          throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {
            callCount++;

            throttle.run(() => callCount++);
          });

          expect(throttle.isTrailingPending(), isTrue);

          throttle.flush();

          expect(callCount, 1);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 2);
          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isTrailingPending(), isFalse);

          throttle.dispose();
        });
      });
    });

    group('keys', () {
      test('keyed operations are independent', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var usersCount = 0;
          var moviesCount = 0;

          throttle.run(() => usersCount++, key: 'users');

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => moviesCount++, key: 'movies');

          expect(throttle.isThrottled(key: 'users'), isTrue);
          expect(throttle.isThrottled(key: 'movies'), isTrue);

          expect(throttle.isTrailingPending(key: 'users'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(usersCount, 1);
          expect(moviesCount, 0);

          expect(throttle.isThrottled(key: 'users'), isTrue);
          expect(throttle.isThrottled(key: 'movies'), isTrue);

          expect(throttle.isTrailingPending(key: 'users'), isFalse);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(moviesCount, 1);
          expect(throttle.isTrailingPending(key: 'movies'), isFalse);
          expect(throttle.isThrottled(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(key: 'movies'), isFalse);

          throttle.dispose();
        });
      });

      test('unkeyed and keyed operations are independent', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var unkeyedCount = 0;
          var keyedCount = 0;

          throttle.run(() => unkeyedCount++);

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => keyedCount++, key: 'search');

          expect(throttle.isTrailingPending(), isTrue);
          expect(throttle.isTrailingPending(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(unkeyedCount, 1);
          expect(keyedCount, 0);

          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isThrottled(key: 'search'), isTrue);

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isTrailingPending(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(keyedCount, 1);
          expect(throttle.isTrailingPending(key: 'search'), isFalse);
          expect(throttle.isThrottled(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(key: 'search'), isFalse);

          throttle.dispose();
        });
      });

      test('same key replaces only its pending trailing operation', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          String? value;

          throttle.run(() => value = 'first', key: 'search');

          async.elapse(const Duration(milliseconds: 50));

          throttle.run(() => value = 'second', key: 'search');

          expect(value, isNull);
          expect(throttle.isTrailingPending(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 50));

          expect(value, 'second');
          expect(throttle.isTrailingPending(key: 'search'), isFalse);

          throttle.dispose();
        });
      });

      test('removes a keyed throttle after natural completion', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++, key: 'search');

          expect(throttle.isThrottled(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(key: 'search'), isFalse);
          expect(throttle.isTrailingPending(key: 'search'), isFalse);

          throttle.dispose();
        });
      });

      test('keeps a keyed trailing throttle until its gap ends', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          throttle.run(() {}, key: 'search');

          expect(throttle.isTrailingPending(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isTrailingPending(key: 'search'), isFalse);
          expect(throttle.isThrottled(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(key: 'search'), isFalse);

          throttle.dispose();
        });
      });

      test('recreates a keyed throttle after natural completion', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
          );

          var callCount = 0;

          throttle.run(() => callCount++, key: 'search');

          async.elapse(const Duration(milliseconds: 100));

          expect(callCount, 1);
          expect(throttle.isThrottled(key: 'search'), isFalse);

          throttle.run(() => callCount++, key: 'search');

          expect(callCount, 2);
          expect(throttle.isThrottled(key: 'search'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(throttle.isThrottled(key: 'search'), isFalse);

          throttle.dispose();
        });
      });

      test('cancel only affects the specified key', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var usersCount = 0;
          var moviesCount = 0;

          throttle.run(() => usersCount++, key: 'users');

          throttle.run(() => moviesCount++, key: 'movies');

          expect(throttle.isTrailingPending(key: 'users'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          throttle.cancel(key: 'users');

          expect(throttle.isThrottled(key: 'users'), isFalse);
          expect(throttle.isTrailingPending(key: 'users'), isFalse);

          expect(throttle.isThrottled(key: 'movies'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(usersCount, 0);
          expect(moviesCount, 1);

          throttle.dispose();
        });
      });

      test('flush only affects the specified key', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(seconds: 1),
            trailing: true,
          );

          var usersCount = 0;
          var moviesCount = 0;

          throttle.run(() => usersCount++, key: 'users');

          throttle.run(() => moviesCount++, key: 'movies');

          throttle.flush(key: 'users');

          expect(usersCount, 1);
          expect(moviesCount, 0);

          expect(throttle.isTrailingPending(key: 'users'), isFalse);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          expect(throttle.isThrottled(key: 'users'), isTrue);
          expect(throttle.isThrottled(key: 'movies'), isTrue);

          async.elapse(const Duration(seconds: 1));

          expect(moviesCount, 1);

          throttle.dispose();
        });
      });

      test('dispose removes only the specified key', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(milliseconds: 100),
            trailing: true,
          );

          var usersCount = 0;
          var recreatedUsersCount = 0;
          var moviesCount = 0;

          throttle.run(() => usersCount++, key: 'users');

          throttle.run(() => moviesCount++, key: 'movies');

          expect(throttle.isTrailingPending(key: 'users'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          throttle.dispose(key: 'users');

          expect(throttle.isThrottled(key: 'users'), isFalse);
          expect(throttle.isTrailingPending(key: 'users'), isFalse);

          expect(throttle.isThrottled(key: 'movies'), isTrue);
          expect(throttle.isTrailingPending(key: 'movies'), isTrue);

          throttle.run(() => recreatedUsersCount++, key: 'users');

          expect(throttle.isTrailingPending(key: 'users'), isTrue);

          async.elapse(const Duration(milliseconds: 100));

          expect(usersCount, 0);
          expect(recreatedUsersCount, 1);
          expect(moviesCount, 1);

          throttle.dispose();
        });
      });

      test('unknown keys are safe', () {
        final throttle = Throttle();

        expect(throttle.isThrottled(key: 'unknown'), isFalse);
        expect(throttle.isTrailingPending(key: 'unknown'), isFalse);

        expect(() => throttle.cancel(key: 'unknown'), returnsNormally);
        expect(() => throttle.flush(key: 'unknown'), returnsNormally);
        expect(() => throttle.dispose(key: 'unknown'), returnsNormally);

        throttle.dispose();
      });
    });

    group('disposal', () {
      test('dispose cancels unkeyed and keyed pending work', () {
        fakeAsync((async) {
          final throttle = Throttle(
            duration: const Duration(seconds: 1),
            trailing: true,
          );

          var unkeyedCount = 0;
          var keyedCount = 0;

          throttle.run(() => unkeyedCount++);

          throttle.run(() => keyedCount++, key: 'search');

          expect(throttle.isThrottled(), isTrue);
          expect(throttle.isThrottled(key: 'search'), isTrue);

          expect(throttle.isTrailingPending(), isTrue);
          expect(throttle.isTrailingPending(key: 'search'), isTrue);

          throttle.dispose();

          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isThrottled(key: 'search'), isFalse);

          expect(throttle.isTrailingPending(), isFalse);
          expect(throttle.isTrailingPending(key: 'search'), isFalse);

          async.elapse(const Duration(seconds: 2));

          expect(unkeyedCount, 0);
          expect(keyedCount, 0);
        });
      });

      test('dispose is idempotent and inactive operations are safe', () {
        final throttle = Throttle();

        throttle.dispose();

        expect(throttle.dispose, returnsNormally);
        expect(throttle.cancel, returnsNormally);
        expect(throttle.flush, returnsNormally);

        expect(throttle.isThrottled(), isFalse);
        expect(throttle.isTrailingPending(), isFalse);

        expect(throttle.isThrottled(key: 'search'), isFalse);
        expect(throttle.isTrailingPending(key: 'search'), isFalse);
      });

      test('cannot be run after being disposed', () {
        final throttle = Throttle();

        throttle.dispose();

        assert(() {
          expect(
            () => throttle.run(() {}),
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

    group('errors', () {
      test('throws when the instance duration is negative', () {
        expect(
          () => Throttle(duration: const Duration(milliseconds: -1)),
          throwsArgumentError,
        );
      });

      test('throws when both leading and trailing are false', () {
        expect(
          () => Throttle(leading: false, trailing: false),
          throwsArgumentError,
        );
      });
    });
  });
}
