import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('Debounce', () {
    test('runs an operation after the default duration', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(() {
          called = true;
        });

        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 299));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        debounce.dispose();
      });
    });

    test('runs an operation after the provided duration', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 999));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        debounce.dispose();
      });
    });

    test('replaces a pending operation when run is called again', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var firstCalled = false;
        var secondCalled = false;

        debounce.run(
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        debounce.run(
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        expect(firstCalled, isFalse);
        expect(secondCalled, isFalse);

        async.elapse(const Duration(milliseconds: 50));

        expect(firstCalled, isFalse);
        expect(secondCalled, isTrue);

        debounce.dispose();
      });
    });

    test('uses the latest duration when run is called again', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            fail('Previous operation should not run');
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 500));

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 99));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        debounce.dispose();
      });
    });

    test('isPending is true while an operation is waiting to be executed', () {
      fakeAsync((async) {
        final debounce = Debounce();

        expect(debounce.isPending, isFalse);

        debounce.run(() {});

        expect(debounce.isPending, isTrue);

        async.elapse(const Duration(milliseconds: 300));

        expect(debounce.isPending, isFalse);

        debounce.dispose();
      });
    });

    test('isPending becomes false after the operation executes', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending, isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
        expect(debounce.isPending, isFalse);

        debounce.dispose();
      });
    });

    test('isPending is false after a pending operation is cancelled', () {
      fakeAsync((async) {
        final debounce = Debounce();

        debounce.run(
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending, isTrue);

        debounce.cancel();

        expect(debounce.isPending, isFalse);

        debounce.dispose();
      });
    });

    test('isPending is false after the debounce is disposed', () {
      fakeAsync((async) {
        final debounce = Debounce();

        debounce.run(
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(debounce.isPending, isTrue);

        debounce.dispose();

        expect(debounce.isPending, isFalse);
      });
    });

    test('cancel prevents a pending operation from running', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        debounce.cancel();

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);

        debounce.dispose();
      });
    });

    test('cancel does not prevent the debounce from being used again', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            fail('Cancelled operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        debounce.cancel();

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);

        debounce.dispose();
      });
    });

    test('cancel is safe when there is no pending operation', () {
      final debounce = Debounce();

      expect(
        debounce.cancel,
        returnsNormally,
      );

      debounce.dispose();
    });

    test('dispose prevents a pending operation from running', () {
      fakeAsync((async) {
        final debounce = Debounce();
        var called = false;

        debounce.run(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        debounce.dispose();

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);
      });
    });

    test('cannot be run after being disposed', () {
      final debounce = Debounce();

      debounce.dispose();

      expect(
        () => debounce.run(() {}),
        throwsA(
          isA<FlutterError>().having(
            (error) => error.message,
            'message',
            contains('used after being disposed'),
          ),
        ),
      );
    });

    test('cancel after dispose does not throw', () {
      final debounce = Debounce();

      debounce.dispose();

      expect(
        debounce.cancel,
        returnsNormally,
      );
    });

    test('dispose can be called more than once', () {
      final debounce = Debounce();

      debounce.dispose();

      expect(
        debounce.dispose,
        returnsNormally,
      );
    });
  });
}
