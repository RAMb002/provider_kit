part of '../mutation.dart';

/// Manages concurrency scheduling for a [Mutation].
///
/// This class only decides which executions can start and tracks their
/// lifecycle. Action execution, state updates, callbacks, and result
/// completion remain responsibilities of [Mutation].
class _MutationConcurrencyHandler<T> {
  _MutationConcurrencyHandler(this._policy);

  final MutationConcurrency _policy;

  /// Executions currently active, including their callbacks.
  final Set<_MutationExecution<T>> _active = {};

  /// Executions waiting for their turn under the queue policy.
  Queue<_MutationExecution<T>> _queue = Queue<_MutationExecution<T>>();

  /// The latest execution that can still publish its outcome.
  _MutationExecution<T>? _latestExecution;

  bool _disposed = false;

  /// Whether any execution is active or queued.
  bool get hasPendingExecutions => _active.isNotEmpty || _queue.isNotEmpty;

  /// Schedules [execution] according to the configured policy.
  ///
  /// The caller must verify that the owning Mutation is mounted before
  /// calling this method.
  ///
  /// Returns:
  /// - [start] when Mutation should execute it immediately.
  /// - [queued] when it must wait.
  /// - [ignored] when it must not execute.
  _ExecutionSchedule schedule(_MutationExecution<T> execution) {
    // defensive check
    // coverage:ignore-start
    if (_disposed) {
      execution.ignoreReason ??= MutationIgnoreReason.disposed;
      return _ExecutionSchedule.ignored;
    }
    // coverage:ignore-end

    switch (_policy) {
      case MutationConcurrency.parallel:
        _active.add(execution);
        return _ExecutionSchedule.start;

      case MutationConcurrency.latestOnly:
        final previous = _latestExecution;

        if (previous != null &&
            !previous.outcomeCommitted &&
            previous.ignoreReason == null) {
          previous.ignoreReason = MutationIgnoreReason.replaced;
        }

        _active.add(execution);
        _latestExecution = execution;

        return _ExecutionSchedule.start;

      case MutationConcurrency.ignoreIfBusy:
        if (_active.isNotEmpty) {
          execution.ignoreReason = MutationIgnoreReason.busy;
          return _ExecutionSchedule.ignored;
        }

        _active.add(execution);
        return _ExecutionSchedule.start;

      case MutationConcurrency.queue:
        if (_active.isNotEmpty) {
          _queue.addLast(execution);
          return _ExecutionSchedule.queued;
        }

        _active.add(execution);
        return _ExecutionSchedule.start;
    }
  }

  /// Marks an execution as completed and selects the next queued execution.
  ///
  /// Returns the next execution to start, or `null` when there is none.
  _MutationExecution<T>? complete(_MutationExecution<T> execution) {
    final wasActive = _active.remove(execution);

    if (wasActive && identical(_latestExecution, execution)) {
      _latestExecution = null;
    }

    if (!wasActive ||
        _disposed ||
        _policy != MutationConcurrency.queue ||
        _active.isNotEmpty ||
        _queue.isEmpty) {
      return null;
    }

    final next = _queue.removeFirst();
    _active.add(next);

    return next;
  }

  /// Invalidates active executions and removes queued executions.
  ///
  /// Active executions retain their original ignore reason if already
  /// invalidated. Queued executions receive [MutationIgnoreReason.reset].
  ///
  /// Returns the removed executions so Mutation can complete their Futures.
  Queue<_MutationExecution<T>> reset() {
    for (final execution in _active) {
      if (!execution.outcomeCommitted) {
        execution.ignoreReason ??= MutationIgnoreReason.reset;
      }
    }

    _latestExecution = null;

    return _drainQueue(MutationIgnoreReason.reset);
  }

  /// Prevents new executions and invalidates outstanding executions.
  ///
  /// Running actions are not cancelled. Their eventual outcomes are ignored.
  ///
  /// Returns queued executions so Mutation can complete their Futures.
  Queue<_MutationExecution<T>> dispose() {
    // defensive check
    // coverage:ignore-start
    if (_disposed) {
      return Queue<_MutationExecution<T>>();
    }
    // coverage:ignore-end

    _disposed = true;

    for (final execution in _active) {
      if (!execution.outcomeCommitted) {
        execution.ignoreReason ??= MutationIgnoreReason.disposed;
      }
    }

    _latestExecution = null;

    return _drainQueue(MutationIgnoreReason.disposed);
  }

  /// Removes and marks all queued executions with [reason].
  ///
  /// Detaches the existing queue instead of copying its contents.
  Queue<_MutationExecution<T>> _drainQueue(MutationIgnoreReason reason) {
    final queued = _queue;
    _queue = Queue<_MutationExecution<T>>();

    for (final execution in queued) {
      execution.ignoreReason ??= reason;
    }

    return queued;
  }
}

/// Describes what the concurrency handler decided for an execution.
enum _ExecutionSchedule {
  /// The execution can start immediately.
  start,

  /// The execution must wait in the queue.
  queued,

  /// The execution must not start.
  ignored,
}
