// ignore_for_file: invalid_use_of_protected_member

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

void main() {
  group('NotifierResourcesMixin', () {
    late _TestNotifier notifier;
    var notifierDisposed = false;

    setUp(() {
      notifier = _TestNotifier();
      notifierDisposed = false;
    });

    tearDown(() {
      if (!notifierDisposed) {
        notifier.dispose();
      }
    });

    void disposeNotifier() {
      if (notifierDisposed) {
        return;
      }

      notifier.dispose();
      notifierDisposed = true;
    }

    group('resource ownership', () {
      test('disposes all owned resources when notifier is disposed', () {
        fakeAsync((async) {
          final stateField = notifier.field("initialState");

          final mutation = notifier.mutation<void>();

          final group = notifier.mutationGroup<void>();
          final groupedMutation = group('item');

          final debounce = notifier.debounce(
            duration: const Duration(seconds: 1),
          );

          final throttle = notifier.throttle(
            duration: const Duration(seconds: 1),
            leading: false,
            trailing: true,
          );

          var debounceCalls = 0;
          var throttleCalls = 0;

          debounce.run(() => debounceCalls++);
          throttle.run(() => throttleCalls++);

          expect(stateField.state, 'initialState');
          expect(stateField.mounted, isTrue);

          stateField.state = 'updatedState';

          expect(stateField.state, 'updatedState');

          expect(debounce.isPending(), isTrue);
          expect(throttle.isTrailingPending(), isTrue);

          disposeNotifier();

          async.elapse(const Duration(seconds: 2));

          expect(stateField.mounted, isFalse);

          expect(debounceCalls, 0);
          expect(throttleCalls, 0);

          expect(debounce.isPending(), isFalse);
          expect(throttle.isThrottled(), isFalse);
          expect(throttle.isTrailingPending(), isFalse);

          expect(mutation.mounted, isFalse);
          expect(groupedMutation.mounted, isFalse);

          expectLater(
            mutation.run(() async {}),
            throwsA(isA<FlutterError>()),
          );

          expectLater(
            groupedMutation.run(() async {}),
            throwsA(isA<FlutterError>()),
          );

          async.flushMicrotasks();
        });
      });

      test(
        'disposes initialized shared debounce and throttle with notifier',
        () {
          fakeAsync((async) {
            var debounceCalls = 0;
            var throttleCalls = 0;

            notifier.debounceRun(
              () => debounceCalls++,
              duration: const Duration(seconds: 1),
            );

            notifier.throttleRun(
              () => throttleCalls++,
            );

            // Default throttle is leading, so this runs immediately.
            expect(throttleCalls, 1);

            disposeNotifier();

            async.elapse(const Duration(seconds: 2));

            // Shared debounce must have been disposed.
            expect(debounceCalls, 0);
            expect(throttleCalls, 1);

            expect(
              () => notifier.debounceRun(() {}),
              throwsA(isA<StateError>()),
            );

            expect(
              () => notifier.throttleRun(() {}),
              throwsA(isA<StateError>()),
            );
          });
        },
      );

      test('disposes all created state fields with the notifier', () {
        final firstField = notifier.field('first');
        final secondField = notifier.field(0);
        final thirdField = notifier.field(false);

        expect(firstField.mounted, isTrue);
        expect(secondField.mounted, isTrue);
        expect(thirdField.mounted, isTrue);

        disposeNotifier();

        expect(firstField.mounted, isFalse);
        expect(secondField.mounted, isFalse);
        expect(thirdField.mounted, isFalse);
      });
    });

    group('resource factories', () {
      test('reject creation after notifier disposal', () {
        disposeNotifier();

        expect(
          () => notifier.field('initialState'),
          throwsA(isA<StateError>()),
        );

        expect(
          () => notifier.mutation<void>(),
          throwsA(isA<StateError>()),
        );

        expect(
          () => notifier.mutationGroup<void>(),
          throwsA(isA<StateError>()),
        );

        expect(
          () => notifier.debounce(),
          throwsA(isA<StateError>()),
        );

        expect(
          () => notifier.throttle(),
          throwsA(isA<StateError>()),
        );
      });

      test('shared rate resources reject initialization after disposal', () {
        disposeNotifier();

        expect(
          () => notifier.debounceRun(() {}),
          throwsA(isA<StateError>()),
        );

        expect(
          () => notifier.throttleRun(() {}),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('shared rate resource forwarding', () {
      test('forwards debounce key and duration', () {
        fakeAsync((async) {
          var firstCalls = 0;
          var secondCalls = 0;

          notifier.debounceRun(
            () => firstCalls++,
            key: 'first',
            duration: const Duration(milliseconds: 100),
          );

          notifier.debounceRun(
            () => secondCalls++,
            key: 'second',
            duration: const Duration(milliseconds: 200),
          );

          async.elapse(const Duration(milliseconds: 100));

          expect(firstCalls, 1);
          expect(secondCalls, 0);

          async.elapse(const Duration(milliseconds: 100));

          expect(secondCalls, 1);
        });
      });

      test('forwards throttle keys', () {
        var firstCalls = 0;
        var secondCalls = 0;

        notifier.throttleRun(
          () => firstCalls++,
          key: 'first',
        );

        notifier.throttleRun(
          () => secondCalls++,
          key: 'second',
        );

        expect(firstCalls, 1);
        expect(secondCalls, 1);
      });
    });
  });
}

class _TestNotifier extends ChangeNotifier with NotifierResourcesMixin {}
