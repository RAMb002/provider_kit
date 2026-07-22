import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

/// A spy observer that records all callback invocations.
class SpyObserver extends StateObserver {
  int onCreateCalls = 0;
  int onChangeCalls = 0;
  int onErrorCalls = 0;
  int onDisposeCalls = 0;

  StateNotifierBase? lastOnCreateTarget;
  StateNotifierBase? lastOnChangeTarget;
  Change? lastChange;
  StateNotifierBase? lastOnErrorTarget;
  Object? lastError;
  StackTrace? lastStackTrace;
  StateNotifierBase? lastOnDisposeTarget;

  @override
  void onCreate(StateNotifierBase notifier) {
    super.onCreate(notifier);
    onCreateCalls++;
    lastOnCreateTarget = notifier;
  }

  @override
  void onChange(StateNotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    onChangeCalls++;
    lastOnChangeTarget = notifier;
    lastChange = change;
  }

  @override
  void onError(StateNotifierBase notifier, Object error, StackTrace stackTrace) {
    super.onError(notifier, error, stackTrace);
    onErrorCalls++;
    lastOnErrorTarget = notifier;
    lastError = error;
    lastStackTrace = stackTrace;
  }

  @override
  void onDispose(StateNotifierBase notifier) {
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

/// A notifier that counts `onChange` calls.
class OnChangeNotifier extends StateNotifier<int> {
  OnChangeNotifier(super.state);

  int onChangeCallCount = 0;

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    onChangeCallCount++;
  }
}

/// A notifier that tracks whether `onError` was called.
class OnErrorNotifier extends StateNotifier<int> {
  OnErrorNotifier(super.state);

  bool onErrorCalled = false;

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    onErrorCalled = true;
  }
}

/// A notifier that throws inside `onChange` to trigger `onError`.
class ThrowingOnChangeNotifier extends StateNotifier<int> {
  ThrowingOnChangeNotifier(super.state);

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    throw Exception('Intentional error in onChange');
  }
}

/// A notifier that extends `OnErrorNotifier` and also throws in `onChange`.
class CombinedErrorNotifier extends OnErrorNotifier {
  CombinedErrorNotifier(super.state);

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    throw Exception('Forced error');
  }
}

// -----------------------------------------------------------------------------
// Test suite
// -----------------------------------------------------------------------------

void main() {
  group('StateNotifier', () {
    // -----------------------------------------------------------------------
    // 1. Basic state management
    // -----------------------------------------------------------------------
    test('initial state is set correctly', () {
      final notifier = StateNotifier<int>(42);
      expect(notifier.state, 42);
    });

    test('setting state updates the state', () {
      final notifier = StateNotifier<int>(0);
      notifier.state = 10;
      expect(notifier.state, 10);
    });

    test('setting same state does not notify listeners (equality check)', () {
      final notifier = StateNotifier<int>(5);
      int listenerCallCount = 0;
      notifier.addListener(() => listenerCallCount++);

      notifier.state = 5; // same value
      expect(listenerCallCount, 0);

      notifier.state = 6; // different
      expect(listenerCallCount, 1);
    });

    // -----------------------------------------------------------------------
    // 2. Listener notification
    // -----------------------------------------------------------------------
    test('listeners are notified when state changes', () {
      final notifier = StateNotifier<int>(1);
      int callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.state = 2;
      expect(callCount, 1);

      notifier.state = 3;
      expect(callCount, 2);
    });

    test('listener can be removed', () {
      final notifier = StateNotifier<int>(0);
      int callCount = 0;
      void listener() => callCount++;
      notifier.addListener(listener);

      notifier.state = 1;
      expect(callCount, 1);

      notifier.removeListener(listener);
      notifier.state = 2;
      expect(callCount, 1);
    });

    // -----------------------------------------------------------------------
    // 3. Observer integration (grouped)
    // -----------------------------------------------------------------------
    group('observer integration', () {
      test('default observer does nothing (no-op)', () {
        final notifier = StateNotifier<int>(0);
        expect(() => notifier.state = 1, returnsNormally);
      });

      test('observer.onCreate is called on instantiation', () {
        final spy = SpyObserver();
        final original = StateNotifier.observer;
        StateNotifier.observer = spy;

        final notifier = StateNotifier<int>(99);

        expect(spy.onCreateCalls, 1);
        expect(spy.lastOnCreateTarget, notifier);

        StateNotifier.observer = original;
      });

      test('observer.onChange is called on state change', () {
        final spy = SpyObserver();
        final original = StateNotifier.observer;
        StateNotifier.observer = spy;

        final notifier = StateNotifier<int>(1);
        notifier.state = 2;

        expect(spy.onChangeCalls, 1);
        expect(spy.lastOnChangeTarget, notifier);
        expect(spy.lastChange?.currentState, 1);
        expect(spy.lastChange?.nextState, 2);

        spy.reset();
        notifier.state = 2; // same
        expect(spy.onChangeCalls, 0);

        StateNotifier.observer = original;
      });

      test('observer.onError is called when an error occurs during onChange', () {
        final spy = SpyObserver();
        final original = StateNotifier.observer;
        StateNotifier.observer = spy;

        final notifier = ThrowingOnChangeNotifier(1);
        expect(() => notifier.state = 2, throwsException);

        expect(spy.onErrorCalls, 1);
        expect(spy.lastOnErrorTarget, notifier);
        expect(spy.lastError, isA<Exception>());
        expect(spy.lastStackTrace, isNotNull);

        StateNotifier.observer = original;
      });

      test('observer.onDispose is called on dispose', () {
        final spy = SpyObserver();
        final original = StateNotifier.observer;
        StateNotifier.observer = spy;

        final notifier = StateNotifier<int>(1);
        notifier.dispose();

        expect(spy.onDisposeCalls, 1);
        expect(spy.lastOnDisposeTarget, notifier);

        StateNotifier.observer = original;
      });

      test('custom observer can be set globally', () {
        final spy = SpyObserver();
        final original = StateNotifier.observer;
        StateNotifier.observer = spy;

        final notifier = StateNotifier<int>(10);
        notifier.state = 20;
        notifier.dispose();

        expect(spy.onCreateCalls, 1);
        expect(spy.onChangeCalls, 1);
        expect(spy.onDisposeCalls, 1);

        StateNotifier.observer = original;
      });
    });

    // -----------------------------------------------------------------------
    // 4. Protected methods can be overridden
    // -----------------------------------------------------------------------
    test('onChange can be overridden (and super is called)', () {
      final notifier = OnChangeNotifier(1);
      notifier.state = 2;
      expect(notifier.onChangeCallCount, 1);
    });

    test('onError can be overridden (and super is called)', () {
      final notifier = CombinedErrorNotifier(1);
      expect(() => notifier.state = 2, throwsException);
      expect(notifier.onErrorCalled, true);
    });

    // -----------------------------------------------------------------------
    // 5. Dispose
    // -----------------------------------------------------------------------
    test('setting state after dispose throws AssertionError', () {
      final notifier = StateNotifier<int>(0);
      notifier.dispose();
      expect(() => notifier.state = 1, throwsAssertionError);
    });

    test('dispose can only be called once; second call throws FlutterError', () {
      final notifier = StateNotifier<int>(0);
      notifier.dispose();
      expect(() => notifier.dispose(), throwsFlutterError);
    });

    // -----------------------------------------------------------------------
    // 6. toString
    // -----------------------------------------------------------------------
    test('toString returns a meaningful description', () {
      final notifier = StateNotifier<String>('hello');
      expect(notifier.toString(), contains('StateNotifier'));
      expect(notifier.toString(), contains('hello'));
    });
  });
}