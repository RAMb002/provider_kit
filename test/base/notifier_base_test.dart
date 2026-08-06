import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';
import 'package:provider_kit/src/base/notifier_base.dart';

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

// -----------------------------------------------------------------------------
// Tests
// -----------------------------------------------------------------------------
void main() {
  group('NotifierBase observer integration', () {
    test('default observer does nothing (no‑op)', () {
      final notifier = StateNotifier<int>(0);
      expect(() => notifier.state = 1, returnsNormally);
    });

    test('observer.onCreate is called on instantiation', () {
      final spy = SpyObserver();
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      final notifier = StateNotifier<int>(99);

      expect(spy.onCreateCalls, 1);
      expect(spy.lastOnCreateTarget, notifier);

      NotifierBase.observer = original;
    });

    test('observer.onChange is called on state change', () {
      final spy = SpyObserver();
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      final notifier = StateNotifier<int>(1);
      notifier.state = 2;

      expect(spy.onChangeCalls, 1);
      expect(spy.lastOnChangeTarget, notifier);
      expect(spy.lastChange?.currentState, 1);
      expect(spy.lastChange?.nextState, 2);

      spy.reset();
      notifier.state = 2; // same
      expect(spy.onChangeCalls, 0);

      NotifierBase.observer = original;
    });

    test('observer.onError is called when an error occurs during onChange', () {
      final spy = SpyObserver();
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      final notifier = ThrowingNotifier(1);
      expect(() => notifier.state = 2, throwsException);

      expect(spy.onErrorCalls, 1);
      expect(spy.lastOnErrorTarget, notifier);
      expect(spy.lastError, isA<Exception>());
      expect(spy.lastStackTrace, isNotNull);

      NotifierBase.observer = original;
    });

    test('observer.onDispose is called on dispose', () {
      final spy = SpyObserver();
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      final notifier = StateNotifier<int>(1);
      notifier.dispose();

      expect(spy.onDisposeCalls, 1);
      expect(spy.lastOnDisposeTarget, notifier);

      NotifierBase.observer = original;
    });

    test('custom observer can be set globally', () {
      final spy = SpyObserver();
      final original = NotifierBase.observer;
      NotifierBase.observer = spy;

      final notifier = StateNotifier<int>(10);
      notifier.state = 20;
      notifier.dispose();

      expect(spy.onCreateCalls, 1);
      expect(spy.onChangeCalls, 1);
      expect(spy.onDisposeCalls, 1);

      NotifierBase.observer = original;
    });
  });
}