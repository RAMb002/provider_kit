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

// A notifier whose onChange hook throws, testing Flutter error reporting.
class ThrowingNotifier extends StateNotifier<int> {
  ThrowingNotifier(super.state);

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    throw Exception('Intentional error in onChange');
  }
}

class DispatchProbeNotifier extends StateNotifier<int> {
  DispatchProbeNotifier(super.state);

  int onChangeHookCalls = 0;
  int onErrorHookCalls = 0;

  Object? hookError;
  StackTrace? hookStackTrace;

  Change<int>? hookChange;
  int? stateDuringOnChange;

  bool disposeFromOnChange = false;
  bool disposeFromOnError = false;
  bool throwFromOnError = false;

  void emitChange(Change<int> change) {
    dispatchChange(change);
  }

  void emitError(Object error, StackTrace stackTrace) {
    dispatchError(error, stackTrace);
  }

  void emitErrorToObserver(Object error, StackTrace stackTrace) {
    dispatchErrorToObserver(error, stackTrace);
  }

  @override
  void onChange(Change<int> change) {
    onChangeHookCalls++;
    hookChange = change;
    stateDuringOnChange = state;

    if (disposeFromOnChange) {
      dispose();
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    onErrorHookCalls++;
    hookError = error;
    hookStackTrace = stackTrace;

    if (disposeFromOnError) {
      dispose();
      return;
    }

    if (throwFromOnError) {
      throw StateError('Intentional onError hook failure');
    }
  }
}

class ThrowingOnChangeObserver extends SpyObserver {
  @override
  void onChange(NotifierBase notifier, Change change) {
    super.onChange(notifier, change);
    throw StateError('Intentional observer onChange failure');
  }
}

class ThrowingOnErrorObserver extends SpyObserver {
  @override
  void onError(NotifierBase notifier, Object error, StackTrace stackTrace) {
    super.onError(notifier, error, stackTrace);
    throw StateError('Intentional observer onError failure');
  }
}

class ThrowingOnCreateObserver extends SpyObserver {
  @override
  void onCreate(NotifierBase notifier) {
    super.onCreate(notifier);
    throw StateError('Intentional observer onCreate failure');
  }
}

class ThrowingOnDisposeObserver extends SpyObserver {
  @override
  void onDispose(NotifierBase notifier) {
    super.onDispose(notifier);
    throw StateError('Intentional observer onDispose failure');
  }
}

VoidCallback captureBaseTestFlutterErrors(List<FlutterErrorDetails> errors) {
  final previousHandler = FlutterError.onError;
  FlutterError.onError = errors.add;

  return () {
    FlutterError.onError = previousHandler;
  };
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
        throwsA(
          isA<FlutterError>().having(
            (e) => e.message,
            'message',
            contains('test operation'),
          ),
        ),
      );
    });

    test('debugAssertNotDisposed does not throw when not disposed', () {
      final notifier = StateNotifier<int>(0);
      addTearDown(notifier.dispose);

      expect(
        () => NotifierBase.debugAssertNotDisposed(notifier),
        returnsNormally,
      );
    });

    test('dispose sets _disposed flag and notifies observer', () {
      final spy = SpyObserver();

      ProviderKit.configure(observer: spy);

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

    test('dispatchChange asserts when called after dispose', () {
      final notifier = DispatchProbeNotifier(0);
      notifier.dispose();

      expect(
        () => notifier.emitChange(
          const Change<int>(currentState: 0, nextState: 1),
        ),
        throwsFlutterError,
      );
    });
    test('dispatchError asserts when called after dispose', () {
      final notifier = DispatchProbeNotifier(0);
      notifier.dispose();

      expect(
        () => notifier.emitError(Exception('test'), StackTrace.current),
        throwsFlutterError,
      );
    });
    test('dispatchErrorToObserver asserts when called after dispose', () {
      final notifier = DispatchProbeNotifier(0);
      notifier.dispose();

      expect(
        () =>
            notifier.emitErrorToObserver(Exception('test'), StackTrace.current),
        throwsFlutterError,
      );
    });
  });
  group('NotifierBase observer integration', () {
    test('default observer does nothing (no‑op)', () {
      final notifier = StateNotifier<int>(0);
      addTearDown(notifier.dispose);
      expect(() => notifier.state = 1, returnsNormally);
    });

    test('observer.onCreate is called on instantiation', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

      final notifier = StateNotifier<int>(99);

      expect(spy.onCreateCalls, 1);
      expect(spy.lastOnCreateTarget, notifier);

      notifier.dispose();
    });

    test('observer.onChange is called on state change', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

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

    test('onChange hook sees the previous state before the update', () {
      final notifier = DispatchProbeNotifier(1);
      addTearDown(notifier.dispose);

      notifier.state = 2;

      expect(notifier.onChangeHookCalls, 1);
      expect(notifier.stateDuringOnChange, 1);

      expect(notifier.hookChange?.currentState, 1);
      expect(notifier.hookChange?.nextState, 2);

      // After the hook finishes, the new state is published.
      expect(notifier.state, 2);
    });

    test('reports an onChange hook exception without dispatching onError', () {
      final spy = SpyObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      final previousErrorHandler = FlutterError.onError;
      FlutterError.onError = reportedErrors.add;
      addTearDown(() {
        FlutterError.onError = previousErrorHandler;
      });

      ProviderKit.configure(observer: spy);

      final notifier = ThrowingNotifier(1);
      addTearDown(notifier.dispose);

      // The hook exception is caught and reported, not rethrown.
      expect(() => notifier.state = 2, returnsNormally);

      // The state change still succeeds.
      expect(notifier.state, 2);

      // The global observer still receives the change.
      expect(spy.onChangeCalls, 1);
      expect(spy.lastOnChangeTarget, notifier);
      expect(spy.lastChange?.currentState, 1);
      expect(spy.lastChange?.nextState, 2);

      // A hook exception is not dispatched as a notifier error.
      expect(spy.onErrorCalls, 0);

      // Flutter receives the original hook exception.
      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception,
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Intentional error in onChange'),
        ),
      );
    });

    test('reports an onChange hook exception without dispatching onError', () {
      final spy = SpyObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      addTearDown(captureBaseTestFlutterErrors(reportedErrors));
      ProviderKit.configure(observer: spy);

      final notifier = ThrowingNotifier(1);
      addTearDown(notifier.dispose);

      expect(() => notifier.state = 2, returnsNormally);

      expect(notifier.state, 2);
      expect(spy.onChangeCalls, 1);
      expect(spy.onErrorCalls, 0);

      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception.toString(),
        contains('Intentional error in onChange'),
      );
    });

    test('onChange hook disposing notifier prevents state update', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

      final notifier = DispatchProbeNotifier(1)..disposeFromOnChange = true;
      addTearDown(notifier.dispose);

      var listenerCalls = 0;
      notifier.addListener(() => listenerCalls++);

      expect(() => notifier.state = 2, returnsNormally);

      expect(notifier.mounted, isFalse);
      expect(notifier.state, 1);
      expect(listenerCalls, 0);

      expect(spy.onChangeCalls, 0);
      expect(spy.onDisposeCalls, 1);
    });

    test(
      'onError hook disposing notifier skips observer error notification',
      () {
        final spy = SpyObserver();
        ProviderKit.configure(observer: spy);

        final notifier = DispatchProbeNotifier(0)..disposeFromOnError = true;

        final error = Exception('original error');
        final stackTrace = StackTrace.current;

        expect(() => notifier.emitError(error, stackTrace), returnsNormally);

        expect(notifier.mounted, isFalse);
        expect(notifier.onErrorHookCalls, 1);

        expect(spy.onDisposeCalls, 1);
        expect(spy.onErrorCalls, 0);
      },
    );
    test('custom observer can be set globally', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

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
      const change = Change<int>(currentState: 1, nextState: 2);

      expect(change.currentState, 1);
      expect(change.nextState, 2);
    });

    test('same instance is equal to itself', () {
      const change = Change<int>(currentState: 1, nextState: 2);

      expect(change == change, isTrue);
    });

    test('changes with equal states are equal', () {
      const first = Change<int>(currentState: 1, nextState: 2);
      const second = Change<int>(currentState: 1, nextState: 2);

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('changes with different current states are not equal', () {
      const first = Change<int>(currentState: 1, nextState: 2);
      const second = Change<int>(currentState: 3, nextState: 2);

      expect(first, isNot(equals(second)));
    });

    test('changes with different next states are not equal', () {
      const first = Change<int>(currentState: 1, nextState: 2);
      const second = Change<int>(currentState: 1, nextState: 3);

      expect(first, isNot(equals(second)));
    });

    test('changes with different generic types are not equal', () {
      const intChange = Change<int>(currentState: 1, nextState: 2);
      const stringChange = Change<String>(currentState: '1', nextState: '2');

      expect(intChange, isNot(equals(stringChange)));
    });

    test('hashCode changes when state values change', () {
      const first = Change<int>(currentState: 1, nextState: 2);
      const second = Change<int>(currentState: 1, nextState: 3);

      expect(first.hashCode, isNot(second.hashCode));
    });

    test('toString returns the expected representation', () {
      const change = Change<int>(currentState: 1, nextState: 2);

      expect(change.toString(), 'Change { currentState: 1, nextState: 2 }');
    });

    test('supports complex state values', () {
      const change = Change<List<int>>(currentState: [1, 2], nextState: [3, 4]);

      expect(change.currentState, [1, 2]);
      expect(change.nextState, [3, 4]);
      expect(
        change.toString(),
        'Change { currentState: [1, 2], nextState: [3, 4] }',
      );
    });
  });

  group('NotifierBase dispatch robustness', () {
    test('dispatchError invokes onError hook and notifies observer', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

      final notifier = DispatchProbeNotifier(0);
      addTearDown(notifier.dispose);

      final error = Exception('original error');
      final stackTrace = StackTrace.current;

      notifier.emitError(error, stackTrace);

      expect(notifier.onErrorHookCalls, 1);
      expect(notifier.hookError, same(error));
      expect(notifier.hookStackTrace, same(stackTrace));

      expect(spy.onErrorCalls, 1);
      expect(spy.lastOnErrorTarget, same(notifier));
      expect(spy.lastError, same(error));
      expect(spy.lastStackTrace, same(stackTrace));
    });

    test('dispatchErrorToObserver skips the overridable onError hook', () {
      final spy = SpyObserver();
      ProviderKit.configure(observer: spy);

      final notifier = DispatchProbeNotifier(0);
      addTearDown(notifier.dispose);

      final error = Exception('observer-only error');
      final stackTrace = StackTrace.current;

      notifier.emitErrorToObserver(error, stackTrace);

      expect(notifier.onErrorHookCalls, 0);

      expect(spy.onErrorCalls, 1);
      expect(spy.lastOnErrorTarget, same(notifier));
      expect(spy.lastError, same(error));
      expect(spy.lastStackTrace, same(stackTrace));
    });

    test(
      'dispatchError reports hook exceptions and still notifies observer',
      () {
        final spy = SpyObserver();
        final reportedErrors = <FlutterErrorDetails>[];

        addTearDown(captureBaseTestFlutterErrors(reportedErrors));

        ProviderKit.configure(observer: spy);

        final notifier = DispatchProbeNotifier(0)..throwFromOnError = true;
        addTearDown(notifier.dispose);

        final originalError = Exception('original error');
        final originalStackTrace = StackTrace.current;

        expect(
          () => notifier.emitError(originalError, originalStackTrace),
          returnsNormally,
        );

        expect(notifier.onErrorHookCalls, 1);

        expect(spy.onErrorCalls, 1);
        expect(spy.lastError, same(originalError));
        expect(spy.lastStackTrace, same(originalStackTrace));

        expect(reportedErrors, hasLength(1));
        expect(
          reportedErrors.single.exception,
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Intentional onError hook failure',
          ),
        );
      },
    );

    test('dispatchChange reports observer exceptions without throwing', () {
      final observer = ThrowingOnChangeObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      addTearDown(captureBaseTestFlutterErrors(reportedErrors));

      ProviderKit.configure(observer: observer);

      final notifier = StateNotifier<int>(1);
      addTearDown(notifier.dispose);

      expect(() => notifier.state = 2, returnsNormally);

      expect(notifier.state, 2);
      expect(observer.onChangeCalls, 1);
      expect(observer.lastOnChangeTarget, same(notifier));

      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Intentional observer onChange failure',
        ),
      );
    });

    test('dispatchError reports observer exceptions without throwing', () {
      final observer = ThrowingOnErrorObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      addTearDown(captureBaseTestFlutterErrors(reportedErrors));

      ProviderKit.configure(observer: observer);

      final notifier = DispatchProbeNotifier(0);
      addTearDown(notifier.dispose);

      final originalError = Exception('original error');
      final originalStackTrace = StackTrace.current;

      expect(
        () => notifier.emitError(originalError, originalStackTrace),
        returnsNormally,
      );

      expect(observer.onErrorCalls, 1);
      expect(observer.lastError, same(originalError));
      expect(observer.lastStackTrace, same(originalStackTrace));

      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Intentional observer onError failure',
        ),
      );
    });

    test(
      'onChange hook disposing notifier skips observer notification and state update',
      () {
        final spy = SpyObserver();
        ProviderKit.configure(observer: spy);

        final notifier = DispatchProbeNotifier(1)..disposeFromOnChange = true;
        addTearDown(notifier.dispose);

        var listenerCalls = 0;
        notifier.addListener(() => listenerCalls++);

        expect(() => notifier.state = 2, returnsNormally);

        expect(notifier.onChangeHookCalls, 1);
        expect(notifier.mounted, isFalse);
        expect(notifier.state, 1);

        expect(spy.onChangeCalls, 0);
        expect(spy.onDisposeCalls, 1);
        expect(listenerCalls, 0);
      },
    );

    test(
      'onError hook disposing notifier skips observer error notification',
      () {
        final spy = SpyObserver();
        ProviderKit.configure(observer: spy);

        final notifier = DispatchProbeNotifier(0)..disposeFromOnError = true;

        final error = Exception('original error');
        final stackTrace = StackTrace.current;

        expect(() => notifier.emitError(error, stackTrace), returnsNormally);

        expect(notifier.onErrorHookCalls, 1);
        expect(notifier.mounted, isFalse);

        // Disposal is reported, but the error event is not dispatched afterward.
        expect(spy.onDisposeCalls, 1);
        expect(spy.onErrorCalls, 0);
      },
    );

    test('throwing onDispose observer does not prevent disposal', () {
      final observer = ThrowingOnDisposeObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      addTearDown(captureBaseTestFlutterErrors(reportedErrors));

      ProviderKit.configure(observer: observer);

      final notifier = StateNotifier<int>(0);
      addTearDown(notifier.dispose);

      expect(notifier.dispose, returnsNormally);

      expect(notifier.mounted, isFalse);
      expect(observer.onDisposeCalls, 1);
      expect(observer.lastOnDisposeTarget, same(notifier));

      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Intentional observer onDispose failure',
        ),
      );
    });

    test('throwing onCreate observer does not prevent construction', () {
      final observer = ThrowingOnCreateObserver();
      final reportedErrors = <FlutterErrorDetails>[];

      addTearDown(captureBaseTestFlutterErrors(reportedErrors));

      ProviderKit.configure(observer: observer);

      final notifier = StateNotifier<int>(0);
      addTearDown(notifier.dispose);

      expect(notifier.mounted, isTrue);
      expect(notifier.state, 0);
      expect(observer.onCreateCalls, 1);
      expect(observer.lastOnCreateTarget, same(notifier));

      expect(reportedErrors, hasLength(1));
      expect(
        reportedErrors.single.exception,
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Intentional observer onCreate failure',
        ),
      );
    });
  });
}
