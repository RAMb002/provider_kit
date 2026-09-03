import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

class _TestNotifier extends ChangeNotifier with DebounceMixin {}

class _TestStateNotifier extends StateNotifier<int> with DebounceMixin {
  _TestStateNotifier() : super(0);
}

void main() {
  group('DebounceMixin', () {
    test('runs the default debounce after the default duration', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(() {
          called = true;
        });

        async.elapse(const Duration(milliseconds: 299));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('runs after the provided duration', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 999));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('replaces a pending default operation and restarts the delay', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var firstCalled = false;
        var secondCalled = false;

        notifier.debounce(
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        notifier.debounce(
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

        notifier.dispose();
      });
    });

    test('uses the latest duration for the default debounce', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            fail('Previous operation should not run');
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 500));

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 99));
        expect(called, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('default debounce reports pending status correctly', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        expect(notifier.isDebouncePending, isFalse);

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebouncePending, isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
        expect(notifier.isDebouncePending, isFalse);

        notifier.dispose();
      });
    });

    test('keyed debounce reports pending status correctly', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        expect(notifier.isDebounceKeyPending('search'), isFalse);

        notifier.debounceKey(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebounceKeyPending('search'), isTrue);

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);
        expect(notifier.isDebounceKeyPending('search'), isFalse);

        notifier.dispose();
      });
    });

    test('default debounce is no longer pending after cancellation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();

        notifier.debounce(
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebouncePending, isTrue);

        notifier.cancelDebounce();

        expect(notifier.isDebouncePending, isFalse);

        notifier.dispose();
      });
    });

    test('default debounce is no longer pending after disposal', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();

        notifier.debounce(
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebouncePending, isTrue);

        notifier.disposeDebounce();

        expect(notifier.isDebouncePending, isFalse);

        notifier.dispose();
      });
    });

    test('keyed debounce is no longer pending after cancellation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();

        notifier.debounceKey(
          'search',
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebounceKeyPending('search'), isTrue);

        notifier.cancelDebounceKey('search');

        expect(notifier.isDebounceKeyPending('search'), isFalse);

        notifier.dispose();
      });
    });

    test('keyed debounce is no longer pending after disposal', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();

        notifier.debounceKey(
          'search',
          () {},
          duration: const Duration(milliseconds: 100),
        );

        expect(notifier.isDebounceKeyPending('search'), isTrue);

        notifier.disposeDebounceKey('search');

        expect(notifier.isDebounceKeyPending('search'), isFalse);

        notifier.dispose();
      });
    });

    test('cancelDebounce prevents the default pending operation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.cancelDebounce();

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);

        notifier.dispose();
      });
    });

    test('default debounce can be used again after cancellation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            fail('Cancelled operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.cancelDebounce();

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('keyed debounce operations are independent', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var usersCalled = false;
        var moviesCalled = false;

        notifier.debounceKey(
          'users',
          () {
            usersCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.debounceKey(
          'movies',
          () {
            moviesCalled = true;
          },
          duration: const Duration(milliseconds: 200),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(usersCalled, isTrue);
        expect(moviesCalled, isFalse);

        async.elapse(const Duration(milliseconds: 100));

        expect(moviesCalled, isTrue);

        notifier.dispose();
      });
    });

    test('replaces a pending operation for the same key', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var firstCalled = false;
        var secondCalled = false;

        notifier.debounceKey(
          'search',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 50));

        notifier.debounceKey(
          'search',
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(firstCalled, isFalse);
        expect(secondCalled, isTrue);

        notifier.dispose();
      });
    });

    test('uses the latest duration for the same key', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounceKey(
          'search',
          () {
            fail('Previous operation should not run');
          },
          duration: const Duration(seconds: 1),
        );

        async.elapse(const Duration(milliseconds: 500));

        notifier.debounceKey(
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

        notifier.dispose();
      });
    });

    test('cancelDebounceKey only cancels the specified key', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var firstCalled = false;
        var secondCalled = false;

        notifier.debounceKey(
          'first',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.debounceKey(
          'second',
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.cancelDebounceKey('first');

        async.elapse(const Duration(milliseconds: 100));

        expect(firstCalled, isFalse);
        expect(secondCalled, isTrue);

        notifier.dispose();
      });
    });

    test('keyed debounce can be used again after cancellation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounceKey(
          'search',
          () {
            fail('Cancelled operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.cancelDebounceKey('search');

        notifier.debounceKey(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('disposeDebounce prevents the default pending operation', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.disposeDebounce();

        async.elapse(const Duration(seconds: 1));

        expect(called, isFalse);

        notifier.dispose();
      });
    });

    test('default debounce can be created again after disposeDebounce', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounce(
          () {
            fail('Disposed operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.disposeDebounce();

        notifier.debounce(
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('disposeDebounceKey prevents only the specified pending operation',
        () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var firstCalled = false;
        var secondCalled = false;

        notifier.debounceKey(
          'first',
          () {
            firstCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.debounceKey(
          'second',
          () {
            secondCalled = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.disposeDebounceKey('first');

        async.elapse(const Duration(milliseconds: 100));

        expect(firstCalled, isFalse);
        expect(secondCalled, isTrue);

        notifier.dispose();
      });
    });

    test('keyed debounce can be created again after disposeDebounceKey', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();
        var called = false;

        notifier.debounceKey(
          'search',
          () {
            fail('Disposed operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.disposeDebounceKey('search');

        notifier.debounceKey(
          'search',
          () {
            called = true;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(called, isTrue);

        notifier.dispose();
      });
    });

    test('dispose automatically cancels all pending debounce operations', () {
      fakeAsync((async) {
        final notifier = _TestNotifier();

        notifier.debounce(
          () {
            fail('Default operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.debounceKey(
          'users',
          () {
            fail('Users operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.debounceKey(
          'movies',
          () {
            fail('Movies operation should not run');
          },
          duration: const Duration(milliseconds: 100),
        );

        notifier.dispose();

        async.elapse(const Duration(seconds: 1));
      });
    });

    test('works with StateNotifier', () {
      fakeAsync((async) {
        final notifier = _TestStateNotifier();

        notifier.debounce(
          () {
            notifier.state = 1;
          },
          duration: const Duration(milliseconds: 100),
        );

        async.elapse(const Duration(milliseconds: 100));

        expect(notifier.state, 1);

        notifier.dispose();
      });
    });
    test(
      'works with ViewStateNotifier',
      () {
        fakeAsync((async) {
          final notifier = _TestViewStateNotifier(const InitialState());

          var called = false;

          notifier.runDebounce(
            () {
              called = true;
            },
          );

          async.elapse(const Duration(milliseconds: 300));

          expect(called, isTrue);

          notifier.dispose();
        });
      },
    );

    test(
      'works with AsyncViewStateNotifier',
      () {
        fakeAsync((async) {
          final notifier = _TestAsyncViewStateNotifier();

          var called = false;

          notifier.runDebounce(
            () {
              called = true;
            },
          );

          async.elapse(const Duration(milliseconds: 300));

          expect(called, isTrue);

          notifier.dispose();
        });
      },
    );
  });
}

class _TestViewStateNotifier extends ViewStateNotifier with DebounceMixin {
  _TestViewStateNotifier(super.state);

  void runDebounce(
    void Function() operation,
  ) {
    debounce(operation);
  }
}

class _TestAsyncViewStateNotifier extends AsyncViewStateNotifier
    with DebounceMixin {
  void runDebounce(
    void Function() operation,
  ) {
    debounce(operation);
  }

  @override
  FutureOr<dynamic> fetchData() {
    return null;
  }
}
