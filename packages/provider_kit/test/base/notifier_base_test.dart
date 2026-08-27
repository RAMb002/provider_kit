// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';
// -----------------------------------------------------------------------------
// Spy observer (copied from state_notifier_test)
// -----------------------------------------------------------------------------
class SpyObserver extends NotifierObserver {
  int onCreateCalls = 0;
  int onChangeCalls = 0;
  int onErrorCalls = 0;
  int onDisposeCalls = 0;

  NotifierBase? lastOnCreateTarget;
  NotifierBase? lastOnChangeTarget;
  Change? lastChange;
  NotifierBase? lastOnErrorTarget;
  Object? lastError;
  StackTrace? lastStackTrace;
  NotifierBase? lastOnDisposeTarget;

  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);
    onCreateCalls++;
    lastOnCreateTarget = notifier;
  }

  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    onChangeCalls++;
    lastOnChangeTarget = notifier;
    lastChange = change;
  }

  @override
  void onError(NotifierBase notifier, Object error, StackTrace stackTrace) {
    super.onError(notifier, error, stackTrace);
    onErrorCalls++;
    lastOnErrorTarget = notifier;
    lastError = error;
    lastStackTrace = stackTrace;
  }

  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);
    onDisposeCalls++;
    lastOnDisposeTarget = notifier;
  }

  void reset() {
    onCreateCalls = 0;
    onChangeCalls = 0;
    onErrorCalls = 0;
    onDisposeCalls = 0;
    lastOnCreateTarget = null;
    lastOnChangeTarget = null;
    lastChange = null;
    lastOnErrorTarget = null;
    lastError = null;
    lastStackTrace = null;
    lastOnDisposeTarget = null;
  }
}

// A simple notifier that throws in onChange to test onError.
class ThrowingNotifier extends StateNotifier<int> {
  ThrowingNotifier(super.state);

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    throw Exception('Intentional error in onChange');
  }
}

class ExposedNotifier extends StateNotifier<int> {
  ExposedNotifier(super.state);
  void callOnError(Object error, StackTrace st) => onError(error, st);
  void callOnChange(Change<int> change) => onChange(change);
}

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------
void main() {
  setUp(() {
    ProviderKit.resetForTesting();
  });
  group('lifecycle', () {
    test('mounted returns true before dispose, false after', () {
      final notifier = StateNotifier<int>(0);
      expect(notifier.mounted, isTrue);

      notifier.dispose();
      expect(notifier.mounted, isFalse);
    });

    test('debugAssertNotDisposed throws with operation hint when disposed', () {
      final notifier = StateNotifier<int>(0);
      notifier.dispose();

      expect(
        () => NotifierBase.debugAssertNotDisposed(notifier, 'test operation'),
        throwsA(isA<FlutterError>().having(
          (e) => e.message,
          'message',
          contains('test operation'),
        )),
      );
    });

    test('debugAssertNotDisposed does not throw when not disposed', () {
      final notifier = StateNotifier<int>(0);
      expect(
        () => NotifierBase.debugAssertNotDisposed(notifier),
        returnsNormally,
      );
    });

    test('dispose sets _disposed flag and notifies observer', () {
      final spy = SpyObserver();

      ProviderKit.configure(
        observer: spy,
      );

      final notifier = StateNotifier<int>(0);
      notifier.dispose();

      expect(spy.onDisposeCalls, 1);
      expect(spy.lastOnDisposeTarget, notifier);
      expect(notifier.mounted, isFalse);
    });

    test('dispose can be called multiple times safely', () {
      final notifier = StateNotifier<int>(0);
      notifier.dispose();
      expect(notifier.dispose, returnsNormally);
    });

    test('onChange asserts when called after dispose', () {
      final notifier = ExposedNotifier(0);
      notifier.dispose();

      expect(
        () => notifier
            .callOnChange(const Change<int>(currentState: 0, nextState: 1)),
        throwsFlutterError,
      );
    });

    test('onError asserts when called after dispose', () {
      final notifier = ExposedNotifier(0);
      notifier.dispose();

      expect(
        () => notifier.callOnError(Exception('test'), StackTrace.current),
        throwsFlutterError,
      );
    });
  });
  group('NotifierBase observer integration', () {
    test('default observer does nothing (no‑op)', () {
      final notifier = StateNotifier<int>(0);
      expect(() => notifier.state = 1, returnsNormally);
    });

    test('observer.onCreate is called on instantiation', () {
      final spy = SpyObserver();
      ProviderKit.configure(
        observer: spy,
      );

      final notifier = StateNotifier<int>(99);

      expect(spy.onCreateCalls, 1);
      expect(spy.lastOnCreateTarget, notifier);

      notifier.dispose();
    });

    test('observer.onChange is called on state change', () {
      final spy = SpyObserver();
      ProviderKit.configure(
        observer: spy,
      );

      final notifier = StateNotifier<int>(1);
      notifier.state = 2;

      expect(spy.onChangeCalls, 1);
      expect(spy.lastOnChangeTarget, notifier);
      expect(spy.lastChange?.currentState, 1);
      expect(spy.lastChange?.nextState, 2);

      spy.reset();
      notifier.state = 2; // same
      expect(spy.onChangeCalls, 0);

      notifier.dispose();
    });

    test('observer.onError is called when an error occurs during onChange', () {
      final spy = SpyObserver();
      ProviderKit.configure(
        observer: spy,
      );

      final notifier = ThrowingNotifier(1);
      expect(() => notifier.state = 2, throwsException);

      expect(spy.onErrorCalls, 1);
      expect(spy.lastOnErrorTarget, notifier);
      expect(spy.lastError, isA<Exception>());
      expect(spy.lastStackTrace, isNotNull);

      notifier.dispose();
    });

    test('observer.onDispose is called on dispose', () {
      final spy = SpyObserver();
      ProviderKit.configure(
        observer: spy,
      );

      final notifier = StateNotifier<int>(1);
      notifier.dispose();

      expect(spy.onDisposeCalls, 1);
      expect(spy.lastOnDisposeTarget, notifier);
    });

    test('custom observer can be set globally', () {
      final spy = SpyObserver();
      ProviderKit.configure(
        observer: spy,
      );

      final notifier = StateNotifier<int>(10);
      notifier.state = 20;
      notifier.dispose();

      expect(spy.onCreateCalls, 1);
      expect(spy.onChangeCalls, 1);
      expect(spy.onDisposeCalls, 1);
    });
  });
  group('Change', () {
    test('stores current and next states', () {
      const change = Change<int>(
        currentState: 1,
        nextState: 2,
      );

      expect(change.currentState, 1);
      expect(change.nextState, 2);
    });

    test('same instance is equal to itself', () {
      const change = Change<int>(
        currentState: 1,
        nextState: 2,
      );

      expect(change == change, isTrue);
    });

    test('changes with equal states are equal', () {
      const first = Change<int>(
        currentState: 1,
        nextState: 2,
      );
      const second = Change<int>(
        currentState: 1,
        nextState: 2,
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('changes with different current states are not equal', () {
      const first = Change<int>(
        currentState: 1,
        nextState: 2,
      );
      const second = Change<int>(
        currentState: 3,
        nextState: 2,
      );

      expect(first, isNot(equals(second)));
    });

    test('changes with different next states are not equal', () {
      const first = Change<int>(
        currentState: 1,
        nextState: 2,
      );
      const second = Change<int>(
        currentState: 1,
        nextState: 3,
      );

      expect(first, isNot(equals(second)));
    });

    test('changes with different generic types are not equal', () {
      const intChange = Change<int>(
        currentState: 1,
        nextState: 2,
      );
      const stringChange = Change<String>(
        currentState: '1',
        nextState: '2',
      );

      expect(intChange, isNot(equals(stringChange)));
    });

    test('hashCode changes when state values change', () {
      const first = Change<int>(
        currentState: 1,
        nextState: 2,
      );
      const second = Change<int>(
        currentState: 1,
        nextState: 3,
      );

      expect(first.hashCode, isNot(second.hashCode));
    });

    test('toString returns the expected representation', () {
      const change = Change<int>(
        currentState: 1,
        nextState: 2,
      );

      expect(
        change.toString(),
        'Change { currentState: 1, nextState: 2 }',
      );
    });

    test('supports complex state values', () {
      const change = Change<List<int>>(
        currentState: [1, 2],
        nextState: [3, 4],
      );

      expect(change.currentState, [1, 2]);
      expect(change.nextState, [3, 4]);
      expect(
        change.toString(),
        'Change { currentState: [1, 2], nextState: [3, 4] }',
      );
    });
  });
}
