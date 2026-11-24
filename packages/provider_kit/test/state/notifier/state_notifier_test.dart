// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/provider_kit.dart';

import '../../shared/mocks/notifiers.dart';

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

class ThrowingEquality {
  @override
  bool operator ==(Object other) {
    throw StateError('Test error');
  }

  @override
  int get hashCode => 0;
}

class ThrowingEqualityNotifier extends StateNotifier<ThrowingEquality> {
  ThrowingEqualityNotifier(super.state);

  int onErrorCallCount = 0;
  Object? receivedError;
  StackTrace? receivedStackTrace;

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);

    onErrorCallCount++;
    receivedError = error;
    receivedStackTrace = stackTrace;
  }
}

// A helper notifier that sets state in dispose (bad practice, but we test it).
class BadDisposeNotifier extends StateNotifier<int> {
  BadDisposeNotifier(super.state);

  @override
  void dispose() {
    state = 999;
    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// Test suite
// -----------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('StateNotifier', () {
    // -----------------------------------------------------------------------
    // 1. Basic state management
    // -----------------------------------------------------------------------
    test('initial state is set correctly', () {
      final notifier = TestStateNotifier<int>(42);
      expect(notifier.state, 42);
    });

    test('setting state updates the state', () {
      final notifier = TestStateNotifier<int>(0);
      notifier.state = 10;
      expect(notifier.state, 10);
    });

    test('setting same state does not notify listeners (equality check)', () {
      final notifier = TestStateNotifier<int>(5);
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
      final notifier = TestStateNotifier<int>(1);
      int callCount = 0;
      notifier.addListener(() => callCount++);

      notifier.state = 2;
      expect(callCount, 1);

      notifier.state = 3;
      expect(callCount, 2);
    });

    test('listener can be removed', () {
      final notifier = TestStateNotifier<int>(0);
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
    // 4. Protected methods can be overridden
    // -----------------------------------------------------------------------
    test('calls overridden onChange when state changes', () {
      final notifier = OnChangeNotifier(1);
      addTearDown(notifier.dispose);

      notifier.state = 2;

      expect(notifier.onChangeCallCount, 1);
      expect(notifier.state, 2);
    });

    test('dispatches error when state equality comparison throws', () {
      final initialState = ThrowingEquality();
      final notifier = ThrowingEqualityNotifier(initialState);
      addTearDown(notifier.dispose);

      expect(
        () => notifier.state = ThrowingEquality(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Test error',
          ),
        ),
      );

      expect(notifier.onErrorCallCount, 1);
      expect(notifier.receivedError, isA<StateError>());
      expect(notifier.receivedStackTrace, isNotNull);
      expect(identical(notifier.state, initialState), isTrue);
    });

    // -----------------------------------------------------------------------
    // 5. toString
    // -----------------------------------------------------------------------
    test('toString returns a meaningful description', () {
      final notifier = TestStateNotifier<String>('hello');
      expect(notifier.toString(), contains('StateNotifier'));
      expect(notifier.toString(), contains('hello'));
    });

    // -----------------------------------------------------------------------
    // 6. Dispose behaviour with pending state changes
    // -----------------------------------------------------------------------
    group('dispose behaviour', () {
      test('setting state after dispose throws FlutterError in debug mode', () {
        final notifier = TestStateNotifier<int>(0);
        notifier.dispose();
        expect(() => notifier.state = 1, throwsFlutterError);
        expect(notifier.state, 0);
      }, skip: kReleaseMode);

      test(
        'notifyListeners after dispose throws FlutterError in debug mode',
        () {
          final notifier = TestStateNotifier<int>(0);
          notifier.dispose();
          expect(() => notifier.notifyListeners(), throwsFlutterError);
        },
        skip: kReleaseMode,
      );

      test('dispose can be called multiple times', () {
        final notifier = TestStateNotifier<int>(0);

        expect(() {
          notifier.dispose();
          notifier.dispose();
          notifier.dispose();
        }, returnsNormally);
      });

      test('setting state inside dispose does not cause issue', () {
        final notifier = BadDisposeNotifier(0);
        notifier.dispose();
        // Since we set state before super.dispose(), it should have changed.
        expect(notifier.state, 999);
      });

      test(
        'setting state after dispose (via async callback) does not recurse',
        () async {
          final completer = Completer<int>();
          final notifier = TestStateNotifier<int>(0);

          Future.delayed(Duration.zero, () {});

          notifier.dispose();
          completer.complete(42);
          await completer.future;
          expect(notifier.state, 0);
        },
      );
    });
  });
}
