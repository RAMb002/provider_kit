import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_kit/src/view_state/notifiers/async/async_notifiers.dart';

const _testTimeout = Duration(seconds: 3);

Future<T> _within<T>(Future<T> future) {
  return future.timeout(_testTimeout);
}

Future<void> _withinAll(Iterable<Future<void>> futures) {
  return _within(Future.wait<void>(futures));
}

/// Controls when each operation starts and finishes.
///
/// Every executor invocation waits on its own gate, allowing tests to
/// deterministically simulate concurrent and superseded operations.
final class _ControlledExecutor {
  _ControlledExecutor(int operationCount)
    : gates = List.generate(operationCount, (_) => Completer<void>()),
      started = List.generate(operationCount, (_) => Completer<int>()),
      finished = List.generate(operationCount, (_) => Completer<void>());

  final List<Completer<void>> gates;
  final List<Completer<int>> started;
  final List<Completer<void>> finished;

  final List<int> tokens = [];
  final List<AsyncBuildReason> reasons = [];

  int calls = 0;

  Iterable<Future<void>> get finishedFutures =>
      finished.map((completer) => completer.future);

  Future<void> call(int token, AsyncBuildReason reason) async {
    final index = calls++;

    if (index >= gates.length) {
      throw StateError('Unexpected build execution: ${index + 1}.');
    }

    tokens.add(token);
    reasons.add(reason);
    started[index].complete(token);

    try {
      await gates[index].future;
    } finally {
      finished[index].complete();
    }
  }

  void release(int index) {
    if (!gates[index].isCompleted) {
      gates[index].complete();
    }
  }

  void fail(int index, Object error, StackTrace stackTrace) {
    assert(
      index >= 0 && index < calls,
      'Cannot fail an operation that has not started.',
    );
    if (!gates[index].isCompleted) {
      gates[index].completeError(error, stackTrace);
    }
  }

  void releaseAll() {
    for (final gate in gates) {
      if (!gate.isCompleted) {
        gate.complete();
      }
    }
  }
}

final class _CapturedFailure {
  const _CapturedFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

/// Attaches an error handler immediately, avoiding unhandled-error races.
Future<_CapturedFailure> _captureFailure(Future<void> operation) async {
  try {
    await _within(operation);
  } catch (error, stackTrace) {
    return _CapturedFailure(error, stackTrace);
  }

  throw StateError('Expected the operation to fail.');
}

void _registerCleanup(AsyncBuildManager manager, _ControlledExecutor executor) {
  addTearDown(() async {
    manager.dispose();
    executor.releaseAll();

    // Wait only for operations that actually started. Pending operations that
    // never started intentionally have no executor completion to wait for.
    final startedOperations = [
      for (var i = 0; i < executor.calls; i++) executor.finished[i].future,
    ];

    if (startedOperations.isNotEmpty) {
      await _withinAll(startedOperations);
    }
  });
}

void main() {
  group('AsyncBuildManager', () {
    test(
      'starts initial work once and joins an active initial operation',
      () async {
        final manager = AsyncBuildManager();
        final executor = _ControlledExecutor(1);

        _registerCleanup(manager, executor);

        final first = manager.startInitial(executor.call);
        final token = await _within(executor.started[0].future);

        final second = manager.startInitial(executor.call);

        expect(executor.calls, 1);
        expect(executor.reasons, [AsyncBuildReason.initial]);
        expect(manager.isCurrent(token), isTrue);

        executor.release(0);

        await _withinAll([first, second]);

        expect(executor.calls, 1);
        expect(executor.finished[0].isCompleted, isTrue);
      },
    );

    test('coalesces pending rebuilds and joins the same operation from '
        'initial and refresh requests', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(1);

      _registerCleanup(manager, executor);

      var invalidations = 0;
      manager.bindOperationInvalidator(() => invalidations++);

      final first = manager.rebuild(executor.call);
      final second = manager.rebuild(executor.call);
      final third = manager.rebuild(executor.call);

      // Rebuild execution is deferred to a microtask.
      expect(executor.calls, 0);

      final initial = manager.startInitial(executor.call);
      final refresh = manager.refresh(executor.call);

      final token = await _within(executor.started[0].future);

      expect(executor.calls, 1);
      expect(executor.reasons, [AsyncBuildReason.rebuild]);

      // The pending operation must use the newest generation.
      expect(manager.isCurrent(token), isTrue);

      // Three rebuild requests and one refresh invalidate independent work.
      // startInitial joins pending work without another invalidation.
      expect(invalidations, 4);

      executor.release(0);

      await _withinAll([first, second, third, initial, refresh]);

      expect(executor.calls, 1);
      expect(executor.finished[0].isCompleted, isTrue);
    });

    test('all waiters follow successive replacements without waiting for '
        'outdated work to finish', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(3);

      _registerCleanup(manager, executor);

      final initial = manager.startInitial(executor.call);
      final initialToken = await _within(executor.started[0].future);

      // Refresh joins the active initial operation.
      final refresh = manager.refresh(executor.call);

      // Build B replaces A.
      final rebuildB = manager.rebuild(executor.call);
      final tokenB = await _within(executor.started[1].future);

      expect(manager.isCurrent(initialToken), isFalse);
      expect(manager.isCurrent(tokenB), isTrue);

      // Build C replaces B before B finishes.
      final rebuildC = manager.rebuild(executor.call);
      final tokenC = await _within(executor.started[2].future);

      expect(manager.isCurrent(tokenB), isFalse);
      expect(manager.isCurrent(tokenC), isTrue);

      expect(executor.calls, 3);
      expect(executor.reasons, [
        AsyncBuildReason.initial,
        AsyncBuildReason.rebuild,
        AsyncBuildReason.rebuild,
      ]);

      // Complete only C. A and B remain blocked.
      executor.release(2);

      await _withinAll([initial, refresh, rebuildB, rebuildC]);

      expect(executor.finished[0].isCompleted, isFalse);
      expect(executor.finished[1].isCompleted, isFalse);
      expect(executor.finished[2].isCompleted, isTrue);

      // Allow obsolete operations to finish their cleanup.
      executor.release(0);
      executor.release(1);

      await _withinAll(executor.finishedFutures);
    });

    test('obsolete operations settling do not release waiters early', () async {
      for (final obsoleteFails in [false, true]) {
        final manager = AsyncBuildManager();
        final executor = _ControlledExecutor(2);

        _registerCleanup(manager, executor);

        var initialDone = false;

        final initial = manager.startInitial(executor.call);

        // Observe completion without creating an unhandled derived error.
        initial.then<void>(
          (_) => initialDone = true,
          onError: (Object _, StackTrace __) {},
        );

        await _within(executor.started[0].future);

        final rebuild = manager.rebuild(executor.call);
        await _within(executor.started[1].future);

        // A is obsolete, while replacement B remains blocked.
        if (obsoleteFails) {
          executor.fail(
            0,
            StateError('Obsolete operation failed'),
            StackTrace.current,
          );
        } else {
          executor.release(0);
        }

        await _within(executor.finished[0].future);

        // Give the awakened waiters an event-loop turn to process A's completion.
        await Future<void>.delayed(Duration.zero);

        expect(
          initialDone,
          isFalse,
          reason: 'The initial waiter must keep waiting for replacement B.',
        );

        // B is the current operation; its completion releases both waiters.
        executor.release(1);

        await _withinAll([initial, rebuild]);

        expect(initialDone, isTrue);
        expect(executor.finished[1].isCompleted, isTrue);
      }
    });
    test(
      'ignores an obsolete build failure when its replacement succeeds',
      () async {
        final manager = AsyncBuildManager();
        final executor = _ControlledExecutor(2);

        _registerCleanup(manager, executor);

        final initial = manager.startInitial(executor.call);
        await _within(executor.started[0].future);

        final rebuild = manager.rebuild(executor.call);
        await _within(executor.started[1].future);

        // A fails after B has replaced it.
        executor.fail(
          0,
          StateError('Obsolete build failed'),
          StackTrace.current,
        );

        await _within(executor.finished[0].future);

        // B succeeds. Neither waiting caller should receive A's error.
        executor.release(1);

        await _withinAll([initial, rebuild]);

        expect(executor.calls, 2);
        expect(executor.finished[1].isCompleted, isTrue);
      },
    );

    test('propagates a current initial failure to all joined callers and '
        'allows a subsequent refresh to recover', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(2);

      _registerCleanup(manager, executor);

      final expectedError = StateError('Initial build failed');
      final expectedStackTrace = StackTrace.current;

      // Attach the first error handler immediately.
      final initialFailure = _captureFailure(
        manager.startInitial(executor.call),
      );

      final initialToken = await _within(executor.started[0].future);

      // These callers join the same active initial operation.
      final secondInitialFailure = _captureFailure(
        manager.startInitial(executor.call),
      );
      final refreshFailure = _captureFailure(manager.refresh(executor.call));

      executor.fail(0, expectedError, expectedStackTrace);

      final failures = await _within(
        Future.wait<_CapturedFailure>([
          initialFailure,
          secondInitialFailure,
          refreshFailure,
        ]),
      );

      expect(manager.isCurrent(initialToken), isTrue);

      for (final failure in failures) {
        expect(failure.error, same(expectedError));
        expect(failure.stackTrace, same(expectedStackTrace));
      }

      expect(executor.finished[0].isCompleted, isTrue);

      // The failed operation must not remain active and block a new refresh.
      final recovery = manager.refresh(executor.call);
      final recoveryToken = await _within(executor.started[1].future);

      expect(executor.calls, 2);
      expect(executor.reasons, [
        AsyncBuildReason.initial,
        AsyncBuildReason.refresh,
      ]);
      expect(manager.isCurrent(recoveryToken), isTrue);

      executor.release(1);

      await _within(recovery);

      expect(executor.finished[1].isCompleted, isTrue);
    });

    test('propagates a replacement failure with its original stack trace '
        'without waiting for obsolete work', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(2);

      _registerCleanup(manager, executor);

      final expectedError = StateError('Replacement build failed');
      final expectedStackTrace = StackTrace.current;

      final initialFailure = _captureFailure(
        manager.startInitial(executor.call),
      );

      await _within(executor.started[0].future);

      final refreshFailure = _captureFailure(manager.refresh(executor.call));

      final rebuildFailure = _captureFailure(manager.rebuild(executor.call));

      await _within(executor.started[1].future);

      // A is obsolete. B is current and fails.
      executor.fail(1, expectedError, expectedStackTrace);

      // All three handlers were attached before the replacement failed.
      final failures = await _within(
        Future.wait<_CapturedFailure>([
          initialFailure,
          refreshFailure,
          rebuildFailure,
        ]),
      );

      for (final failure in failures) {
        expect(failure.error, same(expectedError));
        expect(failure.stackTrace, same(expectedStackTrace));
      }

      // B's failure releases the waiters even while A remains blocked.
      expect(executor.finished[0].isCompleted, isFalse);
      expect(executor.finished[1].isCompleted, isTrue);

      executor.release(0);
      await _within(executor.finished[0].future);
    });

    test('a fresh refresh follows a rebuild that supersedes it', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(2);

      _registerCleanup(manager, executor);

      // No work exists, so refresh starts its own operation.
      final refresh = manager.refresh(executor.call);
      final refreshToken = await _within(executor.started[0].future);

      expect(executor.reasons, [AsyncBuildReason.refresh]);
      expect(manager.isCurrent(refreshToken), isTrue);

      // The rebuild replaces the running refresh.
      final rebuild = manager.rebuild(executor.call);
      final rebuildToken = await _within(executor.started[1].future);

      expect(manager.isCurrent(refreshToken), isFalse);
      expect(manager.isCurrent(rebuildToken), isTrue);

      // Completing the replacement releases both callers; the original
      // refresh operation is deliberately left unresolved.
      executor.release(1);

      await _withinAll([refresh, rebuild]);

      expect(executor.finished[0].isCompleted, isFalse);
      expect(executor.finished[1].isCompleted, isTrue);

      executor.release(0);
      await _withinAll(executor.finishedFutures);
    });

    test('invokes the currently registered invalidator for each accepted '
        'request and permits rebinding', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(3);

      _registerCleanup(manager, executor);

      var firstInvalidatorCalls = 0;
      var secondInvalidatorCalls = 0;

      manager.bindOperationInvalidator(() => firstInvalidatorCalls++);

      final initial = manager.startInitial(executor.call);
      await _within(executor.started[0].future);
      executor.release(0);
      await _within(initial);

      manager.bindOperationInvalidator(() => secondInvalidatorCalls++);

      final refresh = manager.refresh(executor.call);
      await _within(executor.started[1].future);
      executor.release(1);
      await _within(refresh);

      final rebuild = manager.rebuild(executor.call);
      await _within(executor.started[2].future);
      executor.release(2);
      await _within(rebuild);

      expect(firstInvalidatorCalls, 1);
      expect(secondInvalidatorCalls, 2);
    });

    test('disposal releases active and pending waiters and prevents '
        'scheduled work from starting', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(1);

      _registerCleanup(manager, executor);

      final initial = manager.startInitial(executor.call);
      final token = await _within(executor.started[0].future);

      // The replacement is pending; its scheduled microtask has not run yet.
      final pending = manager.rebuild(executor.call);

      manager.dispose();

      await _withinAll([initial, pending]);

      expect(manager.isCurrent(token), isFalse);
      expect(executor.calls, 1);

      // Every subsequent entry point is a no-op.
      await _within(manager.startInitial(executor.call));
      await _within(manager.refresh(executor.call));
      await _within(manager.rebuild(executor.call));

      expect(executor.calls, 1);

      // Disposing the manager releases waiters but doesn't cancel the
      // underlying asynchronous executor.
      expect(executor.finished[0].isCompleted, isFalse);

      executor.release(0);
      await _within(executor.finished[0].future);

      expect(executor.finished[0].isCompleted, isTrue);
    });

    test('suppresses a late executor failure after disposal has already '
        'completed its operation', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(1);

      _registerCleanup(manager, executor);

      final operation = manager.startInitial(executor.call);

      await _within(executor.started[0].future);

      manager.dispose();

      // Disposal completes the waiting operation successfully.
      await _within(operation);

      // The underlying executor fails only after its caller has been released.
      executor.fail(
        0,
        StateError('Late failure after disposal'),
        StackTrace.current,
      );

      // The executor catches the failure through _executeOperation; its
      // attempt to complete the already-completed operation is a no-op.
      await _within(executor.finished[0].future);

      expect(executor.calls, 1);
      expect(executor.finished[0].isCompleted, isTrue);
    });

    test('disposal releases callers waiting on a replacement', () async {
      final manager = AsyncBuildManager();
      final executor = _ControlledExecutor(2);

      _registerCleanup(manager, executor);

      final initial = manager.startInitial(executor.call);
      await _within(executor.started[0].future);

      final rebuild = manager.rebuild(executor.call);
      await _within(executor.started[1].future);

      // Allow the initial waiter to process the supersession and follow B.
      await Future<void>.delayed(Duration.zero);

      manager.dispose();

      await _withinAll([initial, rebuild]);

      // Disposal releases the waiters, but doesn't cancel underlying work.
      expect(executor.finished[0].isCompleted, isFalse);
      expect(executor.finished[1].isCompleted, isFalse);

      executor.releaseAll();
      await _withinAll(executor.finishedFutures);
    });
  });
}
