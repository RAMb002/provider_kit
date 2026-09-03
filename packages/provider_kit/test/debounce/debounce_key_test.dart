import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('DebounceKey', () {
    tearDown(DebounceKey.disposeAll);

    test('runs an operation after the default duration', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
        );

        async.elapse(const Duration(milliseconds: 299));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);
      });
    });

    test('runs an operation after the provided duration', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 999));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);
      });
    });

    test('replaces a pending operation for the same key', () {
      fakeAsync((async) {
        var firstCalled = false;
        var secondCalled = false;

        DebounceKey.run(
          'search',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        DebounceKey.run(
          'search',
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
      });
    });

    test('uses the latest duration for the same key', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            fail('Previous operation should not run');
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 500));

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 99));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);
      });
    });

    test('keeps debounce operations independent for different keys', () {
      fakeAsync((async) {
        var searchCalled = false;
        var filterCalled = false;

        DebounceKey.run(
          'search',
          () {
            searchCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.run(
          'filter',
          () {
            filterCalled = true;
          },
          duration: const Duration(milliseconds: 200),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(searchCalled, isTrue);
        expect(filterCalled, isFalse);

        async.elapse(const Duration(milliseconds: 100));

        expect(filterCalled, isTrue);
      });
    });

    test('cancel prevents a pending operation from running', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.cancel('search');

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);
      });
    });

    test('can be used again after cancel', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            fail('Cancelled operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.cancel('search');

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
      });
    });

    test('cancel does not affect a different key', () {
      fakeAsync((async) {
        var firstCalled = false;
        var secondCalled = false;

        DebounceKey.run(
          'first',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.run(
          'second',
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.cancel('first');

        async.elapse(const Duration(milliseconds: 100));

        expect(firstCalled, isFalse);
        expect(secondCalled, isTrue);
      });
    });

    test('cancel is safe for a key with no debounce', () {
      expect(
        () => DebounceKey.cancel('unknown'),
        returnsNormally,
      );
    });

    test('dispose prevents a pending operation from running', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.dispose('search');

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);
      });
    });

    test('creates a new debounce when the same key is used after dispose', () {
      fakeAsync((async) {
        var called = false;

        DebounceKey.run(
          'search',
          () {
            fail('Disposed operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.dispose('search');

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
      });
    });

    test('dispose is safe for a key with no debounce', () {
      expect(
        () => DebounceKey.dispose('unknown'),
        returnsNormally,
      );
    });

    test('disposeAll prevents all pending operations from running', () {
      fakeAsync((async) {
        var firstCalled = false;
        var secondCalled = false;

        DebounceKey.run(
          'first',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.run(
          'second',
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 200),
        );

        DebounceKey.disposeAll();

        async.elapse(const Duration(seconds: 1));

        expect(firstCalled, isFalse);
        expect(secondCalled, isFalse);
      });
    });

    test('can be used again after disposeAll', () {
      fakeAsync((async) {
        DebounceKey.run(
          'search',
          () {
            fail('Disposed operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        DebounceKey.disposeAll();

        var called = false;

        DebounceKey.run(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
      });
    });

    test('disposeAll is safe when no debounces are registered', () {
      expect(
        DebounceKey.disposeAll,
        returnsNormally,
      );
    });
  });
}